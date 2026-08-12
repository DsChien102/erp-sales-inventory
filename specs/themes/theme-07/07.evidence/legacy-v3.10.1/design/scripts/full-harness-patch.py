from pathlib import Path
import json, re, yaml

ROOT=Path(__file__).resolve().parents[2]
PROTO=ROOT/'prototype'
CON=PROTO/'contracts'
FLOWS=PROTO/'flows'

# ---------- Action registry corrections ----------
ap=CON/'action-registry.json'
ad=json.loads(ap.read_text())
actions=ad['actions']
by={a['id']:a for a in actions}

# UI label must not imply sellability is a user decision in BJ-03.
a=by['ACT-03-CONFIRM-COST']
a['label']='Xác nhận giá trị'
a['effect']='Ghi value movement/provenance và gỡ trạng thái chờ giá trị cho đúng scope; khả dụng chỉ thay đổi theo trạng thái hiện hành đủ điều kiện'
a['screen_ids']=['SCR-017']
a['harness_note']='UIF-03 review owns the confirmation. The result screen is trace-only.'

# Late landed cost is confirmed from the review surface to avoid review -> form -> submit backtracking.
a=by['ACT-03-RECORD-LATE-COST']
a['screen_ids']=['SCR-017']
a['harness_note']='UIF-13 review mode owns final confirmation; SCR-018 is data-entry only.'

# Receiving execution is system-owned after submit/approval; result screen owns processing/result only.
a=by['ACT-02-RECEIVE']
a['interaction_owner']='SYSTEM_AFTER_ROUTING'
a['harness_note']='No user CTA on SCR-012.'

# Shared operation workflow actions already supported by source BCs but missing as explicit UI actions in UIF-09/10/12.
common=[
    {
      'id':'ACT-COMMON-SAVE-DRAFT','label':'Lưu nháp yêu cầu','bc':'BC-IO-16','api':'API-C-25',
      'permission':'Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại',
      'confirmation':'Không','effect':'Lưu operation draft/version; chưa tạo movement',
      'screen_ids':['SCR-038','SCR-040'],'evidence_level':'HARNESS_DERIVED_FROM_UC_BC',
      'harness_note':'Shared UI action instance for UCs that explicitly reference BC-IO-16.'
    },
    {
      'id':'ACT-COMMON-SUBMIT','label':'Gửi xử lý','bc':'BC-IC-07','api':'API-C-26',
      'permission':'Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại',
      'confirmation':'Có','effect':'Khóa payload/version và định tuyến approval/ready theo policy; chưa tự tạo inventory movement',
      'screen_ids':['SCR-038','SCR-040'],'evidence_level':'HARNESS_DERIVED_FROM_UC_BC',
      'harness_note':'Shared UI action instance for UCs that explicitly reference BC-IC-07.'
    },
    {
      'id':'ACT-COMMON-DECIDE','label':'Quyết định phê duyệt','bc':'BC-IC-06','api':'API-C-19',
      'permission':'Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại',
      'confirmation':'Có','effect':'Ghi quyết định duyệt/từ chối; chưa tự tạo inventory movement/value',
      'screen_ids':['SCR-038','SCR-040','SCR-070'],'evidence_level':'HARNESS_DERIVED_FROM_UC_BC',
      'harness_note':'Shared approval decision action used only where source UC explicitly references BC-IC-06.'
    },
]
for item in common:
    if item['id'] in by:
        by[item['id']].update(item)
    else:
        actions.append(item); by[item['id']]=item
ad['version']='4.3.2-harness.1'
ap.write_text(json.dumps(ad,ensure_ascii=False,indent=2)+'\n')

# ---------- Screen registry corrections ----------
sp=CON/'screen-registry.json'
sd=json.loads(sp.read_text())
sby={s['id']:s for s in sd['screens']}

def set_actions(sid, visible=None, trace=None, status=None, disposition=None):
    dr=sby[sid].setdefault('design_readiness',{})
    if visible is not None: dr['visible_action_ids']=visible
    if trace is not None: dr['trace_only_action_ids']=trace
    if status: dr['status']=status
    if disposition: dr['structural_disposition']=disposition

set_actions('SCR-012', [], ['ACT-02-RECEIVE'])
# shared review owns a different action per mode.
set_actions('SCR-017', ['ACT-03-CONFIRM-COST','ACT-03-RECORD-LATE-COST'], [])
set_actions('SCR-018', [], ['ACT-03-RECORD-LATE-COST'])
# state change / disposal use shared draft-submit-approval controls before their inventory mutation.
set_actions('SCR-038', ['ACT-COMMON-SAVE-DRAFT','ACT-COMMON-SUBMIT','ACT-COMMON-DECIDE'], ['ACT-08-STATE'])
set_actions('SCR-040', ['ACT-COMMON-SAVE-DRAFT','ACT-COMMON-SUBMIT','ACT-COMMON-DECIDE','ACT-08-DISPOSE'], [])
# correction selection is one canonical screen with mutually-exclusive context modes; execution becomes result-owned/system.
set_actions('SCR-052', ['ACT-10-CANCEL'], ['ACT-10-CORRECT'], disposition='KEEP_WITH_CONTEXT_MODE')
set_actions('SCR-053', [], ['ACT-10-CORRECT'])
# opening-balance approver only decides; commit is automatic on result processing after approval.
set_actions('SCR-070', ['ACT-COMMON-DECIDE'], ['ACT-13-COMMIT'])
set_actions('SCR-071', [], ['ACT-13-COMMIT'])

