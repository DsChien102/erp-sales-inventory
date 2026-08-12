# Bản đồ chuyển đổi mã — Theme 7 v4.0.0 → v4.1.0

> Freeze: `T7-BJ-MIGRATION-FREEZE-v4.1.0` · `outbound/` vẫn ở Theme 7 nhưng là `TEMPORARY_NON_CANONICAL`.

| Nguồn | Hành động | Đích | Owner/ghi chú |
|---|---|---|---|
| `BJ-01` | `MERGE_TARGET` | `BJ-01` | — |
| `BJ-02` | `KEEP` | `BJ-02` | — |
| `BJ-03` | `KEEP` | `BJ-03` | — |
| `BJ-04` | `KEEP` | `BJ-04` | — |
| `BJ-05` | `MOVE` | `XREF-01` | T5-BJ-CHECKOUT-POS |
| `BJ-06` | `KEEP` | `BJ-05` | — |
| `BJ-07` | `KEEP` | `BJ-06` | — |
| `BJ-08` | `KEEP` | `BJ-07` | — |
| `BJ-09` | `KEEP` | `BJ-08` | — |
| `BJ-10` | `KEEP` | `BJ-09` | Inventory Control |
| `BJ-11` | `KEEP` | `BJ-10` | — |
| `BJ-12` | `KEEP` | `BJ-11` | — |
| `BJ-13` | `KEEP` | `BJ-12` | — |
| `BJ-14` | `KEEP` | `BJ-13` | — |
| `BJ-15` | `KEEP` | `BJ-14` | — |
| `BJ-16` | `RECLASSIFY` | `CAP-01` | — |
| `BJ-17` | `MERGE` | `BJ-01` | — |
| `BJ-18` | `KEEP` | `BJ-15` | — |
| `BJ-19` | `KEEP` | `BJ-16` | — |
| `BJ-20` | `KEEP` | `BJ-17` | — |
| `BJ-21` | `RECLASSIFY` | `PROC-01` | — |
| `BJ-22` | `MOVE` | `XREF-02` | T10-BJ-DISCOUNT-SCENARIO |
| `BJ-23` | `MOVE` | `XREF-03` | T2-BJ-PRICING-BASIS |
| `BJ-24` | `MOVE` | `XREF-04` | T2-BJ-PRICING-REVIEW |
| `BJ-25` | `MOVE` | `XREF-05` | RPT-BJ-PROFIT-VIEWS |

Chi tiết 99 quan hệ UC nằm tại [registry máy đọc được](../legacy-package/bj-v4.0.0-to-v4.1.0/uc-reference-rewrite-registry.json).
