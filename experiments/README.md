## Full config matrix

| Group | Config | Method | Multifd ch | QEMU | Description |
|-------|--------|---------|------------|------|-------------|
| Baseline | A0 | none | 0 | mainline | precopy, no compression |
| Baseline | A2 | none | 2 | mainline | multifd 2ch, no compression |
| Baseline | A4 | none | 4 | mainline | multifd 4ch, no compression |
| Baseline | A8 | none | 8 | mainline | multifd 8ch, no compression |
| Codec | G0 | xbzrle | 0 | mainline | XBZRLE only, no multifd |
| Codec | H4 | zstd | 4 | mainline | multifd 4ch + zstd |
| Codec | H8 | zstd | 8 | mainline | multifd 8ch + zstd |
| Codec | I4 | zlib | 4 | mainline | multifd 4ch + zlib |
| Codec | I8 | zlib | 8 | mainline | multifd 8ch + zlib |
| Proposed | J4 | xbzrle | 4 | patched | multifd 4ch + XBZRLE (*)|
| Proposed | J8 | xbzrle | 8 | patched | multifd 8ch + XBZRLE (*)|
| Extended | K4 | xbzrle + zstd | 4 | patched | multifd 4ch + zstd + XBZRLE (*)|
| Extended | K8 | xbzrle + zstd | 8 | patched | multifd 8ch + zstd + XBZRLE (*)|
| Extended | L4 | xbzrle + zlib | 4 | patched | multifd 4ch + zlib + XBZRLE (*)|
| Extended | L8 | xbzrle + zlib | 8 | patched | multifd 8ch + zlib + XBZRLE (*)|

##  Result - Total Migration Time (seconds)

### W1 - idle

| Config | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Min | Max | Avg |
|--------|------:|------:|------:|------:|------:|----:|----:|----:|
| A0 | 195.0 | 195.0 | 195.0 | 195.1 | 195.1 | 195.0 | 195.1 | 195.0 |
| A2 | 113.2 | 113.5 | 113.0 | 113.1 | 113.8 | 113.0 | 113.8 | 113.3 |
| A4 | 77.8 | 77.3 | 77.5 | 77.0 | 76.7 | 76.7 | 77.8 | 77.3 |
| A8 | 46.8 | 47.4 | 47.1 | 46.5 | 47.5 | 46.5 | 47.5 | 47.1 |
| B0 | 44.2 | 44.2 | 44.2 | 44.2 | 44.2 | 44.2 | 44.2 | 44.2 |
| B2 | 22.6 | 22.9 | 22.9 | 23.1 | 23.0 | 22.6 | 23.1 | 22.9 |
| B4 | 18.5 | 18.8 | 18.2 | 18.6 | 18.1 | 18.1 | 18.8 | 18.4 |
| B8 | 11.6 | 11.9 | 11.6 | 12.2 | 11.9 | 11.6 | 12.2 | 11.8 |
| G0 | 194.9 | 195.0 | 195.0 | 194.9 | 194.9 | 194.9 | 195.0 | 194.9 |
| H4 | 11.9 | 12.1 | 12.2 | 12.5 | 11.7 | 11.7 | 12.5 | 12.1 |
| H8 | 10.9 | 10.6 | 10.7 | 11.1 | 11.1 | 10.6 | 11.1 | 10.9 |
| I4 | 14.3 | 14.7 | 14.4 | 14.4 | 13.8 | 13.8 | 14.7 | 14.3 |
| I8 | 13.0 | 13.2 | 12.9 | 13.0 | 12.9 | 12.9 | 13.2 | 13.0 |
| **J4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **J8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |

### W2 - mem (dd fill, static)

