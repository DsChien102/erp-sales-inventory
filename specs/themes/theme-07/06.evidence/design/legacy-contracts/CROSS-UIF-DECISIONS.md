# Cross-UIF Decisions — Theme 7

> Decisions are grouped by UX/business pattern, not by software version.

## Round 01 — UIF-02 / BJ-02

**Corrections:**
- Giữ quyết định pilot v0.3.2 làm calibration baseline.

**Patterns validated/promoted:** `WHOLE_CARD_NAV`, `PROGRESSIVE_FORM`, `ACTOR_HANDOFF`, `REJECT_REASON_SHEET`, `AUTO_EXECUTION_RESULT`, `UNKNOWN_RECOVERY`.

## Round 02 — UIF-01 / BJ-01

**Corrections:**
- Chèn canonical SCR-055 giữa SCR-054 và SCR-056 để form query không kiêm list kết quả.

**Patterns validated/promoted:** `WHOLE_CARD_NAV`, `PREFILL_KNOWN_CONTEXT`, `AS_OF_FRESHNESS`, `EVIDENCE_TIMELINE`, `ACTIONABLE_DASHBOARD`.

## Round 03 — UIF-03 / BJ-03

**Corrections:**
- Đổi ACT-03-CONFIRM-COST từ “Xác nhận giá và đưa vào bán” thành “Xác nhận giá trị”; loại suy diễn sellability khỏi SCR-017/019.

**Patterns validated/promoted:** `FINANCIAL_MASKING`, `REVIEW_DIFFERENCES_FIRST`, `OPERATION_RESULT`.

## Round 04 — UIF-13 / BJ-13

**Corrections:**
- Chuyển ACT-03-RECORD-LATE-COST sang SCR-017 review; retire backtrack review → form → submit.

**Patterns validated/promoted:** `SHARED_SCREEN_CONTEXT_MODE`, `REVIEW_OWNS_COMMIT`, `FINANCIAL_MASKING`, `OPERATION_RESULT`.

## Round 05 — UIF-04 / BJ-04

**v1.3.4 correction:**
- Reservation create/amend/release/re-evaluate là source/system-driven. Retire manual list/review/release/result workflow khỏi active UIF-04; chỉ giữ `SCR-021` read-only projection với lượng cần/đã giữ/thiếu.
- Shortage quay về source; Inventory không tự đổi kho hoặc tạo purchase proposal.

**Patterns validated/promoted:** `SYSTEM_OWNED_RESERVATION`, `READ_ONLY_PROJECTION`, `SHORTAGE_TO_SOURCE`.

**v3.9.6 deep-review lock:**
- Explicit source `reservation_policy`; Basic Stock/POS `NONE` không tạo Theme 7 Reservation.
- Preserve source UOM snapshot; current held tách khỏi consumed; deterministic priority.
- Reservation không mutate PickAllocation; chỉ phát `allocation_review_required` cho BJ-05.
- Combo dùng ReservationGroup atomic; SCR-021 là current line projection, không global FULL/PARTIAL/RELEASED/STALE.

**Additional patterns:** `SOURCE_RESERVATION_POLICY`, `CURRENT_HOLD_VS_CONSUMED`, `ALLOCATION_OWNER_BOUNDARY`, `ATOMIC_COMBO_RESERVATION`, `LINE_FACT_PROJECTION`.

## Round 06 — UIF-05 / BJ-05

**v1.3.4 correction:**
- Không expose allocation version; hệ thống đề xuất FEFO/FIFO và tự re-evaluate trong cùng kho khi stale.
- Normal pick/handover không approval. Đổi LOT là permission riêng + lý do + audit, không maker-checker mặc định.
- Pick không giảm physical; actual handover là physical commit.

**Patterns validated/promoted:** `SYSTEM_SUGGESTED_PICK`, `AUTHORIZED_LOT_OVERRIDE`, `HANDOVER_IS_PHYSICAL_COMMIT`, `UNKNOWN_RECOVERY`.

## Round 07 — UIF-06 / BJ-06

**v1.3.4 correction:**
- Physical receipt và classification là hai milestone.
- Wrong LOT bắt buộc maker-checker: maker gửi evidence, approver khác maker quyết định; approval không tự commit receipt.
- Normal classification không approval; hard guards không được permission override.

**Patterns validated/promoted:** `TWO_STAGE_PHYSICAL_CLASSIFICATION`, `WRONG_LOT_MAKER_CHECKER`, `HARD_CLASSIFICATION_GUARDS`, `UNKNOWN_RECOVERY`.

## Round 08 — UIF-07 / BJ-07

**v1.3.4 correction:**
- Supplier return là `SOURCE_AUTHORIZED`: Inventory không phê duyệt lại commercial intent.
- `RTV_PENDING` preparation/adjustment là system-owned; `SCR-038` không còn trong active UIF-07 nhưng vẫn giữ cho UIF-09.
- Actual handover là mutation duy nhất của user trong Inventory và là mốc giảm physical/value.

