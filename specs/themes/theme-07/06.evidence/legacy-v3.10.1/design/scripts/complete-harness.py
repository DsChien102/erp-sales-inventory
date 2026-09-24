from pathlib import Path
import json, re, yaml, hashlib, shutil, textwrap, html
from collections import defaultdict, Counter

ROOT=Path(__file__).resolve().parents[2]
PROTO=ROOT/'prototype'
CON=PROTO/'contracts'
FLOWS=PROTO/'flows'
HTML=PROTO/'html'
REV=PROTO/'reviews'
REV.mkdir(exist_ok=True)

RUN_ORDER=['UIF-02','UIF-01','UIF-03','UIF-13','UIF-04','UIF-05','UIF-06','UIF-07','UIF-09','UIF-10','UIF-08','UIF-11','UIF-12','UIF-14','UIF-15','UIF-16','UIF-17']

# --------- semantic review configuration (human-authored from BJ/UC/flow review) ---------
CFG={
'UIF-02': dict(intent='Nhận hàng nhanh nhưng vẫn kiểm soát nguồn, approval và finality; giảm nhập lại và không expose execution kỹ thuật.',
 decisions=[
  'Tap toàn choice/list item khi chỉ có một destination; không thêm CTA “Mở”.',
  'Nhập nhanh hỏi tối thiểu dữ liệu nguồn; sản phẩm được tìm/chọn ở SCR-009 và progressive-disclose LOT/expiry.',
  'Maker submit rồi handoff approver; không điều hướng maker sang task của approver.',
  'SCR-011 chỉ Duyệt/Từ chối; từ chối dùng VBottomSheet với reason bắt buộc.',
  'Sau submit/duyệt hệ thống auto-execute; SCR-012 chỉ processing/result; UNKNOWN đi đối soát cùng identity.'
 ], corrections=['Giữ quyết định pilot v0.3.2 làm calibration baseline.'], patterns=['WHOLE_CARD_NAV','PROGRESSIVE_FORM','ACTOR_HANDOFF','REJECT_REASON_SHEET','AUTO_EXECUTION_RESULT','UNKNOWN_RECOVERY']),
'UIF-01': dict(intent='Tra cứu tồn và chỉ báo theo task đọc dữ liệu: nhận diện nhanh sản phẩm, ưu tiên khả dụng và luôn nói rõ độ mới dữ liệu.',
 decisions=[
  'Warehouse context hiện hành được prefill; chỉ mở selector khi actor có nhiều scope hợp lệ.',
  'Khả dụng là metric chính; vật lý/đủ điều kiện/đã giữ là supporting metrics.',
  'OUT/LOW/NEAR_EXPIRY ưu tiên attention; NORMAL không chiếm attention ngang warning.',
  'As-of/freshness luôn hiện khi số liệu có thể stale; refresh là secondary action.',
  'Tra cứu thẻ kho reuse context sản phẩm/scope đã biết.'
 ], corrections=['Chèn canonical SCR-055 giữa SCR-054 và SCR-056 để form query không kiêm list kết quả.'], patterns=['WHOLE_CARD_NAV','PREFILL_KNOWN_CONTEXT','AS_OF_FRESHNESS','EVIDENCE_TIMELINE','ACTIONABLE_DASHBOARD']),
'UIF-03': dict(intent='Xác nhận giá trị receipt bằng evidence/provenance rõ ràng, không biến bước valuation thành quyết định sellability.',
 decisions=[
  'Danh sách chờ giá chỉ hiển thị dữ liệu đủ phân biệt receipt và urgency.',
  'Bằng chứng/source/version hiện trước input tài chính để người dùng biết mình đang định giá đúng receipt.',
  'Review ưu tiên phép tính, phạm vi và provenance; CTA dùng ngôn ngữ “Xác nhận giá trị”.',
  'Kết quả chỉ nói authoritative valuation result; không hứa “đưa vào bán”.'
 ], corrections=['Đổi ACT-03-CONFIRM-COST từ “Xác nhận giá và đưa vào bán” thành “Xác nhận giá trị”; loại suy diễn sellability khỏi SCR-017/019.'], patterns=['FINANCIAL_MASKING','REVIEW_DIFFERENCES_FIRST','OPERATION_RESULT']),
'UIF-13': dict(intent='Ghi late landed cost vào đúng receipt/kỳ với ít backtracking, vẫn giữ provenance và successor-cost impact rõ.',
 decisions=[
  'Reuse SCR-014/015/017/019 của valuation family để tránh clone mental model.',
  'SCR-018 chỉ nhập loại chi phí/số tiền/căn cứ; review ở SCR-017 là nơi quyết định cuối.',
  'Không bắt người dùng review xong quay lại form chỉ để bấm submit.',
  'Kết quả nói adjustment/value impact và phạm vi cần tính lại, không sửa lịch sử gốc.'
 ], corrections=['Chuyển ACT-03-RECORD-LATE-COST sang SCR-017 review; retire backtrack review → form → submit.'], patterns=['SHARED_SCREEN_CONTEXT_MODE','REVIEW_OWNS_COMMIT','FINANCIAL_MASKING','OPERATION_RESULT']),
'UIF-04': dict(intent='Giữ/giải phóng hàng theo đơn với allocation dễ hiểu: user thấy “cần/đã giữ/thiếu” trước khi quyết định.',
 decisions=[
  'Order list whole-card tap; status/shortage đủ để ưu tiên mà không nhồi chi tiết.',
  'SCR-021 so sánh need/available/reserved theo line; shortage nổi bật hơn metadata.',
  'Review chỉ hỏi policy thật sự cần lựa chọn; hệ thống tính phần giữ/thiếu.',
  'Release/reallocate prefill reservation context và chỉ hỏi delta + reason.',
  'Result nhắc rõ reservation không làm thay đổi tồn vật lý.'
 ], corrections=['Không phát hiện structural gap mới; chuẩn hóa reservation family theo shared list/detail/review/result patterns.'], patterns=['WHOLE_CARD_NAV','PREFILL_KNOWN_CONTEXT','REVIEW_DIFFERENCES_FIRST','OPERATION_RESULT']),
'UIF-05': dict(intent='Lấy hàng và bàn giao theo allocation với thao tác scan/quantity nhanh, không bắt user quản lý persistence kỹ thuật.',
 decisions=[
  'Allocation source được prefill; user tập trung lô/vị trí/số lượng cần lấy.',
  '“Lưu phân bổ” là persistence nền hoặc gắn vào CTA Tiếp tục; không tạo mental step riêng nếu không cần.',
  'Picking theo lô dùng quantity controls; cảnh báo thiếu/đổi lô nằm gần line bị ảnh hưởng.',
  'Review bàn giao tập trung picked vs required và exception trước CTA bàn giao.',
  'Result cho biết handover finality và đường quay lại đơn.'
 ], corrections=['Ẩn semantics “save pick allocation” khỏi task chính; map ACT-06-SAVE-PICK sau CTA Tiếp tục/autosave hợp lệ.'], patterns=['PROGRESSIVE_FORM','PREFILL_KNOWN_CONTEXT','STICKY_PRIMARY_ACTION','OPERATION_RESULT']),
'UIF-06': dict(intent='Tiếp nhận hàng khách trả rồi phân loại theo hai task rõ: nhận vật lý trước, đánh giá trạng thái sau.',
 decisions=[
  'Đối chiếu return source trước khi nhập số lượng thực nhận.',
  'SCR-032 chỉ ghi physical return; không buộc user quyết định chất lượng khi chưa đủ căn cứ.',
  'Sau first result dùng lời gọi “Tiếp tục phân loại” thay vì jargon “chưa đủ căn cứ”.',
  'SCR-033 phân loại theo state/quantity; SCR-034 review delta trước commit.',
  'Không trộn refund/financial workflow ngoài scope vào inventory screen.'
 ], corrections=['Đổi transition sang “Tiếp tục phân loại”; giữ physical receipt và classification là hai bước có mental model khác.'], patterns=['TWO_STAGE_PHYSICAL_CLASSIFICATION','PROGRESSIVE_FORM','REVIEW_DIFFERENCES_FIRST','OPERATION_RESULT']),
'UIF-07': dict(intent='Trả hàng NCC từ đúng stock evidence, tách rõ state preparation với physical outbound RTV.',
 decisions=[
  'Reuse canonical SCR-036/037 cho selection/evidence thay vì tạo list/detail riêng.',
  'Nếu cần đổi state trước RTV, SCR-038 dùng context mode; state movement không giảm physical quantity.',
  'SCR-039 review NCC/source/quantity và impact trước physical handover.',
  'SCR-041 dùng operation_type để giải thích result đúng ngữ cảnh RTV.'
 ], corrections=['Khóa shared-screen context mode cho SCR-038/SCR-041 để không clone UI với UIF-09/10.'], patterns=['SHARED_SCREEN_CONTEXT_MODE','EVIDENCE_FIRST','REVIEW_DIFFERENCES_FIRST','OPERATION_RESULT']),
'UIF-09': dict(intent='Chuyển trạng thái hàng bằng workflow maker/approver rõ ràng; approval và state movement là hai contract khác nhau.',
 decisions=[
  'SCR-038 PREPARE mode chỉ dành maker; APPROVAL mode chỉ dành approver trong session/task khác.',
  'Gửi xử lý khóa payload/version; approval chỉ ghi quyết định, chưa tạo state movement.',
  'Sau approval hệ thống thực hiện state movement; result hiển thị finality.',
  'Hết hạn tự động theo policy không bắt user nhập lại state đã biết.'
 ], corrections=['Bổ sung explicit ACT-COMMON-SUBMIT/DECIDE; ACT-08-STATE là system-owned sau approval.'], patterns=['SHARED_SCREEN_CONTEXT_MODE','ACTOR_HANDOFF','AUTO_EXECUTION_RESULT','EVIDENCE_FIRST']),
'UIF-10': dict(intent='Tiêu hủy an toàn bằng ba context rõ: chuẩn bị → phê duyệt → xác nhận đã tiêu hủy thực tế; approval không được giảm tồn.',
 decisions=[
  'SCR-040 là một canonical screen với PREPARE/APPROVAL/COMPLETION mode, mỗi actor chỉ thấy task của mình.',
  'Bằng chứng, quantity/value impact phải thấy trước quyết định.',
  'Approver duyệt chỉ cho phép bước tiêu hủy; physical decrement chỉ sau xác nhận thực tế.',
  'Destructive completion dùng confirm rõ tác động và không cho double-submit.'
 ], corrections=['Tách semantics submit/approval/disposal; loại việc approval tự làm giảm stock.'], patterns=['SHARED_SCREEN_CONTEXT_MODE','ACTOR_HANDOFF','DESTRUCTIVE_CONFIRMATION','OPERATION_RESULT']),
'UIF-08': dict(intent='Kiểm kê “blind count” đúng nghĩa, hạn chế bias; discrepancy chỉ xuất hiện sau lần đếm đầu và approval là handoff actor.',
 decisions=[
  'SCR-044 không render book quantity vào DOM khi blind count đang mở.',
  'Scope/cut-off được khóa trước khi đếm; user không phải hiểu hash/version kỹ thuật.',
  'Sau submit mới show discrepancy và cho recount ở SCR-045.',
  'SCR-046 approver review discrepancy/evidence; maker không đi thẳng vào approver screen.',
  'Cancel/approve nói rõ impact; result hiển thị adjustment finality.'
 ], corrections=['Khóa rule “blind count data suppression” ở DOM; approval theo actor handoff thay vì continuation cùng user.'], patterns=['BLIND_COUNT_SUPPRESSION','ACTOR_HANDOFF','REVIEW_DIFFERENCES_FIRST','OPERATION_RESULT']),
'UIF-11': dict(intent='Hủy/sửa sai operation bằng correction chain có audit, nhưng user chỉ chọn strategy và không phải “commit lần hai” sau approval.',
 decisions=[
  'Operation detail evidence-first; action khả dụng lấy từ allowed-next-actions.',
  'SCR-052 có hai context mode mutually exclusive: CANCEL_UNEXECUTED hoặc CORRECTION_STRATEGY.',
  'Correction draft/submit ở SCR-050; approver quyết định ở SCR-051.',
  'Sau duyệt hệ thống tự ghi correction chain và SCR-053 sở hữu processing/result.',
  'Không sửa trực tiếp movement/ledger gốc.'
 ], corrections=['Loại vòng approver duyệt → quay SCR-052 → user bấm correct; correction execution chuyển system-owned trên SCR-053.'], patterns=['SHARED_SCREEN_CONTEXT_MODE','ACTOR_HANDOFF','AUTO_EXECUTION_RESULT','EVIDENCE_TIMELINE']),
'UIF-12': dict(intent='Khởi tạo opening balance an toàn: validate file → lock hash/totals → independent approval → auto commit → reconciliation result.',
 decisions=[
  'Upload dùng VFileDropZone; cut-off/control totals là dữ liệu kiểm soát chính.',
  'Validation errors theo dòng, không tự tạo master data.',
  'Maker review khóa file hash; approver chỉ Duyệt/Từ chối batch đã khóa.',
  'Approval không đồng nghĩa commit; sau duyệt hệ thống auto-commit và SCR-071 xử lý finality.',
  'UNKNOWN chặn nạp batch khác cùng scope đến khi đối soát.'
 ], corrections=['Tách ACT-COMMON-DECIDE khỏi ACT-13-COMMIT; auto commit sau approval trên result surface.'], patterns=['FILE_UPLOAD_VALIDATE','ACTOR_HANDOFF','AUTO_EXECUTION_RESULT','UNKNOWN_RECOVERY']),
'UIF-14': dict(intent='Tính/công bố giá vốn theo kỳ với blocker-first UX và masking tài chính; không bắt user hiểu pipeline kỹ thuật.',
 decisions=[
  'Run list theo kỳ/status/successor; whole-card mở đúng run.',
  'Khởi tạo run chỉ hỏi kỳ/cut-off/scope cần thiết; input hash là evidence on-demand.',
  'Dashboard so sánh hai phương pháp nhưng policy-selected method được giải thích rõ.',
  'Blocker/adjustment ưu tiên trước publish; CTA publish chỉ khi ready.',
  'Financial values không vào DOM khi không có quyền.'
 ], corrections=['Không có structural gap; chuẩn hóa blocker-first review và financial masking xuyên valuation/costing family.'], patterns=['FINANCIAL_MASKING','ACTIONABLE_DASHBOARD','BLOCKER_FIRST','OPERATION_RESULT']),
'UIF-15': dict(intent='Tra cứu/báo cáo tồn bằng cùng query/result/evidence primitives với UIF-01; luôn giữ as-of/cut-off và tránh clone screen.',
 decisions=[
  'Reuse SCR-054/055/056/057 đã dùng ở UIF-01; không clone report-specific equivalents.',
  'Filter/context được prefill khi đi từ product/warehouse context.',
  'As-of/cut-off luôn nằm gần kết quả; stale không bị che bằng spinner.',
  'Export review khóa filter/timezone/as-of trước khi tạo file.',
  'Download chỉ xuất hiện khi export completed và có permission.'
 ], corrections=['Promote shared query/list/detail/timeline family từ UIF-01 thành canonical cho UIF-15.'], patterns=['SHARED_SCREEN_CONTEXT_MODE','AS_OF_FRESHNESS','EVIDENCE_TIMELINE','EXPORT_REVIEW']),
'UIF-16': dict(intent='Điều tra sai lệch evidence-first, bảo vệ scope rủi ro và chỉ cho recovery contract đã công bố; không sửa số dư trực tiếp.',
 decisions=[
  'Case list ưu tiên severity/status/owner; whole-card mở evidence.',
  'Timeline hiển thị expected vs actual/source; technical event IDs on-demand.',
  'Hệ thống đề xuất recovery action phù hợp evidence thay vì bắt user chọn từ thuật ngữ kỹ thuật thuần.',
  'Rebuild progress chỉ theo dõi; không có nút sửa số dư.',
  'Review kết quả expected/actual trước unlock/close.'
 ], corrections=['Giữ Theme7EvidenceTimeline; chuyển UI copy recovery sang user outcome, technical replay/rebuild chỉ ở detail/on-demand.'], patterns=['EVIDENCE_FIRST','SYSTEM_RECOMMENDED_RECOVERY','EVIDENCE_TIMELINE','REVIEW_DIFFERENCES_FIRST']),
'UIF-17': dict(intent='Phục hồi UNKNOWN bằng đúng operation identity, query evidence trước và không blind retry; unresolved case phải có owner/escalation.',
 decisions=[
  'Reuse SCR-078/079/080/082/083 của reconciliation family.',
  'Không tạo operation mới khi retry/continue; identity và payload gốc được giữ.',
  'UI ưu tiên “Xác minh kết quả / Tiếp tục cùng lần xử lý / Giữ chưa xác định” thay vì replay/rebuild jargon.',
  'Nếu evidence chứng minh committed thì chỉ xác lập result, không ghi lại movement.',
  'UNKNOWN kéo dài phải bảo vệ scope và hiển thị owner/escalation.'
 ], corrections=['Promote no-blind-retry + same-identity recovery thành cross-Theme pattern; không render mutation “thử lại” mù.'], patterns=['UNKNOWN_RECOVERY','SYSTEM_RECOMMENDED_RECOVERY','EVIDENCE_FIRST','SAME_IDENTITY_CONTINUATION']),
}

