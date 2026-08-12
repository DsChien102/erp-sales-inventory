# Correction & Recovery Group QA — v1.7.0

Scope: **BJ11/UIF11 + BJ16/UIF16 + BJ17/UIF17**  
Parent: **v1.6.0**  
Product approval: **PENDING_REVIEW**

## Release gates

| Gate | Result | Evidence |
|---|---:|---|
| Static / contract | **PASS · 65/65** | `CORRECTION-RECOVERY-STATIC-QA-v1.7.0.md` |
| Scenario/state render | **PASS · 95 renders** | `CORRECTION-RECOVERY-SCENARIO-QA-v1.7.0.md` |
| End-user interaction | **PASS · 68/68** | `CORRECTION-RECOVERY-END-USER-QA-v1.7.0.md` |
| Visual / 402×874 | **PASS · 64/64 · 21 specimens** | `VISUAL-QA-v1.7.0.md` |
| Protected non-target UIF | **PASS · 3/3 · 68 exact renders** | `REGRESSION-PROTECTED-FLOWS-v1.7.0.md` |
| Prior-cluster interactions | **PASS** | `REGRESSION-PRIOR-CLUSTERS-v1.7.0.md` |
| All active flows runtime | **PASS · 85 renders** | `ALL-FLOWS-RUNTIME-SMOKE-v1.7.0.md` |
| Frozen source immutability | **PASS** | `SOURCE-IMMUTABILITY-v1.7.0.md` |
| JS syntax | **PASS** | `node --check app.js` |

## Product corrections verified

### BJ11 — Hủy và sửa sai nghiệp vụ kho

- Cancel chỉ áp dụng trước execution; kết quả cancel không tạo stock/value movement.
- Completed operation không bị rewrite; sửa sai tạo correction chain có evidence.
- Maker submit kết thúc maker task tại `Chờ duyệt`; approver mở task độc lập.
- Approver chỉ quyết định Duyệt/Từ chối; từ chối bắt buộc lý do; self-approval bị chặn.
- Sau approve, system recheck/execute; user không phải commit lần hai.
- `UNKNOWN` không cho cancel/correct/retry mù; handoff BJ17 giữ cùng operation identity.
- Sale issue đã physical handover không được giả lập trả hàng bằng correction; real return thuộc BJ06.

### BJ16 — Điều tra và đối soát sai lệch

- Evidence-first, đối chiếu rõ Nguồn nghiệp vụ / Sổ kho / Số liệu hiển thị.
- Route source mismatch, correction required, UNKNOWN, projection mismatch và ledger-integrity suspicion được tách riêng.
- Chỉ cho “Khôi phục số liệu hiển thị” sau khi evidence chứng minh sổ kho đúng.
- Product UI không expose replay/rebuild/hash/outbox selectors.
- Ledger-integrity suspicion không auto recovery/correction; giữ scope protection và escalation.
- Case chỉ close/unlock sau review evidence.

### BJ17 — Phục hồi nghiệp vụ có kết quả chưa xác định

- `UNKNOWN ≠ FAILED`.
- Evidence commit: xác lập finality từ tác động đã tồn tại, không ghi inventory effect lần hai.
- Evidence no-commit: chỉ tiếp tục cùng operation/request identity và cùng confirmed content sau proof không có partial effect.
- Insufficient evidence: giữ `Chưa xác định`, scope protected, source waiting và owner escalation; không tạo operation mới/blind retry.

## Cumulative regression

- Inventory Valuation on v1.7 runtime remains **54/54 + 27/27 + 14/14 PASS**.
- Inventory Audit & Control on v1.7 runtime remains **48/48 + 53 state renders PASS**.
- Every non-target UIF retains exact Product text/topology against v1.6.0 across **68 protected screen renders**.
- All **85 active flow/screen combinations** render without runtime failure.

## Source / validator status

- All **106 SRS files** and `theme.manifest.yaml` are byte-identical to v1.6.0.
- Canonical frozen validator fails on both parent and child because inherited `prototype/screen-map.md` is absent. This release does **not** claim canonical-validator readiness; see `ISOLATION-REPORT-v1.7.0.md`.

## Visual evidence

`qa/screenshots-v1.7.0/CORRECTION-RECOVERY-CONTACT-SHEET-v1.7.0.png` contains **21** Product-only specimens at canonical **402×874**, covering maker, approver, finality, evidence routing, projection recovery, ledger-risk escalation and insufficient-evidence recovery.

## Release conclusion

**Engineering/UX QA candidate: PASS. Product approval: PENDING_REVIEW.**

QA pass is evidence for review; it does not freeze Product design or replace Product approval.
