#!/usr/bin/env python3
from pathlib import Path
import json,re,sys
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[6]
HTML=ROOT/'specs/themes/theme-07/prototype/html'; QA=HTML/'qa'; T=ROOT/'specs/themes/theme-07'
checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':str(note)[:1000]})
def rd(rel): return (T/rel).read_text(encoding='utf-8')
def js(rel): return json.loads((T/rel).read_text(encoding='utf-8'))
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
def inline(root):
    h=(root/'index.html').read_text(encoding='utf-8')
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0];h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text(encoding="utf-8")}</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0];h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
    return h

dec=rd('know-how/decisions/decision-register.md')
bj=rd('srs/02-business-journeys/09-BJ-09-quan-ly-trang-thai-hang.md')
ucdir='srs/05-use-cases/BJ-09-quan-ly-trang-thai-hang'
ucs={i:rd(f'{ucdir}/'+fn) for i,fn in {
1:'UC-09-01-chuan-bi-thay-doi-trang-thai.md',2:'UC-09-02-phe-duyet-thay-doi-trang-thai.md',3:'UC-09-03-xac-dinh-hang-het-han.md',4:'UC-09-04-ghi-state-movement.md'}.items()}
data=rd('srs/04-data-entities.md');bc=rd('srs/06-shared-behavioral-contracts.md');tech=rd('srs/07-technical-contracts.md')
flow=rd('prototype/flows/UIF-09-BJ-09.md');scr038=rd('prototype/contracts/screens/SCR-038.md');scr041=rd('prototype/contracts/screens/SCR-041.md')
cu=rd('prototype/contracts/component-usage/UIF-09-COMPONENT-USAGE.md'); cuy=rd('prototype/contracts/component-usage/UIF-09-COMPONENT-USAGE.yaml')
overlay=(HTML/'v3101-bj09-semantic-hardening.js').read_text(encoding='utf-8'); html_index=(HTML/'index.html').read_text(encoding='utf-8')
manifest=json.loads((HTML/'manifest.json').read_text()); pm=js('prototype/prototype.manifest.json'); hpm=json.loads((HTML/'prototype.manifest.json').read_text())
wb=json.loads((HTML/'workbench-data.json').read_text());actions=js('prototype/contracts/action-registry.json');reg=js('prototype/contracts/screen-registry.json');cat=js('prototype/contracts/screen-catalog.json');trace=js('harness/trace-index.json');creg=js('harness/contract-registry.json')
# 1-8 Baseline / lineage
ck('candidate manifest is v3.10.1 on direct parent v3.10.0',manifest.get('version')=='3.10.1' and manifest.get('parentVersion')=='3.10.0' and manifest.get('parent')=='3.10.0')
ck('both prototype manifests identify v3.10.1 parent v3.10.0',pm.get('version')=='3.10.1' and pm.get('parentVersion')=='3.10.0' and hpm.get('version')=='3.10.1' and hpm.get('parentVersion')=='3.10.0')
ck('canonical UI registries identify v3.10.1',reg.get('version')=='3.10.1' and actions.get('version')=='3.10.1' and cat.get('version')=='3.10.1' and cat.get('package_version')=='3.10.1')
ck('workbench identifies v3.10.1',wb.get('version')=='3.10.1')
ck('v3.10.1 BJ09 overlay loads exactly once',html_index.count('v3101-bj09-semantic-hardening.js')==1)
ck('v3.10.1 overlay loads after v3.10.0 overlay',html_index.index('v3101-bj09-semantic-hardening.js')>html_index.index('v3100-bj08-semantic-hardening.js'))
ck('root launcher/readme identify v3.10.1',(ROOT/'README.md').read_text().startswith('# VET45 Theme 7 Prototype Harness — v3.10.1') and 'VET45 Theme 7 - v3.10.1' in (ROOT/'index.html').read_text())
loaded_js=[]
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"',html_index):
    p=HTML/fn.split('?')[0]
    if p.exists(): loaded_js.append((p,p.read_text(encoding='utf-8')))
