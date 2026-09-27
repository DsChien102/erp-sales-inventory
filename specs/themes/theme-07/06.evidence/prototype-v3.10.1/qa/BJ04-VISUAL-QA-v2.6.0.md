# BJ04 Visual QA — v2.6.0

**Result: PASS**

Reviewed at the canonical `402 × 874` Product viewport using the generated browser captures in `v260-bj04-captures/`.

## Reviewed states

- `PARTIAL` — PASS: compact 70px warning banner; one row-level shortage badge; no clipped copy; Product/SKU and `Cần / Đã giữ` remain scannable.
- `FULL` — PASS: no success banner/badge noise; two product rows remain compact and readable.
- `RELEASED` — PASS: compact 70px Info banner; section changes to `Sản phẩm đã nhả`; no false shortage status.
- `STALE` — PASS: compact 70px Info banner; latest projection remains readable; no retry control.
- `LOADING` — PASS: skeleton stays within the 402×874 frame with no overflow.
- `PERMISSION_DENIED` — PASS: centered empty/access state fits the viewport; no business data is exposed.

## Visual gates

- No horizontal overflow.
- AppBar title/subtitle are not clipped.
- Info Row values share the right edge and use current 338×44 anatomy.
- Product rows have no chevron/radio/navigation affordance.
- Semantic color is limited to meaningful warning/info states.
- No sticky footer or mutation action occupies Product space.
