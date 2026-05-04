// SPDX-License-Identifier: GPL-2.0
/*
 * bpf_iter_buddyallocator — BPF kfuncs that let eBPF programs iterate over
 * the Linux buddy allocator's free-page lists.
 *
 * Provides:
 *   bpf_iter_buddyallocator_new(it, order)   — initialize iterator
 *   bpf_iter_buddyallocator_next(it)          — get next free page (or NULL)
 *   bpf_iter_buddyallocator_destroy(it)       — clean up (no-op here)
 *
 * Used by R1 (Storniolo et al. JSA 2024) to feed free-page hints to QEMU
 * live migration via qemu_guest_free_page_hint().
 *
 * DRAFT — research prototype for verifying approach correctness.
 *
 * LIMITATIONS:
 *   - Does NOT hold zone->lock during iteration (best-effort, may see stale
 *     data if pages are freed mid-iteration, but will not crash).
 *   - Iterates all migrate types including MIGRATE_ISOLATE (conservative).
 *   - Single-node-first design; NUMA awareness is best-effort.
 *
 * COMPATIBILITY:
 *   - Kernel 5.18+  (BTF_SET8 API, KF_RET_NULL flag)
 *   - Kernel 5.15–5.17: see #if guards below (BTF_SET API)
 *   - Kernel 6.0+: __bpf_kfunc macro available
 *
 * BUILD:
 *   make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
 *
 * LOAD:
 *   sudo insmod buddyiter.ko
 *   # Verify: sudo dmesg | grep buddyiter
 *
 * VERIFY (quick smoke test):
 *   sudo bpftool prog load test.bpf.o /sys/fs/bpf/test
 *   # Should see buddy pages in kernel ring buffer
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/bpf.h>
#include <linux/btf.h>
#include <linux/btf_ids.h>
#include <linux/mmzone.h>
#include <linux/mm.h>
#include <linux/nodemask.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Research prototype — extending Storniolo et al. JSA 2024");
MODULE_DESCRIPTION("BPF kfuncs: bpf_iter_buddyallocator for live migration free-page hints");
MODULE_VERSION("0.1-draft");

/* ── Compatibility shim ────────────────────────────────────────────────────── */

#ifndef __bpf_kfunc
/* Introduced in kernel 6.0. On older kernels just use noinline + __used. */
#define __bpf_kfunc noinline __used
#endif

/* ── Public struct (must match the eBPF program's declaration exactly) ─────── */

/*
 * Opaque iterator state handed to the eBPF program.
 * 17 × u64 = 136 bytes — enough to hold our full state without allocation.
 *
 * The eBPF program declares this as:
 *   struct bpf_iter_buddyallocator { __u64 __opaque[17]; } __attribute__((aligned(8)));
 */
struct bpf_iter_buddyallocator {
	__u64 __opaque[17];
} __attribute__((aligned(8)));

/*
 * Element returned by _next(). Must match eBPF program's declaration:
 *   struct return_elem_iter { uint64_t physical_address; uint64_t order; };
 */
struct return_elem_iter {
	u64 physical_address;
	u64 order;
};

/* ── Internal iterator state (fits inside bpf_iter_buddyallocator) ─────────── */

/*
 * Five-level traversal: node → zone → order → migrate-type → page in list.
 * Stored in the opaque field; no heap allocation needed.
 */
struct buddy_state {
	/* Current position in the 5-level hierarchy */
	s32 nid;          /* NUMA node index */
	s32 zone_idx;     /* zone index within node */
	s32 order;        /* buddy order (0 … MAX_ORDER-1) */
	s32 migtype;      /* migrate type (0 … MIGRATE_TYPES-1) */

	/* Configuration */
	s32 start_order;  /* minimum order to iterate (from _new parameter) */
	s32 done;         /* 1 when the iterator is exhausted */

	u32 _pad1;        /* alignment padding */
	u32 _pad2;

	/* Current position within the active free list */
	u64 pos;          /* struct list_head * — next entry to yield */
	u64 end;          /* struct list_head * — sentinel (head of list) */

	/* Result slot — _next returns a pointer into here */
	struct return_elem_iter result;  /* 16 bytes */

	/* Padding to fill 136 bytes exactly */
	u64 _reserved[7];
};

static_assert(sizeof(struct buddy_state) == sizeof(struct bpf_iter_buddyallocator),
	      "buddy_state size mismatch — adjust _reserved[]");

/* ── Iterator helpers ────────────────────────────────────────────────────── */

/*
 * Walk forward from the current (nid, zone_idx, order, migtype) to find the
 * next non-empty free list.  Updates s->pos and s->end on success.
 * Sets s->done=1 if all lists are exhausted.
 *
 * NOTE: caller must set s->migtype to the desired STARTING migtype before
 *       calling (i.e., already incremented past the exhausted list).
 */
static void find_next_nonempty(struct buddy_state *s)
{
	while (s->nid < nr_node_ids) {
		pg_data_t *pgdat = NODE_DATA(s->nid);

		if (!pgdat || !pgdat->nr_zones) {
			s->nid++;
			s->zone_idx = 0;
			s->order    = s->start_order;
			s->migtype  = 0;
			continue;
		}

		while (s->zone_idx < pgdat->nr_zones) {
			struct zone *z = &pgdat->node_zones[s->zone_idx];

			while (s->order < MAX_ORDER) {
				while (s->migtype < MIGRATE_TYPES) {
					struct list_head *h =
						&z->free_area[s->order].free_list[s->migtype];

					if (!list_empty(h)) {
						/* Found a non-empty list */
						s->pos = (u64)(uintptr_t)h->next;
						s->end = (u64)(uintptr_t)h;
						return;
					}
					s->migtype++;
				}
				s->migtype = 0;
				s->order++;
			}

			s->order   = s->start_order;
			s->migtype = 0;
			s->zone_idx++;
		}

		s->zone_idx = 0;
		s->order    = s->start_order;
		s->migtype  = 0;
		s->nid++;
	}

	s->done = 1;
}

