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
def ck(n,c,note=''): checks.append({'name':n,'pass':bool(c),'note':str(note)[:1400]})
# QA evidence
focused=load('BJ09-DEEP-REVIEW-QA-v3.10.1.json'); fresh=load('BJ09-FRESH-EYE-QA-v3.10.1.json')
prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.10.1.json'); wave3=load('WAVE-3-CROSS-BJ-AUDIT-v3.10.1.json')
frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.10.1.json'); enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.10.1.json')
flowqa=load('FLOW-LOGIC-E2E-QA-v3.10.1.json'); smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.10.1.json')
runtime=load('RUNTIME-UI-QA-v3.10.1.json'); coh=load('REPRESENTATIVE-COHERENCE-QA-v3.10.1.json'); device=load('DEVICE-FRAME-QA-v3.10.1.json'); structural=load('STRUCTURAL-PACKAGE-QA-v3.10.1.json')
# Package artifacts
proto=j('specs/themes/theme-07/prototype/prototype.manifest.json'); outer=j('specs/themes/theme-07/prototype/html/prototype.manifest.json')
manifest=j('specs/themes/theme-07/prototype/html/manifest.json'); wb=j('specs/themes/theme-07/prototype/html/workbench-data.json')
reg=j('specs/themes/theme-07/prototype/contracts/screen-registry.json'); cat=j('specs/themes/theme-07/prototype/contracts/screen-catalog.json')
acts=j('specs/themes/theme-07/prototype/contracts/action-registry.json'); creg=j('specs/themes/theme-07/harness/contract-registry.json'); trace=j('specs/themes/theme-07/harness/trace-index.json')
readme=r('README.md'); root_index=r('index.html'); html_index=r('specs/themes/theme-07/prototype/html/index.html')
dec=r('specs/themes/theme-07/know-how/decisions/decision-register.md'); bj=r('specs/themes/theme-07/srs/02-business-journeys/09-BJ-09-quan-ly-trang-thai-hang.md')
data=r('specs/themes/theme-07/srs/04-data-entities.md'); bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'); tech=r('specs/themes/theme-07/srs/07-technical-contracts.md')
flow09=r('specs/themes/theme-07/prototype/flows/UIF-09-BJ-09.md'); scr38=r('specs/themes/theme-07/prototype/contracts/screens/SCR-038.md'); scr41=r('specs/themes/theme-07/prototype/contracts/screens/SCR-041.md')
cu=r('specs/themes/theme-07/prototype/contracts/component-usage/UIF-09-COMPONENT-USAGE.md'); cuy=r('specs/themes/theme-07/prototype/contracts/component-usage/UIF-09-COMPONENT-USAGE.yaml')
overlay=r('specs/themes/theme-07/prototype/html/v3101-bj09-semantic-hardening.js')
ucs=[r(f'specs/themes/theme-07/srs/05-use-cases/BJ-09-quan-ly-trang-thai-hang/{fn}') for fn in ['UC-09-01-chuan-bi-thay-doi-trang-thai.md','UC-09-02-phe-duyet-thay-doi-trang-thai.md','UC-09-03-xac-dinh-hang-het-han.md','UC-09-04-ghi-state-movement.md']]
# Version/baseline closure
ck('root package identifies v3.10.1',readme.startswith('# VET45 Theme 7 Prototype Harness — v3.10.1') and 'v3.10.1' in root_index)
ck('prototype manifests use direct parent v3.10.0',all(x.get('version')=='3.10.1' and x.get('parentVersion')=='3.10.0' for x in [proto,outer,manifest]))
ck('current registries identify v3.10.1',wb.get('version')=='3.10.1' and reg.get('version')=='3.10.1' and cat.get('version')=='3.10.1' and cat.get('package_version')=='3.10.1' and acts.get('version')=='3.10.1')
ck('screen registry current prototype status identifies BJ09',reg.get('prototype_status')=='BJ09_DEEP_REVIEW_v3.10.1',reg.get('prototype_status'))
ck('v3.10.1 overlay loads exactly once after v3.10.0 layer',html_index.count('v3101-bj09-semantic-hardening.js')==1 and html_index.index('v3101-bj09-semantic-hardening.js')>html_index.index('v3100-bj08-semantic-hardening.js'))
# Evidence closure
ck('BJ09 deep review passes 127/127',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==127)
ck('BJ09 fresh-eye passes 31/31',fresh.get('status')=='PASS' and fresh.get('passed')==fresh.get('total')==31)
ck('prior locked regression passes 37/37 including BJ08',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==37)
ck('Wave 3 cross-BJ audit remains 35/35',wave3.get('status')=='PASS' and wave3.get('passed')==wave3.get('total')==35)
ck('frozen source direct-parent comparison passes 108/108',frozen.get('status')=='PASS' and frozen.get('filesCompared')==frozen.get('candidateFiles')==108 and not frozen.get('added') and not frozen.get('removed') and not frozen.get('changed'))
ck('full-theme end-user regression passes 19/19',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19)
ck('flow logic passes 26 checks',flowqa.get('status')=='PASS' and len(flowqa.get('pass',[]))==26 and flowqa.get('version')=='3.10.1')
ck('all-flow smoke passes 89 renders',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI passes 514 route-state renders / 89 routes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==514 and runtime.get('canonical_routes')==89 and runtime.get('version')=='3.10.1')
ck('representative coherence passes 8/8',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.10.1')
ck('device frame passes 7/7 over 89 routes',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('structural package gate passes',structural.get('status')=='PASS' and structural.get('passed')==structural.get('total')==10)
# Decision/BJ/UC authority
for i in range(178,185): ck(f'T7-DR-{i} exists ACTIVE',bool(re.search(rf'T7-DR-{i}.*?`ACTIVE`',dec,re.S)))
ck('canonical state is DEMO and TRIAL is explicitly retired','`DEMO`' in dec and '`TRIAL` không phải enum hợp lệ' in dec)
ck('state policy is versioned/immutable','StateTransitionPolicyVersion' in dec and 'policy_hash' in dec)
ck('partial quantity resolves exact valuation slices','exact source balance slices' in dec and 'STATE_SOURCE_SLICE_AMBIGUOUS' in dec)
ck('STATE_TRANSFER preserves valuation and book value','STATE_TRANSFER' in dec and 'valuation_state_snapshot' in dec and 'không đổi authoritative book value' in dec)
ck('expiry is system-derived','EXPIRED' in dec and 'system-derived' in dec)
ck('reservation reconciliation is atomic','reconcile reservation atomically' in dec and 'allocation_review_required' in dec)
ck('approval binds immutable StateChangeBasis','StateChangeBasis' in dec and 'APPROVAL_BASIS_MISMATCH' in dec)
ck('BJ09 separates submit/approval/system execution','StateChangeBasis' in bj and 'system executor' in bj.lower() and 'approver' in bj.lower())
ck('all four BJ09 UCs carry v3.10.1 amendment semantics',all('v3.10.1' in u and 'StateChangeBasis' in u for u in ucs))
ck('UC09-02 says approval decision does not mutate stock','approver' in ucs[1].lower() and ('approval không tự ghi state movement' in ucs[1].lower()))
ck('UC09-03 owns system-derived expiry','EXPIRED' in ucs[2] and 'system' in ucs[2].lower())
ck('UC09-04 owns system execution boundary','system-owned' in ucs[3].lower() and 'ACT-08-STATE' in ucs[3])
# Data/BC/technical
ck('data owns immutable StateTransitionPolicyVersion','ENT-IC-10 — StateTransitionPolicyVersion' in data)
ck('data owns immutable StateChangeBasis','ENT-IC-11 — StateChangeBasis' in data and 'basis_hash' in data)
ck('InventoryMovement has valuation_state_snapshot','valuation_state_snapshot' in data)
ck('BC-IO-10 exact basis execution and no value movement','BC-IO-10' in bc and 'StateChangeBasis' in bc and 'InventoryValueMovement' in bc and 'STATE_TRANSFER' in bc)
ck('BC-IC-06 exact approval basis','BC-IC-06' in bc and 'basis' in bc.lower())
ck('BC-IC-07 locks submit basis','BC-IC-07' in bc and 'StateChangeBasis' in bc)
ck('API-C-10 is system execution endpoint','API-C-10 deep-review contract v3.10.1' in tech and 'system execution endpoint' in tech)
ck('technical errors cover ambiguity/stale/policy/approval mismatch',all(x in tech for x in ['STATE_SOURCE_SLICE_AMBIGUOUS','STATE_CHANGE_BASIS_STALE','STATE_POLICY_VERSION_STALE','APPROVAL_BASIS_MISMATCH']))
ck('EVT-IO-08 includes basis/policy/reservation lineage','EVT-IO-08' in tech and 'basis' in tech.lower() and 'reservation' in tech.lower())
# UI/action/trace closure
act=find_id(acts,'ACT-08-STATE'); ck('ACT-08-STATE is trace-only system execution',act and act.get('ui_visibility')=='TRACE_ONLY_SYSTEM' and act.get('bc')=='BC-IO-10' and act.get('api')=='API-C-10',act)
ck('SCR038 From is read-only and destination policy-driven','SERVER_AUTHORITATIVE_READ_ONLY' in scr38 and 'StateTransitionPolicyVersion' in scr38)
ck('SCR038 has stale-basis state','STATE_CHANGE_BASIS_STALE' in scr38)
ck('SCR041 owns processing/system result states','PROCESSING' in scr41 and 'COMPLETED' in scr41 and 'UNKNOWN' in scr41)
ck('UIF09 separates HANDOFF and SYSTEM transition','HANDOFF' in flow09 and 'SYSTEM' in flow09 and 'ACT-08-STATE' in flow09)
ck('component usage binds policy and immutable basis','StateTransitionPolicyVersion' in cu and 'StateChangeBasis' in cu and 'policy_source' in cuy and 'submit_basis' in cuy)
for i in range(1,5):
    st=next((x for x in trace.get('stories',[]) if x.get('story')==f'UC-09-0{i}'),None)
    ck(f'trace UC09-{i:02d} carries DR178..184',st is not None and all(f'T7-DR-{n}' in st.get('decisions',[]) for n in range(178,185)),st)
ck('contract registry contains new IC entities',find_id(creg,'ENT-IC-10') is not None and find_id(creg,'ENT-IC-11') is not None)
ck('contract registry marks amended state-change BCs',all(find_id(creg,x) and find_id(creg,x).get('version')=='4.2.6-amendment' for x in ['BC-IO-10','BC-IC-06','BC-IC-07']))
# Runtime static closure
active_js='\n'.join(p.read_text(encoding='utf-8',errors='ignore') for p in HTML.glob('*.js') if p.name in html_index)
ck('active loaded JS contains no TRIAL enum','TRIAL' not in active_js)
ck('runtime policy uses DEMO','DEMO' in overlay and "label:'Dùng thử'" in overlay)
ck('runtime approval stores decision before system commit','decision={decision:\'APPROVE\'' in overlay and 'queueSystemCommit' in overlay)
ck('runtime system commit preserves valuation and no value movement','valuationStateSnapshot' in overlay and 'valueMovementCreated:false' in overlay)
ck('runtime expiry has no manual action','không có thao tác đánh dấu hết hạn' in overlay)
ck('runtime supports atomic reservation impact preview','reservationImpact' in overlay and 'allocationReviewRequired' in overlay)
ck('runtime fixture hash explicitly not production hash', 'fixtureHashNote' in overlay and 'production contract requires canonical SHA-256' in overlay)
ck('manifest marks BJ09 lock candidate',manifest.get('status')=='WAVE_4_BJ09_DEEP_REVIEW_LOCK_CANDIDATE' and manifest.get('productApproval')=='BJ09_DEEP_REVIEW_QA_v3.10.1')
ck('BJ09 focused evidence has ten captures',len(list((QA/'v3101-bj09-captures').glob('*.png')))==10)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.10.1','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.10.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.10.1.md').write_text('\n'.join(['# Current Package Validation — v3.10.1','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
