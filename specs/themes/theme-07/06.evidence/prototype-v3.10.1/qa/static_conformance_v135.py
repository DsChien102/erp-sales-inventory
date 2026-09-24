from pathlib import Path
import json, re
ROOT=Path(__file__).resolve().parents[1]
THEME=ROOT.parents[1]
OUT=Path(__file__).resolve().parent
checks=[]
def add(name,cond,detail=''): checks.append((name,bool(cond),detail))
def txt(rel): return (THEME/rel).read_text(encoding='utf8')
def html(rel): return (ROOT/rel).read_text(encoding='utf8')
app=html('app.js'); css=html('styles.css')
dec=txt('know-how/decisions/decision-register.md')
ux=txt('prototype/contracts/UX-PATTERN-REGISTRY.md')
cross=txt('prototype/contracts/CROSS-UIF-DECISIONS.md')
s008=txt('prototype/contracts/screens/SCR-008.md')
s009=txt('prototype/contracts/screens/SCR-009.md')
s084=txt('prototype/contracts/screens/SCR-084.md')
s032=txt('prototype/contracts/screens/SCR-032.md')
s028=txt('prototype/contracts/screens/SCR-028.md')
s039=txt('prototype/contracts/screens/SCR-039.md')
u2=txt('srs/05-use-cases/BJ-02-nhan-hang-mua/UC-02-02-chuan-bi-nhap-hang-nhanh.md')
u6=txt('srs/05-use-cases/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra/UC-06-02-xu-ly-ngoai-le-truy-vet.md')
flow2=txt('prototype/flows/UIF-02-BJ-02.md')
comp2=txt('prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.md')
comp2y=txt('prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.yaml')
comp5=txt('prototype/contracts/component-usage/UIF-05-COMPONENT-USAGE.md')
comp5y=txt('prototype/contracts/component-usage/UIF-05-COMPONENT-USAGE.yaml')
comp6=txt('prototype/contracts/component-usage/UIF-06-COMPONENT-USAGE.md')
comp6y=txt('prototype/contracts/component-usage/UIF-06-COMPONENT-USAGE.yaml')
comp7=txt('prototype/contracts/component-usage/UIF-07-COMPONENT-USAGE.md')
comp7y=txt('prototype/contracts/component-usage/UIF-07-COMPONENT-USAGE.yaml')
reg=json.loads(txt('prototype/contracts/screen-registry.json'))
# Decision lock
add('DR110 exists as active decision row','<a id="t7-dr-110"></a>' in dec and 'Xác minh và xác nhận bàn giao vật lý Phase 1' in dec)
add('DR111 exists as active decision row','<a id="t7-dr-111"></a>' in dec and 'Evidence tối thiểu cho handover và ngoại lệ sai LOT Phase 1' in dec)
add('DR110 makes scan optional Phase 1','không bắt buộc trong Phase 1' in dec[dec.find('t7-dr-110'):dec.find('t7-dr-031')])
add('DR111 normal handover does not invent photo/signature','không bắt buộc ảnh, chữ ký' in dec)
add('DR111 wrong LOT requires reason code and LOT image','reason code' in dec and 'ảnh nhãn LOT thực nhận' in dec)
# BJ02 SCR008
add('SCR008 warehouse uses disabled VSelect','VSelect` disabled' in s008 and 'Kho mặc định' in s008)
add('SCR008 date forbids prior day','không cho chọn ngày trước ngày hiện hành' in s008)
add('SCR008 evidence uses VFileDropZone','VFileDropZone' in s008 and 'không nhập chuỗi text' in s008)
add('UC02 acceptance locks warehouse/date','AS-UC-02-02-10' in u2)
add('UC02 acceptance locks file evidence','AS-UC-02-02-11' in u2)
# BJ02 SCR009
add('SCR009 direct visible UOM choice','hiển thị **toàn bộ UOM hợp lệ dạng lựa chọn trực tiếp**' in s009)
add('SCR009 explicitly forbids UOM dropdown','không dùng dropdown' in s009)
add('SCR009 advances directly to SCR084','đi thẳng `SCR-084`' in s009)
add('UC02 acceptance locks visible multi-UOM','AS-UC-02-02-12' in u2 and 'không dùng dropdown' in u2)
add('UC02 acceptance locks single-UOM direct advance','AS-UC-02-02-13' in u2)
# BJ02 SCR084
add('SCR084 append label is Thêm lô khác','label: "Thêm lô khác"' in s084)
add('SCR084 Xong is only completion CTA','`Xong` là CTA duy nhất hoàn tất item' in s084)
add('Flow contract has no progressive classification toggle','không còn progressive toggle' in flow2)
add('Flow contract keeps four authoritative quantity inputs','Đạt / Cách ly / Hỏng / Từ chối' in flow2 and 'authoritative user inputs' in flow2)
add('Component usage documents upload evidence','VFileDropZone' in comp2 and 'delivery_evidence' in comp2y)
# UX guardrails
for pat in ['LOCKED_CONTROL_FIDELITY','VISIBLE_MANDATORY_CHOICE','EVIDENCE_INPUT_MATCHES_ARTIFACT','DECISIVE_SELECTION_ADVANCES','APPEND_IS_NOT_COMPLETE','TEMPORAL_GUARD_IN_CONTROL']:
    add(f'UX guardrail {pat} exists',pat in ux)