# Clarify shared review purpose without changing business semantics.
sby['SCR-017']['purpose']='Rà soát phạm vi, phép tính/phân bổ và provenance trước khi xác nhận giá trị hoặc chi phí mua bổ sung.'
sby['SCR-019']['purpose']='Hiển thị kết quả authoritative của xác nhận giá trị hoặc ghi chi phí bổ sung; không suy diễn sellability ngoài trạng thái hiện hành.'
sd['version']='4.3.2-harness.1'
sp.write_text(json.dumps(sd,ensure_ascii=False,indent=2)+'\n')

# Mirror important fields in screen-catalog when present.
cp=CON/'screen-catalog.json'
if cp.exists():
    cd=json.loads(cp.read_text())
    screens=cd.get('screens',[])
    cby={s.get('id'):s for s in screens}
    for sid in ['SCR-012','SCR-017','SCR-018','SCR-038','SCR-040','SCR-052','SCR-053','SCR-070','SCR-071']:
        if sid in cby and sid in sby:
            cby[sid]['purpose']=sby[sid]['purpose']
            dr=sby[sid].get('design_readiness',{})
            cby[sid].setdefault('design_readiness',{}).update({
                'visible_action_ids':dr.get('visible_action_ids',[]),
                'trace_only_action_ids':dr.get('trace_only_action_ids',[]),
                'structural_disposition':dr.get('structural_disposition')
            })
    cd['version']='4.3.2-harness.1'
    cp.write_text(json.dumps(cd,ensure_ascii=False,indent=2)+'\n')

# ---------- Flow patch helper ----------
def patch_flow(fid, diagram, transitions, acceptance_actions=None, note=None):
    # fid like UIF-13
    num=fid.split('-')[1]
    p=next(FLOWS.glob(f'{fid}-BJ-*.md'))
    text=p.read_text()
    # replace section 2 body until section 3
    sec2=f"## 2. Sơ đồ UI flow\n\n```mermaid\n{diagram.strip()}\n```\n\n"
    text=re.sub(r'## 2\. Sơ đồ UI flow\n.*?(?=## 3\. Transition Contract)',sec2,text,flags=re.S)
    # build transition table
    lines=[
        '## 3. Transition Contract','',
        '`NAVIGATION` không tạo tác động nghiệp vụ; `QUERY` chỉ đọc/tạo bản xuất; `MUTATION` bắt buộc có Action ID; `SYSTEM` là định tuyến từ kết quả authoritative; `HANDOFF` chuyển quyền xử lý nhưng không tự xác lập finality.','',
        '| Transition | Từ | Trigger/điều kiện | Đến | Loại | Trace |',
        '|---|---|---|---|---|---|'
    ]
    for t in transitions:
        lines.append('| `{id}` | {src} | {trigger} | {dst} | `{kind}` | {trace} |'.format(**t))
    if note:
        lines += ['', f'> **Harness UX patch:** {note}']
    lines += ['','']
    sec3='\n'.join(lines)
    text=re.sub(r'## 3\. Transition Contract\n.*?(?=## 4\. Bao phủ UC và Screen)',sec3,text,flags=re.S)
    if acceptance_actions is not None:
        # Replace action-count bullet in section 6.
        ids=', '.join(f'`{x}`' for x in acceptance_actions)
        text=re.sub(r'- \d+ Action ID được tham chiếu: .*?\.',f'- {len(acceptance_actions)} Action ID được tham chiếu: {ids}.',text)
    # Patch header prototype/evidence line lightly.
    text=text.replace('**Bằng chứng:** `STATIC_VALIDATED_DERIVED`','**Bằng chứng:** `HARNESS_LOCAL_AND_CUMULATIVE_REVIEWED`')
    text=text.replace('| Prototype | `NOT_RENDERED` |','| Prototype | `HTML_HARNESS_RENDERED` |')
    p.write_text(text)
    return p

L=lambda sid:f'[`{sid}`](../../prototype/contracts/screens/{sid}.md)'
UC=lambda u,path:f'[`{u}`](../../srs/05-use-cases/{path})'
ACT=lambda a:f'[`{a}`](../../prototype/contracts/action-registry.json)'

