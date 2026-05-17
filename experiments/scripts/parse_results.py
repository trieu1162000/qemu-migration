#!/usr/bin/env python3
import os, re, glob, statistics
from collections import defaultdict

def parse_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
    except Exception:
        return None

    d = {}
    # 1. Extract integer metrics
    for key, pat in [
        ('total_ms', r'total=(\d+)'),
        ('down_ms',  r'down=(\d+)'),
        ('normal',   r'normal=(\d+)'),
        ('zero',     r'zero=(\d+)'),
    ]:
        m = re.search(pat, text)
        d[key] = float(m.group(1)) if m else None

    # 2. Extract data transferred (supports both GiB and MiB dynamically)
    xfer_match = re.search(r'transferred=([\d.]+)\s+(GiB|MiB)', text)
    if xfer_match:
        val = float(xfer_match.group(1))
        unit = xfer_match.group(2)
        # Normalize all values to GiB for consistent statistical calculations
        d['xfer_gib'] = val / 1024 if unit == 'MiB' else val
    else:
        d['xfer_gib'] = None

    parts = os.path.basename(path).split('-')
    if len(parts) < 3:
        return None

    d['config']   = parts[0]
    d['workload'] = parts[1]

    # 3. Extract exact run index from file name (e.g., 'run1' -> 1) to prevent column shifting
    run_match = re.search(r'run(\d+)', parts[2])
    d['run_idx'] = int(run_match.group(1)) if run_match else None

    return d

# Scan all .txt result logs recursively
base_dir = os.path.expanduser('~/workspace/qemu-migration/experiments/results')
all_files = glob.glob(os.path.join(base_dir, '**/*.txt'), recursive=True)

# Initialize a fixed map structure for Run 1 to Run 5 to ensure slot alignment
groups = defaultdict(lambda: {i: {} for i in range(1, 6)})

for f in all_files:
    parsed = parse_file(f)
    if parsed and parsed['run_idx'] in range(1, 6):
        cfg = parsed['config']
        wl = parsed['workload']
        idx = parsed['run_idx']
        groups[(cfg, wl)][idx] = parsed

# Table layout presentation header
print(f"\n{'Config':<7} {'Workload':<9} {'Metric':<13} {'Run 1':<8} {'Run 2':<8} {'Run 3':<8} {'Run 4':<8} {'Run 5':<8} | {'Min':<8} {'Max':<8} {'Avg':<8}")
print("-" * 105)

for (cfg, wl), run_dict in sorted(groups.items()):
    # Map metrics sequentially from Run 1 through Run 5
    normals = [run_dict[i].get('normal') for i in range(1, 6)]
    xfers   = [run_dict[i].get('xfer_gib') for i in range(1, 6)]
    downs   = [run_dict[i].get('down_ms') for i in range(1, 6)]

    # Filter out None values to avoid math errors during min/max/mean calculations
    v_normals = [v for v in normals if v is not None]
    v_xfers   = [v for v in xfers if v is not None]
    v_downs   = [v for v in downs if v is not None]

    # Format helper: padds missing slots with "-" safely if a text log is corrupted/absent
    def fmt_run(val, is_float=False):
        if val is None: return "-"
        return f"{val:.2f}" if is_float else f"{val:.0f}"

    if v_normals:
        # Line 1: Normal Pages
        print(f"{cfg:<7} {wl:<9} {'normal':<13} "
              f"{fmt_run(normals[0]):<8} {fmt_run(normals[1]):<8} {fmt_run(normals[2]):<8} {fmt_run(normals[3]):<8} {fmt_run(normals[4]):<8} | "
              f"{min(v_normals):<8.0f} {max(v_normals):<8.0f} {statistics.mean(v_normals):<8.0f}")

        # Line 2: Transferred GiB
        if v_xfers:
            print(f"{'':<7} {'':<9} {'xfer GiB':<13} "
                  f"{fmt_run(xfers[0], True):<8} {fmt_run(xfers[1], True):<8} {fmt_run(xfers[2], True):<8} {fmt_run(xfers[3], True):<8} {fmt_run(xfers[4], True):<8} | "
                  f"{min(v_xfers):<8.2f} {max(v_xfers):<8.2f} {statistics.mean(v_xfers):<8.2f}")

        # Line 3: Downtime ms
        if v_downs:
            print(f"{'':<7} {'':<9} {'down ms':<13} "
                  f"{fmt_run(downs[0]):<8} {fmt_run(downs[1]):<8} {fmt_run(downs[2]):<8} {fmt_run(downs[3]):<8} {fmt_run(downs[4]):<8} | "
                  f"{min(v_downs):<8.0f} {max(v_downs):<8.0f} {statistics.mean(v_downs):<8.0f}")
        print("-" * 105)

# Calculate improvement percentages (Savings) with clear labels
print("\n=== Hinting savings (B vs A based on Average) ===")
for wl in ['idle', 'mem', 'cpu']:
    a_runs = groups.get(('A', wl), {})
    b_runs = groups.get(('B', wl), {})

    a_normals = [a_runs[i].get('normal') for i in range(1, 6) if a_runs[i].get('normal') is not None]
    b_normals = [b_runs[i].get('normal') for i in range(1, 6) if b_runs[i].get('normal') is not None]

    if a_normals and b_normals:
        a_avg = statistics.mean(a_normals)
        b_avg = statistics.mean(b_normals)

        # Calculate percentage change from baseline A to variant B
        diff_pct = ((b_avg - a_avg) / a_avg) * 100

        if diff_pct <= 0:
            status = f"[Reduced/Saved {abs(diff_pct):.1f}%]"
        else:
            status = f"[Increased/Worse +{diff_pct:.1f}%]"

        print(f"  {wl:<6}: {a_avg:.0f} -> {b_avg:.0f} normal pages  {status}")