**Patterns validated/promoted:** `SOURCE_AUTHORIZED`, `SYSTEM_OWNED_PENDING_STATE`, `HANDOVER_IS_PHYSICAL_COMMIT`, `UNKNOWN_RECOVERY`.

## Round 09 — UIF-09 / BJ-09

**Corrections:**
- Bổ sung explicit ACT-COMMON-SUBMIT/DECIDE; ACT-08-STATE là system-owned sau approval.

**Patterns validated/promoted:** `SHARED_SCREEN_CONTEXT_MODE`, `ACTOR_HANDOFF`, `AUTO_EXECUTION_RESULT`, `EVIDENCE_FIRST`.

## Round 10 — UIF-10 / BJ-10

**Corrections:**
- Tách semantics submit/approval/disposal; loại việc approval tự làm giảm stock.

**Patterns validated/promoted:** `SHARED_SCREEN_CONTEXT_MODE`, `ACTOR_HANDOFF`, `DESTRUCTIVE_CONFIRMATION`, `OPERATION_RESULT`.

## Round 11 — UIF-08 / BJ-08

**Corrections:**
- Khóa rule “blind count data suppression” ở DOM; approval theo actor handoff thay vì continuation cùng user.

**Patterns validated/promoted:** `BLIND_COUNT_SUPPRESSION`, `ACTOR_HANDOFF`, `REVIEW_DIFFERENCES_FIRST`, `OPERATION_RESULT`.

## Round 12 — UIF-11 / BJ-11

**Corrections:**
- Loại vòng approver duyệt → quay SCR-052 → user bấm correct; correction execution chuyển system-owned trên SCR-053.

**Patterns validated/promoted:** `SHARED_SCREEN_CONTEXT_MODE`, `ACTOR_HANDOFF`, `AUTO_EXECUTION_RESULT`, `EVIDENCE_TIMELINE`.

## Round 13 — UIF-12 / BJ-12

**Corrections:**
- Tách ACT-COMMON-DECIDE khỏi ACT-13-COMMIT; auto commit sau approval trên result surface.

**Patterns validated/promoted:** `FILE_UPLOAD_VALIDATE`, `ACTOR_HANDOFF`, `AUTO_EXECUTION_RESULT`, `UNKNOWN_RECOVERY`.

## Round 14 — UIF-14 / BJ-14

**Corrections:**
- Không có structural gap; chuẩn hóa blocker-first review và financial masking xuyên valuation/costing family.

**Patterns validated/promoted:** `FINANCIAL_MASKING`, `ACTIONABLE_DASHBOARD`, `BLOCKER_FIRST`, `OPERATION_RESULT`.

## Round 15 — UIF-15 / BJ-15

**Corrections:**
- Promote shared query/list/detail/timeline family từ UIF-01 thành canonical cho UIF-15.

**Patterns validated/promoted:** `SHARED_SCREEN_CONTEXT_MODE`, `AS_OF_FRESHNESS`, `EVIDENCE_TIMELINE`, `EXPORT_REVIEW`.

## Round 16 — UIF-16 / BJ-16

**Corrections:**
- Giữ Theme7EvidenceTimeline; chuyển UI copy recovery sang user outcome, technical replay/rebuild chỉ ở detail/on-demand.

**Patterns validated/promoted:** `EVIDENCE_FIRST`, `SYSTEM_RECOMMENDED_RECOVERY`, `EVIDENCE_TIMELINE`, `REVIEW_DIFFERENCES_FIRST`.

## Round 17 — UIF-17 / BJ-17

**Corrections:**
- Promote no-blind-retry + same-identity recovery thành cross-Theme pattern; không render mutation “thử lại” mù.

**Patterns validated/promoted:** `UNKNOWN_RECOVERY`, `SYSTEM_RECOMMENDED_RECOVERY`, `EVIDENCE_FIRST`, `SAME_IDENTITY_CONTINUATION`.


## v1.3.5 interaction/evidence lock
- Small mandatory choices are visible directly when they fit; avoid collapsed dropdowns that only add a tap.
- File/image evidence uses `VFileDropZone`; reason/description uses text input.
- Fixed selector semantics remain a disabled selector when the field is conceptually a choice but Phase/context locks the value.
- A decisive selection may advance immediately to the next mental task; do not require a redundant second tap.
- Collection append actions use wording such as `Thêm lô khác`; `Xong` remains the completion action.
- Handover physical confirmation and evidence policy follow `T7-DR-110`/`T7-DR-111`.

## v1.3.6 — Physical-task UX guards promoted from BJ05–BJ07

