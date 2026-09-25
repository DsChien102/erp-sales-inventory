# UX Pattern Registry — Theme 7

> Canonical cross-UIF patterns promoted by the 17-round Harness. These are usage/UX rules, not a second Design System.

## STANDARD_APP_BAR

VPageScaffold → VAppBar, centerTitle=false; no trailing action unless contract owns one.

**Adopted/validated by:** Harness cross-review.

## WHOLE_CARD_NAV

If an item has one destination, the whole card/row is tappable; do not add an Open CTA.

**Adopted/validated by:** `UIF-02`, `UIF-01`, `UIF-04`.

## PREFILL_KNOWN_CONTEXT

Do not ask for warehouse/product/source again when entry context already establishes it.

**Adopted/validated by:** `UIF-01`, `UIF-04`, `UIF-05`.

## PROGRESSIVE_FORM

Reveal dependent fields only after prerequisite selection/value exists; one primary continuation.

**Adopted/validated by:** `UIF-02`, `UIF-05`, `UIF-06`.

## STICKY_PRIMARY_ACTION

Long mobile form/review keeps the primary next action reachable without duplicating actions.

**Adopted/validated by:** `UIF-05`.

## REVIEW_DIFFERENCES_FIRST

Review screens prioritize exceptions/delta/risk/routing before repeated source details.

**Adopted/validated by:** `UIF-03`, `UIF-04`, `UIF-06`, `UIF-07`, `UIF-08`, `UIF-16`.

## ACTOR_HANDOFF

Maker and approver tasks are separate sessions/routes; never teleport maker into approver UI.

**Adopted/validated by:** `UIF-02`, `UIF-09`, `UIF-10`, `UIF-08`, `UIF-11`, `UIF-12`.

## REJECT_REASON_SHEET

Reject reason is collected in VBottomSheet/VTextFormField when rejection is an outcome of the same decision task.

**Adopted/validated by:** `UIF-02`.

## AUTO_EXECUTION_RESULT

When UC separates approval from execution, system executes after valid route; result surface owns processing/finality.

**Adopted/validated by:** `UIF-02`, `UIF-09`, `UIF-11`, `UIF-12`.

## OPERATION_RESULT

Use semantic operation result layout; transient toast never replaces authoritative result.

**Adopted/validated by:** `UIF-03`, `UIF-13`, `UIF-04`, `UIF-05`, `UIF-06`, `UIF-07`, `UIF-10`, `UIF-08`, `UIF-14`.

## UNKNOWN_RECOVERY

UNKNOWN is neither success nor failure; preserve identity and reconcile before retry.

**Adopted/validated by:** `UIF-02`, `UIF-12`, `UIF-17`.

## SAME_IDENTITY_CONTINUATION

Recovery continues the original operation identity/payload; never create a second business operation blindly.

**Adopted/validated by:** `UIF-17`.

## EVIDENCE_TIMELINE

Timeline is a Theme 7 composition from VCard/VIconBox/VText/VBadge; no fake Flutter Timeline component.

**Adopted/validated by:** `UIF-01`, `UIF-11`, `UIF-15`, `UIF-16`.

## PERMISSION_MASKING

Protected data is omitted before DOM render, not merely visually hidden.

**Adopted/validated by:** Harness cross-review.

## AS_OF_FRESHNESS

Read/report surfaces expose as-of/freshness and explicit refresh when stale matters.

**Adopted/validated by:** `UIF-01`, `UIF-15`.

## ACTIONABLE_DASHBOARD

Dashboard prioritizes actionable exceptions; normal states do not compete for attention.

**Adopted/validated by:** `UIF-01`, `UIF-14`.

## SHARED_SCREEN_CONTEXT_MODE

One canonical screen implementation may expose mutually exclusive context modes; no clone per BJ.

**Adopted/validated by:** `UIF-13`, `UIF-07`, `UIF-09`, `UIF-10`, `UIF-11`, `UIF-15`.

## BLIND_COUNT_SUPPRESSION

Blind-count phase MUST NOT render book quantity in DOM before first count submission.

**Adopted/validated by:** `UIF-08`.

## FINANCIAL_MASKING

Finance values are absent from DOM when permission is missing.

**Adopted/validated by:** `UIF-03`, `UIF-13`, `UIF-14`.

## DESTRUCTIVE_CONFIRMATION

Irreversible/destructive completion explains impact and prevents double submit.

**Adopted/validated by:** `UIF-10`.

## SYSTEM_RECOMMENDED_RECOVERY

System narrows/recommends valid recovery based on evidence; technical replay/rebuild vocabulary is secondary.

**Adopted/validated by:** `UIF-16`, `UIF-17`.

## FILE_UPLOAD_VALIDATE

Import flow separates file selection/cut-off from row validation and never auto-creates missing master data.

**Adopted/validated by:** `UIF-12`.

## EXPORT_REVIEW

Export review locks filters/timezone/as-of before file generation.

**Adopted/validated by:** `UIF-15`.

## TWO_STAGE_PHYSICAL_CLASSIFICATION

