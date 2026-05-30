### Full config matrix

| Group | Config | Hinting | Multifd ch | QEMU | Description |
|-------|--------|---------|------------|------|-------------|
| Baseline | A0 | none | 0 | mainline | precopy, no compression |
| Baseline | A2 | none | 2 | mainline | multifd 2ch, no compression |
| Baseline | A4 | none | 4 | mainline | multifd 4ch, no compression |
| Baseline | A8 | none | 8 | mainline | multifd 8ch, no compression |
| Baseline | B0 | none | 0 | mainline | balloon hinting, no multifd |
| Baseline | B2 | none | 2 | mainline | balloon + 2ch (obslete) |
| Baseline | B4 | none | 4 | mainline | balloon + 4ch (obslete) |
| Baseline | B8 | none | 8 | mainline | balloon + 8ch (obslete) |
| Codec | G0 | xbzrle | 0 | mainline | XBZRLE only, no multifd |
| Codec | H4 | zstd | 4 | mainline | multifd 4ch + zstd |
| Codec | H8 | zstd | 8 | mainline | multifd 8ch + zstd |
| Codec | I4 | zlib | 4 | mainline | multifd 4ch + zlib |
| Codec | I8 | zlib | 8 | mainline | multifd 8ch + zlib |
| Proposed | J4 | xbzrle | 4 | patched | multifd 4ch + XBZRLE (*)|
| Proposed | J8 | xbzrle | 8 | patched | multifd 8ch + XBZRLE (*)|
| Extended | C | eBPF host-side | 0 | mainline | Host-side hinting, no multifd |
| Extended | G | eBPF host-side | 2 | mainline | eBPF + 2ch multifd (degraded) |
| Extended | H | eBPF host-side | 4 | mainline | eBPF + 4ch multifd (degraded) |
| Extended | I | eBPF host-side | 8 | mainline | eBPF + 8ch multifd (degraded) |
| Extended | G' | eBPF host-side | 2 | patched | eBPF + 2ch + fix |
| Extended | H' | eBPF host-side | 4 | patched | eBPF + 4ch + fix |
| Extended | I' | eBPF host-side | 8 | patched | eBPF + 8ch + fix |

