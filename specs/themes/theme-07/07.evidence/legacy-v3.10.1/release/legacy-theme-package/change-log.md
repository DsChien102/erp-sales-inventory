# Change log

## v1.4.5 — BJ13/UIF13 late landed cost deep Product correction — 2026-09-04

- Kế thừa cumulative v1.4.4; chỉ deep-correct BJ13/UIF13 và shared valuation contracts cần thiết.
- Tách BJ13 khỏi shared BJ03 screen identity; active flow mới `SCR-085..089`.
- Bổ sung `ENT-IV-07/08`, `BC-IV-06/API-Q-12` preview và sửa `BC-IV-04/API-C-23` thành atomic value-only late-cost commit cho 1..N exact receipt lines.
- Không hard-code allocation-method enum khi source chưa khóa; production lấy allowed set/policy version từ preview. Nhiều method hợp lệ thì UI không preselect.
- Final effect: quantity không đổi, lịch sử không bị sửa, official cost không tự publish; Product+Period scope chuyển dirty cho BJ14.
- Protected non-UIF13 runtime giữ exact-parent behavior; Product approval vẫn PENDING.

## BJ-02 pilot amendment v0.2.7 — 2026-08-26

- Chỉ calibrate BJ-02/UIF-02; các UIF khác giữ nguyên baseline v0.2.6.
- Redesign receipt mobile theo multi-product: `SCR-008` receipt header, `SCR-009` shared overview, thêm `SCR-084` one-item editor.
- Khóa one Receipt = one Supplier; BJ-02 không tạo Product/Supplier master.
- Khóa Product + transaction UOM ở mức receipt item; cùng Product khác UOM là các item riêng; một item có thể materialize thành nhiều technical lines theo lot/state.
- Khóa progressive quantity classification, multi-lot, expiry required/optional theo Product policy và `Chưa nhận lần này` cho source item.
- Bổ sung `T7-DR-103..105`, `supplier_id`, `supplier_version_id`, `receipt_item_ref`; đồng bộ BJ-02, UC-02-01/02/03, shared behavior, wiki, glossary, screen/component contracts và HTML prototype.
- Đây là pilot overlay, không thay đổi historical DR1 checkpoint; nếu chốt BJ-02 làm golden standard thì `SCR-084` sẽ vào checkpoint kế tiếp.

## 4.3.1 — 2026-08-24

- Repackage nguyên trạng v4.3.0 dưới version mới để tránh cache artifact.
- Không thay đổi nghiệp vụ, Decision Register, Wiki/SRS, 17 UI flow, Screen Registry, prototype v4.1.0 hoặc Harness catalog.
- Sinh lại freeze ID, manifest, checksum, validation và ZIP release.

## 4.3.0 — 2026-08-24

- Hợp nhất baseline nghiệp vụ v4.0.0, BJ migration v4.1.0, tài liệu v4.1.3 và UI model v4.2.0-rc1.
- Giữ nguyên 102 quyết định và 78 yêu cầu chi tiết; không thay đổi semantic projection.
- Giữ 17 BJ, 70 UC và external/outbound tạm thời trong Theme 7.
- Chuẩn hóa toàn bộ link active tới full generated-heading permalink của GitLab.
- Giữ 0 Screen Group active; 83 Screen, 479 State obligation và 33 Action.
- Bổ sung đầy đủ `ui/flows`: 17 flow, 70 UC và 201 transition từ patch UI-flow đã duyệt.
- Copy nguyên trạng prototype v4.1.0 vào package; chưa nâng cấp prototype theo UI-flow model v4.2.0-rc1.
- Thêm validation, package manifest, semantic-preservation report và UI trace overlay cho Harness.

## 4.2.0-rc1 — 2026-08-24