# UIF-13: final mutation moves to review, eliminating review -> form -> submit backtracking.
patch_flow('UIF-13', '''flowchart TD
    START(["Bắt đầu"])
    S014["SCR-014 — Việc chờ xác nhận giá"]
    S015["SCR-015 — Bằng chứng và receipt"]
    S018["SCR-018 — Ghi chi phí mua bổ sung"]
    S017["SCR-017 — Rà soát xác nhận giá"]
    S019["SCR-019 — Kết quả định giá receipt"]
    END(["Kết thúc"])
    H_BJ17["Handoff BJ-17"]
    START -->|"Có bằng chứng chi phí mua bổ sung"| S014
    S014 -->|"Chọn receipt và dòng liên quan"| S015
    S015 -->|"Nguồn và phiên bản hợp lệ"| S018
    S018 -->|"Phân bổ chưa hợp lệ"| S018
    S018 -->|"Mở bản rà soát"| S017
    S017 -->|"Cần sửa căn cứ hoặc phân bổ"| S018
    S017 -->|"Ghi chi phí mua bổ sung"| S019
    S019 -->|"COMPLETED"| END
    S019 -->|"REJECTED; không có tác động"| S018
    S019 -->|"UNKNOWN"| H_BJ17''', [
    {'id':'UIF-13-T01','src':'`Bắt đầu`','trigger':'Có bằng chứng chi phí mua bổ sung','dst':L('SCR-014'),'kind':'NAVIGATION','trace':UC('UC-13-01','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-01-xac-dinh-nguon-va-pham-vi.md')},
    {'id':'UIF-13-T02','src':L('SCR-014'),'trigger':'Chọn receipt và dòng liên quan','dst':L('SCR-015'),'kind':'NAVIGATION','trace':UC('UC-13-01','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-01-xac-dinh-nguon-va-pham-vi.md')},
    {'id':'UIF-13-T03','src':L('SCR-015'),'trigger':'Nguồn và phiên bản hợp lệ','dst':L('SCR-018'),'kind':'NAVIGATION','trace':UC('UC-13-02','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-02-tinh-va-phan-bo-chi-phi.md')},
    {'id':'UIF-13-T04','src':L('SCR-018'),'trigger':'Phân bổ chưa hợp lệ','dst':L('SCR-018'),'kind':'SYSTEM','trace':UC('UC-13-02','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-02-tinh-va-phan-bo-chi-phi.md')},
    {'id':'UIF-13-T05','src':L('SCR-018'),'trigger':'Mở bản rà soát','dst':L('SCR-017'),'kind':'NAVIGATION','trace':UC('UC-13-02','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-02-tinh-va-phan-bo-chi-phi.md')},
    {'id':'UIF-13-T06','src':L('SCR-017'),'trigger':'Cần sửa căn cứ hoặc phân bổ','dst':L('SCR-018'),'kind':'NAVIGATION','trace':UC('UC-13-02','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-02-tinh-va-phan-bo-chi-phi.md')},
    {'id':'UIF-13-T07','src':L('SCR-017'),'trigger':'Ghi chi phí mua bổ sung','dst':L('SCR-019'),'kind':'MUTATION','trace':UC('UC-13-03','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-03-xac-nhan-ghi-nhan-chi-phi.md')+'; '+ACT('ACT-03-RECORD-LATE-COST')},
    {'id':'UIF-13-T09','src':L('SCR-019'),'trigger':'COMPLETED','dst':'`Kết thúc`','kind':'TERMINAL','trace':UC('UC-13-03','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-03-xac-nhan-ghi-nhan-chi-phi.md')},
    {'id':'UIF-13-T10','src':L('SCR-019'),'trigger':'REJECTED; không có tác động','dst':L('SCR-018'),'kind':'SYSTEM','trace':UC('UC-13-03','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-03-xac-nhan-ghi-nhan-chi-phi.md')},
    {'id':'UIF-13-T11','src':L('SCR-019'),'trigger':'UNKNOWN','dst':'`Handoff BJ-17`','kind':'HANDOFF','trace':UC('UC-13-03','BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-03-xac-nhan-ghi-nhan-chi-phi.md')},
], ['ACT-03-RECORD-LATE-COST'], 'Final mutation is owned by the review surface. The user never returns to the entry form only to press a second submit button.')