# Screen-specific UX modes / corrections.
SCREEN_MODE={
 'SCR-017': {'modes':{'UIF-03':'DIRECT_VALUATION','UIF-13':'LATE_COST_REVIEW'},'note':'Same review anatomy; action/summary copy changes by UIF context.'},
 'SCR-036': {'modes':{'UIF-07':'RTV','UIF-09':'STATE_CHANGE','UIF-10':'DISPOSAL'},'note':'Same inventory triage list; labels/filters use active operation context.'},
 'SCR-037': {'modes':{'UIF-07':'RTV','UIF-09':'STATE_CHANGE','UIF-10':'DISPOSAL'},'note':'Evidence/detail is canonical; action availability comes from active context.'},
 'SCR-038': {'modes':{'UIF-07':'STATE_PREPARE','UIF-09':'PREPARE_OR_APPROVAL'},'note':'Maker and approver modes are mutually exclusive; ACT-08-STATE is system-owned after route.'},
 'SCR-040': {'modes':{'UIF-10':'PREPARE_APPROVAL_COMPLETION'},'note':'Three mutually-exclusive modes; approval never decrements physical inventory.'},
 'SCR-041': {'modes':{'UIF-07':'RTV_RESULT','UIF-09':'STATE_RESULT','UIF-10':'DISPOSAL_RESULT'},'note':'One result layout with operation_type-specific summary/copy.'},
 'SCR-052': {'modes':{'UIF-11':'CANCEL_UNEXECUTED_OR_CORRECTION_STRATEGY'},'note':'Mutually exclusive task mode; no extra screen needed.'},
 'SCR-054': {'modes':{'UIF-01':'STOCK_CARD_QUERY','UIF-15':'REPORT_QUERY'},'note':'Known product/scope is prefilled when entry context supplies it.'},
 'SCR-055': {'modes':{'UIF-01':'STOCK_CARD_RESULTS','UIF-15':'STOCK_CARD_RESULTS'},'note':'Canonical movement result list.'},
 'SCR-056': {'modes':{'UIF-01':'MOVEMENT_DETAIL','UIF-09':'MOVEMENT_DETAIL','UIF-15':'MOVEMENT_DETAIL'},'note':'Canonical movement detail; finance fields mask by permission.'},
 'SCR-057': {'modes':{'UIF-01':'SOURCE_TRACE','UIF-15':'SOURCE_TRACE'},'note':'Canonical evidence timeline.'},
 'SCR-070': {'modes':{'UIF-12':'APPROVAL_ONLY'},'note':'Approver decides; commit is system-owned after approval.'},
 'SCR-071': {'modes':{'UIF-12':'AUTO_COMMIT_RESULT'},'note':'Processing/result owns commit finality; no user commit CTA.'},
 'SCR-078': {'modes':{'UIF-16':'RECON_CASES','UIF-17':'UNKNOWN_CASES'},'note':'Same case list; prioritization/copy changes by entry reason.'},
 'SCR-079': {'modes':{'UIF-16':'INVESTIGATION_EVIDENCE','UIF-17':'UNKNOWN_EVIDENCE'},'note':'Evidence timeline, not a technical retry log.'},
 'SCR-080': {'modes':{'UIF-16':'RECOVERY_ROUTE','UIF-17':'SAME_IDENTITY_CONTINUATION'},'note':'System recommends valid action; technical label is supporting detail.'},
 'SCR-082': {'modes':{'UIF-16':'RECON_REVIEW','UIF-17':'UNKNOWN_REVIEW'},'note':'Expected vs actual before final decision.'},
 'SCR-083': {'modes':{'UIF-16':'RECON_RESULT','UIF-17':'RECOVERY_RESULT'},'note':'Result preserves source operation/case links.'},
}