Physical receipt and later quality classification are separate tasks when evidence may not exist at receipt time.

**Adopted/validated by:** `UIF-06`.

## BLOCKER_FIRST

Costing/complex review surfaces show blockers before derived totals or publish CTA.

**Adopted/validated by:** `UIF-14`.

## v1.3.5 — Interaction fidelity guardrails

| Pattern | Rule | Applies |
|---|---|---|
| `LOCKED_CONTROL_FIDELITY` | Nếu dữ liệu về bản chất là selector nhưng Phase/context chỉ cho một giá trị, vẫn dùng control selector ở trạng thái disabled thay vì đổi semantic thành card/text tùy tiện. | Quick warehouse và các fixed-choice field tương tự |
| `VISIBLE_MANDATORY_CHOICE` | Tập lựa chọn nhỏ, bắt buộc và đủ chỗ trên mobile phải hiển thị trực tiếp; không giấu trong dropdown làm phát sinh thêm một tap. | UOM Quick, reason code ngoại lệ |
| `EVIDENCE_INPUT_MATCHES_ARTIFACT` | Bằng chứng là file/ảnh phải dùng upload; textarea chỉ dùng cho lý do/mô tả. Không dùng text field giả làm file evidence. | BJ02 delivery evidence, BJ06 wrong-LOT |
| `DECISIVE_SELECTION_ADVANCES` | Khi lựa chọn đã xác định đủ object cho mental task kế tiếp, chuyển thẳng sang task đó; không bắt user tap lại item vừa tạo. | Quick Product+UOM → SCR-084 |
| `APPEND_IS_NOT_COMPLETE` | Action thêm phần tử vào collection đặt ở cấp collection và dùng nhãn “Thêm … khác”; completion phải có CTA riêng. | LOT editor |
| `TEMPORAL_GUARD_IN_CONTROL` | Date không hợp lệ theo business rule phải bị chặn ngay trong picker và vẫn được server kiểm lại. | Quick receipt date |

## HOMOGENEOUS_NAVIGATION_LIST

Trong cùng một collection của các peer destination/task, giữ cùng `DS v2 / List Row · Type=Navigation`. Item chưa thể mở phải dùng `State=Disabled`, vẫn giữ chevron/anatomy như các peer và bị chặn interaction. Không đổi item sang `Status` chỉ vì đang chờ.

**Adopted/validated by:** `UIF-03`, `UIF-05`, `UIF-06`, `UIF-07`, `UIF-13`.


## v3.13.0 — Valuation design parity

| Pattern | Rule | Applies |
|---|---|---|
| `VALUATION_WORK_QUEUE` | Worklist nói bằng công việc cần xử lý (`Có thể xác nhận`, `Cần đối chiếu`, `Chưa đủ căn cứ`), không expose technical valuation state. | UIF-03, UIF-13, UIF-14 |
| `BASIS_THEN_VALUE` | Trình bày nguồn/căn cứ trước, cấu thành giá trị sau; người dùng không nhập lại fact thuộc nguồn thương mại. | UIF-03 |
| `QUICK_DIRECT_BASIS_SHEET` | Nhập nhanh không phụ thuộc Theme 10; căn cứ giá trực tiếp được thêm trong Form Sheet/Bottom Sheet và phải có nguồn, cách hiểu thuế/giá, validation phù hợp. | UIF-03 |
| `SIGNED_VALUE_ADJUSTMENT` | Điều chỉnh giá trị dùng dấu tăng/giảm và tách `Nguồn` khỏi `Cách phân bổ`; không gọi mọi adjustment là chi phí. | UIF-13 |
| `CONSOLIDATED_ALLOCATION_TASK` | Chọn phạm vi, phương pháp và xem kết quả phân bổ là cùng một mental task khi không có commit boundary riêng; không tạo screen trung gian. | UIF-13 |
| `COST_WORK_QUEUE` | BJ14 bắt đầu từ công việc cần tính/cập nhật/chốt, không bắt người dùng quản lý run kỹ thuật. | UIF-14 |
| `TENANT_METHOD_READ_ONLY` | Phương pháp giá vốn lấy từ chính sách tenant và chỉ hiển thị read-only; phương pháp phụ chỉ dùng đối chiếu. | UIF-14 |
| `DIRTY_SCOPE_SYSTEM_DERIVED` | Khi hệ thống biết chính xác phạm vi cần tính lại, phạm vi là read-only; không bắt user chọn lại. | UIF-14 |
| `BLOCKERS_INLINE` | Blocker hiển thị bằng `Readiness Item`/Banner ngay trong task; không tạo màn blocker riêng. | UIF-14 |
| `PUBLICATION_REVIEW_SHEET` | Rà soát finality của công bố dùng Bottom Sheet/Confirmation Sheet trên màn kết quả tính; không tạo màn review publication độc lập. | UIF-14 |
| `NO_TECHNICAL_JARGON_IN_PRODUCT_UI` | `DirectCostBasis`, hash/version, dirty scope, event/API/internal state chỉ xuất hiện trong Inspect/audit. | UIF-03, UIF-13, UIF-14 |