# UIF-11: approved correction auto-executes on the processing/result surface; no return to strategy selection.
patch_flow('UIF-11', '''flowchart TD
    START(["Bắt đầu"])
    S048["SCR-048 — Danh sách operation"]
    S049["SCR-049 — Chi tiết operation"]
    S052["SCR-052 — Hủy hoặc sửa sai"]
    S050["SCR-050 — Nháp và gửi operation"]
    S051["SCR-051 — Quyết định phê duyệt"]
    S053["SCR-053 — Kết quả kiểm soát operation"]
    END(["Kết thúc"])
    H_BJ17["Handoff BJ-17"]
    START -->|"Có yêu cầu hủy hoặc sửa sai"| S048
    S048 -->|"Chọn operation"| S049
    S049 -->|"Nháp, chờ duyệt hoặc sẵn sàng"| S052
    S052 -->|"Hủy operation chưa thực thi"| S053
    S049 -->|"Đang xử lý hoặc UNKNOWN"| H_BJ17
    S049 -->|"Operation đã hoàn tất"| S052
    S052 -->|"Chọn delta, reversal hoặc replacement"| S050
    S050 -->|"Lưu nháp correction"| S050
    S050 -->|"Gửi correction"| S051
    S051 -->|"Từ chối"| S053
    S051 -->|"Duyệt"| S053
    S053 -->|"Đã duyệt; hệ thống ghi correction chain"| S053
    S053 -->|"CANCELLED, COMPLETED hoặc REJECTED"| END
    S053 -->|"UNKNOWN"| H_BJ17''', [
    {'id':'UIF-11-T01','src':'`Bắt đầu`','trigger':'Có yêu cầu hủy hoặc sửa sai','dst':L('SCR-048'),'kind':'NAVIGATION','trace':UC('UC-11-01','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-01-xac-dinh-duong-xu-ly.md')},
    {'id':'UIF-11-T02','src':L('SCR-048'),'trigger':'Chọn operation','dst':L('SCR-049'),'kind':'NAVIGATION','trace':UC('UC-11-01','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-01-xac-dinh-duong-xu-ly.md')},
    {'id':'UIF-11-T03','src':L('SCR-049'),'trigger':'Nháp, chờ duyệt hoặc sẵn sàng','dst':L('SCR-052'),'kind':'NAVIGATION','trace':UC('UC-11-02','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-02-huy-operation-chua-thuc-thi.md')},
    {'id':'UIF-11-T04','src':L('SCR-052'),'trigger':'Hủy operation chưa thực thi','dst':L('SCR-053'),'kind':'MUTATION','trace':UC('UC-11-02','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-02-huy-operation-chua-thuc-thi.md')+'; '+ACT('ACT-10-CANCEL')},
    {'id':'UIF-11-T05','src':L('SCR-049'),'trigger':'Đang xử lý hoặc UNKNOWN','dst':'`Handoff BJ-17`','kind':'HANDOFF','trace':UC('UC-11-01','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-01-xac-dinh-duong-xu-ly.md')},
    {'id':'UIF-11-T06','src':L('SCR-049'),'trigger':'Operation đã hoàn tất','dst':L('SCR-052'),'kind':'NAVIGATION','trace':UC('UC-11-03','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-03-chuan-bi-phuong-an-correction.md')},
    {'id':'UIF-11-T07','src':L('SCR-052'),'trigger':'Chọn delta, reversal hoặc replacement','dst':L('SCR-050'),'kind':'NAVIGATION','trace':UC('UC-11-03','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-03-chuan-bi-phuong-an-correction.md')},
    {'id':'UIF-11-T08','src':L('SCR-050'),'trigger':'Lưu nháp correction; chưa ghi Nhật ký biến động','dst':L('SCR-050'),'kind':'MUTATION','trace':UC('UC-11-03','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-03-chuan-bi-phuong-an-correction.md')+'; '+ACT('ACT-10-SAVE-DRAFT')},
    {'id':'UIF-11-T09','src':L('SCR-050'),'trigger':'Gửi correction','dst':L('SCR-051'),'kind':'MUTATION','trace':UC('UC-11-04','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-04-phe-duyet-correction.md')+'; '+ACT('ACT-10-SUBMIT')},
    {'id':'UIF-11-T10','src':L('SCR-051'),'trigger':'Từ chối','dst':L('SCR-053'),'kind':'MUTATION','trace':UC('UC-11-04','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-04-phe-duyet-correction.md')+'; '+ACT('ACT-10-DECIDE')},
    {'id':'UIF-11-T11','src':L('SCR-051'),'trigger':'Duyệt','dst':L('SCR-053'),'kind':'MUTATION','trace':UC('UC-11-04','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-04-phe-duyet-correction.md')+'; '+ACT('ACT-10-DECIDE')},
    {'id':'UIF-11-T12','src':L('SCR-053'),'trigger':'Đã duyệt; hệ thống ghi correction chain','dst':L('SCR-053'),'kind':'MUTATION','trace':UC('UC-11-05','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-05-ghi-correction-chain.md')+'; '+ACT('ACT-10-CORRECT')},
    {'id':'UIF-11-T13','src':L('SCR-053'),'trigger':'CANCELLED, COMPLETED hoặc REJECTED','dst':'`Kết thúc`','kind':'TERMINAL','trace':UC('UC-11-02','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-02-huy-operation-chua-thuc-thi.md')+'; '+UC('UC-11-04','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-04-phe-duyet-correction.md')+'; '+UC('UC-11-05','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-05-ghi-correction-chain.md')},
    {'id':'UIF-11-T14','src':L('SCR-053'),'trigger':'UNKNOWN','dst':'`Handoff BJ-17`','kind':'HANDOFF','trace':UC('UC-11-05','BJ-11-huy-va-sua-sai-nghiep-vu-kho/UC-11-05-ghi-correction-chain.md')},
], ['ACT-10-CANCEL','ACT-10-SAVE-DRAFT','ACT-10-SUBMIT','ACT-10-DECIDE','ACT-10-CORRECT'], 'After approval, correction execution is automatic on the same operation identity; the user is not sent back to a strategy screen to press another commit button.')

