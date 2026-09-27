#!/usr/bin/env python3
from pathlib import Path
import json,re,sys
ROOT=Path(__file__).resolve().parents[6]
T=ROOT/'specs/themes/theme-07'; HTML=T/'prototype/html'; QA=HTML/'qa'
def load(n): return json.loads((QA/n).read_text(encoding='utf-8'))
def j(rel): return json.loads((ROOT/rel).read_text(encoding='utf-8'))
def r(rel): return (ROOT/rel).read_text(encoding='utf-8')
def find_id(o,target):
    if isinstance(o,dict):
        if o.get('id')==target or o.get('screen_id')==target:return o
        for v in o.values():
            x=find_id(v,target)
            if x:return x
    elif isinstance(o,list):
        for v in o:
            x=find_id(v,target)
            if x:return x
    return None
checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':str(note)[:1200]})
# Evidence
focused=load('BJ08-DEEP-REVIEW-QA-v3.10.0.json'); fresh=load('BJ08-FRESH-EYE-QA-v3.10.0.json')
prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.10.0.json'); wave3=load('WAVE-3-CROSS-BJ-AUDIT-v3.10.0.json')
frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.10.0.json'); enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.10.0.json')
flowqa=load('FLOW-LOGIC-E2E-QA-v3.10.0.json'); smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.10.0.json')
runtime=load('RUNTIME-UI-QA-v3.10.0.json'); coh=load('REPRESENTATIVE-COHERENCE-QA-v3.10.0.json'); device=load('DEVICE-FRAME-QA-v3.10.0.json')
# Package artifacts
proto=j('specs/themes/theme-07/prototype/prototype.manifest.json'); outer=j('specs/themes/theme-07/prototype/html/prototype.manifest.json')
manifest=j('specs/themes/theme-07/prototype/html/manifest.json'); wb=j('specs/themes/theme-07/prototype/html/workbench-data.json')
reg=j('specs/themes/theme-07/prototype/contracts/screen-registry.json'); cat=j('specs/themes/theme-07/prototype/contracts/screen-catalog.json')
acts=j('specs/themes/theme-07/prototype/contracts/action-registry.json'); creg=j('specs/themes/theme-07/harness/contract-registry.json'); trace=j('specs/themes/theme-07/harness/trace-index.json')
readme=r('README.md'); root_index=r('index.html'); html_index=r('specs/themes/theme-07/prototype/html/index.html')
dec=r('specs/themes/theme-07/know-how/decisions/decision-register.md'); bj=r('specs/themes/theme-07/srs/02-business-journeys/08-BJ-08-kiem-ke-va-dieu-chinh-chenh-lech.md')
data=r('specs/themes/theme-07/srs/04-data-entities.md'); bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'); tech=r('specs/themes/theme-07/srs/07-technical-contracts.md')
flow08=r('specs/themes/theme-07/prototype/flows/UIF-08-BJ-08.md'); cu=r('specs/themes/theme-07/prototype/contracts/component-usage/UIF-08-COMPONENT-USAGE.md')
overlay=r('specs/themes/theme-07/prototype/html/v3100-bj08-semantic-hardening.js')
ucs=[r(f'specs/themes/theme-07/srs/05-use-cases/BJ-08-kiem-ke-va-dieu-chinh-chenh-lech/{fn}') for fn in [
'UC-08-01-mo-va-khoa-pham-vi.md','UC-08-02-ghi-nhan-lan-dem-mu.md','UC-08-03-dem-lai-va-hoan-thien-bang-chung.md','UC-08-04-duyet-va-dieu-chinh.md','UC-08-05-huy-phien-kiem-ke.md']]
# Baseline/version closure
ck('root package identifies v3.10.0',readme.startswith('# VET45 Theme 7 Prototype Harness — v3.10.0') and 'v3.10.0' in root_index)
ck('prototype manifests identify v3.10.0 parent v3.9.9',proto.get('version')=='3.10.0' and proto.get('parentVersion')=='3.9.9' and outer.get('version')=='3.10.0' and outer.get('parentVersion')=='3.9.9' and manifest.get('version')=='3.10.0' and manifest.get('parentVersion')=='3.9.9')
ck('current registries identify v3.10.0',wb.get('version')=='3.10.0' and reg.get('version')=='3.10.0' and cat.get('version')=='3.10.0' and cat.get('package_version')=='3.10.0' and acts.get('version')=='3.10.0')
ck('v3.10.0 runtime overlay loads after v3.9.9',html_index.count('v3100-bj08-semantic-hardening.js')==1 and html_index.index('v3100-bj08-semantic-hardening.js')>html_index.index('v399-bj14-semantic-hardening.js'))
# Evidence closure
ck('BJ08 focused deep review passes 135/135',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==135)
ck('BJ08 fresh-eye passes 18/18',fresh.get('status')=='PASS' and fresh.get('passed')==fresh.get('total')==18)
ck('prior locked regression passes 29/29',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==29)
ck('Wave 3 cross-BJ audit remains 35/35',wave3.get('status')=='PASS' and wave3.get('passed')==wave3.get('total')==35)
ck('frozen source comparison passes 108/108',frozen.get('status')=='PASS' and frozen.get('filesCompared')==frozen.get('candidateFiles')==108 and not frozen.get('added') and not frozen.get('removed') and not frozen.get('changed'))
ck('full-theme end-user regression passes 19/19',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19)
ck('flow logic passes 23 checks',flowqa.get('status')=='PASS' and len(flowqa.get('pass',[]))==23 and flowqa.get('version')=='3.10.0')
ck('all-flow smoke passes 89 renders',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI passes 514 route-state renders / 89 routes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==514 and runtime.get('canonical_routes')==89 and runtime.get('version')=='3.10.0')
ck('representative coherence passes 8/8',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.10.0')
ck('device frame passes 7/7 over 89 screens',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
# Decision / journey / data
ck('approved DR171..177 exist and are ACTIVE',all(f'**`T7-DR-{i}`' in dec and re.search(rf'T7-DR-{i}.*?`ACTIVE`',dec,re.S) for i in range(171,178)))
ck('BJ08 uses atomic barrier before cutoff', 'Atomic cut-off barrier' in bj and 'Barrier được acquire trước khi chốt cutoff' in bj)
ck('BJ08 freezes canonical CountScopeSnapshot','CountScopeSnapshot' in bj and 'resolved' in dec.lower())
ck('BJ08 count identity is PhysicalCountKey in base UOM','PhysicalCountKey' in bj and 'base UOM' in bj)
ck('BJ08 blocks unresolved valuation','VALUATION_PENDING' in bj and 'không mở session' in bj)
ck('BJ08 count rounds are immutable','Immutable FIRST submission' in bj and 'Immutable RECOUNT submission' in bj)
ck('BJ08 zero variance bypasses approval','Zero variance' in bj and 'không tạo approval giả' in bj)
ck('data owns CountScopeSnapshot entity','ENT-IC-08 — CountScopeSnapshot' in data and 'scope_hash' in data)
ck('data owns immutable StockCountSubmission entity','ENT-IC-09 — StockCountSubmission' in data and 'round_no' in data and 'payload_hash' in data)
ck('StockCountSession stores counter assignment',all(x in data for x in ['assigned_counter_id','assignment_version','assignment_snapshot']))
ck('StockCountLine is current projection by physical key','physical_count_key_hash' in data and 'book_balance_ids_snapshot' in data)
ck('ApprovalCase supports STOCK_COUNT_SESSION subject','subject_type' in data and 'STOCK_COUNT_SESSION' in data and 'subject_id' in data and 'excluded_actor_ids' in data)
ck('ApprovalCase supports immutable recount successor','REQUEST_RECOUNT' in data and 'predecessor_case_id' in data and 'superseded_by_case_id' in data)
# BC/technical closure
bc01=re.search(r'### BC-IC-01 — Open stock count(.*?)(?=\n### BC-IC-02)',bc,re.S).group(1)
ck('BC-IC-01 barrier is before cutoff',bc01.find('scope barrier')>=0 and bc01.find('scope barrier')<bc01.find('cutoff'))
ck('BC-IC-02 creates immutable submission and zero-variance completion','StockCountSubmission' in bc and 'zero variance' in bc.lower() and 'ApprovalCase' in bc)
ck('BC-IC-03 binds CountAdjustmentBasis and stale basis checks','CountAdjustmentBasis' in bc and 'stale' in bc.lower())
ck('BC-IC-08 preserves evidence on cancel','BC-IC-08' in bc and 'evidence' in bc.lower())
ck('technical contracts expose BJ08 command APIs',all(x in tech for x in ['API-C-14','API-C-15','API-C-16','API-C-27']))
ck('technical contract covers unresolved valuation/basis stale',all(x in tech for x in ['COUNT_SCOPE_HAS_UNRESOLVED_VALUATION','COUNT_APPROVAL_SNAPSHOT_STALE','COUNT_VALUE_BASIS_STALE']))
ck('technical lock covers prospective PhysicalCountKey','prospective PhysicalCountKey' in tech)
# UC trace and authority
actors=['Người có quyền mở kiểm kê','Assigned counter','Assigned counter','Eligible independent approver','Người có quyền hủy']
for i,u in enumerate(ucs,1):
    ck(f'UC08-{i:02d} has explicit actor authority',actors[i-1] in u)
    ck(f'UC08-{i:02d} retains four stable acceptance anchors',all(f'as-uc-08-{i:02d}-{n:02d}' in u for n in range(1,5)))
ck('UC08-04 approval subject is stock count and contributor-excluded','STOCK_COUNT_SESSION' in ucs[3] and 'excluded_actor_ids' in ucs[3])
ck('UC08-05 cancel is contextual only','SCR-044/SCR-045' in ucs[4] and 'browse list' in ucs[4])
# UI/action/trace closure
act=find_id(acts,'ACT-09-CANCEL'); ck('cancel action belongs exactly to SCR044/SCR045',act and act.get('screen_ids')==['SCR-044','SCR-045'],act)
ck('SCR042 and SCR046 do not own cancel','ACT-09-CANCEL' not in (find_id(reg,'SCR-042').get('action_ids') or []) and 'ACT-09-CANCEL' not in (find_id(reg,'SCR-046').get('action_ids') or []))
ck('all active BJ08 screens carry v3.10.0 prototype status',all('3.10.0' in str(find_id(reg,f'SCR-{n:03d}').get('prototype_status','')) for n in range(42,48)))
ck('UIF08 has 16 transitions and zero variance direct result','UIF-08-T16' in flow08 and 'no ApprovalCase' in flow08 and 'SCR-047' in flow08)
ck('component usage keeps cancel contextual only', 'cancellation is contextual on SCR-044/SCR-045 only' in cu)
for i in range(1,6):
    st=next((x for x in trace.get('stories',[]) if x.get('story')==f'UC-08-0{i}'),None)
    ck(f'trace UC08-{i:02d} carries DR171..177',st is not None and all(f'T7-DR-{n}' in st.get('decisions',[]) for n in range(171,178)))
ck('contract registry BC-IC-01 is amended',find_id(creg,'BC-IC-01') is not None and find_id(creg,'BC-IC-01').get('version')=='4.2.5-amendment')
# Runtime semantic closure
ck('runtime resets evidence on new session','roundHistory=[]' in overlay and "k==='new'" in overlay)
ck('runtime rejects blank first/recount',overlay.count("VALIDATION_ERROR")>=2)
ck('runtime requires physical state for unexpected stock','stockState' in overlay and 'data-v3100-stock-state' in overlay)
ck('runtime blocks unresolved valuation and missing basis','COUNT_SCOPE_HAS_UNRESOLVED_VALUATION' in overlay and 'PRICE_BASIS_REQUIRED' in overlay)
ck('runtime blocks contributor self approval','SELF_APPROVAL_NOT_ALLOWED' in overlay and 'getActor' in overlay)
ck('runtime zero result says no adjustment/unlocked','Không cần tạo điều chỉnh' in overlay and 'Đã mở' in overlay)
ck('runtime UNKNOWN preserves same identity and BJ17 handoff','data-v350-action="handoff-unknown"' in overlay and 'data-operation="KK-1709-01"' in overlay and 'Không gửi lại thao tác' in overlay)
ck('manifest marks BJ08 lock candidate',manifest.get('status')=='WAVE_4_BJ08_DEEP_REVIEW_LOCK_CANDIDATE' and manifest.get('productApproval')=='BJ08_DEEP_REVIEW_QA_v3.10.0')
ck('BJ08 focused evidence has nine captures',len(list((QA/'v3100-bj08-captures').glob('*.png')))==9)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.10.0','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.10.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.10.0.md').write_text('\n'.join(['# Current Package Validation — v3.10.0','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