add('Cross-UIF lock promotes file upload for artifact evidence','File/image evidence uses `VFileDropZone`' in cross)
add('Cross-UIF lock promotes append wording','Thêm lô khác' in cross)
# BJ06 evidence
add('SCR032 wrong LOT uses direct reason choices','reason code' in s032 and 'VFileDropZone' in s032)
add('SCR032 wrong LOT forbids text-only evidence','Free-text đơn lẻ không đủ evidence' in s032)
add('UC06 screens include maker + approver surfaces','SCR-032' in u6 and 'SCR-034' in u6)
add('UC06 acceptance blocks missing reason/image','AS-UC-06-02-05' in u6)
add('UC06 Other requires detail','AS-UC-06-02-06' in u6)
add('UC06 approver acceptance includes evidence','AS-UC-06-02-07' in u6)
# Handover evidence
add('SCR028 system evidence + physical confirmation','system-generated immutable evidence' in s028 and 'bàn giao vật lý' in s028)
add('SCR039 system evidence + physical confirmation','system-generated immutable evidence' in s039 and 'bàn giao vật lý' in s039)
add('SCR028 does not invent mandatory recipient/photo/signature','không invent field' in s028)
add('SCR039 does not invent mandatory recipient/photo/signature','không invent recipient/photo/signature/carrier' in s039)
add('UIF05 component usage records physical confirmation','physical handover' in comp5.lower() and 'physicalConfirmationRequired: true' in comp5y)
add('UIF05 component usage keeps scan optional','scanRequiredPhase1: false' in comp5y)
add('UIF06 component usage requires VFileDropZone image evidence','VFileDropZone' in comp6 and 'evidenceComponent: VFileDropZone' in comp6y)
add('UIF06 component usage forbids text-only evidence','textOnlyEvidenceAllowed: false' in comp6y)
add('UIF07 component usage records physical confirmation','handover physically occurred' in comp7.lower() and 'physicalConfirmationRequired: true' in comp7y)
add('UIF07 component usage keeps scan optional','scanRequiredPhase1: false' in comp7y)
# Renderer / Flutter DS fidelity
add('SCR008 renderer uses disabled select','data-bj02-warehouse disabled' in app)
add('SCR008 renderer uses date min localDateIso','type="date" min="${localDateIso()}"' in app)
add('SCR008 renderer uses file input','data-bj02-evidence-file type="file"' in app)
add('SCR009 renderer has direct UOM buttons','data-bj02-overview-uom-choice' in app)
add('SCR009 renderer does not implement overview UOM select','data-bj02-overview-uom]' not in app and 'data-bj02-overview-uom aria' not in app)
add('Fallback line UOM also uses direct visible choice','data-bj02-line-uom-choice' in app)
add('SCR084 renderer uses Thêm lô khác','>Thêm lô khác</button>' in app)
add('BJ06 renderer has image upload','data-io06-evidence-file type="file" accept="image/*"' in app)
add('File zones use existing mapped fileText icon','icon("fileText", "icon--sm")' in app and "icon('fileText','icon--sm')" in app)
add('No unsupported upload semantic icon is invoked','icon("upload"' not in app and "icon('upload'" not in app)
add('No horizontal fixed width introduced in new choice CSS','quick-uom-choice-group' in css and 'io-reason-choice-list' in css)
# Registry relevant semantics
screen_by_id={x.get('id'):x for x in reg.get('screens',reg if isinstance(reg,list) else [])} if isinstance(reg,dict) else {x.get('id'):x for x in reg}
# Don't assume exact schema; raw JSON still must mention ownership tags.
raw=json.dumps(reg,ensure_ascii=False)
add('Registry records required file upload ownership','USER_FILE_UPLOAD_REQUIRED' in raw)
add('Registry records wrong-LOT file upload ownership','USER_FILE_UPLOAD_REQUIRED_WHEN_MISMATCH' in raw)

passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# Static / Flutter-DS contract conformance — v1.3.5','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'Focused static conformance for the v1.3.5 interaction/evidence corrections. This supplements, rather than rewrites, historical validators tied to the v0.2.9 pilot.','', '## Checks','']
for n,ok,d in checks: lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
(OUT/'STATIC-CONFORMANCE-v1.3.5.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
raise SystemExit(1 if failed else 0)