# UIF-12: approval decision and opening-balance commit are separate BCs; commit becomes automatic processing after approval.
patch_flow('UIF-12', '''flowchart TD
    START(["Bắt đầu"])
    S066["SCR-066 — Các batch số dư đầu kỳ"]
    S067["SCR-067 — Nạp file và thiết lập cut-off"]
    S068["SCR-068 — Kiểm tra dữ liệu"]
    S069["SCR-069 — Rà soát và gửi duyệt"]
    S070["SCR-070 — Xác nhận kích hoạt"]
    S071["SCR-071 — Báo cáo kích hoạt"]
    END(["Kết thúc"])
    H_BJ17["Handoff BJ-17"]
    START -->|"Có dữ liệu đầu kỳ và số kiểm soát"| S066
    S066 -->|"Tạo hoặc mở batch"| S067
    S067 -->|"Nạp và kiểm tra batch"| S068
    S068 -->|"Batch không hợp lệ"| S067
    S068 -->|"Batch hợp lệ"| S069
    S069 -->|"Gửi duyệt batch"| S070
    S070 -->|"Từ chối"| END
    S070 -->|"Duyệt batch"| S071
    S071 -->|"Đã duyệt; hệ thống commit và kích hoạt"| S071
    S071 -->|"ACTIVE hoặc REJECTED"| END
    S071 -->|"UNKNOWN"| H_BJ17''', [
    {'id':'UIF-12-T01','src':'`Bắt đầu`','trigger':'Có dữ liệu đầu kỳ và số kiểm soát','dst':L('SCR-066'),'kind':'NAVIGATION','trace':UC('UC-12-01','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-01-nap-va-kiem-tra-batch-dau-ky.md')},
    {'id':'UIF-12-T02','src':L('SCR-066'),'trigger':'Tạo hoặc mở batch','dst':L('SCR-067'),'kind':'NAVIGATION','trace':UC('UC-12-01','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-01-nap-va-kiem-tra-batch-dau-ky.md')},
    {'id':'UIF-12-T03','src':L('SCR-067'),'trigger':'Nạp và kiểm tra batch; chưa ledger','dst':L('SCR-068'),'kind':'MUTATION','trace':UC('UC-12-01','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-01-nap-va-kiem-tra-batch-dau-ky.md')+'; '+ACT('ACT-13-PREPARE')},
    {'id':'UIF-12-T04','src':L('SCR-068'),'trigger':'Batch không hợp lệ','dst':L('SCR-067'),'kind':'SYSTEM','trace':UC('UC-12-01','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-01-nap-va-kiem-tra-batch-dau-ky.md')},
    {'id':'UIF-12-T05','src':L('SCR-068'),'trigger':'Batch hợp lệ','dst':L('SCR-069'),'kind':'NAVIGATION','trace':UC('UC-12-01','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-01-nap-va-kiem-tra-batch-dau-ky.md')},
    {'id':'UIF-12-T06','src':L('SCR-069'),'trigger':'Gửi duyệt batch','dst':L('SCR-070'),'kind':'MUTATION','trace':UC('UC-12-02','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-02-ra-soat-va-duyet-batch.md')+'; '+ACT('ACT-13-PREPARE')},
    {'id':'UIF-12-T07','src':L('SCR-070'),'trigger':'Từ chối; tồn kho chưa kích hoạt','dst':'`Kết thúc`','kind':'MUTATION','trace':UC('UC-12-02','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-02-ra-soat-va-duyet-batch.md')+'; '+ACT('ACT-COMMON-DECIDE')},
    {'id':'UIF-12-T08','src':L('SCR-070'),'trigger':'Duyệt batch','dst':L('SCR-071'),'kind':'MUTATION','trace':UC('UC-12-02','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-02-ra-soat-va-duyet-batch.md')+'; '+ACT('ACT-COMMON-DECIDE')},
    {'id':'UIF-12-T11','src':L('SCR-071'),'trigger':'Đã duyệt; hệ thống commit và kích hoạt','dst':L('SCR-071'),'kind':'MUTATION','trace':UC('UC-12-03','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-03-commit-va-kich-hoat-ton-kho.md')+'; '+ACT('ACT-13-COMMIT')},
    {'id':'UIF-12-T09','src':L('SCR-071'),'trigger':'ACTIVE hoặc REJECTED','dst':'`Kết thúc`','kind':'TERMINAL','trace':UC('UC-12-03','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-03-commit-va-kich-hoat-ton-kho.md')},
    {'id':'UIF-12-T10','src':L('SCR-071'),'trigger':'UNKNOWN','dst':'`Handoff BJ-17`','kind':'HANDOFF','trace':UC('UC-12-03','BJ-12-khoi-tao-so-du-ton-kho-dau-ky/UC-12-03-commit-va-kich-hoat-ton-kho.md')},
], ['ACT-13-PREPARE','ACT-COMMON-DECIDE','ACT-13-COMMIT'], 'Approval and authoritative opening-balance commit are separate behavioral contracts. Approver decides once; commit then runs automatically and SCR-071 owns processing/result.')