/* ── kfunc implementations ───────────────────────────────────────────────── */

/**
 * bpf_iter_buddyallocator_new - Initialize a buddy allocator iterator.
 * @it:    Opaque iterator state (on BPF stack).
 * @order: Minimum buddy order to include (0 = all orders, pass 0 to match R1).
 *
 * After return, the first call to _next() yields the first free page.
 */
__bpf_kfunc int
bpf_iter_buddyallocator_new(struct bpf_iter_buddyallocator *it, s64 order)
{
	struct buddy_state *s = (struct buddy_state *)it;

	memset(s, 0, sizeof(*s));

	s->start_order = (order >= 0 && order < MAX_ORDER) ? (s32)order : 0;
	s->order       = s->start_order;
	/* pos == end == 0: first call to _next will trigger find_next_nonempty */

	return 0;
}
EXPORT_SYMBOL_GPL(bpf_iter_buddyallocator_new);

/**
 * bpf_iter_buddyallocator_next - Yield the next free page.
 * @it: Opaque iterator state.
 *
 * Returns pointer to the current result (valid until next _next call), or
 * NULL when exhausted.  The BPF verifier treats NULL return as loop exit.
 *
 * WARNING: We do not hold zone->lock.  Physical addresses returned are
 * best-effort and may be stale (page already allocated) by the time the
 * caller processes them.  For free-page hinting this is acceptable — QEMU
 * will simply skip the hint for pages that were reallocated.
 */
__bpf_kfunc struct return_elem_iter *
bpf_iter_buddyallocator_next(struct bpf_iter_buddyallocator *it)
{
	struct buddy_state *s = (struct buddy_state *)it;
	struct list_head *pos, *end;
	struct page *page;

	if (s->done)
		return NULL;

	/* If pos == end, current list is empty/exhausted — advance. */
	if (s->pos == s->end) {
		find_next_nonempty(s);
		if (s->done)
			return NULL;
	}

	/* Yield the page at current pos */
	pos  = (struct list_head *)(uintptr_t)s->pos;
	end  = (struct list_head *)(uintptr_t)s->end;
	page = list_entry(pos, struct page, lru);

	s->result.physical_address = page_to_phys(page);
	s->result.order            = (u64)s->order;

	/* Advance position; if we reach end, next _next() will advance list */
	s->pos = (u64)(uintptr_t)pos->next;

	/* If we just consumed the last element, move to next migrate type now
	 * so _next() immediately advances rather than needing a no-op call. */
	if (s->pos == s->end) {
		s->migtype++;
		find_next_nonempty(s);
		/* If done, result is still valid for this call — return it. */
	}

	return &s->result;
}
EXPORT_SYMBOL_GPL(bpf_iter_buddyallocator_next);

/**
 * bpf_iter_buddyallocator_destroy - Clean up iterator.
 * @it: Opaque iterator state.
 *
 * No-op since all state is embedded in @it (on BPF stack).
 */
__bpf_kfunc void
bpf_iter_buddyallocator_destroy(struct bpf_iter_buddyallocator *it)
{
	/* Nothing to free — state is on BPF stack */
	(void)it;
}
EXPORT_SYMBOL_GPL(bpf_iter_buddyallocator_destroy);

/* ── BTF registration ────────────────────────────────────────────────────── */

/*
 * Kernel 5.18+ uses BTF_SET8 with per-function flags (KF_RET_NULL etc).
 * Kernel 5.15-5.17 uses the older BTF_SET API without flags.
 */

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 18, 0)

BTF_SET8_START(buddy_kfunc_ids)
BTF_ID_FLAGS(func, bpf_iter_buddyallocator_new)
BTF_ID_FLAGS(func, bpf_iter_buddyallocator_next, KF_RET_NULL)
BTF_ID_FLAGS(func, bpf_iter_buddyallocator_destroy)
BTF_SET8_END(buddy_kfunc_ids)

static const struct btf_kfunc_id_set buddy_kfunc_set = {
	.owner = THIS_MODULE,
	.set   = &buddy_kfunc_ids,
};

#else /* 5.15 – 5.17 */

BTF_SET_START(buddy_ret_null_set)
BTF_ID(func, bpf_iter_buddyallocator_next)
BTF_SET_END(buddy_ret_null_set)

static const struct btf_kfunc_id_set buddy_kfunc_set = {
	.owner       = THIS_MODULE,
	.ret_null_set = &buddy_ret_null_set,
};

#endif

/* ── Module init / exit ──────────────────────────────────────────────────── */

static int __init buddyiter_init(void)
{
	int ret;

	ret = register_btf_kfunc_id_set(BPF_PROG_TYPE_KPROBE, &buddy_kfunc_set);
	if (ret) {
		pr_err("buddyiter: failed to register BTF kfuncs: %d\n", ret);
		return ret;
	}

	pr_info("buddyiter: bpf_iter_buddyallocator kfuncs registered "
		"(MAX_ORDER=%d, MIGRATE_TYPES=%d)\n",
		MAX_ORDER, MIGRATE_TYPES);
	return 0;
}

static void __exit buddyiter_exit(void)
{
	pr_info("buddyiter: unloaded\n");
}

module_init(buddyiter_init);
module_exit(buddyiter_exit);
