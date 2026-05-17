### Full config matrix

| Group | Config | Hinting | Multifd ch | QEMU | Description |
|-------|--------|---------|------------|------|-------------|
| Core | A | None | 0 | mainline | baseline |
| Core | B | virtio-balloon | 0 | mainline | pure hinting |
| Core | A2 | None | 2 | mainline | multifd 2ch, no hinting |
| Core | A4 | None | 4 | mainline | multifd 4ch, no hinting |
| Core | A8 | None | 8 | mainline | multifd 8ch, no hinting |
| Core | D | virtio-balloon | 2 | mainline | Balloon + 2ch multifd (degraded) |
| Core | E | virtio-balloon | 4 | mainline | Balloon + 4ch multifd (degraded) |
| Core | F | virtio-balloon | 8 | mainline | Balloon + 8ch multifd (degraded) |
| Core | D' | virtio-balloon | 2 | patched | Balloon + 2ch + fix |
| Core | E' | virtio-balloon | 4 | patched | Balloon + 4ch + fix |
| Core | F' | virtio-balloon | 8 | patched | Balloon + 8ch + fix |
| Extended | C | eBPF host-side | 0 | mainline | Host-side hinting, no multifd |
| Extended | G | eBPF host-side | 2 | mainline | eBPF + 2ch multifd (degraded) |
| Extended | H | eBPF host-side | 4 | mainline | eBPF + 4ch multifd (degraded) |
| Extended | I | eBPF host-side | 8 | mainline | eBPF + 8ch multifd (degraded) |
| Extended | G' | eBPF host-side | 2 | patched | eBPF + 2ch + fix |
| Extended | H' | eBPF host-side | 4 | patched | eBPF + 4ch + fix |
| Extended | I' | eBPF host-side | 8 | patched | eBPF + 8ch + fix |