# UIF-09: make draft/submit/approval explicit and keep state movement system-owned after approval.
patch_flow('UIF-09', '''flowchart TD
    START(["Bắt đầu"])
    S036["SCR-036 — Hàng cần xử lý"]
    S037["SCR-037 — Chi tiết hàng và bằng chứng"]
    S038["SCR-038 — Chuyển trạng thái"]
    S041["SCR-041 — Kết quả xử lý"]
    S056["SCR-056 — Chi tiết movement"]
    END(["Kết thúc"])
    H_BJ17["Handoff BJ-17"]
    START -->|"Có căn cứ thay đổi trạng thái"| S036
    S036 -->|"Chọn hàng và phạm vi"| S037
    S037 -->|"Người dùng chuẩn bị thay đổi"| S038
    S038 -->|"Gửi xử lý; policy yêu cầu phê duyệt"| S038
    S038 -->|"Approver từ chối"| END
    S038 -->|"Gửi xử lý; không cần duyệt"| S041
    S038 -->|"Approver duyệt"| S041
    S041 -->|"Approval đã duyệt; hệ thống ghi state movement"| S041
    S037 -->|"Ngày nghiệp vụ xác định không hết hạn"| S041
    S037 -->|"Ngày nghiệp vụ xác định đã hết hạn"| S041
    S041 -->|"Mở biến động vừa ghi"| S056
    S041 -->|"Không thay đổi hoặc kết quả đã rõ"| END
    S056 -->|"Đã đủ dấu vết"| END
    S041 -->|"UNKNOWN"| H_BJ17''', [
    {'id':'UIF-09-T01','src':'`Bắt đầu`','trigger':'Có căn cứ thay đổi trạng thái','dst':L('SCR-036'),'kind':'NAVIGATION','trace':UC('UC-09-01','BJ-09-quan-ly-trang-thai-hang/UC-09-01-chuan-bi-thay-doi-trang-thai.md')+'; '+UC('UC-09-03','BJ-09-quan-ly-trang-thai-hang/UC-09-03-xac-dinh-hang-het-han.md')},
    {'id':'UIF-09-T02','src':L('SCR-036'),'trigger':'Chọn hàng và phạm vi','dst':L('SCR-037'),'kind':'NAVIGATION','trace':UC('UC-09-01','BJ-09-quan-ly-trang-thai-hang/UC-09-01-chuan-bi-thay-doi-trang-thai.md')+'; '+UC('UC-09-03','BJ-09-quan-ly-trang-thai-hang/UC-09-03-xac-dinh-hang-het-han.md')},
    {'id':'UIF-09-T03','src':L('SCR-037'),'trigger':'Người dùng chuẩn bị thay đổi','dst':L('SCR-038'),'kind':'NAVIGATION','trace':UC('UC-09-01','BJ-09-quan-ly-trang-thai-hang/UC-09-01-chuan-bi-thay-doi-trang-thai.md')},
    {'id':'UIF-09-T04','src':L('SCR-038'),'trigger':'Gửi xử lý; policy yêu cầu phê duyệt','dst':L('SCR-038'),'kind':'MUTATION','trace':UC('UC-09-01','BJ-09-quan-ly-trang-thai-hang/UC-09-01-chuan-bi-thay-doi-trang-thai.md')+'; '+ACT('ACT-COMMON-SUBMIT')},
    {'id':'UIF-09-T05','src':L('SCR-038'),'trigger':'Approver từ chối; không có state movement','dst':'`Kết thúc`','kind':'MUTATION','trace':UC('UC-09-02','BJ-09-quan-ly-trang-thai-hang/UC-09-02-phe-duyet-thay-doi-trang-thai.md')+'; '+ACT('ACT-COMMON-DECIDE')},
    {'id':'UIF-09-T06','src':L('SCR-038'),'trigger':'Gửi xử lý; không cần duyệt','dst':L('SCR-041'),'kind':'MUTATION','trace':UC('UC-09-04','BJ-09-quan-ly-trang-thai-hang/UC-09-04-ghi-state-movement.md')+'; '+ACT('ACT-08-STATE')},
    {'id':'UIF-09-T13','src':L('SCR-038'),'trigger':'Approver duyệt','dst':L('SCR-041'),'kind':'MUTATION','trace':UC('UC-09-02','BJ-09-quan-ly-trang-thai-hang/UC-09-02-phe-duyet-thay-doi-trang-thai.md')+'; '+ACT('ACT-COMMON-DECIDE')},
    {'id':'UIF-09-T14','src':L('SCR-041'),'trigger':'Approval đã duyệt; hệ thống ghi state movement','dst':L('SCR-041'),'kind':'MUTATION','trace':UC('UC-09-04','BJ-09-quan-ly-trang-thai-hang/UC-09-04-ghi-state-movement.md')+'; '+ACT('ACT-08-STATE')},
    {'id':'UIF-09-T07','src':L('SCR-037'),'trigger':'Ngày nghiệp vụ xác định không hết hạn','dst':L('SCR-041'),'kind':'SYSTEM','trace':UC('UC-09-03','BJ-09-quan-ly-trang-thai-hang/UC-09-03-xac-dinh-hang-het-han.md')},
    {'id':'UIF-09-T08','src':L('SCR-037'),'trigger':'Ngày nghiệp vụ xác định đã hết hạn','dst':L('SCR-041'),'kind':'SYSTEM','trace':UC('UC-09-03','BJ-09-quan-ly-trang-thai-hang/UC-09-03-xac-dinh-hang-het-han.md')+'; '+UC('UC-09-04','BJ-09-quan-ly-trang-thai-hang/UC-09-04-ghi-state-movement.md')},
    {'id':'UIF-09-T09','src':L('SCR-041'),'trigger':'Mở biến động vừa ghi','dst':L('SCR-056'),'kind':'NAVIGATION','trace':UC('UC-09-04','BJ-09-quan-ly-trang-thai-hang/UC-09-04-ghi-state-movement.md')},
    {'id':'UIF-09-T10','src':L('SCR-041'),'trigger':'Không thay đổi hoặc kết quả đã rõ','dst':'`Kết thúc`','kind':'TERMINAL','trace':UC('UC-09-03','BJ-09-quan-ly-trang-thai-hang/UC-09-03-xac-dinh-hang-het-han.md')+'; '+UC('UC-09-04','BJ-09-quan-ly-trang-thai-hang/UC-09-04-ghi-state-movement.md')},
    {'id':'UIF-09-T11','src':L('SCR-056'),'trigger':'Đã đủ dấu vết','dst':'`Kết thúc`','kind':'TERMINAL','trace':UC('UC-09-04','BJ-09-quan-ly-trang-thai-hang/UC-09-04-ghi-state-movement.md')},
    {'id':'UIF-09-T12','src':L('SCR-041'),'trigger':'UNKNOWN','dst':'`Handoff BJ-17`','kind':'HANDOFF','trace':UC('UC-09-04','BJ-09-quan-ly-trang-thai-hang/UC-09-04-ghi-state-movement.md')},
], ['ACT-COMMON-SUBMIT','ACT-COMMON-DECIDE','ACT-08-STATE'], 'Maker submit, approval decision and state movement are distinct contracts. The same canonical SCR-038 may render PREPARE or APPROVAL mode, but a user never sees both actor tasks in one session.')