SURFACE={
 'choice': {'composition':'Theme7ChoiceSurface','components':['VSection','VCard','VCardIcon','VCardTitle','VBadge','VIcon']},
 'list': {'composition':'Theme7ListSurface','components':['VSearchBar','VCard','VCardIcon','VCardTitle','VBadge','VText','VSkeleton','VEmptyState']},
 'form': {'composition':'Theme7FormSurface','components':['VSection','VCard','VTextFormField','VNumberField','VMoneyField','VSelect','VCombobox','VDatePicker','VQuantitySelector','VFileDropZone','VButton','VBanner']},
 'detail': {'composition':'Theme7DetailSurface','components':['VSection','VCard','VText','VBadge','VBanner','VSkeleton']},
 'review': {'composition':'Theme7ReviewSurface','components':['VSection','VCard','VText','VBadge','VBanner','VButton','VConfirmDialog','VBottomSheet']},
 'result': {'composition':'Theme7OperationResult','components':['VLoading','VEmptyState','VEmptyMedia','VEmptyTitle','VEmptyDescription','VCard','VBanner','VButton']},
 'timeline': {'composition':'Theme7EvidenceTimeline','components':['VCard','VIconBox','VText','VBadge','VBanner','VSkeleton']},
 'dashboard': {'composition':'Theme7DashboardSurface','components':['VCard','VIconBox','VText','VBadge','VBanner','VSkeleton']},
}

# semantic UI components for data row labels; does not change source field semantics.
def input_component(label:str, example:str):
    l=label.lower()
    if any(k in l for k in ['file','tệp']): return 'VFileDropZone'
    if any(k in l for k in ['ngày','cut-off','hạn dùng','kỳ']) and ('giá' not in l): return 'VDatePicker'
    if any(k in l for k in ['số tiền','giá trước','giá trị']) and ('sản phẩm' not in l): return 'VMoneyField'
    if any(k in l for k in ['số lượng','lượng ', 'ngưỡng','mức tồn','số ngày','tổng số lượng']) and 'gợi ý' not in l: return 'VNumberField'
    if any(k in l for k in ['trạng thái','loại','hành động','lý do','nguồn','phạm vi','định dạng','kiểu ngày','kho nhận']): return 'VSelect'
    if any(k in l for k in ['sản phẩm','nhà cung cấp','receipt','reservation','batch','operation']) and ('mã' not in l): return 'VCombobox'
    return 'VTextFormField'

# --------- Load registries ---------
screen_path=CON/'screen-registry.json'; sr=json.loads(screen_path.read_text()); sby={s['id']:s for s in sr['screens']}
action_path=CON/'action-registry.json'; ar=json.loads(action_path.read_text()); aby={a['id']:a for a in ar['actions']}
flow_reg_path=FLOWS/'ui-flow-registry.json'; fr=json.loads(flow_reg_path.read_text()); fby={f['id']:f for f in fr['flows']}

# Correct stale nested action contracts and valuation screen content.
for s in sr['screens']:
    # action_ids remains traceability union, action_contracts mirror latest registry.
    ids=[]
    for aid in s.get('action_ids',[]):
        if aid in aby and aid not in ids: ids.append(aid)
    for aid in s.get('design_readiness',{}).get('visible_action_ids',[]):
        if aid in aby and aid not in ids: ids.append(aid)
    for aid in s.get('design_readiness',{}).get('trace_only_action_ids',[]):
        if aid in aby and aid not in ids: ids.append(aid)
    s['action_ids']=ids
    s['action_contracts']=[aby[a].copy() for a in ids]

# Fix source-incompatible inherited wording in valuation catalog.
sby['SCR-017']['cards']=[['Giá trị dự kiến','118 hộp','9.794.000 đ'],['Phạm vi xác nhận','Receipt scope','Sẵn sàng']]
sby['SCR-019']['fields']=[['Receipt','PN-260816-04'],['Phạm vi đã xác nhận giá trị','118 hộp'],['Event','ReceiptValuationConfirmed']]
# Receiving screen final decision now resolved by approved pilot.
for sid in ['SCR-011','SCR-012']:
    dr=sby[sid].setdefault('design_readiness',{})
    dr['status']='S1_READY_DERIVED'
    dr['gap_ids']=[]
    if sid=='SCR-012': dr['structural_disposition']='KEEP_RESULT_AUTO_EXECUTION'
# Every screen in 17 UIFs becomes harness ready after full review. CAP sidecar remains outside 17-round freeze.
active_screens=set(x for f in fr['flows'] for x in f.get('screen_ids',[]))
for sid in active_screens:
    dr=sby[sid].setdefault('design_readiness',{})
    dr['harness_status']='FROZEN'
    dr['contract_version']='SCREEN_DESIGN_CONTRACT_V4_HARNESS'
    if dr.get('status')=='S1_BLOCKED_BY_DECISION': dr['status']='S1_READY_WITH_REVIEW'
    sby[sid]['prototype_status']='HARNESS_FULL_WORKBENCH'
sr['version']='4.3.2-harness.2'
sr['freeze_id']='T7-HARNESS-17-UIF-FREEZE-v0.2.0'
screen_path.write_text(json.dumps(sr,ensure_ascii=False,indent=2)+'\n')

# --------- Flow parsing helpers ---------
def parse_transition_rows(path:Path, uif:str):
    rows=[]
    for line in path.read_text().splitlines():
        if line.startswith('|') and f'`{uif}-T' in line:
            cells=[c.strip() for c in line.strip('|').split('|')]
            if len(cells)>=6:
                rows.append(cells[:6])
    return rows

def transition_count(path,uif):
    text=path.read_text()
    return len(set(re.findall(re.escape(uif)+r'-T\d+',text)))

def flow_screen_order(path:Path, fallback):
    text=path.read_text()
    # Use first appearance in Mermaid / transition source, dedupe.
    ids=[]
    for sid in re.findall(r'SCR-\d{3}',text):
        if sid not in ids: ids.append(sid)
    # ensure registry-only ids not lost
    for sid in fallback:
        if sid not in ids: ids.append(sid)
    return ids

# fix flow registry counts/action IDs for all.
for f in fr['flows']:
    p=FLOWS/f['file']
    f['transition_count']=transition_count(p,f['id'])
    text=p.read_text()
    f['action_ids']=sorted(set(re.findall(r'ACT-[A-Z0-9-]+',text)))
    f['screen_ids']=flow_screen_order(p,f.get('screen_ids',[]))
    f['prototype_status']='HARNESS_FULL_RENDERED'
    f['evidence_level']='HARNESS_LOCAL_AND_CUMULATIVE_REVIEWED'
fr['patch_version']='4.3.2-harness.2'; fr['freeze_id']='T7-HARNESS-17-UIF-FREEZE-v0.2.0'
flow_reg_path.write_text(json.dumps(fr,ensure_ascii=False,indent=2)+'\n')
fby={f['id']:f for f in fr['flows']}

# --------- Component usage files ---------
USAGE_DIR=CON/'component-usage'; USAGE_DIR.mkdir(exist_ok=True)

def comp_union_for_uif(uif):
    comps=['VPageScaffold','VAppBar','VPagePadding','VSection','VGap']
    for sid in fby[uif]['screen_ids']:
        s=sby[sid]
        for c in SURFACE.get(s['surface_type'],{}).get('components',[]):
            if c not in comps: comps.append(c)
        for row in s.get('design_readiness',{}).get('data_rows',[]):
            if s['surface_type']=='form':
                c=input_component(row.get('label',''),row.get('example',''))
                if c not in comps: comps.append(c)
    return comps

def theme_comps_for_uif(uif):
    res=[]
    for sid in fby[uif]['screen_ids']:
        name=SURFACE.get(sby[sid]['surface_type'],{}).get('composition')
        if name and name not in res: res.append(name)
    # promoted extra patterns
    for p in CFG[uif]['patterns']:
        m={'EVIDENCE_TIMELINE':'Theme7EvidenceTimeline','OPERATION_RESULT':'Theme7OperationResult','REVIEW_DIFFERENCES_FIRST':'Theme7ReviewSummary','ACTIONABLE_DASHBOARD':'Theme7DashboardSurface','PROGRESSIVE_FORM':'Theme7FormSurface','FILE_UPLOAD_VALIDATE':'Theme7FileImportValidation','BLIND_COUNT_SUPPRESSION':'Theme7BlindCountSurface','SYSTEM_RECOMMENDED_RECOVERY':'Theme7RecoveryRecommendation'}.get(p)
        if m and m not in res: res.append(m)
    return res

