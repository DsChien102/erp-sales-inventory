# 05 — Business / Structural / DS Gap Register

> Checkpoint `4.3.1-dr1`. Chỉ các gap cần quyết định mới chặn scale HTML; các derivable corrections đã áp dụng.

| Gap | Type | Severity | Title | Scope | Status |
|---|---|---|---|---|---|
| `BG-001` | `BUSINESS_GAP` | `BLOCKER` | Quyền sở hữu bước thực thi ghi nhận hàng chưa rõ trên UI | `SCR-012`, `UIF-02`, `UC-02-04` | `OPEN_BLOCKER` |
| `BG-002` | `BUSINESS_GAP` | `BLOCKER` | ACT-02-DECIDE gộp ba quyết định nhưng thiếu contract theo từng outcome | `SCR-011`, `ACT-02-DECIDE`, `UC-02-03` | `OPEN_BLOCKER` |
| `BG-003` | `BUSINESS_GAP` | `HIGH` | Thiếu entry/resume contract cho multi-actor approval | `SCR-011`, `SCR-046`, `SCR-051`, `SCR-070`, `BJ-02`, `BJ-08`, `BJ-11`, `BJ-12` | `OPEN_BLOCKER` |
| `BG-004` | `STRUCTURAL_REVIEW` | `MEDIUM` | SCR-041 đang phục vụ ba ngữ cảnh kết quả và cả bước trung gian | `SCR-041`, `BJ-07`, `BJ-09`, `BJ-10` | `OPEN_STRUCTURAL_REVIEW` |
| `BG-005` | `STRUCTURAL_REVIEW` | `HIGH` | SCR-052 gộp hủy operation chưa thực thi và chuẩn bị correction sau finality | `SCR-052`, `BJ-11`, `UC-11-02`, `UC-11-03`, `UC-11-05` | `OPEN_BLOCKER` |
| `BG-006` | `FLOW_GAP` | `HIGH` | CAP-01 có bốn screen nhưng chưa có supporting UI flow/entry contract | `CAP-01`, `SCR-062`, `SCR-063`, `SCR-064`, `SCR-065` | `OPEN_BLOCKER` |
| `BG-007` | `TRACE_GAP` | `MEDIUM` | SCR-081 thiếu direct UC trace dù được dùng trực tiếp trong UIF-16 | `SCR-081`, `UIF-16`, `UC-16-03`, `PROC-01-STEP-03` | `RESOLVED_DERIVED` |
| `DG-001` | `DOCUMENTATION_GAP` | `MEDIUM` | Nội dung Screen Contract chủ yếu là semantic label và example, chưa có field identifier/data source đầy đủ | `ALL_SCREENS` | `OPEN_BEFORE_FLUTTER_HANDOFF` |
| `DSG-001` | `DS_GOVERNANCE_GAP` | `MEDIUM` | Package Flutter DS khai báo version 1.0.0 trong khi project rule gọi Design System v2 | `FLUTTER_DS` | `OPEN_DS_GOVERNANCE_REVIEW` |
| `DSG-002` | `DS_SOURCE_GAP` | `HIGH` | VAssets tham chiếu illustration/icon không tồn tại hoặc không được bundle | `VAssets` | `OPEN_SOURCE_FIX_NOT_THEME_BLOCKER` |
| `DSG-003` | `DS_SOURCE_GAP` | `MEDIUM` | Line-height headingH4/headingH4Mono có dấu hiệu không nhất quán | `VTypography` | `OPEN_DS_TOKEN_REVIEW` |
| `DSG-004` | `DS_SOURCE_GAP` | `LOW` | VSpacing.space0 = 1 là naming anomaly | `VSpacing` | `OPEN_DS_TOKEN_REVIEW` |
| `DSG-005` | `MODULE_PRESENTATION_REQUIREMENT` | `INFO` | Theme 7 cần module-presentation patterns đặc thù nghiệp vụ | `THEME7_MODULE_PRESENTATION` | `DERIVED_MODULE_PRESENTATION_WORK` |

## BG-001 — Quyền sở hữu bước thực thi ghi nhận hàng chưa rõ trên UI

