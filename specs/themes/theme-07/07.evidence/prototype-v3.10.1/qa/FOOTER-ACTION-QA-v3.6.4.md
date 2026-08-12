# Footer Action QA — v3.6.4

**Status: PASS**

Scope: all declared Theme 7 route-state renders. Validates the canonical DS dual Sticky Footer rule: `Secondary/Destructive | Primary`, 402×92 footer, 181/8/181 actions, 44 px action height, and no bezel/footer bleed.

- Route-state renders scanned: **518**
- Visible footer occurrences: **288**
- Dual-footer occurrences: **17**
- Single-footer occurrences: **271**
- Browser page errors: **0**

## Checks

- **PASS** — `runtime_version` — runtime=3.6.4 expected=3.6.4
- **PASS** — `no_browser_page_errors` — errors=0
- **PASS** — `dual_footer_occurrences` — observed=17 expected=17
- **PASS** — `no_footer_with_3plus_actions` — max=2
- **PASS** — `dual_actions_horizontal` — violations=0
- **PASS** — `dual_footer_exact_geometry` — violations=0
- **PASS** — `secondary_or_destructive_left_primary_right` — violations=0
- **PASS** — `no_footer_bleed_outside_product_viewport` — violations=0
- **PASS** — `dual_footer_ds_metadata` — violations=0
- **PASS** — `danger_dual_footer_semantics` — violations=0
- **PASS** — `single_primary_footer_regression` — checked=271 violations=0

## Dual-footer states

| Flow | Screen | State | Left | Right | Tone |
|---|---|---|---|---|---|
| UIF-02 | SCR-011 | READY | Từ chối | Duyệt | Danger |
| UIF-02 | SCR-011 | VALIDATION_ERROR | Từ chối | Duyệt | Danger |
| UIF-02 | SCR-011 | APPROVAL_REQUIRED | Từ chối | Duyệt | Danger |
| UIF-02 | SCR-011 | SELF_APPROVAL_NOT_ALLOWED | Từ chối | Duyệt | Danger |
| UIF-02 | SCR-011 | FINANCIAL_MASKED | Từ chối | Duyệt | Danger |
| UIF-08 | SCR-044 | BLIND_COUNT | Hủy phiên | Nộp kết quả đếm | Danger |
| UIF-08 | SCR-044 | VALIDATION_ERROR | Hủy phiên | Nộp kết quả đếm | Danger |
| UIF-08 | SCR-045 | RECOUNT_REQUIRED | Hủy phiên | Gửi chờ duyệt | Danger |
| UIF-08 | SCR-045 | EVIDENCE_REQUIRED | Hủy phiên | Gửi chờ duyệt | Danger |
| UIF-08 | SCR-045 | PRICE_BASIS_REQUIRED | Hủy phiên | Gửi chờ duyệt | Danger |
| UIF-08 | SCR-045 | VALIDATION_ERROR | Hủy phiên | Gửi chờ duyệt | Danger |
| UIF-08 | SCR-046 | APPROVAL_REQUIRED | Yêu cầu xem lại | Duyệt và điều chỉnh | Default |
| UIF-08 | SCR-046 | APPROVAL_REVIEW | Yêu cầu xem lại | Duyệt | Default |
| UIF-11 | SCR-051 | READY | Từ chối | Duyệt | Danger |
| UIF-11 | SCR-051 | VALIDATION_ERROR | Từ chối | Duyệt | Danger |
| UIF-12 | SCR-070 | READY | Từ chối | Duyệt | Danger |
| CAP-01 | SCR-064 | READY | Chỉnh sửa | Lưu chính sách | Default |