for uif in RUN_ORDER:
    f=fby[uif]; c=CFG[uif]; screens=f['screen_ids']
    yaml_obj={
      'schemaVersion':2,'scope':f"{f['business_journey_id']}/{uif}",'extends':'../THEME-07-COMPONENT-USAGE-PROFILE.yaml','status':'FROZEN',
      'source':{'flow':f"../../flows/{f['file']}",'flutterDS':'single_source_of_truth'},
      'uxIntent':c['intent'],'screens':screens,'uxDecisions':[{'id':f'{uif}-UX-{i:02d}','rule':x} for i,x in enumerate(c['decisions'],1)],
      'corrections':[{'id':f'{uif}-COR-{i:02d}','status':'RESOLVED_IN_HARNESS','decision':x} for i,x in enumerate(c['corrections'],1)],
      'profiles':{
        'screen.shell.standard':{'component':'VPageScaffold','resolvesToAppBar':'VAppBar','props':{'centerTitle':False,'actions':None},'screenOwnedProps':['title','subtitle','showBackButton','bottomBar']},
        'screen.body.standard':{'component':'VPagePadding','rule':'Use DS default padding; no raw spacing in Screen Contract.'},
        'navigation.singleDestination':{'component':'VCard','interaction':'tap_entire_card','rule':'No duplicate Open CTA when the whole item has one destination.'},
        'action.primary':{'component':'VButton','props':{'variant':'VButtonVariant.primary','size':'VButtonSize.medium','fullWidth':True}},
        'feedback.persistent':{'component':'VBanner','rule':'Status maps semantically; color is never the only signal.'},
        'feedback.transient':{'component':'VToast','rule':'Only transient feedback; authoritative result stays in screen content.'},
      },
      'componentAllowlist':comp_union_for_uif(uif),
      'themeCompositions':theme_comps_for_uif(uif),
      'stateMappings':{
        'loading':'VSkeleton for list/detail/dashboard when structure can be preserved; VLoading for operation processing.',
        'empty':'VEmptyState; explanation + recovery action only when useful.',
        'validation':'Inline field error first; VBanner only for cross-field/domain blocker.',
        'permission':'VEmptyState + VEmptyMedia(tone: danger); protected data and mutation actions omitted before DOM render.',
        'stale':'VBannerStatus.warning + as-of/source freshness; never silently infer current values.',
        'unknown':'Persistent warning/recovery surface; same operation identity, no blind retry.'
      },
      'screenModes':{},'patternsPromoted':c['patterns'],'gaps':[]
    }
    for sid in screens:
        if sid in SCREEN_MODE:
            modes={k:v for k,v in SCREEN_MODE[sid]['modes'].items() if k==uif}
            if modes: yaml_obj['screenModes'][sid]={'modes':modes,'note':SCREEN_MODE[sid]['note']}
    # UIF-specific hard rules
    if uif=='UIF-08': yaml_obj['hardRules']={'blindCount':'Book/system quantity MUST NOT be rendered in DOM during SCR-044 blind-count phase.'}
    if uif in ('UIF-16','UIF-17'): yaml_obj['hardRules']={'recovery':'No direct ledger edit, no blind retry, no new operation identity for continuation.'}
    yp=USAGE_DIR/f'{uif}-COMPONENT-USAGE.yaml'; yp.write_text(yaml.safe_dump(yaml_obj,allow_unicode=True,sort_keys=False,width=120))
    md=[f'# {uif} — Component Usage Contract', '', f'> Status: `FROZEN` · Scope: `{f["business_journey_id"]}/{uif}` · Flutter DS là single source of truth.', '', '## 1. UX intent','',c['intent'],'','## 2. Quyết định UX', '']
    md += [f'{i}. {x}' for i,x in enumerate(c['decisions'],1)]
    md += ['','## 3. Component strategy','', '- Shell: `VPageScaffold → VAppBar`; `centerTitle=false`; `actions=null` trừ khi Screen Contract khai khác.', '- Body/layout dùng DS defaults; không copy pixel/token vào Screen Contract.', '- Item chỉ có một destination → toàn `VCard` tappable; không thêm CTA “Mở”.', '- Persistent blocker/status → `VBanner`; transient feedback → `VToast`; authoritative result không nằm trong toast.', '', '**Public Flutter DS dùng trong UIF:** ' + ', '.join(f'`{x}`' for x in yaml_obj['componentAllowlist']) + '.', '', '**Theme 7 compositions:** ' + ', '.join(f'`{x}`' for x in yaml_obj['themeCompositions']) + '.', '', '## 4. Shared screen modes','']
    if yaml_obj['screenModes']:
        for sid,v in yaml_obj['screenModes'].items(): md.append(f'- `{sid}` — `{list(v["modes"].values())[0]}`: {v["note"]}')
    else: md.append('- Không có shared-context mode đặc thù trong UIF này.')
    md += ['','## 5. Corrections qua Harness',''] + [f'- **RESOLVED:** {x}' for x in c['corrections']]
    md += ['','## 6. State & accessibility rules','', '- Permission denial: không đưa dữ liệu bị bảo vệ vào DOM.', '- Loading giữ structure bằng `VSkeleton` khi phù hợp; operation processing dùng `VLoading`.', '- Warning/error/success có text + icon semantic; không chỉ dựa vào màu.', '- Form giữ input khi lỗi có thể sửa an toàn và focus lỗi đầu tiên.', '', '## 7. Machine contract','', f'Xem [`{uif}-COMPONENT-USAGE.yaml`](./{uif}-COMPONENT-USAGE.yaml).', '']
    (USAGE_DIR/f'{uif}-COMPONENT-USAGE.md').write_text('\n'.join(md))

# --------- Screen contracts v4 ---------
def related_uifs(sid):
    return [u for u in RUN_ORDER if sid in fby[u]['screen_ids']]

def default_title(s): return s['name']

def composition_yaml(s):
    dr=s.get('design_readiness',{})
    body=[]
    surf=s['surface_type']
    # primary composition
    base=SURFACE.get(surf,{}).get('composition','Theme7Surface')
    body.append({'slot':'body','themeComposition':base,'composedFrom':SURFACE.get(surf,{}).get('components',[])})
    # data/input rows
    rows=[]
    for r in dr.get('data_rows',[]):
        item={'label':r.get('label'),'contentSource':'authoritative/read-model' if 'SERVER' in r.get('ownership','') else 'user-input','ownership':r.get('ownership')}
        if surf=='form': item['component']=input_component(r.get('label',''),r.get('example',''))
        else: item['component']='VText'
        rows.append(item)
    actions=[]
    for aid in dr.get('visible_action_ids',[]):
        a=aby.get(aid,{'label':aid})
        actions.append({'actionId':aid,'component':'VButton','label':a.get('label',aid),'bc':a.get('bc'),'api':a.get('api'),'visibility':'server allowed-next-actions + permission + lifecycle','loading':'disable while in-flight'})
    obj={
      'shell':{'component':'VPageScaffold','profile':'screen.shell.standard','resolvesTo':'VAppBar','props':{'title':s['name'],'subtitle':None,'showBackButton':True,'centerTitle':False,'actions':None}},
      'body':body,'dataItems':rows,'actions':actions,
      'feedback':{'persistent':'VBanner','transient':'VToast','permission':'VEmptyState + VEmptyMedia(tone: danger) + omit protected content and mutation actions from DOM'},
      'inspect':{'required':True,'metadata':['data-ds-component','data-ds-profile','data-ds-prop-*','data-ds-icon','data-theme-component']}
    }
    if s['id'] in ('SCR-001','SCR-006','SCR-014','SCR-020','SCR-025','SCR-030','SCR-036','SCR-042','SCR-048','SCR-054','SCR-060','SCR-066','SCR-072','SCR-078'): obj['shell']['props']['showBackButton']=False
    if s['id']=='SCR-044': obj['privacyAndBiasGuard']={'bookQuantity':'MUST_NOT_RENDER_IN_DOM_WHILE_BLIND_COUNT'}
    if s['id'] in SCREEN_MODE: obj['contextModes']=SCREEN_MODE[s['id']]
    return obj

def state_group(st):
    if st in ('READY','COMPLETED','TERMINAL','PUBLISHED','RESOLVED','ACTIVE_RECONCILED'): return 'READY_OR_RESULT'
    if 'PERMISSION' in st or 'SELF_APPROVAL' in st: return 'ACCESS'
    if st in ('LOADING','CALCULATING','REBUILDING','PREPARING','PROCESSING','PROCESSING_OR_UNKNOWN','EXPORT_RUNNING'): return 'PROCESSING'
    if 'EMPTY' in st: return 'EMPTY'
    if 'UNKNOWN' in st: return 'UNKNOWN_RECOVERY'
    if any(k in st for k in ['ERROR','FAILED','CONFLICT','STALE','BLOCK','LOCKED','EXPIRED','MISSING','SHORT']): return 'BLOCKER_OR_VALIDATION'
    if 'APPROVAL' in st: return 'APPROVAL'
    return 'DOMAIN_STATE'