**Type/Severity:** `BUSINESS_GAP` / `BLOCKER`

**Problem:** SCR-012 được định nghĩa là result screen nhưng đồng thời là nguồn của ACT-02-RECEIVE. UC-02-04 nói UC không sở hữu màn hình riêng và UI chỉ hiển thị tiến trình/kết quả. Chưa rõ người dùng phải bấm ghi nhận, hệ thống tự thực thi sau submit/approval, hay cần tách một execution/confirmation surface.

**Decision needed:** Chọn một trong ba mô hình: tự thực thi; người dùng xác nhận trên review screen; hoặc tách execution screen và result screen.

**Recommendation:** Ưu tiên tách trách nhiệm: mutation ở review/confirmation surface; SCR-012 chỉ hiển thị processing/result. Không chốt cho đến khi Product/BA xác nhận.

## BG-002 — ACT-02-DECIDE gộp ba quyết định nhưng thiếu contract theo từng outcome

**Type/Severity:** `BUSINESS_GAP` / `BLOCKER`

**Problem:** Flow có Duyệt, Từ chối và Yêu cầu bổ sung nhưng Screen/Action Registry chưa khóa reason bắt buộc hay không, dữ liệu được giữ, destination của maker, và điều kiện enable/visibility theo từng outcome.

**Decision needed:** Khóa payload/validation/result/navigation cho APPROVE, REJECT và REQUEST_CHANGES.

**Recommendation:** Giữ một review screen; tách ba outcome trong action payload và UI action hierarchy, không cần tách ba màn hình.

## BG-003 — Thiếu entry/resume contract cho multi-actor approval

**Type/Severity:** `BUSINESS_GAP` / `HIGH`

**Problem:** Các BJ nhảy trực tiếp sang màn hình duyệt nhưng chưa xác định approver mở task từ đâu, deep link/task list nào sở hữu context, maker nhận kết quả và resume ở đâu, và xử lý task stale/đã được người khác quyết định thế nào.

**Decision needed:** Chọn task surface dùng chung hoặc framework-level route/deep link; khóa return/resume destination.

**Recommendation:** Tạo một approval work-queue dùng chung ở application layer hoặc một route contract dùng chung; không clone inbox theo từng BJ.

## BG-004 — SCR-041 đang phục vụ ba ngữ cảnh kết quả và cả bước trung gian

**Type/Severity:** `STRUCTURAL_REVIEW` / `MEDIUM`

**Problem:** Screen vừa hiển thị kết quả chuyển trạng thái, chờ/bàn giao RTV và tiêu hủy; trong BJ-07 còn là điểm điều hướng tiếp. Cần xác nhận một canonical result surface có mode rõ ràng hay tách theo user task.

**Decision needed:** KEEP_WITH_MODE_CONTRACT hoặc SPLIT theo RTV / state change / disposal.

**Recommendation:** Tạm giữ một canonical result pattern nhưng bắt buộc operation_type, result headline, impact anatomy và next-action map theo mode. Chỉ split nếu HTML review cho thấy mental context khác rõ.

## BG-005 — SCR-052 gộp hủy operation chưa thực thi và chuẩn bị correction sau finality

**Type/Severity:** `STRUCTURAL_REVIEW` / `HIGH`

**Problem:** Hai nhánh có precondition, risk, fields, action và destination khác nhau; một nhánh destructive cancel, nhánh còn lại chọn delta/reversal/replacement rồi tạo operation mới.

**Decision needed:** SPLIT thành hai canonical screens hoặc giữ một conditional shell với hai mode không đồng thời.

**Recommendation:** Đề nghị split để giảm nhầm lẫn và đơn giản validation/action contract.

## BG-006 — CAP-01 có bốn screen nhưng chưa có supporting UI flow/entry contract

**Type/Severity:** `FLOW_GAP` / `HIGH`

**Problem:** Bốn screen được loại khỏi 17 BJ có chủ đích, nhưng chưa khóa entry từ NAV-06 hay từ chi tiết chỉ báo, nhánh tenant default/product override, back/destination và quyền quản trị policy.

**Decision needed:** Duyệt supporting capability flow và entry points.