# UIF-10: same screen has preparation/approval/completion modes; no physical decrement on approval.
patch_flow('UIF-10', '''flowchart TD
    START(["Bắt đầu"])
    S036["SCR-036 — Hàng cần xử lý"]
    S037["SCR-037 — Chi tiết hàng và bằng chứng"]
    S040["SCR-040 — Xác nhận tiêu hủy"]
    S041["SCR-041 — Kết quả xử lý"]
    END(["Kết thúc"])
    H_BJ17["Handoff BJ-17"]
    START -->|"Có đề nghị tiêu hủy"| S036
    S036 -->|"Chọn hàng đề nghị xử lý"| S037
    S037 -->|"Mở yêu cầu tiêu hủy"| S040
    S040 -->|"Thiếu điều kiện hoặc bằng chứng"| END
    S040 -->|"Gửi duyệt"| S040
    S040 -->|"Approver từ chối"| END
    S040 -->|"Approver duyệt"| S040
    S040 -->|"Xác nhận đã tiêu hủy thực tế"| S041
    S041 -->|"COMPLETED hoặc REJECTED"| END
    S041 -->|"UNKNOWN"| H_BJ17''', [
    {'id':'UIF-10-T01','src':'`Bắt đầu`','trigger':'Có đề nghị tiêu hủy','dst':L('SCR-036'),'kind':'NAVIGATION','trace':UC('UC-10-01','BJ-10-tieu-huy-hang/UC-10-01-chuan-bi-yeu-cau-tieu-huy.md')},
    {'id':'UIF-10-T02','src':L('SCR-036'),'trigger':'Chọn hàng đề nghị xử lý','dst':L('SCR-037'),'kind':'NAVIGATION','trace':UC('UC-10-01','BJ-10-tieu-huy-hang/UC-10-01-chuan-bi-yeu-cau-tieu-huy.md')},
    {'id':'UIF-10-T03','src':L('SCR-037'),'trigger':'Mở yêu cầu tiêu hủy','dst':L('SCR-040'),'kind':'NAVIGATION','trace':UC('UC-10-01','BJ-10-tieu-huy-hang/UC-10-01-chuan-bi-yeu-cau-tieu-huy.md')},
    {'id':'UIF-10-T04','src':L('SCR-040'),'trigger':'Thiếu điều kiện hoặc bằng chứng','dst':'`Dừng hoặc chờ; không phát sinh tác động`','kind':'TERMINAL','trace':UC('UC-10-01','BJ-10-tieu-huy-hang/UC-10-01-chuan-bi-yeu-cau-tieu-huy.md')},
    {'id':'UIF-10-T05','src':L('SCR-040'),'trigger':'Gửi duyệt; chưa giảm tồn','dst':L('SCR-040'),'kind':'MUTATION','trace':UC('UC-10-01','BJ-10-tieu-huy-hang/UC-10-01-chuan-bi-yeu-cau-tieu-huy.md')+'; '+ACT('ACT-COMMON-SUBMIT')},
    {'id':'UIF-10-T06','src':L('SCR-040'),'trigger':'Approver từ chối; không giảm tồn','dst':'`Kết thúc`','kind':'MUTATION','trace':UC('UC-10-02','BJ-10-tieu-huy-hang/UC-10-02-phe-duyet-tieu-huy.md')+'; '+ACT('ACT-COMMON-DECIDE')},
    {'id':'UIF-10-T07','src':L('SCR-040'),'trigger':'Approver duyệt; chưa giảm tồn','dst':L('SCR-040'),'kind':'MUTATION','trace':UC('UC-10-02','BJ-10-tieu-huy-hang/UC-10-02-phe-duyet-tieu-huy.md')+'; '+ACT('ACT-COMMON-DECIDE')},
    {'id':'UIF-10-T08','src':L('SCR-040'),'trigger':'Xác nhận đã tiêu hủy thực tế','dst':L('SCR-041'),'kind':'MUTATION','trace':UC('UC-10-03','BJ-10-tieu-huy-hang/UC-10-03-xac-nhan-da-tieu-huy.md')+'; '+UC('UC-10-04','BJ-10-tieu-huy-hang/UC-10-04-ghi-giam-hang-tieu-huy.md')+'; '+ACT('ACT-08-DISPOSE')},
    {'id':'UIF-10-T09','src':L('SCR-041'),'trigger':'COMPLETED hoặc REJECTED','dst':'`Kết thúc`','kind':'TERMINAL','trace':UC('UC-10-04','BJ-10-tieu-huy-hang/UC-10-04-ghi-giam-hang-tieu-huy.md')},
    {'id':'UIF-10-T10','src':L('SCR-041'),'trigger':'UNKNOWN','dst':'`Handoff BJ-17`','kind':'HANDOFF','trace':UC('UC-10-04','BJ-10-tieu-huy-hang/UC-10-04-ghi-giam-hang-tieu-huy.md')},
], ['ACT-COMMON-SUBMIT','ACT-COMMON-DECIDE','ACT-08-DISPOSE'], 'SCR-040 is one canonical surface with PREPARE, APPROVAL and COMPLETION modes. Approval never decrements stock; only actual completion can trigger disposal movement.')