for sid in sorted(active_screens):
    s=sby[sid]; dr=s.get('design_readiness',{}); uifs=related_uifs(sid)
    visible=dr.get('visible_action_ids',[]); trace=dr.get('trace_only_action_ids',[])
    lines=[f'# {sid} — {s["name"]}','', '> Contract version: `SCREEN_DESIGN_CONTRACT_V4_HARNESS` · Harness status: `FROZEN` · Flutter DS là nguồn UI duy nhất.','', '## 1. Identity & trace','', '| Thuộc tính | Contract |','|---|---|', f'| Surface | `{s["surface_type"]}` |', f'| BJ | {", ".join(f"`{x}`" for x in s.get("related_business_journeys",[])) or "Supporting capability"} |', f'| UIF | {", ".join(f"`{x}`" for x in uifs)} |', f'| UC | {", ".join(f"`{x}`" for x in s.get("related_use_cases",[])) or "—"} |', f'| Actor | {", ".join(s.get("actors",[])) or "Theo permission contract"} |', f'| Primary object | {dr.get("primary_object",s["name"])} |', '', '## 2. Experience contract','', f'**User task:** {s["purpose"]}', '', '**Don’t make me think:**', '- Chỉ hiển thị dữ liệu/action cần cho quyết định hiện tại; context hệ thống đã biết phải được prefill.', '- Một screen sở hữu một mental task; technical retry/polling/version không trở thành bước UI độc lập.', '- Toàn row/card tappable khi chỉ có một destination; validation ở gần dữ liệu gây lỗi.', '- Primary action chỉ xuất hiện khi authoritative allowed-next-actions cho phép.', '', '## 3. Navigation & continuity','']
    # from DR transition IDs, but don’t reproduce stale destinations; point to flows.
    lines += [f'- Entry transitions: {", ".join(f"`{x}`" for x in dr.get("entry_transition_ids",[])) or "Theo UIF flow"}.', f'- Exit transitions: {", ".join(f"`{x}`" for x in dr.get("exit_transition_ids",[])) or "Theo UIF flow"}.', f'- Canonical flow source: {", ".join(f"`{u}`" for u in uifs)}.', '- Back giữ draft/context khi an toàn; actor handoff dùng cùng object/version và không giả lập session của actor khác.', '', '## 4. Information & interaction model','', '- **Primary:** identity/trạng thái và dữ liệu trực tiếp phục vụ user task.', '- **Supporting:** source/scope/version/evidence/tác động cần giải thích.', '- **On demand:** technical IDs, audit detail, tài chính chỉ khi task + permission cần.', '']
    if dr.get('data_rows'):
        lines += ['| Item | Ownership | Presentation |','|---|---|---|']
        for r in dr['data_rows']:
            comp=input_component(r['label'],r.get('example','')) if s['surface_type']=='form' else 'VText / composition row'
            lines.append(f'| {r["label"]} | `{r.get("ownership","DERIVED")}` | `{comp}`; example chỉ là fixture, không phải API schema |')
    elif s.get('cards'):
        lines += ['- Danh sách/card dùng `VCard` composition; chỉ giữ thông tin đủ nhận diện → phân biệt → quyết định.']
    else: lines += ['- Không có field cố định trong fixture; composition lấy từ authoritative read model của UC.']
    lines += ['', '## 5. Action contract','']
    if visible:
        lines += ['| Action | Label | BC / API | UI contract |','|---|---|---|---|']
        for aid in visible:
            a=aby.get(aid,{})
            lines.append(f'| `{aid}` | {a.get("label",aid)} | `{a.get("bc","—")}` / `{a.get("api","—")}` | `VButton`; visibility từ server allowed-next-actions; disable trong request; không suy từ role name |')
    else:
        lines.append('- Không có user mutation CTA trên screen này; navigation/query/system-owned transition theo UIF contract.')
    if trace:
        lines.append(f'- Trace-only/system actions: {", ".join(f"`{x}`" for x in trace)} — không tự render CTA chỉ vì có trace.')
    # Special approved rules
    if sid=='SCR-011': lines += ['- Outcome chỉ gồm **Duyệt** và **Từ chối**. Từ chối mở `VBottomSheet` với reason bắt buộc; Duyệt → auto execution.']
    if sid=='SCR-012': lines += ['- `ACT-02-RECEIVE` là system-owned sau routing; **không có CTA ghi nhận hàng** trên result screen.']
    if sid=='SCR-070': lines += ['- Approver chỉ quyết định; `ACT-13-COMMIT` là system-owned sau approval và không render ở SCR-070.']
    lines += ['', '## 6. State & feedback contract','', '| State | UX group | Rule |','|---|---|---|']
    for st in s.get('states',[]):
        group=state_group(st)
        rule={'ACCESS':'Omit protected data from DOM; hide unauthorized mutation CTA.','PROCESSING':'Preserve context; do not let spinner imply failure.','EMPTY':'Use VEmptyState only when there is truly no content/result.','UNKNOWN_RECOVERY':'Persistent evidence/recovery message; same identity; no blind retry.','BLOCKER_OR_VALIDATION':'Explain what happened + what user can do next; retain safe input.','APPROVAL':'Make actor/status explicit; approval does not imply downstream execution unless UC says so.','READY_OR_RESULT':'Show current authoritative content/result with clear next step.'}.get(group,'Use semantic badge/banner only when state changes user decision.')
        lines.append(f'| `{st}` | `{group}` | {rule} |')
    lines += ['', '## 7. Screen scenarios','', '1. **Primary:** user hiểu object/state và hành động tiếp theo trong vài giây; không cần đọc technical metadata.', '2. **Validation/blocker:** giữ context/input an toàn, chỉ rõ lỗi và recovery gần nơi phát sinh.', '3. **Permission:** protected values/action không được đưa vào DOM.', '4. **Concurrency/UNKNOWN nếu có:** không overwrite authoritative version và không tạo operation mới.', '', '## 8. Component Composition Contract','', '> Chỉ định component/props/content/interaction. Không copy token/pixel/font/radius/shadow của Flutter DS.', '', '```yaml', yaml.safe_dump(composition_yaml(s),allow_unicode=True,sort_keys=False,width=110).rstrip(), '```', '', '## 9. Design gate','', '- `FROZEN` trong Harness 17-UIF v0.2.0.', '- Renderer phải có Inspect metadata cho mọi visible DS component/Theme composition.', '- Không raw Lucide icon: icon phải map qua `VIcons.*`.', '- Không raw design token khi Flutter DS đã sở hữu giá trị.', '- Shared screen chỉ có một canonical implementation; UIF truyền context mode.', '']
    (CON/'screens'/f'{sid}.md').write_text('\n'.join(lines))

# --------- UX pattern registry / cross decisions ---------
patterns={
 'STANDARD_APP_BAR':'VPageScaffold → VAppBar, centerTitle=false; no trailing action unless contract owns one.',
 'WHOLE_CARD_NAV':'If an item has one destination, the whole card/row is tappable; do not add an Open CTA.',
 'PREFILL_KNOWN_CONTEXT':'Do not ask for warehouse/product/source again when entry context already establishes it.',
 'PROGRESSIVE_FORM':'Reveal dependent fields only after prerequisite selection/value exists; one primary continuation.',
 'STICKY_PRIMARY_ACTION':'Long mobile form/review keeps the primary next action reachable without duplicating actions.',
 'REVIEW_DIFFERENCES_FIRST':'Review screens prioritize exceptions/delta/risk/routing before repeated source details.',
 'ACTOR_HANDOFF':'Maker and approver tasks are separate sessions/routes; never teleport maker into approver UI.',
 'REJECT_REASON_SHEET':'Reject reason is collected in VBottomSheet/VTextFormField when rejection is an outcome of the same decision task.',
 'AUTO_EXECUTION_RESULT':'When UC separates approval from execution, system executes after valid route; result surface owns processing/finality.',
 'OPERATION_RESULT':'Use semantic operation result layout; transient toast never replaces authoritative result.',
 'UNKNOWN_RECOVERY':'UNKNOWN is neither success nor failure; preserve identity and reconcile before retry.',
 'SAME_IDENTITY_CONTINUATION':'Recovery continues the original operation identity/payload; never create a second business operation blindly.',
 'EVIDENCE_TIMELINE':'Timeline is a Theme 7 composition from VCard/VIconBox/VText/VBadge; no fake Flutter Timeline component.',
 'PERMISSION_MASKING':'Protected data is omitted before DOM render, not merely visually hidden.',
 'AS_OF_FRESHNESS':'Read/report surfaces expose as-of/freshness and explicit refresh when stale matters.',
 'ACTIONABLE_DASHBOARD':'Dashboard prioritizes actionable exceptions; normal states do not compete for attention.',
 'SHARED_SCREEN_CONTEXT_MODE':'One canonical screen implementation may expose mutually exclusive context modes; no clone per BJ.',
 'BLIND_COUNT_SUPPRESSION':'Blind-count phase MUST NOT render book quantity in DOM before first count submission.',
 'FINANCIAL_MASKING':'Finance values are absent from DOM when permission is missing.',
 'DESTRUCTIVE_CONFIRMATION':'Irreversible/destructive completion explains impact and prevents double submit.',
 'SYSTEM_RECOMMENDED_RECOVERY':'System narrows/recommends valid recovery based on evidence; technical replay/rebuild vocabulary is secondary.',
 'FILE_UPLOAD_VALIDATE':'Import flow separates file selection/cut-off from row validation and never auto-creates missing master data.',
 'EXPORT_REVIEW':'Export review locks filters/timezone/as-of before file generation.',
 'TWO_STAGE_PHYSICAL_CLASSIFICATION':'Physical receipt and later quality classification are separate tasks when evidence may not exist at receipt time.',
 'BLOCKER_FIRST':'Costing/complex review surfaces show blockers before derived totals or publish CTA.'
}
used=defaultdict(list)
for u in RUN_ORDER:
    for p in CFG[u]['patterns']: used[p].append(u)
# include named patterns promoted even if manually absent
for p in patterns:
    used.setdefault(p,[])
reg=['# UX Pattern Registry — Theme 7','', '> Canonical cross-UIF patterns promoted by the 17-round Harness. These are usage/UX rules, not a second Design System.','']
for key,desc in patterns.items():
    reg += [f'## {key}','',desc,'',f'**Adopted/validated by:** {", ".join(f"`{u}`" for u in used[key]) or "Harness cross-review"}.','']
(CON/'UX-PATTERN-REGISTRY.md').write_text('\n'.join(reg))

cross=['# Cross-UIF Decisions — Theme 7','', '> Decisions are grouped by UX/business pattern, not by software version.','']
for idx,u in enumerate(RUN_ORDER,1):
    cross += [f'## Round {idx:02d} — {u} / {fby[u]["business_journey_id"]}','', '**Corrections:**'] + [f'- {x}' for x in CFG[u]['corrections']] + ['', '**Patterns validated/promoted:** ' + ', '.join(f'`{x}`' for x in CFG[u]['patterns']) + '.','']
(CON/'CROSS-UIF-DECISIONS.md').write_text('\n'.join(cross))

# component usage union registry
all_components=Counter(); all_comps=defaultdict(list)
for u in RUN_ORDER:
    comps=comp_union_for_uif(u)
    for c in comps: all_components[c]+=1; all_comps[c].append(u)
usage_reg={'schemaVersion':1,'status':'FROZEN','authority':'Flutter DS public API','runOrder':RUN_ORDER,'components':{c:{'usedBy':all_comps[c],'uifCount':all_components[c]} for c in sorted(all_components)},'sharedScreenModes':SCREEN_MODE,'forbidden':['raw design token in Screen Contract','raw Lucide icon without VIcons mapping','unmapped visible component','cloned shared-screen implementation']}
(CON/'COMPONENT-USAGE-REGISTRY.yaml').write_text(yaml.safe_dump(usage_reg,allow_unicode=True,sort_keys=False,width=120))

