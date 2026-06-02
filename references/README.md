# References & Design Motivations

This directory contains the core literature that motivates and validates the architectural decisions of this project.

## Reference Papers


| Paper | Venue/Year | Design Motivation & Insights |
| :--- | :--- | :--- |
| **Dong et al.** | FAST 2011 | Establishes address-hash routing as the primary mechanism; proves ~90% effectiveness. |
| **Shilane et al.** | FAST 2012 | Evaluates shared frozen cache alternative; clarifies why we chose routing over freezing. |
| **Nathan et al.** | VEE 2016 | Empirically validates hot-page classification over 42 real-world workloads. |
| **Ha et al.** | SEC 2017 | Evaluates two-tier pipeline alternative; justifies choosing per-thread execution over pipelining. |
| **He et al.** | IEEE Access 2021 | Demonstrates hybrid stateless+stateful routing as the optimal architectural tradeoff. |
| **Zou et al. (MeGA)** | USENIX ATC 2022 | Validates that cache-miss fallback (skipping delta and sending the full page) is correct and effective. |
| **Park et al. (DeepSketch)** | USENIX FAST 2022 | Proves parallel lookup + encode is the correct decoupled architecture for high throughput. |
| **Xia et al. (Odess)** | ACM TOS 2023 | Introduces shared read-only index + parallel encoders; highlights SIMD optimization opportunities. |
| **Li & Li** | Euro-Par 2024 | Highlights that the multifd/XBZRLE gap remains unaddressed, directly motivating this work. |
| **Zhang et al.** | ACM TOS 2025 | Proves per-page inline delta decision is highly viable at line-rate production throughput. |
| **Fu et al. (survey)** | ACM CS 2025 | Confirms address-hash is the accepted industry standard; validates cross-domain novelty. |
| **Wei et al. (LPAQMP)** | IEEE DCC 2026 | Demonstrates lock-free per-thread encode with read-only context achieves zero-overhead. |

---

## Key Architectural Decisions Derived

* **Routing Mechanism**: **Address-hash routing** is selected as the primary mechanism due to its ~90% proven effectiveness and status as an accepted standard (Dong 2011, Fu 2025), rejecting the shared frozen cache alternative (Shilane 2012).
* **Threading & Pipeline**: We adopt a **decoupled parallel lookup + encode** architecture (Park 2022) with a **lock-free per-thread** model to achieve zero-overhead (Ha 2017, Wei 2026).
* **Cache & Delta Policy**: Implementation of a **per-page inline delta decision** at production throughput (Zhang 2025) backed by a **cache-miss fallback** policy that skips delta calculations to send full pages instantly upon a miss (Zou 2022).
* **Research Gap**: This project directly targets and resolves the unresolved **multifd/XBZRLE compatibility and performance gap** identified in recent literature (Li & Li 2024).