- Loại Screen Group khỏi mô hình chính thức; giữ alias trong migration map.
- Chuyển 83 màn hình sang ID liên tục `SCR-001…SCR-083` và Screen Contract độc lập.
- Tạo sáu khu vực điều hướng, Screen Registry, Action Registry và bản đồ BJ → UC → Screen.
- Khóa gói giao FE ở cấp BJ; checkpoint theo `UC × Screen × State × Action`.
- Áp dụng know-how documentation patch v4.1.2 và thuật ngữ Việt hóa đã thống nhất.
- Loại Figma khỏi handoff chính thức; prototype HTML đặt `NOT_RENDERED`.
- Giữ semantic baseline `T7-BASELINE-FREEZE-v4.0.0` và BJ migration `T7-BJ-MIGRATION-FREEZE-v4.1.0`.

## 4.1.0 — 2026-08-23

- Tinh gọn 25 source BJ thành 17 BJ canonical + CAP-01 + PROC-01 + 5 XREF.
- Materialize 99 quan hệ nguồn thành 70 UC canonical, 3 CAP ops, 4 PROC steps và 19 UC outbound.
- Chuyển BJ-09 mới về Inventory Control.
- Giữ `outbound/` tạm thời trong Theme 7; sửa owner Sản phẩm → Theme 2 và Mua hàng → Theme 10.
- Loại SG-05/16/17 khỏi active UI/prototype; giữ snapshot dưới outbound.
- Sinh lại manifest, trace, Harness, validator và checksum; không sửa package v4.0.0.


## Design Readiness Checkpoint DR1

- Checkpoint `4.3.1-dr1` (`T7-DESIGN-READINESS-CHECKPOINT-DR1`).
- Audited all 17 BJ, 70 UC, 17 UI flows and 83 baseline Screens.
- Normalized every canonical Screen with a Design Readiness Contract section.
- Corrected derivable BJ/UC/action trace drift without changing business semantics.
- Moved canonical UI flows to `prototype/flows/` and refreshed registries/checksums.
- Audited uploaded Flutter Design System as the single UI source; no independent HTML DS was created.
- HTML design intentionally not started; structural and business gaps await checkpoint approval.

## v2.0.2 — Phase 3 representative Figma DS calibration — 2026-09-08

- Kế thừa cumulative v2.0.1; không rebuild từ baseline cũ.
- Chỉ calibrate Product expression của UIF-02/UIF-05/UIF-08/UIF-10/UIF-15/UIF-17 theo live Figma Design System v2.0.2.
- Khóa explicit Mobile template cho toàn bộ screen trong calibration set; normalize AppBar 56, gutter 16, Sticky Footer 92, 44px controls/touch target, List Row, Info Row, VSearchBar/VChip và State-template responsibility.
- Loại generic clickable-card và HTML-only VQuantitySelector khỏi representative Product renders; business semantics không đổi.
- Bảo vệ 106 SRS files, canonical screen registry và non-target UIF rendering; Phase 4 mới rollout toàn bộ 73 canonical screens.

## v2.3.0 — Theme 7 Working Freeze + BJ08 structural migration — 2026-09-09

- Kế thừa trực tiếp user-delivered v2.2.0; không lấy v4.3.1 làm user-facing version mới.
- Đóng Phase B bằng `Theme 7 Working Freeze`: Product migration chỉ cần canonical DS dependency surface của BJ hiện tại rõ ràng; global/experimental gap không liên quan được defer có chủ đích.
- Structural migration đầu tiên sau audit dài: BJ-08/UIF-08, `SCR-042…047`.
- Khóa Product canvas 402×874, edge 16px, content width 370px; SCR-042 dùng Nested List.
- Blind count không render book/variance trước first submit; quantity/recount dùng VNumericKeypadSheet.
- Request-review ở SCR-046 quay lại SCR-045; cancellation tách khỏi approval task; SCR-047 terminal/result-only và có CANCELLED.
- Confirmation dùng `DS v2 / Confirmation Sheet`; không dùng naked generic VBottomSheet cho BJ08.
- Ghi rõ DS gap `VTimePicker` và các source-model/evidence gap; không import third-party component, không tự tạo backend enum hay data model mới.
- Core Theme 7 v4.3.1 IDs/counts được giữ ổn định; v2.3.0 migration overlay chịu trách nhiệm Product correction/UI expression.