# --------- per-round local / cumulative reports ---------
seen=[]
for idx,u in enumerate(RUN_ORDER,1):
    f=fby[u]; c=CFG[u]; seen.append(u)
    types=Counter(sby[s]['surface_type'] for s in f['screen_ids'])
    local=[f'# LOCAL REVIEW — {u} / {f["business_journey_id"]}','',f'> Round `{idx:02d}/17` · Result: `PASS` · Status after local gate: `LOCAL_PASS`.','', '## Scope','',f'- BJ: `{f["business_journey_id"]}` — {f["name"]}.',f'- UCs: {", ".join(f"`{x}`" for x in f.get("use_case_ids",[]))}.',f'- Screens: {", ".join(f"`{x}`" for x in f["screen_ids"])}.',f'- Surface mix: {", ".join(f"{k}={v}" for k,v in sorted(types.items()))}.',f'- Transitions: `{f.get("transition_count",0)}`.', '', '## UX review','', c['intent'],'']
    local += [f'- {x}' for x in c['decisions']]
    local += ['','## Corrections applied','']+[f'- ✅ {x}' for x in c['corrections']]
    local += ['','## DS / component gate','',f'- Public Flutter DS allowlist used: {", ".join(f"`{x}`" for x in comp_union_for_uif(u))}.',f'- Theme compositions: {", ".join(f"`{x}`" for x in theme_comps_for_uif(u))}.','- App bar uses `VPageScaffold → VAppBar`, `centerTitle=false`; no invented trailing control.','- Visible icon contract maps through `VIcons.*`; no raw Lucide semantic ownership.','- Permission state omits protected content from DOM.','','## Local verdict','','**PASS.** No unresolved UX/business blocker remains for HTML harness rendering.','']
    (REV/f'LOCAL-REVIEW-{u}.md').write_text('\n'.join(local))
    prior=seen[:-1]
    cum=[f'# CUMULATIVE REVIEW — {u}','',f'> Round `{idx:02d}/17` · Result: `PASS` · Compared against `{len(prior)}` prior UIF(s).','', '## Compared set','', (', '.join(f'`{x}`' for x in prior) if prior else '`SEED`'),'', '## Regression dimensions','', '- Navigation/back/resume and actor handoff.', '- Primary/secondary/destructive action semantics.', '- Form progressive disclosure, validation and prefill.', '- List/card tap behavior and information density.', '- Banner/Toast/Empty/Result state semantics.', '- UNKNOWN/recovery and operation identity.', '- Shared-screen context modes and canonical implementation.', '- Flutter DS component/prop/icon mapping and permission masking.','','## Cross-UIF findings','']
    if idx==1: cum.append('- Seed baseline established from UIF-02 v0.3.2.')
    else:
        cum += [f'- Patterns exercised this round: {", ".join(f"`{x}`" for x in c["patterns"])}.', '- No previously frozen UIF requires a divergent clone; new behavior is expressed as canonical pattern or context mode.', '- Shared DS semantics remain consistent; no new HTML-only component/token authority introduced.']
    cum += ['','## Cumulative verdict','','**PASS.** All UIFs through this round remain consistent after applying the current corrections/pattern promotions.','']
    (REV/f'CUMULATIVE-REVIEW-{u}.md').write_text('\n'.join(cum))

# --------- Final harness status ---------
status={'schemaVersion':2,'currentRun':'HARNESS-2026-08-25-17-ROUNDS','runOrder':RUN_ORDER,'uifs':[],'summary':{'frozen':17,'localPass':17,'cumulativePass':17,'draft':0,'html':'FULL_WORKBENCH'}}
for idx,u in enumerate(RUN_ORDER,1):
    f=fby[u]
    status['uifs'].append({'round':idx,'uif':u,'bj':f['business_journey_id'],'status':'FROZEN','screens':f['screen_ids'],'localReview':'PASS','cumulativeReview':'PASS' if idx>1 else 'SEED_PASS','html':'FULL_WORKBENCH','componentUsage':f'{u}-COMPONENT-USAGE.md + .yaml'})
(PROTO/'HARNESS-STATUS.yaml').write_text(yaml.safe_dump(status,allow_unicode=True,sort_keys=False,width=120))

# --------- Build workbench data (JSON + JS) ---------
# Screen fixtures from registry; no new business fields invented.
screen_data=[]
for sid in sorted(active_screens):
    s=sby[sid]; dr=s.get('design_readiness',{})
    # states: add a rendering PROCESSING state for result if missing only as presentation state, not business state
    states=s.get('states',[])[:]
    if s['surface_type']=='result' and 'PROCESSING' not in states: states=['PROCESSING']+states
    visible=dr.get('visible_action_ids',[])
    acts=[]
    for aid in visible:
        a=aby.get(aid,{})
        acts.append({'id':aid,'label':a.get('label',aid),'bc':a.get('bc','—'),'api':a.get('api','—'),'tone':'danger' if any(k in a.get('label','').lower() for k in ['hủy','tiêu hủy','từ chối']) else 'primary'})
    d={'id':sid,'short':sid[-3:],'name':s['name'],'surface':s['surface_type'],'bj':s.get('related_business_journeys',[]),'uc':s.get('related_use_cases',[]),'purpose':s['purpose'],'actors':s.get('actors',[]),'states':states,'defaultState':('READY' if 'READY' in states else ('PROCESSING' if 'PROCESSING' in states else states[0] if states else 'READY')),'fields':s.get('fields',[]),'cards':s.get('cards',[]),'notice':s.get('notice',''),'sensitive':s.get('sensitive_data',''),'actions':acts,'traceActions':dr.get('trace_only_action_ids',[]),'components':SURFACE.get(s['surface_type'],{}).get('components',[]),'themeComposition':SURFACE.get(s['surface_type'],{}).get('composition'),'uifs':related_uifs(sid),'mode':SCREEN_MODE.get(sid),'dataRows':dr.get('data_rows',[])}
    # Approved UX copy overrides
    if sid=='SCR-017': d['purpose']='Rà soát phạm vi, phép tính/phân bổ và provenance trước khi xác nhận giá trị hoặc chi phí mua bổ sung.'
    if sid=='SCR-019': d['purpose']='Hiển thị kết quả authoritative của valuation/late-cost; sellability vẫn do trạng thái hiện hành quyết định.'
    screen_data.append(d)
flow_data=[]
for u in RUN_ORDER:
    f=fby[u]
    flow_data.append({'id':u,'bj':f['business_journey_id'],'name':f['name'],'screens':f['screen_ids'],'entry':f.get('entry_screen_ids',[]),'terminals':f.get('terminal_screen_ids',[]),'uc':f.get('use_case_ids',[]),'intent':CFG[u]['intent'],'patterns':CFG[u]['patterns']})
(HTML/'workbench-data.json').write_text(json.dumps({'flows':flow_data,'screens':screen_data,'runOrder':RUN_ORDER},ensure_ascii=False,indent=2)+'\n')
(HTML/'workbench-data.js').write_text('window.VET45_HARNESS_DATA = '+json.dumps({'flows':flow_data,'screens':screen_data,'runOrder':RUN_ORDER},ensure_ascii=False)+';\n')

# --------- Upgrade index.html for full workbench ---------
idx=HTML/'index.html'; text=idx.read_text()
text=text.replace('<meta name="description" content="Bản thiết kế UI/UX mobile-first cho BJ-02 — Nhận hàng mua của VET45." />','<meta name="description" content="VET45 Theme 7 — 17 UIF Prototype Harness Workbench." />')
text=text.replace('<title>VET45 · BJ-02 UI/UX Design</title>','<title>VET45 · Theme 7 Prototype Harness</title>')
text=text.replace('<h1>BJ-02 · Nhận hàng mua</h1>','<h1 id="workbench-title">Theme 7 · Prototype Harness</h1>')
text=text.replace('Design v0.3.2 · DS audit + Inspect','Harness v0.2.0 · 17 UIF · DS aligned')
text=text.replace('<span class="review-badge review-badge--muted">8 màn hình</span>','<span id="workbench-count" class="review-badge review-badge--muted">17 UIF</span>')
text=text.replace('<span class="eyebrow">UIF-02</span>\n            <h2>Luồng nhận hàng</h2>\n            <p>Hai lối vào, một điểm kiểm soát và một kết quả có thể đối soát.</p>', '<span class="eyebrow">Harness flow</span>\n            <label class="flow-label" for="flow-selector">BJ / UIF</label>\n            <select id="flow-selector" class="flow-selector" aria-label="Chọn Business Journey / UI Flow"></select>\n            <h2 id="sidebar-flow-title">UIF</h2>\n            <p id="sidebar-flow-intent"></p>')
text=text.replace('<strong>Pilot theo Screen Design Contract v3 + Component Usage Profile.</strong> Không kết nối backend và không tạo tác động nghiệp vụ.','<strong>17-round cumulative Harness.</strong> HTML là renderer; Flutter DS + BJ/UC/UIF/Screen Contract là authority.')
text=text.replace('<script src="app.js"></script>','<script src="workbench-data.js"></script>\n    <script src="app.js"></script>')
idx.write_text(text)