- **Actionable vs waiting:** work queues phải phân biệt việc actor hiện tại làm được ngay với việc đang chờ source/hệ thống/actor khác. Một waiting state không được đặt dưới heading mang nghĩa “cần bạn xử lý”.
- **Multi-LOT representation:** Product+UOM là mental object; bên trong có thể có `1..N` LOT allocations. Không ép một Product về một LOT khi business model cho phép nhiều LOT.
- **Actual handover authority:** nếu partial được phép, actual handover quantity phải được xác định tại handover, theo đúng LOT/allocation trace; không dùng picked quantity như handover quantity một cách mặc định không thể chỉnh.
- **Physical stale correction:** khi source/allocation thay đổi sau khi người dùng có thể đã cầm hàng, UI phải nói rõ phần cần trả lại/lấy thay, không chỉ báo “đã cập nhật”.
- **Re-entry to current task:** waiting/history/result screen không được chèn vào navigation khi user quay lại một task đang còn mở; ví dụ `Cần phân loại` mở thẳng classification.
- **Lifecycle vs event:** event như `Yêu cầu vừa thay đổi` là supporting information, không thay thế lifecycle state như `Chờ bàn giao`.
- **Source change invalidates verification:** khi source delta thay đổi Product/LOT/quantity đang chuẩn bị, physical verification của item bị ảnh hưởng phải được thực hiện lại.


## v1.3.9 — BJ07 supplier-return deep correction

1. **Exact source scope:** UIF07 warehouse execution is exact Product+UOM+LOT scope from current source version; warehouse does not create commercial partial handover or LOT substitution.
2. **Granular invalidation:** source add/change/remove invalidates only affected physical verification; unaffected evidence remains valid. Source remove/cancel releases pending quantity system-side.
3. **Waiting ownership:** source-owned waiting tasks are visible/read-only but not presented as warehouse-actionable navigation.
4. **Finality:** SCR-039 is the only handover commit review; SCR-041 never navigates Back into the consumed mutation and UNKNOWN never blind-retries.

## v1.4.0 — UIF03 initial valuation deep correction

1. **Identified valuation scope:** direct receipt valuation is selected by receipt line / identified quantity slice, grouped by Product+UOM; cross-UOM quantity is never aggregated into one total.
2. **Provenance first:** authoritative source price/tax/FX data is read-only. When valid sources conflict, no source is preselected; the authorized actor explicitly selects the source and records a reason.
3. **Value vs sellability:** review/result present valuation effect separately from availability effect. Valuation confirmation never changes quarantine/damaged/expired into sellable state.
4. **Mode-scoped shared valuation screens:** SCR-014/015/017/019 remain canonical shared screens. v1.4.0 scopes the new renderer to UIF-03 and preserves UIF-13 parent behavior byte/renderer-equivalent; UIF-13 Product correction remains owned by its later deep-design release.
5. **Single direct-valuation commit:** UIF-03 SCR-017 owns the single explicit `ACT-03-CONFIRM-COST`; source/version is rechecked before commit; no second approval or repeat confirmation modal.
6. **Finality:** SCR-019 has no Back-to-consumed-commit; UNKNOWN preserves same operation identity and never blind-retries.

## v1.4.5 — BJ13 late-landed-cost boundary correction

1. **Dedicated Product screen identity:** the v1.4.0 shared-screen strategy was an interim Harness choice, not a permanent Product boundary. Active BJ13 now uses `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`; BJ03 keeps `SCR-014/015/016/017/019`. Reuse is limited to composition/patterns.
2. **Source-component task, not valuation-pending receipt:** BJ13 queue is keyed by late-cost source component/evidence. Source-owned waiting work is visible/read-only and is not presented as an actionable Inventory Valuation task.
3. **Preview owns allocation choice:** `BC-IV-06/API-Q-12` returns `allowed_allocation_methods + policy_version`; the Product UI must not invent a canonical allocation-method enum. If more than one method is valid, none is preselected.
4. **Value-only finality:** `BC-IV-04/API-C-23` commits late-cost header + all selected allocation lines + adjustment/value + dirty Product/Period scopes atomically. Quantity does not change, receipt/direct valuation history is not rewritten, and official cost is not auto-published.
5. **Stale/recovery:** source version or preview hash change invalidates the final review. UNKNOWN preserves the same operation identity and does not return as a fresh actionable task or permit blind retry.

## v3.6.3 — Homogeneous navigation-list state invariant

- Trong một collection mà các peer rows cùng đại diện cho cùng một loại destination/task, tất cả rows phải giữ cùng `DS v2 / List Row · Type=Navigation` anatomy.
- Row tạm thời không thể mở vì đang chờ source/actor/evidence **không được đổi Type sang Status chỉ để bỏ chevron**. Nó phải dùng `State=Disabled`, giữ nguyên chevron/geometry như các peer và không nhận interaction.
- `Status` chỉ dùng cho row thực sự là read-only context/status presentation, không phải một peer destination đang tạm unavailable.
- Disabled state dùng parent opacity theo DS (`Opacity/Disabled = 0.4`); không tạo màu disabled riêng.
- Quy tắc này áp dụng xuyên Theme 7 và được QA ở toàn bộ declared route-state renders.

## v3.6.4 — Supporting text / helper visual invariant

- Helper/supporting text is descriptive copy, not status. It must not receive `VBadge`/pill background, semantic fill, or rounded-chip treatment unless the business meaning is genuinely a badge/status.
- Selection controls must reuse the canonical Figma DS control first. For radio choices, use `VRadio` (`522:7410`) and compose explanatory text separately if needed; do not invent feature-specific radio-card anatomy.