**Recommendation:** Giữ CAP-01 ngoài 17 BJ; dùng supporting flow riêng, không ép vào BJ-01/BJ-09.

## BG-007 — SCR-081 thiếu direct UC trace dù được dùng trực tiếp trong UIF-16

**Type/Severity:** `TRACE_GAP` / `MEDIUM`

**Problem:** Screen theo dõi rebuild run xuất hiện trong transition T08-T10 nhưng coverage/registry cũ chỉ gắn PROC-01-STEP-03.

**Decision needed:** Không cần business decision; xác nhận correction trace.

**Recommendation:** Đã xử lý derivable: gắn SCR-081 với BJ-16 và UC-16-03, vẫn giữ PROC-01-STEP-03 làm supporting evidence.

## DG-001 — Nội dung Screen Contract chủ yếu là semantic label và example, chưa có field identifier/data source đầy đủ

**Type/Severity:** `DOCUMENTATION_GAP` / `MEDIUM`

**Problem:** Thiết kế HTML có thể dùng minimum anatomy đã derivation, nhưng FE handoff sau này vẫn cần mapping field → read model/command payload và permission masking.

**Decision needed:** Không chặn visual design; bổ sung khi khóa từng BJ/Screen trước handoff Flutter.

**Recommendation:** Dùng Design Readiness extension làm source UX; không biến example thành API contract.

## DSG-001 — Package Flutter DS khai báo version 1.0.0 trong khi project rule gọi Design System v2

**Type/Severity:** `DS_GOVERNANCE_GAP` / `MEDIUM`

**Problem:** Người dùng đã xác nhận ZIP là nguồn Flutter DS hiện hành, nhưng naming/version governance chưa đồng nhất.

**Decision needed:** Không chặn Theme 7; sau này thống nhất release naming để tránh hiểu nhầm.

**Recommendation:** Dùng ZIP này làm single technical source of truth theo chỉ định của Product; không tạo HTML DS thứ hai.

## DSG-002 — VAssets tham chiếu illustration/icon không tồn tại hoặc không được bundle

**Type/Severity:** `DS_SOURCE_GAP` / `HIGH`

**Problem:** logo.png, empty_state.png, error_state.png và ba SVG icon được khai báo nhưng assets thực tế chỉ có font; pubspec cũng chỉ bundle font.

**Decision needed:** Bổ sung assets hoặc loại bỏ constants trước khi feature dựa vào chúng.

**Recommendation:** Theme 7 không dùng các asset constants này cho tới khi DS được sửa.

## DSG-003 — Line-height headingH4/headingH4Mono có dấu hiệu không nhất quán

**Type/Severity:** `DS_SOURCE_GAP` / `MEDIUM`

**Problem:** fontSize 14 nhưng height dùng 22/16, khác denominator của body 14; cần xác nhận đây là chủ đích hay typo.

**Decision needed:** DS owner xác nhận token.

**Recommendation:** Không hard-code bản sửa trong HTML; giữ source hiện hành cho đến khi DS owner sửa.

## DSG-004 — VSpacing.space0 = 1 là naming anomaly

**Type/Severity:** `DS_SOURCE_GAP` / `LOW`

**Problem:** Tên space0 thường gợi 0 px nhưng source là 1 px.

**Decision needed:** DS owner xác nhận naming.

**Recommendation:** HTML về sau phải đọc token theo source, không suy theo tên.

## DSG-005 — Theme 7 cần module-presentation patterns đặc thù nghiệp vụ

**Type/Severity:** `MODULE_PRESENTATION_REQUIREMENT` / `INFO`

**Problem:** Core DS chủ đích không chứa business chrome. Timeline evidence, operation result, approval action group, metric/status card, reconciliation progress và mobile record list phải thuộc module presentation của Theme 7.

**Decision needed:** Không cần mở rộng core DS ở checkpoint này; chỉ đề xuất promote khi pattern chứng minh tái sử dụng đa module.

**Recommendation:** Tạo module presentation components trong code Theme 7 bằng cách compose public Flutter DS; HTML chỉ mô phỏng cùng cấu trúc, không tạo HTML DS độc lập.