ck('active loaded JavaScript contains no TRIAL enum',all('TRIAL' not in txt for _,txt in loaded_js),[str(p.name) for p,txt in loaded_js if 'TRIAL' in txt])
# 9-22 Decisions: 7 existence + 7 semantic locks
for n in range(178,185): ck(f'DR-{n} exists and is ACTIVE',f'<a id="t7-dr-{n}"></a>' in dec and re.search(rf'T7-DR-{n}.*?`ACTIVE`',dec,re.S) is not None)
semantics={
178:['`DEMO`','`TRIAL`','Dùng thử'],179:['StateTransitionPolicy','policy_hash','version'],180:['valuation_state','STATE_SOURCE_SLICE_AMBIGUOUS','source balance slices'],
181:['STATE_TRANSFER','InventoryValueMovement','valuation_state_snapshot'],182:['EXPIRED','business date','idempotent'],183:['reservation','allocation_review_required','PickAllocation'],184:['StateChangeBasis','basis_hash','APPROVAL_BASIS_MISMATCH']}
for n,toks in semantics.items():
    sec=re.search(rf'<a id="t7-dr-{n}"></a>.*?(?=\n\| <a id="t7-dr-|\n\n<a id="g07")',dec,re.S); text=sec.group(0) if sec else ''
    ck(f'DR-{n} carries its semantic invariant',all(tok in text for tok in toks),[tok for tok in toks if tok not in text])
# 23-37 BJ semantic model
bj_checks=[
('BJ09 canonical taxonomy is explicit',all(x in bj for x in ['SELLABLE','QUARANTINE','DAMAGED','DEMO']) and 'Không dùng `TRIAL`' in bj),
('BJ09 policy is immutable and versioned','StateTransitionPolicyVersion' in bj and 'policy_version + policy_hash' in bj),
('BJ09 partial quantity remains user input','Partial quantity' in bj and 'User nhập quantity' in bj),
('BJ09 exact source slices are server-resolved','Server resolve exact source slices' in bj and 'balance_id, balance_version, valuation_state, quantity' in bj),
('BJ09 ambiguous composition is blocked','ambiguous composition bị block' in bj),
('BJ09 state transfer preserves valuation state','STATE_TRANSFER' in bj and 'cùng valuation state' in bj),
('BJ09 state transfer creates no value movement','không tạo value movement' in bj.lower()),
('BJ09 approval binds immutable basis','immutable `StateChangeBasis`' in bj and 'basis_hash' in bj),
('BJ09 approval itself does not write stock','approve không ghi stock' in bj),
('BJ09 system executor owns final commit','System executor recheck basis' in bj and 'UC-09-04 — Ghi state movement' in bj),
('BJ09 expiry is system-derived','EXPIRED` là system-derived' in bj and 'Không có destination/CTA thủ công' in bj),
('BJ09 reservation reconcile is atomic','reservation capacity/reconciliation commit atomically' in bj),
('BJ09 does not silently rewrite PickAllocation','Không rewrite active PickAllocation' in bj),
('BJ09 protects states owned by other journeys',all(x in bj for x in ['VALUATION_PENDING','RETURN_PENDING','RTV_PENDING']) and 'không phải đường tắt' in bj),
('BJ09 keeps technical basis facts out of product UI','UI không expose balance ID, valuation state, policy hash' in bj),
]
for n,c in bj_checks: ck(n,c)
# 38-57 UC common deep-review clauses
for i,u in ucs.items():
    ck(f'UC09-{i:02d} has v3.10.1 deep-review amendment','## v3.10.1 deep-review amendment' in u)
    ck(f'UC09-{i:02d} canonicalizes DEMO and retires active TRIAL','Canonical business state code dùng `DEMO`' in u and '`TRIAL` không còn là active enum' in u)
    ck(f'UC09-{i:02d} binds immutable StateChangeBasis exact slices','immutable `StateChangeBasis`' in u and 'exact source balance slices/version/valuation state' in u)
    ck(f'UC09-{i:02d} keeps valuation state system-owned','User không chọn valuation state' in u)
    ck(f'UC09-{i:02d} blocks ambiguous partial source composition','STATE_SOURCE_SLICE_AMBIGUOUS' in u and 'trước mutation' in u)