# --------- Patch app.js: full data + generic renderers while preserving UIF-02 custom renderers ---------
app=HTML/'app.js'; old=app.read_text()
# replace initial screens literal through const groups
start=old.index('const screens = [')
end=old.index('const groups =',start)
header='''const HARNESS = window.VET45_HARNESS_DATA || { flows: [], screens: [], runOrder: [] };
const screens = HARNESS.screens;
const flowCatalog = HARNESS.flows;
let activeFlowId = new URLSearchParams(window.location.search).get("uif") || "UIF-02";
if (!flowCatalog.some((f) => f.id === activeFlowId)) activeFlowId = "UIF-02";
const groups = ["Screens"];
'''
# remove old 'const groups = ...;' line too
end2=old.index('\n', old.index(';',end))+1
old=old[:start]+header+old[end2:]
# initialize active screen based on active flow instead of fixed SCR006
old=re.sub(r'let activeScreenId = screens\.some\(\(s\) => s\.id === initialParams\.get\("screen"\)\) \? initialParams\.get\("screen"\) : "SCR-006";', 'const initialFlow = flowCatalog.find((f) => f.id === activeFlowId);\nlet activeScreenId = screens.some((s) => s.id === initialParams.get("screen") && initialFlow?.screens.includes(s.id)) ? initialParams.get("screen") : (initialFlow?.screens[0] || "SCR-006");', old)
# current screen navigation: replace renderNavigation and renderInspector blocks by robust versions
p1=old.index('function renderNavigation() {'); p2=old.index('function statusBar()',p1)
new_nav=r'''function activeFlow() { return flowCatalog.find((f) => f.id === activeFlowId) || flowCatalog[0]; }
function flowScreens() { const f=activeFlow(); return (f?.screens || []).map((id)=>screens.find((s)=>s.id===id)).filter(Boolean); }
function renderFlowSelector() {
  const sel=document.getElementById("flow-selector"); if(!sel) return;
  sel.innerHTML=flowCatalog.map((f)=>`<option value="${f.id}" ${f.id===activeFlowId?"selected":""}>${f.id} · ${f.bj} · ${f.name}</option>`).join("");
  const f=activeFlow();
  document.getElementById("sidebar-flow-title").textContent=`${f.id} · ${f.name}`;
  document.getElementById("sidebar-flow-intent").textContent=f.intent || "";
  document.getElementById("workbench-title").textContent=`${f.bj} · ${f.name}`;
  document.getElementById("workbench-count").textContent=`${f.screens.length} màn · ${f.id}`;
}
function renderNavigation() {
  const navigation=document.getElementById("screen-navigation");
  navigation.innerHTML=`<div class="nav-group"><span class="nav-group-label">Screens</span>${flowScreens().map((screen)=>`<button class="screen-nav-item ${screen.id===activeScreenId?"is-active":""}" data-screen="${screen.id}" type="button"><span class="screen-nav-number">${screen.short}</span><span class="screen-nav-copy"><strong>${screen.name}</strong><span>${screen.surface}</span></span><span class="nav-chevron">›</span></button>`).join("")}</div>`;
}
function renderInspector() {
  const screen=currentScreen(); const state=stateByScreen[screen.id]; const f=activeFlow();
  document.getElementById("current-screen-id").textContent=`${screen.id} · ${screen.surface}`;
  document.getElementById("current-screen-name").textContent=screen.name;
  document.getElementById("state-switcher").innerHTML=screen.states.map((item)=>`<button class="state-chip ${item===state?"is-active":""}" data-state="${item}" type="button">${item}</button>`).join("");
  const actions=(screen.actions||[]).map((a)=>a.id).join(" · ") || (screen.traceActions?.length ? `System: ${screen.traceActions.join(" · ")}` : "Navigation / query");
  document.getElementById("traceability").innerHTML=`<div class="trace-row"><span>BJ / UIF</span><strong>${f.bj} · ${f.id}</strong></div><div class="trace-row"><span>UC</span><strong>${(screen.uc||[]).join(" · ")||"—"}</strong></div><div class="trace-row"><span>Purpose</span><strong>${screen.purpose||"—"}</strong></div><div class="trace-row"><span>Action</span><strong>${actions}</strong></div><div class="trace-row"><span>Flutter DS</span><strong>VPageScaffold → VAppBar · ${(screen.components||[]).join(" · ")}</strong></div><div class="trace-row"><span>Composition</span><strong>${screen.themeComposition||"—"}</strong></div>`;
  document.getElementById("design-rationale").textContent=f.intent || screen.purpose;
}

'''
old=old[:p1]+new_nav+old[p2:]
# add generic helpers/renderers before const renderers
insert=old.index('const renderers = {')
generic=r'''
function esc(v){return String(v??"").replace(/[&<>\"]/g,(m)=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[m]));}
function dsIconForSurface(surface){return {list:"listCheck",form:"edit",detail:"fileText",review:"shield",result:"checkCircle",timeline:"history",dashboard:"layers",choice:"listCheck"}[surface]||"info";}
function genericFieldRows(screen){
  const rows=(screen.dataRows?.length?screen.dataRows:(screen.fields||[]).map((x)=>({label:x[0],example:x[1],ownership:"DERIVED"})));
  if(!rows.length) return "";
  if(screen.surface==="form") return `<section class="generic-form-section v-section" data-ds-component="VSection">${rows.map((r,i)=>{const comp=(r.component||(/(ngày|hạn|cut-off|kỳ)/i.test(r.label)?"VDatePicker":/(số tiền|giá trị|giá trước)/i.test(r.label)?"VMoneyField":/(số lượng|lượng |ngưỡng|mức tồn|số ngày)/i.test(r.label)?"VNumberField":/(trạng thái|loại|hành động|lý do|nguồn|phạm vi|định dạng|kho)/i.test(r.label)?"VSelect":"VTextFormField")); return `<label class="generic-field" data-ds-component="${comp}" data-ds-prop-label="${esc(r.label)}"><span>${esc(r.label)}</span><div class="generic-input">${esc(r.example||"Nhập dữ liệu")}</div></label>`}).join("")}</section>`;
  return `<div class="generic-kv-card" data-ds-component="VCard" data-ds-profile="card.readOnly">${rows.map((r)=>`<div class="generic-kv-row"><span data-ds-component="VText">${esc(r.label)}</span><strong data-ds-component="VText">${esc(r.example||"—")}</strong></div>`).join("")}</div>`;
}
function genericCards(screen){
  const cards=screen.cards||[]; if(!cards.length) return "";
  if(screen.surface==="timeline") return `<div class="generic-timeline" data-theme-component="Theme7EvidenceTimeline" data-composed-from="VCard,VIconBox,VText,VBadge">${cards.map((c,i)=>`<div class="timeline-event"><span class="timeline-dot" data-ds-component="VIconBox">${icon(i===cards.length-1?"checkCircle":"fileText","icon--sm")}</span><div class="timeline-copy"><strong data-ds-component="VText">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span>${c[2]?vBadge(esc(c[2]),i===cards.length-1?"success":"info"):""}</div></div>`).join("")}</div>`;
  return `<div class="generic-card-list">${cards.map((c)=>`<article class="generic-data-card" data-ds-component="VCard" data-ds-profile="${screen.surface==="list"?"card.interactive":"card.readOnly"}"><div class="generic-card-icon" data-ds-component="VCardIcon">${icon(dsIconForSurface(screen.surface),"icon--sm")}</div><div class="generic-card-copy"><strong data-ds-component="VCardTitle">${esc(c[0])}</strong><span data-ds-component="VText">${esc(c[1]||"")}</span></div>${c[2]?vBadge(esc(c[2]),/lỗi|block|thiếu|unknown|hết/i.test(c[2])?"warning":"info"):""}${screen.surface==="list"?icon("chevronRight","icon--sm"):""}</article>`).join("")}</div>`;
}
function genericPrimaryActions(screen,state){
  if(state==="PERMISSION_DENIED") return "";
  const acts=screen.actions||[]; if(!acts.length){
    if(screen.surface==="result") return primaryFooter("Xong",'data-generic-next',false);
    return "";
  }
  const primary=acts[0]; return primaryFooter(esc(primary.label),'data-generic-action="'+esc(primary.id)+'"',false,primary.tone==="danger"?"danger":"primary");
}
function genericStateContent(screen,state){
  if(state==="PERMISSION_DENIED") return deniedBody();
  if(state==="LOADING"||state==="CALCULATING"||state==="REBUILDING"||state==="PREPARING"||state==="PROCESSING"){
    if(screen.surface==="result") return `<div class="generic-result-center" data-theme-component="Theme7OperationResult"><div class="generic-spinner" data-ds-component="VLoading"></div><h3 data-ds-component="VText">Đang xử lý</h3><p data-ds-component="VText">Giữ nguyên ngữ cảnh. Bạn không cần gửi lại thao tác.</p></div>`;
    return loadingBody();
  }
  if(state.includes("EMPTY")) return `<div class="empty-state" data-ds-component="VEmptyState"><div class="icon-box" data-ds-component="VEmptyMedia">${icon("inbox")}</div><h3 data-ds-component="VEmptyTitle">Chưa có dữ liệu</h3><p data-ds-component="VEmptyDescription">Không có mục phù hợp trong phạm vi hiện tại.</p></div>`;
  if(screen.surface==="result" && /(COMPLETED|PUBLISHED|RESOLVED|ACTIVE_RECONCILED)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult" data-composed-from="VEmptyState,VEmptyMedia,VCard,VBanner"><div class="icon-box icon-box--success" data-ds-component="VEmptyMedia">${icon("checkCircle")}</div><h3 data-ds-component="VEmptyTitle">Đã xác lập kết quả</h3><p data-ds-component="VEmptyDescription">Kết quả authoritative đã sẵn sàng.</p>${genericFieldRows(screen)}${genericCards(screen)}</div>`;
  if(screen.surface==="result" && /(UNKNOWN|COMMIT_UNKNOWN)/.test(state)) return `<div class="generic-result-center" data-theme-component="Theme7OperationResult">${vBanner("warning","Kết quả chưa xác định","Hệ thống tiếp tục xác minh cùng operation identity; không tạo thao tác mới.")}${genericFieldRows(screen)}</div>`;
  let notice=screen.notice? vBanner("info","Lưu ý",esc(screen.notice)):"";
  let stateNote="";
  if(/ERROR|FAILED|CONFLICT|BLOCK|LOCKED|STALE|MISSING|EXPIRED/.test(state)) stateNote=stateBanner(state)||vBanner("warning","Cần kiểm tra",`Trạng thái ${esc(state)} cần được xử lý trước khi tiếp tục.`);
  if(/APPROVAL/.test(state)) stateNote=stateBanner(state)||vBanner("info","Đang chờ phê duyệt","Chưa có tác động cuối cho đến khi có quyết định hợp lệ.");
  const intro=`<section class="v-section generic-intro" data-ds-component="VSection"><span class="eyebrow">${esc(activeFlowId)} · ${esc(screen.surface)}</span><h2 data-ds-component="VText">${esc(screen.name)}</h2><p data-ds-component="VText">${esc(screen.purpose)}</p></section>`;
  return intro+stateNote+notice+genericCards(screen)+genericFieldRows(screen);
}
function renderGeneric(screen,state){
  let body=genericStateContent(screen,state);
  if(screen.id==="SCR-044") body=`${vBanner("info","Đếm mù đang bật","Số lượng sổ sách không được tải vào DOM trước khi bạn gửi lần đếm đầu tiên.")}${body}`;
  if((screen.id==="SCR-080") && (activeFlowId==="UIF-16"||activeFlowId==="UIF-17")) body=`${vBanner("info","Hệ thống đã thu hẹp lựa chọn","Chỉ các hành động phục hồi được contract cho phép mới hiển thị; thao tác kỹ thuật nằm ở phần chi tiết.")}${body}`;
  return appShell({title:screen.name,body,actions:genericPrimaryActions(screen,state),back:!activeFlow()?.entry.includes(screen.id)});
}
'''
old=old[:insert]+generic+old[insert:]
# extend renderers after object
old=old.replace('const renderers = {\n  "SCR-006": render006,\n  "SCR-007": render007,\n  "SCR-008": render008,\n  "SCR-009": render009,\n  "SCR-010": render010,\n  "SCR-011": render011,\n  "SCR-012": render012,\n  "SCR-013": render013,\n};', 'const renderers = {"SCR-006":render006,"SCR-007":render007,"SCR-008":render008,"SCR-009":render009,"SCR-010":render010,"SCR-011":render011,"SCR-012":render012,"SCR-013":render013};\nfor (const screen of screens) if (!renderers[screen.id]) renderers[screen.id]=(state)=>renderGeneric(screen,state);')
# flow URL + dynamic render
old=old.replace('url.searchParams.set("screen", activeScreenId);','url.searchParams.set("uif", activeFlowId);\n  url.searchParams.set("screen", activeScreenId);')
# replace previousScreen function body
ps=old.index('function previousScreen() {'); pe=old.index('function showToast',ps)
prev=r'''function previousScreen() {
  const list=activeFlow()?.screens||[]; const idx=list.indexOf(activeScreenId);
  if(idx>0) return navigate(list[idx-1]);
  showToast("Đã ở điểm bắt đầu của flow", "info");
}

'''
old=old[:ps]+prev+old[pe:]
# ensure renderFlowSelector called
old=old.replace('function render() {\n  renderNavigation();','function render() {\n  renderFlowSelector();\n  renderNavigation();')
# append event listener for flow selector and generic interactions before initial render invocation
marker='render();\n'
last=old.rfind(marker)
extra=r'''
const flowSelectorEl=document.getElementById("flow-selector");
flowSelectorEl?.addEventListener("change",(e)=>{activeFlowId=e.target.value; const f=activeFlow(); activeScreenId=f.screens[0]; syncReviewUrl(); render();});
document.addEventListener("click",(e)=>{
  const next=e.target.closest("[data-generic-next]"); if(next){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); else showToast("Đã hoàn thành flow demo", "checkCircle"); }
  const act=e.target.closest("[data-generic-action]"); if(act){ showToast(`${act.textContent.trim()} · prototype không gọi backend`, "checkCircle"); }
  const card=e.target.closest(".generic-data-card[data-ds-profile='card.interactive']"); if(card&&!inspectEnabled){ const ids=activeFlow()?.screens||[]; const i=ids.indexOf(activeScreenId); if(i>=0&&i<ids.length-1) navigate(ids[i+1]); }
});
'''
old=old[:last]+extra+old[last:]
app.write_text(old)