| Config | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Min | Max | Avg |
|--------|------:|------:|------:|------:|------:|----:|----:|----:|
| A0 | 196.8 | 196.7 | 197.0 | 196.7 | 196.8 | 196.7 | 197.0 | 196.8 |
| A2 | 113.7 | 113.3 | 112.8 | 113.0 | 113.3 | 112.8 | 113.7 | 113.2 |
| A4 | 77.1 | 77.3 | 78.5 | 78.3 | 77.9 | 77.1 | 78.5 | 77.8 |
| A8 | 48.4 | 48.3 | 47.3 | 48.7 | 47.3 | 47.3 | 48.7 | 48.0 |
| B0 | 198.0 | 198.2 | 198.0 | 198.1 | 201.2 | 198.0 | 201.2 | 198.7 |
| B2 | 115.2 | 115.9 | 115.3 | 114.1 | 115.5 | 114.1 | 115.9 | 115.2 |
| B4 | 78.3 | 78.3 | 78.0 | 76.5 | 86.9 | 76.5 | 86.9 | 79.6 |
| B8 | 48.2 | 47.9 | 47.5 | 47.2 | 47.3 | 47.2 | 48.2 | 47.6 |
| G0 | 196.5 | 196.6 | 196.7 | 196.6 | 196.7 | 196.5 | 196.7 | 196.6 |
| H4 | 11.6 | 12.2 | 11.6 | 11.9 | 12.3 | 11.6 | 12.3 | 11.9 |
| H8 | 10.5 | 10.7 | 10.3 | 10.9 | 9.8 | 9.8 | 10.9 | 10.4 |
| I4 | 14.4 | 14.1 | 14.2 | 13.7 | 14.5 | 13.7 | 14.5 | 14.2 |
| I8 | 13.0 | 13.2 | 13.1 | 12.8 | 12.9 | 12.8 | 13.2 | 13.0 |
| **J4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **J8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |

### W3 - cpu (sysbench)

| Config | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Min | Max | Avg |
|--------|------:|------:|------:|------:|------:|----:|----:|----:|
| A0 | 196.3 | 196.4 | 196.4 | 196.3 | 196.4 | 196.3 | 196.4 | 196.4 |
| A2 | 116.6 | 116.5 | 115.5 | 114.2 | 117.7 | 114.2 | 117.7 | 116.1 |
| A4 | 76.9 | 76.3 | 79.2 | 79.1 | 75.9 | 75.9 | 79.2 | 77.5 |
| A8 | 48.2 | 48.7 | 48.0 | 46.9 | 47.0 | 46.9 | 48.7 | 47.8 |
| B0 | 58.7 | 58.6 | 58.5 | 58.5 | 58.7 | 58.5 | 58.7 | 58.6 |
| B2 | 32.0 | 32.2 | 32.2 | 32.0 | 29.0 | 29.0 | 32.2 | 31.5 |
| B4 | 22.8 | 20.4 | 22.9 | 21.4 | 22.7 | 20.4 | 22.9 | 22.0 |
| B8 | 15.7 | 15.6 | 14.7 | 15.3 | 15.1 | 14.7 | 15.7 | 15.3 |
| G0 | 196.3 | 196.4 | 196.3 | 196.3 | 196.2 | 196.2 | 196.4 | 196.3 |
| H4 | 11.9 | 11.7 | 12.6 | 12.1 | 12.1 | 11.7 | 12.6 | 12.1 |
| H8 | 10.8 | 10.4 | 10.8 | 10.5 | 11.6 | 10.4 | 11.6 | 10.8 |
| I4 | 14.4 | 15.3 | 14.7 | 15.2 | 15.4 | 14.4 | 15.4 | 15.0 |
| I8 | 13.5 | 13.6 | 13.6 | 13.8 | 13.5 | 13.5 | 13.8 | 13.6 |
| **J4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **J8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |

### W4 - hotmem (stress-ng --vm-keep)

| Config | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Min | Max | Avg |
|--------|------:|------:|------:|------:|------:|----:|----:|----:|
| A0 | 383.8 | 384.3 | 498.0 | 384.4 | 384.8 | 383.8 | 498.0 | 407.1 |
| A2 | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| A4 | 159.6 | 159.5 | 160.8 | 161.9 | 162.2 | 159.5 | 162.2 | 160.8 |
| A8 | 48.2 | 49.4 | 49.6 | 51.1 | 49.9 | 48.2 | 51.1 | 49.6 |
| B0 | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| B2 | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| B4 | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| B8 | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| G0 | 380.2 | 268.3 | 269.2 | 269.6 | 269.8 | 268.3 | 380.2 | 291.4 |
| H4 | 16.9 | 21.2 | 20.8 | 21.6 | 17.8 | 16.9 | 21.6 | 19.7 |
| H8 | 15.1 | 14.4 | 13.7 | 14.4 | 15.6 | 13.7 | 15.6 | 14.7 |
| I4 | 30.8 | 30.7 | 36.6 | 30.5 | 29.1 | 29.1 | 36.6 | 31.5 |
| I8 | 19.5 | 20.7 | 20.6 | 20.4 | 22.2 | 19.5 | 22.2 | 20.7 |
| **J4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **J8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **K8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L4** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
| **L8** | TBU | TBU | TBU | TBU | TBU | TBU | TBU | TBU |