# 58-65 UC-specific behavioral/technical ownership
ck('UC09-01 uses draft + submit contracts','BC-IO-16' in ucs[1] and 'BC-IC-07' in ucs[1])
ck('UC09-01 submit technical trace includes API-C-26','API-C-26' in ucs[1] and 'SubmitInventoryOperation' in ucs[1])
ck('UC09-02 approval result is decision, not stock mutation','approval decision' in ucs[2].lower() and 'không phải stock mutation' in ucs[2].lower())
ck('UC09-02 requires reject reason and blocks self-approval','REJECT' in ucs[2] and 'bắt buộc lý do' in ucs[2] and 'self-approval bị chặn' in ucs[2])
ck('UC09-03 expiry is system behavior','Expiry evaluation là system behavior' in ucs[3] and 'không cần người dùng submit' in ucs[3])
ck('UC09-03 technical trace uses API-C-10','API-C-10' in ucs[3] and 'BC-IO-10' in ucs[3])
ck('UC09-04 is system-owned execution with no ACT-08-STATE CTA','system-owned execution' in ucs[4] and 'không có CTA `ACT-08-STATE`' in ucs[4])
ck('UC09-04 technical trace uses API-C-10','API-C-10' in ucs[4] and 'BC-IO-10' in ucs[4])
# 66-80 data model
ck('Inventory Control catalog owns 11 entities','Inventory Control — 11 thực thể' in data)
ck('entity catalog contains ENT-IC-10 StateTransitionPolicyVersion','`ENT-IC-10`' in data and '`StateTransitionPolicyVersion`' in data)
ck('entity catalog contains ENT-IC-11 StateChangeBasis','`ENT-IC-11`' in data and '`StateChangeBasis`' in data)
polsec=re.search(r'### ENT-IC-10 — StateTransitionPolicyVersion(.*?)(?=\n### ENT-IC-11)',data,re.S).group(1)
bassec=re.search(r'### ENT-IC-11 — StateChangeBasis(.*?)(?=\n## 5\.)',data,re.S).group(1)
ck('policy entity has immutable version identity','state_transition_policy_version_id' in polsec and 'Immutable version identity' in polsec)
ck('policy entity stores canonical transition rules','transition_rules' in polsec and 'permission, reason/evidence, approval route/level, eligibility effect' in polsec)
ck('policy entity stores canonical SHA-256 hash','policy_hash' in polsec and 'SHA-256 canonical payload' in polsec)
ck('basis entity has immutable basis identity','state_change_basis_id' in bassec and 'Immutable request basis identity' in bassec)
ck('basis stores exact source balance slice snapshot','source_balance_slices_snapshot' in bassec and 'balance_id,balance_version,valuation_state,quantity' in bassec)
ck('basis stores policy version and policy hash','state_transition_policy_version_id' in bassec and 'policy_hash' in bassec)
ck('basis snapshots reason evidence date expiry and reservation',all(x in bassec for x in ['reason_snapshot','evidence_snapshot','business_date','expiry_fact_snapshot','reservation_impact_snapshot']))
ck('basis stores canonical SHA-256 basis hash','basis_hash' in bassec and 'SHA-256 canonical basis payload' in bassec)
ck('basis is append-only and not updateable after submit','không được update sau submit' in bassec and 'SUPERSEDED' in bassec)
ck('InventoryMovement preserves valuation state for STATE_TRANSFER','valuation_state_snapshot' in data and 'Bắt buộc với `STATE_TRANSFER`' in data)
ck('basis destination excludes system/other-BJ states','không nhận `EXPIRED/VALUATION_PENDING/RETURN_PENDING/RTV_PENDING` từ user' in bassec)
ck('ApprovalCase data model supports STATE_CHANGE subject','STATE_CHANGE' in data and 'ApprovalCase' in data and 'basis' in data.lower())
# 81-96 shared/technical contracts
bc10=re.search(r'### BC-IO-10.*?(?=\n### BC-IO-11|\n### BC-)',bc,re.S); bc10=bc10.group(0) if bc10 else bc
ck('BC-IO-10 locks exact basis and source balances','immutable `StateChangeBasis`' in bc10 and 'source balances' in bc10)
ck('BC-IO-10 appends STATE_TRANSFER per source slice','STATE_TRANSFER' in bc10 and 'source slice' in bc10)
ck('BC-IO-10 preserves valuation state','valuation_state_snapshot' in bc10 and 'cùng valuation_state' in bc10)
ck('BC-IO-10 reconciles reservation atomically','reconcile reservation capacity atomically' in bc10 and 'cùng transaction' in bc10)
ck('BC-IO-10 does not rewrite active PickAllocation','không rewrite active PickAllocation' in bc10)
ck('BC-IO-10 has ambiguity/stale/policy/basis errors',all(x in bc10 for x in ['STATE_SOURCE_SLICE_AMBIGUOUS','STATE_CHANGE_BASIS_STALE','STATE_POLICY_VERSION_STALE','APPROVAL_BASIS_MISMATCH']))
ck('BC-IC-06 binds state-change approval to exact basis','Với `STATE_CHANGE`, exact `StateChangeBasis`' in bc and 'decision' in bc.lower())
ck('BC-IC-07 creates basis before approval/system route','tạo `StateChangeBasis`/basis hash trước khi route' in bc)
ck('BC-IC-07 says state movement remains system-executed','việc ghi state movement vẫn do system executor BC-IO-10' in bc)
ck('API-C-10 is ChangeInventoryState with exact basis recheck','API-C-10' in tech and 'Exact StateChangeBasis recheck' in tech)
ck('technical contract blocks ambiguous source slice','STATE_SOURCE_SLICE_AMBIGUOUS' in tech and 'không chọn arbitrary valuation slice' in tech)
ck('technical contract includes basis/policy/approval stale errors',all(x in tech for x in ['STATE_CHANGE_BASIS_STALE','STATE_POLICY_VERSION_STALE','APPROVAL_BASIS_MISMATCH']))
ck('technical success writes valuation snapshot with no value movement','movement_kind=STATE_TRANSFER' in tech and 'valuation_state_snapshot' in tech and 'không sinh `InventoryValueMovement`' in tech)
ck('EVT-IO-08 carries basis/policy/slice/reservation evidence','EVT-IO-08' in tech and all(x in tech for x in ['basis','policy','slices','reservation']))
ck('technical contract rejects manual expiry destination','EXPIRED_SYSTEM_DERIVED' in tech)
ck('technical contract preserves same identity for UNKNOWN/retry','UNKNOWN' in tech and ('same' in tech.lower() or 'cùng' in tech.lower()) and 'idempot' in tech.lower())
# 97-108 UI flow/screen/component contracts
ck('UIF09 submit transition routes immutable basis before execution','UIF-09-T06' in flow and 'StateChangeBasis' in flow and 'ACT-COMMON-SUBMIT' in flow)
ck('UIF09 approver transition decides exact basis without stock write','UIF-09-T13' in flow and 'Approver duyệt exact `StateChangeBasis`; **chưa đổi stock**' in flow)
ck('UIF09 execution transition is SYSTEM','UIF-09-T14' in flow and '| `SYSTEM` |' in flow)
ck('UIF09 explicitly has no user-facing ACT-08-STATE CTA','no user-facing `ACT-08-STATE` CTA' in flow)
ck('SCR038 current state is server-authoritative read-only','SERVER_AUTHORITATIVE_READ_ONLY' in scr038 and '| Từ |' in scr038)
ck('SCR038 destination is server-policy validated','USER_INPUT_SERVER_POLICY_VALIDATED' in scr038 and 'StateTransitionPolicyVersion' in scr038)
ck('SCR038 exposes STATE_CHANGE_BASIS_STALE recovery state','STATE_CHANGE_BASIS_STALE' in scr038)
ck('SCR038 canonical destination copy maps DEMO to Dùng thử','`DEMO` hiển thị “Dùng thử”' in scr038 and 'không có `TRIAL/EXPIRED/*_PENDING`' in scr038)
ck('SCR038 marks ACT-08-STATE trace-only system','ACT-08-STATE' in scr038 and 'TRACE_ONLY_SYSTEM' in scr038)
ck('SCR041 PROCESSING means system executor recheck','PROCESSING' in scr041 and 'system executor đang recheck immutable StateChangeBasis' in scr041)
ck('component usage carries v3.10.1 state-change amendment','v3.10.1' in cu and 'StateChangeBasis' in cu and 'StateTransitionPolicyVersion' in cu)
ck('component usage YAML carries v3.10.1 basis/policy mapping','v3.10.1' in cuy and 'StateChangeBasis' in cuy and 'StateTransitionPolicyVersion' in cuy)
# 109-116 trace/registry closure
for i in range(1,5):
    st=next((x for x in trace.get('stories',[]) if x.get('story')==f'UC-09-0{i}'),None)
    ck(f'trace UC09-{i:02d} includes DR178..184 and new entities',st is not None and all(f'T7-DR-{n}' in st.get('decisions',[]) for n in range(178,185)) and all(e in st.get('entities',[]) for e in ['ENT-IC-10','ENT-IC-11']))
