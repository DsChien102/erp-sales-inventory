# Operations + Valuation UI Polish QA — v3.0.1

**Result: FAIL · 34/37 checks · 41 canonical screens · 228 declared-state renders**

Scope: BJ01, BJ02, BJ03, BJ04, BJ05, BJ06, BJ07, BJ13, BJ14. Gates cover optional semantic List Row icons, Product→child hierarchy, overflow/overlap, redundant headings, Vietnamese terminology, non-empty evidence sheets, declared-state rendering, and topology regression against v3.0.0.

## Checks

- FAIL — Workbench package version is v3.0.1 — 3.6.0
- FAIL — HTML manifest version/parent correct — 3.6.0 <- 3.5.1
- PASS — v3.0.1 correction layer loaded after v3.0.0
- PASS — All 9 Operations + Valuation UIF inspector labels are v3.0.1
- PASS — Shared List Row supports semantic hidden leading state
- PASS — v3.0.1 CSS is explicitly scoped to all 9 requested UIFs
- PASS — No feature-specific core DS component introduced
- PASS — BJ03 VCheckbox composition is annotated, not a custom selector component
- PASS — Requested scope is exactly 41 canonical routes — 41
- PASS — Requested route map matches release scope — {'UIF-02': {'screens': [{'id': 'SCR-006', 'states': ['READY', 'LOADING', 'CONFLICT', 'LOCKED', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-007', 'states': ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'PERMISSION_DENIED', 'PARTIAL_RECEIPT', 'SOURCE_VERSION_STALE'], 'actions': [], 'traceActions': []}, {'id': 'SCR-008', 'states': ['READY', 'VALIDATION_ERROR', 'CONFLICT', 'LOCKED', 'PERMISSION_DENIED', 'DRAFT_VALIDATION_FAILED'], 'actions': [], 'traceActions': ['ACT-02-SAVE-DRAFT']}, {'id': 'SCR-009', 'states': ['READY', 'EMPTY', 'VALIDATION_ERROR', 'CONFLICT', 'LOCKED', 'PERMISSION_DENIED', 'READ_ONLY'], 'actions': [], 'traceActions': ['ACT-02-SAVE-DRAFT']}, {'id': 'SCR-084', 'states': ['READY', 'VALIDATION_ERROR', 'LOT_CONFLICT', 'DUPLICATE_LINE', 'PERMISSION_DENIED', 'READ_ONLY'], 'actions': [], 'traceActions': ['ACT-02-SAVE-DRAFT']}, {'id': 'SCR-010', 'states': ['READY', 'VALIDATION_ERROR', 'APPROVAL_REQUIRED', 'PERMISSION_DENIED', 'PENDING_APPROVAL', 'DRAFT_VALIDATION_FAILED', 'APPROVAL_PRICE_BASIS_REQUIRED', 'APPROVER_CONFIGURATION_MISSING', 'FINANCIAL_MASKED'], 'actions': ['ACT-02-SUBMIT'], 'traceActions': []}, {'id': 'SCR-011', 'states': ['READY', 'VALIDATION_ERROR', 'APPROVAL_REQUIRED', 'PERMISSION_DENIED', 'SELF_APPROVAL_NOT_ALLOWED', 'APPROVAL_ALREADY_DECIDED', 'FINANCIAL_MASKED'], 'actions': ['ACT-02-DECIDE'], 'traceActions': []}, {'id': 'SCR-012', 'states': ['PROCESSING', 'COMPLETED', 'UNKNOWN', 'REJECTED_EXECUTION', 'PERMISSION_DENIED', 'VALUATION_PENDING_RESULT', 'COMMIT_UNKNOWN'], 'actions': [], 'traceActions': ['ACT-02-RECEIVE']}, {'id': 'SCR-013', 'states': ['READY', 'LOADING', 'EMPTY', 'STALE', 'PERMISSION_DENIED', 'PROCESSING_OR_UNKNOWN', 'TERMINAL'], 'actions': [], 'traceActions': []}]}, 'UIF-01': {'screens': [{'id': 'SCR-001', 'states': ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'STALE', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-003', 'states': ['READY', 'LOADING', 'STALE', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}]}, 'UIF-03': {'screens': [{'id': 'SCR-014', 'states': ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'PERMISSION_DENIED', 'FINANCIAL_MASKED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-015', 'states': ['READY', 'LOADING', 'VALIDATION_ERROR', 'PERMISSION_DENIED', 'EVIDENCE_MISSING', 'ALREADY_CONFIRMED', 'SOURCE_CHANGED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-017', 'states': ['READY', 'SOURCE_CHANGED', 'PERMISSION_DENIED'], 'actions': ['ACT-03-CONFIRM-COST'], 'traceActions': []}, {'id': 'SCR-019', 'states': ['PROCESSING', 'COMPLETED', 'UNKNOWN', 'REJECTED_EXECUTION', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['ACT-03-CONFIRM-COST']}]}, 'UIF-13': {'screens': [{'id': 'SCR-085', 'states': ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'PERMISSION_DENIED', 'FINANCIAL_MASKED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-086', 'states': ['READY', 'LOADING', 'SOURCE_CHANGED', 'VALIDATION_ERROR', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['BC-IV-06', 'API-Q-12']}, {'id': 'SCR-087', 'states': ['READY', 'LOADING', 'VALIDATION_ERROR', 'SOURCE_CHANGED', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['BC-IV-06', 'API-Q-12']}, {'id': 'SCR-088', 'states': ['READY', 'SOURCE_CHANGED', 'VALIDATION_ERROR', 'PERMISSION_DENIED'], 'actions': ['ACT-03-RECORD-LATE-COST'], 'traceActions': []}, {'id': 'SCR-089', 'states': ['PROCESSING', 'COMPLETED', 'REJECTED_EXECUTION', 'UNKNOWN', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['ACT-03-RECORD-LATE-COST']}]}, 'UIF-04': {'screens': [{'id': 'SCR-021', 'states': ['PARTIAL', 'FULL', 'SHORT', 'RELEASED', 'STALE', 'LOADING', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['ACT-04-RESERVE', 'ACT-04-RELEASE']}]}, 'UIF-05': {'screens': [{'id': 'SCR-025', 'states': ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-026', 'states': ['READY', 'STALE_RECOVERED', 'SHORTAGE', 'LOADING', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-027', 'states': ['READY', 'STALE_RECOVERED', 'PERMISSION_DENIED'], 'actions': ['ACT-06-SAVE-PICK'], 'traceActions': []}, {'id': 'SCR-028', 'states': ['READY', 'PARTIAL_ALLOWED', 'PARTIAL_BLOCKED', 'SOURCE_CHANGED', 'PERMISSION_DENIED'], 'actions': ['ACT-06-HANDOVER'], 'traceActions': []}, {'id': 'SCR-029', 'states': ['COMPLETED', 'PARTIAL_COMPLETED', 'UNKNOWN', 'REJECTED_EXECUTION', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['ACT-06-HANDOVER']}]}, 'UIF-06': {'screens': [{'id': 'SCR-030', 'states': ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-031', 'states': ['READY', 'LOADING', 'WAITING_APPROVAL', 'RETURN_CAP_CHANGED', 'SOURCE_CHANGED', 'CONFLICT', 'LOCKED', 'PERMISSION_DENIED'], 'actions': ['ACT-07-SUBMIT-LOT-EXCEPTIONS', 'ACT-07-RECEIVE-RETURN'], 'traceActions': []}, {'id': 'SCR-032', 'states': ['READY', 'VALIDATION_ERROR', 'APPROVED_EXCEPTION', 'REJECTED_EXCEPTION', 'PENDING_APPROVAL', 'CONFLICT', 'LOCKED', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-033', 'states': ['READY', 'VALIDATION_ERROR', 'EXPIRED_GUARD', 'SOURCE_CHANGED', 'CONFLICT', 'LOCKED', 'PERMISSION_DENIED'], 'actions': ['ACT-07-CLASSIFY'], 'traceActions': ['ACT-07-CLASSIFY']}, {'id': 'SCR-035', 'states': ['RECEIVED_PENDING_CLASSIFICATION', 'COMPLETED', 'UNKNOWN', 'REJECTED_EXECUTION', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['ACT-07-RECEIVE-RETURN', 'ACT-07-CLASSIFY']}, {'id': 'SCR-034', 'states': ['TASK_LIST', 'READY', 'APPROVED', 'REJECTED', 'PERMISSION_DENIED'], 'actions': ['ACT-07-DECIDE-LOT-EXCEPTION'], 'traceActions': []}]}, 'UIF-07': {'screens': [{'id': 'SCR-036', 'states': ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'PERMISSION_DENIED', 'EXPIRED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-037', 'states': ['READY', 'LOADING', 'EXPIRED', 'LOCKED', 'PERMISSION_DENIED', 'FINANCIAL_RESTRICTED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-039', 'states': ['READY', 'SOURCE_CHANGED', 'PHYSICAL_MISMATCH', 'VALIDATION_ERROR', 'PERMISSION_DENIED'], 'actions': ['ACT-08-RTV'], 'traceActions': []}, {'id': 'SCR-041', 'states': ['PROCESSING', 'COMPLETED', 'PENDING_APPROVAL', 'REJECTED_EXECUTION', 'UNKNOWN', 'EXPIRED', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['ACT-08-STATE']}]}, 'UIF-14': {'screens': [{'id': 'SCR-072', 'states': ['READY', 'LOADING', 'EMPTY', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-073', 'states': ['READY', 'VALIDATION_ERROR', 'PERMISSION_DENIED'], 'actions': [None], 'traceActions': ['ACT-14-CALCULATE']}, {'id': 'SCR-074', 'states': ['CALCULATING', 'BLOCKED', 'READY_FOR_REVIEW', 'INPUT_CHANGED', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': []}, {'id': 'SCR-076', 'states': ['READY', 'SOURCE_CHANGED', 'PERMISSION_DENIED'], 'actions': [None], 'traceActions': ['ACT-14-PUBLISH']}, {'id': 'SCR-077', 'states': ['COMPLETED', 'REJECTED_EXECUTION', 'UNKNOWN', 'PERMISSION_DENIED'], 'actions': [], 'traceActions': ['ACT-14-PUBLISH']}]}}
- FAIL — v3.0.0 baseline available for topology regression — baseline missing
- PASS — All declared states render without JS/geometry/horizontal-overflow failures — 228 states; failures=[]
- PASS — No List Row copy/status overlap across all 228 state renders
- PASS — Hidden List Row icons reclaim canonical copy inset
- PASS — No banned English/implementation revision terms in Product UI across 228 states
- PASS — UIF-03/SCR-014 work queue rows are text-first with no decorative leading icon — [{'lead': 'Hidden', 'title': 'PN-260816-04'}, {'lead': 'Hidden', 'title': 'PN-260816-02'}, {'lead': 'Hidden', 'title': 'PN-260901-03'}, {'lead': 'Hidden', 'title': 'PN-260902-07'}]
- PASS — UIF-05/SCR-025 work queue rows are text-first with no decorative leading icon — [{'lead': 'Hidden', 'title': 'SO-260827-21'}, {'lead': 'Hidden', 'title': 'SO-260827-24'}]
- PASS — UIF-06/SCR-030 work queue rows are text-first with no decorative leading icon — [{'lead': 'Hidden', 'title': 'RET-260827-03'}, {'lead': 'Hidden', 'title': 'RET-260827-05'}, {'lead': 'Hidden', 'title': 'RET-260827-07'}]
- PASS — UIF-07/SCR-036 work queue rows are text-first with no decorative leading icon — [{'lead': 'Hidden', 'title': 'RTV-260827-02'}, {'lead': 'Hidden', 'title': 'RTV-260827-04'}, {'lead': 'Hidden', 'title': 'RTV-260903-03'}, {'lead': 'Hidden', 'title': 'RTV-260903-05'}]
- PASS — UIF-13/SCR-085 work queue rows are text-first with no decorative leading icon — [{'lead': 'Hidden', 'title': 'VC-8842 · dòng 1'}, {'lead': 'Hidden', 'title': 'INS-2609-17 · dòng 2'}, {'lead': 'Hidden', 'title': 'VC-8890 · dòng 1'}, {'lead': 'Hidden', 'title': 'CK-2609-06 · dòng 1'}]
- PASS — UIF-14/SCR-072 work queue rows are text-first with no decorative leading icon — [{'lead': 'Hidden', 'title': 'Tháng 08/2026'}, {'lead': 'Hidden', 'title': 'Cập nhật 03/09/2026'}, {'lead': 'Hidden', 'title': 'Tháng 09/2026'}]
- PASS — BJ06 return-request context hides decorative product icon
- PASS — BJ06 classification-request context hides decorative product icon
- PASS — BJ07 Product parents use canonical Status/Compact List Row with meaningful product icon — [['Status', 'Compact', 'Visible'], ['Status', 'Compact', 'Visible'], ['Status', 'Compact', 'Visible']]
- PASS — BJ07 LOT/non-LOT children use canonical Navigation/Default List Row without decorative icon — [['Navigation', 'Default', 'Hidden'], ['Navigation', 'Default', 'Hidden'], ['Navigation', 'Default', 'Hidden'], ['Navigation', 'Default', 'Hidden']]
- PASS — BJ07 preparation meta uses user language, not UOM jargon
- PASS — BJ03 Product parents use canonical Status/Compact List Row with product icon — [['Status', 'Compact', 'Visible'], ['Status', 'Compact', 'Visible']]
- PASS — BJ03 multi-select child scopes use VCheckbox composition — 4
- PASS — BJ03 queue has no redundant “Công việc” heading
- PASS — BJ03 “Căn cứ và cách tính” sheet has useful empty content instead of blank body — {'exists': True, 'text': 'Căn cứ và cách tính\nChưa có phạm vi để xem căn cứ\n\nChọn ít nhất một lô hoặc phạm vi hàng trước khi xem căn cứ và cách tính.\n\nĐóng', 'empty': True}
- PASS — BJ03 conflicting evidence still requires an explicit source decision — {'selected': 0, 'sources': 2}
- PASS — BJ03 selecting valuation quantity does not mutate pending received quantity before commit — {'before': 50, 'after': 50}
- PASS — BJ13 queue titles/statuses do not overlap — [{'title': 'VC-8842 · dòng 1', 'overlap': False}, {'title': 'INS-2609-17 · dòng 2', 'overlap': False}, {'title': 'VC-8890 · dòng 1', 'overlap': False}, {'title': 'CK-2609-06 · dòng 1', 'overlap': False}]
- PASS — BJ13 foreign-currency source still exposes accounting exchange rate in Vietnamese — 9:41
LTE  100%
Phân bổ chi phí
Chi phí cần phân bổ
Giá trị nguồn
250 USD
Tỷ giá
Tỷ giá kế toán 24.500 VND/USD
Sau chuẩn hóa
6.125.000 đ
Căn cứ phân bổ
Căn cứ phân bổ
Chọn căn cứ phân bổ
Theo giá trị hàng nhận
Áp dụng chính sách phân bổ hiện hành
Kết quả phân bổ
2 dòng đích
Vaccine Canine X
PN-260901-03 · 10 lọ · Lô CX2609
748.558 đ
Doxycycline 100mg
PN-260901-08 · 60 hộp
5.376.442 đ
Tổng phân bổ
6.125.000 đ
Kỳ ghi nhận
Kỳ gốc
09/2026
Kỳ ghi nhận
09/2026
Rà soát ghi chi phí
- PASS — BJ14 setup uses “Thời điểm chốt” and hides raw policy revisions — 9:41
LTE  100%
Thiết lập lần tính
Loại lần tính
Chốt kỳ
Tính toàn kỳ theo thời điểm chốt kế toán
Cập nhật trong kỳ
Chỉ tính phạm vi cần cập nhật
Kỳ
08/2026
09/2026
Phạm vi
Toàn bộ sản phẩm
Sản phẩm cần tính lại
Chính sách áp dụng
Thời điểm chốt
Cuối kỳ 08/2026
Phương pháp công bố
Bình quân cuối kỳ
Chính sách
Chính sách giá vốn
Tính giá vốn
- PASS — BJ14 run kind remains canonical VRadio
- PASS — No browser page errors during v3.0.1 scope QA