# Lightweight wording correction for UIF-06 handoff from first result to classification.
p=FLOWS/'UIF-06-BJ-06.md'
t=p.read_text().replace('SCR-035 | Chưa đủ căn cứ phân loại |', 'SCR-035 | Tiếp tục phân loại hoặc hồ sơ còn RETURN_PENDING |')
t=t.replace('S035 -->|"Chưa đủ căn cứ phân loại"| S033','S035 -->|"Tiếp tục phân loại"| S033')
p.write_text(t)

# ---------- Update flow registry from patched files ----------
frp=FLOWS/'ui-flow-registry.json'
fr=json.loads(frp.read_text())
for f in fr['flows']:
    path=FLOWS/f['file']
    text=path.read_text()
    trans=re.findall(r'^\| `'+re.escape(f['id'])+r'-T[^`]+` \|',text,re.M)
    f['transition_count']=len(trans)
    ids=sorted(set(re.findall(r'ACT-[A-Z0-9-]+',text)))
    f['action_ids']=ids
    f['prototype_status']='HARNESS_FULL_RENDERED'
    f['evidence_level']='HARNESS_LOCAL_AND_CUMULATIVE_REVIEWED'
    sys=[]
    if f['id']=='UIF-02': sys=['ACT-02-RECEIVE']
    if f['id']=='UIF-09': sys=['ACT-08-STATE']
    if f['id']=='UIF-11': sys=['ACT-10-CORRECT']
    if f['id']=='UIF-12': sys=['ACT-13-COMMIT']
    if sys: f['system_action_ids']=sys
fr['patch_version']='4.3.2-harness.1'
fr['freeze_id']='T7-HARNESS-FULL-RUN-v0.2.0'
frp.write_text(json.dumps(fr,ensure_ascii=False,indent=2)+'\n')

print('patched actions/screens/flows')