ck('contract registry BC-IO-10 is v4.2.6 amendment',find_id(creg,'BC-IO-10').get('version')=='4.2.6-amendment')
ck('contract registry BC-IC-06/07 are v4.2.6 amendments',find_id(creg,'BC-IC-06').get('version')=='4.2.6-amendment' and find_id(creg,'BC-IC-07').get('version')=='4.2.6-amendment')
ck('contract registry contains ENT-IC-10 and ENT-IC-11',find_id(creg,'ENT-IC-10') is not None and find_id(creg,'ENT-IC-11') is not None)
act=find_id(actions,'ACT-08-STATE');ck('ACT-08-STATE registry is system trace-only',act is not None and act.get('ui_visibility')=='TRACE_ONLY_SYSTEM' and 'System executor recheck StateChangeBasis' in act.get('effect',''),act)
# Runtime 117-127
errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1450,'height':1050}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e)))
    html=inline(HTML)
    def reset_page(): p.goto('about:blank');p.set_content(html,wait_until='load',timeout=30000);p.wait_for_timeout(20)
    def go(screen,state='READY',selected='amox'):
        p.evaluate('([s,t,id])=>{activeFlowId="UIF-09";ic09Selected=id;activeScreenId=s;stateByScreen[s]=t;render()}',[screen,state,selected]);p.wait_for_timeout(15)
    def st(): return p.evaluate('()=>({screen:activeScreenId,state:stateByScreen[activeScreenId]})')
    reset_page();go('SCR-036')
    txt=p.locator('#app-screen').inner_text(); ck('runtime list renders Dùng thử and no Trial leakage','Dùng thử' in txt and 'Trial' not in txt and 'TRIAL' not in txt,txt[:500])
    go('SCR-038','READY'); p.evaluate('window.__VET45_V3101__.setDraft({destination:"QUARANTINE",quantity:"5",reason:"",evidence:""});render()')
    ck('runtime current state is read-only and EXPIRED is not a destination',p.locator('[data-v3101-destination][value="EXPIRED"]').count()==0 and p.locator('[data-v3101-destination]').count()>0 and 'Từ' in p.locator('#app-screen').inner_text())
    p.click('[data-v3101-action="submit"]'); ck('runtime missing reason fails validation without mutation',st()['state']=='VALIDATION_ERROR' and p.evaluate('window.__VET45_V3101__.getMovement()') is None,st())
    p.evaluate('stateByScreen["SCR-038"]="READY";window.__VET45_V3101__.setDraft({destination:"QUARANTINE",quantity:"5",reason:"Bao bì rách",evidence:""});render()');p.click('[data-v3101-action="submit"]')
    basis=p.evaluate('window.__VET45_V3101__.getBasis()'); ck('runtime approval submit locks exact basis and creates no movement',st()['state']=='PENDING_APPROVAL' and basis and len(basis['sourceSlices'])==1 and basis['sourceSlices'][0]['valuationState']=='VALUATION_CONFIRMED' and p.evaluate('window.__VET45_V3101__.getMovement()') is None,basis)
    p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-038"]="APPROVAL_REVIEW";render()');p.click('[data-v3101-action="approve"]');decision=p.evaluate('window.__VET45_V3101__.getDecision()');mov0=p.evaluate('window.__VET45_V3101__.getMovement()');ck('runtime approver records decision before stock execution',decision and decision['decision']=='APPROVE' and mov0 is None and st()['state']=='PROCESSING',(decision,st()))
    p.wait_for_timeout(260);mov=p.evaluate('window.__VET45_V3101__.getMovement()');ck('runtime system executor commits movement after recheck',st()['state']=='COMPLETED' and mov and mov['to']=='QUARANTINE' and mov['quantity']==5,(st(),mov))
    ck('runtime movement preserves valuation and creates no value movement',mov and mov['valuationPreserved'] is True and mov['valueMovementCreated'] is False and all(s['valuationStateSnapshot']==s['valuationState'] for s in mov['sourceSlices']),mov)
    ck('runtime eligibility reduction reconciles reservation atomically',mov and mov['reservationImpact']['before']==10 and mov['reservationImpact']['after']==7 and mov['reservationImpact']['shortfall']==3 and mov['reservationImpact']['allocationReviewRequired'] is True,mov.get('reservationImpact') if mov else None)
    reset_page();go('SCR-038','READY');p.evaluate('window.__VET45_V3101__.setDraft({destination:"DEMO",quantity:"2",reason:"Dùng làm mẫu trưng bày",evidence:""});render()');p.click('[data-v3101-action="submit"]');p.wait_for_timeout(260);mov=p.evaluate('window.__VET45_V3101__.getMovement()');dec2=p.evaluate('window.__VET45_V3101__.getDecision()');ck('runtime direct DEMO route completes without synthetic approval',st()['state']=='COMPLETED' and mov and mov['to']=='DEMO' and dec2 is None,(st(),mov,dec2))
    reset_page();go('SCR-038','READY');p.evaluate('window.__VET45_V3101__.setDraft({destination:"QUARANTINE",quantity:"5",reason:"Bao bì rách",evidence:""});render()');p.click('[data-v3101-action="submit"]');p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-038"]="APPROVAL_REVIEW";render()');p.click('[data-v3101-action="reject-open"]');disabled=p.locator('[data-v3101-action="reject-confirm"]').is_disabled();p.fill('[data-v3101-reject-reason]','Chưa đủ bằng chứng');enabled=not p.locator('[data-v3101-action="reject-confirm"]').is_disabled();p.click('[data-v3101-action="reject-confirm"]');ck('runtime reject requires reason, re-enables CTA, and has zero stock effect',disabled and enabled and st()['state']=='REJECTED_EXECUTION' and p.evaluate('window.__VET45_V3101__.getDecision().decision')=='REJECT' and p.evaluate('window.__VET45_V3101__.getMovement()') is None,(disabled,enabled,st()))
    reset_page();go('SCR-038','READY');p.evaluate('window.__VET45_V3101__.setDraft({destination:"DEMO",quantity:"2",reason:"Dùng thử",evidence:""});window.__VET45_V3101__.buildBasis();window.__VET45_V3101__.setStaleOnExecute(true);activeScreenId="SCR-041";stateByScreen["SCR-041"]="PROCESSING";render()');ret=p.evaluate('window.__VET45_V3101__.systemCommit()');ck('runtime stale basis blocks execution and focused browser has no errors',ret is False and st()['state']=='STATE_CHANGE_BASIS_STALE' and p.evaluate('window.__VET45_V3101__.getMovement()') is None and not errors,(st(),errors))
    b.close()

if len(checks)!=127:
    print('INTERNAL QA DEFINITION ERROR: expected 127 checks, got',len(checks));sys.exit(2)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.10.1','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'scope':'Wave 4 / BJ09 forensic semantic, authority-chain, trace, runtime and interaction review','checks':checks,'browserErrors':errors}
(QA/'BJ09-DEEP-REVIEW-QA-v3.10.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'BJ09-DEEP-REVIEW-QA-v3.10.1.md').write_text('\n'.join(['# BJ09 Deep Review QA — v3.10.1','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','',f'Scope: {out["scope"]}.','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
