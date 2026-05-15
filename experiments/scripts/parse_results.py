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
    # Skip invalid file formats (e.g., result.txt or conditions-*.txt)
    if len(parts) < 3:
        return None
        
    d['config']   = parts[0]
    d['workload'] = parts[1]
    return d

# Recursively scan all .txt files inside results/ and its subdirectories
base_dir = os.path.expanduser('~/workspace/qemu-migration/experiments/results')
all_files = sorted(glob.glob(os.path.join(base_dir, '**/*.txt'), recursive=True))

rows = []
for f in all_files:
    parsed = parse_file(f)
    if parsed:  # Only append if parsing was successful
        rows.append(parsed)

groups = defaultdict(list)
for r in rows:
    groups[(r['config'], r['workload'])].append(r)

# Table layout configuration
print(f"\n{'Config':<7} {'Workload':<9} {'Metric':<13} {'Run 1':<8} {'Run 2':<8} {'Run 3':<8} {'Run 4':<8} {'Run 5':<8} | {'Min':<8} {'Max':<8} {'Avg':<8}")
print("-" * 105)

for (cfg, wl), items in sorted(groups.items()):
    normals = [r['normal'] for r in items if r['normal'] is not None]
    xfers   = [r['xfer_gib'] for r in items if r['xfer_gib'] is not None]
    downs   = [r['down_ms'] for r in items if r['down_ms'] is not None]
    
    # Helper functions to pad missing runs if fewer than 5 files exist
    def pad_runs(lst):
        return [f"{v:.0f}" for v in lst] + ["-"] * (5 - len(lst))
    def pad_runs_float(lst):
        return [f"{v:.2f}" for v in lst] + ["-"] * (5 - len(lst))

    if normals:
        # 1. Normal Pages row
        n_runs = pad_runs(normals)
        print(f"{cfg:<7} {wl:<9} {'normal':<13} "
              f"{n_runs[0]:<8} {n_runs[1]:<8} {n_runs[2]:<8} {n_runs[3]:<8} {n_runs[4]:<8} | "
              f"{min(normals):<8.0f} {max(normals):<8.0f} {statistics.mean(normals):<8.0f}")
        
        # 2. Transferred GiB row
        if xfers:
            x_runs = pad_runs_float(xfers)
            print(f"{'':<7} {'':<9} {'xfer GiB':<13} "
                  f"{x_runs[0]:<8} {x_runs[1]:<8} {x_runs[2]:<8} {x_runs[3]:<8} {x_runs[4]:<8} | "
                  f"{min(xfers):<8.2f} {max(xfers):<8.2f} {statistics.mean(xfers):<8.2f}")
                  
        # 3. Downtime row
        if downs:
            d_runs = pad_runs(downs)
            print(f"{'':<7} {'':<9} {'down ms':<13} "
                  f"{d_runs[0]:<8} {d_runs[1]:<8} {d_runs[2]:<8} {d_runs[3]:<8} {d_runs[4]:<8} | "
                  f"{min(downs):<8.0f} {max(downs):<8.0f} {statistics.mean(downs):<8.0f}")
        print("-" * 105)

print("\n=== Hinting savings (B vs A based on Average) ===")
for wl in ['idle', 'mem', 'cpu']:
    a = groups.get(('A', wl), [])
    b = groups.get(('B', wl), [])
    if a and b:
        a_normals = [r['normal'] for r in a if r['normal'] is not None]
        b_normals = [r['normal'] for r in b if r['normal'] is not None]
        if a_normals and b_normals:
            a_avg = statistics.mean(a_normals)
            b_avg = statistics.mean(b_normals)
            saving = (a_avg - b_avg) / a_avg * 100
            print(f"  {wl:<6}: {a_avg:.0f} -> {b_avg:.0f} normal pages  ({saving:+.1f}%)")

