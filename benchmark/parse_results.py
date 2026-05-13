#!/usr/bin/env python3
import os, re, glob, statistics
from collections import defaultdict

def parse_file(path):
    text = open(path).read()
    d = {}
    for key, pat in [
        ('total_ms', r'total=(\d+)'),
        ('down_ms',  r'down=(\d+)'),
        ('xfer_gib', r'transferred=([\d.]+) GiB'),
        ('normal',   r'normal=(\d+)'),
        ('zero',     r'zero=(\d+)'),
    ]:
        m = re.search(pat, text)
        d[key] = float(m.group(1)) if m else None
    parts = os.path.basename(path).split('-')
    d['config']   = parts[0] if len(parts) > 0 else '?'
    d['workload'] = parts[1] if len(parts) > 1 else '?'
    return d

#files = sorted(glob.glob(os.path.expanduser('~/workspace/qemu-migration/results/*.txt')))
# Get all files
all_files = sorted(glob.glob(os.path.expanduser('~/workspace/qemu-migration/results/*.txt')))

# Exclude conditions*
files = [f for f in all_files if not os.path.basename(f).startswith('conditions')]
rows = [parse_file(f) for f in files]

groups = defaultdict(list)
for r in rows:
    groups[(r['config'], r['workload'])].append(r)

print(f"\n{'Config':<8} {'Workload':<8} {'Runs':<5} {'normal(med)':<14} {'xfer GiB(med)':<16} {'down ms(med)'}")
print("-" * 68)
for (cfg, wl), items in sorted(groups.items()):
    normals = [r['normal'] for r in items if r['normal']]
    xfers   = [r['xfer_gib'] for r in items if r['xfer_gib']]
    downs   = [r['down_ms'] for r in items if r['down_ms']]
    if normals:
        print(f"{cfg:<8} {wl:<8} {len(items):<5} "
              f"{statistics.median(normals):<14.0f} "
              f"{statistics.median(xfers) if xfers else 'N/A':<16} "
              f"{statistics.median(downs) if downs else 'N/A'}")

print("\n=== Hinting savings (B vs A) ===")
for wl in ['idle', 'mem', 'cpu']:
    a = groups.get(('A', wl), [])
    b = groups.get(('B', wl), [])
    if a and b:
        a_n = statistics.median([r['normal'] for r in a if r['normal']])
        b_n = statistics.median([r['normal'] for r in b if r['normal']])
        saving = (a_n - b_n) / a_n * 100
        print(f"  {wl:<6}: {a_n:.0f} -> {b_n:.0f} normal pages  ({saving:+.1f}%)")