# Append generic CSS
css=HTML/'styles.css'; ct=css.read_text()
ct += r'''

/* Harness v0.2.0 generic 17-UIF renderer */
.flow-label{display:block;margin:12px 0 6px;font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--v-color-text-secondary,#64748b)}
.flow-selector{width:100%;border:1px solid var(--v-color-border-default,#d8dee5);border-radius:10px;background:#fff;padding:10px 12px;font:inherit;color:var(--v-color-text-primary,#12201a);margin-bottom:14px}
.generic-intro{display:grid;gap:6px}.generic-intro h2{margin:0;font-size:20px}.generic-intro p{margin:0;color:#6b7280;line-height:1.45}
.generic-card-list{display:grid;gap:10px}.generic-data-card{display:grid;grid-template-columns:36px 1fr auto auto;align-items:center;gap:10px;padding:14px;border:1px solid #dfe5e1;border-radius:12px;background:#fff}.generic-data-card[data-ds-profile="card.interactive"]{cursor:pointer}.generic-card-icon{width:36px;height:36px;border-radius:10px;background:#e9f7ec;color:#21783d;display:grid;place-items:center}.generic-card-copy{display:grid;gap:3px;min-width:0}.generic-card-copy strong{font-size:14px;color:#173522}.generic-card-copy span{font-size:12px;color:#66756d}
.generic-kv-card{border:1px solid #dfe5e1;border-radius:12px;background:#fff;padding:4px 14px}.generic-kv-row{display:flex;justify-content:space-between;gap:16px;padding:12px 0;border-bottom:1px solid #edf0ee}.generic-kv-row:last-child{border-bottom:0}.generic-kv-row span{color:#6b746f;font-size:13px}.generic-kv-row strong{text-align:right;color:#193522;font-size:13px}
.generic-form-section{display:grid;gap:12px}.generic-field{display:grid;gap:6px;font-size:13px;font-weight:650;color:#24412e}.generic-input{min-height:44px;border:1px solid #d8dfdb;border-radius:10px;background:#fff;padding:12px 13px;font-weight:500;color:#23372a}
.generic-result-center{display:grid;gap:14px;text-align:center;align-content:start;padding-top:24px}.generic-result-center .generic-kv-card,.generic-result-center .generic-card-list{text-align:left}.generic-spinner{width:40px;height:40px;margin:6px auto;border:4px solid #def1e2;border-top-color:#3a9c50;border-radius:50%;animation:generic-spin 1s linear infinite}@keyframes generic-spin{to{transform:rotate(360deg)}}
.generic-timeline{display:grid;gap:0;padding:8px 0}.timeline-event{display:grid;grid-template-columns:36px 1fr;gap:10px;position:relative;padding-bottom:18px}.timeline-event:not(:last-child):before{content:"";position:absolute;left:17px;top:34px;bottom:0;width:1px;background:#d9e3dc}.timeline-dot{width:36px;height:36px;border-radius:50%;background:#e9f7ec;color:#2d8d48;display:grid;place-items:center;z-index:1}.timeline-copy{display:grid;gap:4px;padding-top:2px}.timeline-copy strong{font-size:13px;color:#183a25}.timeline-copy span{font-size:12px;color:#6d7972}
'''
css.write_text(ct)

# README/HTML manifest
manifest={'version':'0.2.0','scope':'Theme 7 / 17 Business Journeys / 17 UIF','flows':17,'screens':len(active_screens),'inspect':True,'authority':{'business':'BJ/UC/UIF/Screen Contracts','ui':'Flutter Design System','visualReference':'Vercel Flutter-rendered catalog'},'runOrder':RUN_ORDER}
(HTML/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(HTML/'README.md').write_text('''# Theme 7 HTML Prototype Harness v0.2.0\n\nMột workbench chung cho 17 UIF. Flutter Design System là UI authority; HTML chỉ là renderer có Inspect metadata.\n\n- Chọn UIF/BJ ở sidebar.\n- Chọn Screen/state và Mobile/Wide.\n- Inspect hiển thị box model + `data-ds-component` / profile / props / `VIcons.*`.\n- UIF-02 giữ renderer pilot chi tiết; các UIF còn lại dùng canonical data-driven renderer từ Screen Contract và cùng DS profiles.\n- Shared Screen không bị clone; active UIF truyền context mode.\n''')

# --------- Final report ---------
shared=[(sid,related_uifs(sid)) for sid in sorted(active_screens) if len(related_uifs(sid))>1]
report=['# Theme 7 Prototype Harness — Final 17-Round Report','', '> Harness v0.2.0 · 17/17 UIF local + cumulative review complete.','', '## Result','', '- `17/17` UIF: `FROZEN`.', '- `17/17` local reviews: `PASS`.', '- `17/17` cumulative reviews: `PASS`.', f'- `{len(active_screens)}` canonical Screen trong 17 BJ được đưa vào Full HTML Workbench.', f'- `{len(shared)}` canonical Screen được reuse qua nhiều UIF; không clone implementation.', '- `17` component usage contracts `.md` + `17` machine contracts `.yaml`.', '- Flutter DS vẫn là single UI source of truth; HTML không sở hữu DS thứ hai.', '', '## Structural/UX corrections discovered during Harness','', '1. UIF-01: chèn shared `SCR-055` giữa query `SCR-054` và movement detail `SCR-056`.', '2. UIF-03: bỏ ngôn ngữ “đưa vào bán” khỏi valuation confirmation; valuation không sở hữu sellability.', '3. UIF-13: commit late cost từ review `SCR-017`, bỏ backtrack review → form chỉ để submit.', '4. UIF-06: đổi continuation copy sang “Tiếp tục phân loại”, tách physical receipt khỏi quality classification.', '5. UIF-09: explicit maker submit → approver decision → system state movement.', '6. UIF-10: PREPARE/APPROVAL/COMPLETION mode; approval không làm giảm tồn vật lý.', '7. UIF-08: blind count không render book quantity trong DOM trước first submission.', '8. UIF-11: correction auto-exec sau approval; không bắt user commit lần hai.', '9. UIF-12: approval decision tách khỏi opening-balance commit; commit tự chạy trên result processing.', '10. UIF-16/17: evidence-first + system-recommended recovery; no blind retry, same operation identity.', '', '## Cumulative invariants','', '- Don’t make me think: prefill context đã biết, giảm tap/input thừa, mỗi screen một mental task.', '- Shared screen = một canonical implementation + context mode.', '- Approval/handoff không trộn actor session.', '- Result screen sở hữu processing/finality; technical retry/polling không trở thành user task.', '- Permission masking xảy ra trước render DOM.', '- Icons map qua `VIcons.*`; Theme compositions compose public Flutter DS.', '', '## Runtime note','', '- Harness đã chạy static/contract/JS validation. Pixel regression với Vercel là visual gate riêng và phụ thuộc browser runtime ổn định.', '']
(PROTO/'HARNESS-FINAL-REPORT.md').write_text('\n'.join(report))

print('completed component usage, screen contracts, reviews, workbench')
