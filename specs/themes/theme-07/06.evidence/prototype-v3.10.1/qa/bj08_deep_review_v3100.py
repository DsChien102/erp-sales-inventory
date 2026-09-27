#!/usr/bin/env python3
from pathlib import Path
import json,re,sys
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[6]
HTML=ROOT/'specs/themes/theme-07/prototype/html'; QA=HTML/'qa'
T=ROOT/'specs/themes/theme-07'
checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':str(note)[:900]})
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

dec=rd('know-how/decisions/decision-register.md')
bj=rd('srs/02-business-journeys/08-BJ-08-kiem-ke-va-dieu-chinh-chenh-lech.md')
ucdir='srs/05-use-cases/BJ-08-kiem-ke-va-dieu-chinh-chenh-lech'
ucs={i:rd(f'{ucdir}/'+fn) for i,fn in {
1:'UC-08-01-mo-va-khoa-pham-vi.md',2:'UC-08-02-ghi-nhan-lan-dem-mu.md',3:'UC-08-03-dem-lai-va-hoan-thien-bang-chung.md',4:'UC-08-04-duyet-va-dieu-chinh.md',5:'UC-08-05-huy-phien-kiem-ke.md'}.items()}
data=rd('srs/04-data-entities.md');bc=rd('srs/06-shared-behavioral-contracts.md');tech=rd('srs/07-technical-contracts.md')
flow=rd('prototype/flows/UIF-08-BJ-08.md'); overlay=(HTML/'v3100-bj08-semantic-hardening.js').read_text()
screens={i:rd(f'prototype/contracts/screens/SCR-{i:03d}.md') for i in range(42,48)}
cu=rd('prototype/contracts/component-usage/UIF-08-COMPONENT-USAGE.md')
actions=js('prototype/contracts/action-registry.json');reg=js('prototype/contracts/screen-registry.json');cat=js('prototype/contracts/screen-catalog.json');trace=js('harness/trace-index.json');creg=js('harness/contract-registry.json');manifest=json.loads((HTML/'manifest.json').read_text());wb=json.loads((HTML/'workbench-data.json').read_text())
# Baseline/version
ck('candidate manifest is v3.10.0 on parent v3.9.9',manifest.get('version')=='3.10.0' and manifest.get('parentVersion')=='3.9.9')
ck('workbench identifies v3.10.0',wb.get('version')=='3.10.0')
ck('v3.10.0 runtime overlay is loaded once',(HTML/'index.html').read_text().count('v3100-bj08-semantic-hardening.js')==1)
ck('v3.10.0 overlay loads after v3.9.9', (HTML/'index.html').read_text().index('v3100-bj08-semantic-hardening.js')>(HTML/'index.html').read_text().index('v399-bj14-semantic-hardening.js'))
# Decisions
for i in range(171,178): ck(f'DR-{i} exists and is ACTIVE',f'**`T7-DR-{i}`' in dec and re.search(rf'T7-DR-{i}.*?`ACTIVE`',dec,re.S) is not None)
ck('DR171 locks barrier before cutoff','scope barrier' in dec and 'cutoff' in dec.lower())
ck('DR172 establishes CountScopeSnapshot','CountScopeSnapshot' in dec and 'resolved membership' in dec)
ck('DR173 names PhysicalCountKey and unresolved valuation blocker','PhysicalCountKey' in dec and 'COUNT_SCOPE_HAS_UNRESOLVED_VALUATION' in dec)
ck('DR174 locks immutable count rounds','StockCountSubmission' in dec and 'immutable rounds' in dec.lower())
ck('DR175 generalizes ApprovalCase subject','STOCK_COUNT_SESSION' in dec and 'excluded_actor_ids' not in dec or 'contributor' in dec.lower())
ck('DR176 prohibits counter-entered surplus price','Counter không nhập giá' in dec and 'Official Cost' in dec)
ck('DR177 zero variance bypasses approval','variance = 0' in dec and 'không cần approval' in dec)
# BJ semantics
for token in ['CountScopeSnapshot','PhysicalCountKey','CountAdjustmentBasis','PRICE_BASIS_REQUIRED','REQUEST_RECOUNT']:
    ck(f'BJ08 carries {token}',token in bj)
ck('BJ08 carries immutable StockCountSubmission semantics','Immutable FIRST submission' in bj and 'Immutable RECOUNT submission' in bj)
ck('BJ08 zero first count ends without approval','Zero variance' in bj and 'không tạo approval giả' in bj)
ck('BJ08 recount zero ends without approval','RECOUNT' in bj and 'no adjustment' in bj.lower())
ck('BJ08 nonzero routes independent approval','người duyệt độc lập' in bj.lower() and 'approval case' in bj.lower())
ck('BJ08 cancellation preserves evidence','CANCEL' in bj.upper() and 'evidence' in bj.lower())
ck('BJ08 UNKNOWN preserves identity','UNKNOWN' in bj and ('cùng' in bj.lower() or 'same' in bj.lower()))
# UCs actors/anchors/contracts
actors=['Người có quyền mở kiểm kê','Assigned counter','Assigned counter','Eligible independent approver','Người có quyền hủy']
for i,u in ucs.items():
    ck(f'UC08-{i:02d} actor authority explicit',actors[i-1] in u)
    ck(f'UC08-{i:02d} has four stable acceptance anchors',sum(f'as-uc-08-{i:02d}-{n:02d}' in u for n in range(1,5))==4)
ck('UC08-01 orders barrier before cutoff',ucs[1].find('Acquire scope barrier')<ucs[1].find('cutoff_ledger_sequence'))
ck('UC08-01 unresolved valuation is safe rejection','COUNT_SCOPE_HAS_UNRESOLVED_VALUATION' in ucs[1] and 'orphan lock' in ucs[1])
ck('UC08-02 blind DOM contract explicit','DOM/accessibility' in ucs[2] and 'book/variance' in ucs[2])
ck('UC08-02 zero path excludes ApprovalCase','Zero variance' in ucs[2] and 'không tạo ApprovalCase' in ucs[2])
ck('UC08-03 appends immutable recount','immutable recount' in ucs[3].lower() and 'round_no' in ucs[3])
ck('UC08-03 surplus basis blocks approval','PRICE_BASIS_REQUIRED' in ucs[3] and 'lock giữ nguyên' in ucs[3])
ck('UC08-04 approval subject is stock-count session','STOCK_COUNT_SESSION' in ucs[4] and 'excluded_actor_ids' in ucs[4])
ck('UC08-04 risk does not net signs','Σ abs' in ucs[4] and 'không net' in ucs[4])
ck('UC08-04 stale basis has effect NONE','COUNT_APPROVAL_SNAPSHOT_STALE' in ucs[4] and 'effect NONE' in ucs[4])
ck('UC08-05 cancel only session context','SCR-044/SCR-045' in ucs[5] and 'browse list' in ucs[5])
ck('UC08-05 cancel creates no adjustment','Không tạo InventoryOperation adjustment' in ucs[5])
# Data model
ck('Inventory Control owns 9 entities','Inventory Control — 9 thực thể' in data)
ck('CountScopeSnapshot entity exists','ENT-IC-08 — CountScopeSnapshot' in data and 'scope_hash' in data)
ck('StockCountSubmission entity exists','ENT-IC-09 — StockCountSubmission' in data and 'round_no' in data and 'payload_hash' in data)
ck('StockCountSession stores assignment snapshot',all(x in data for x in ['assigned_counter_id','assignment_version','assignment_snapshot']))
ck('StockCountLine uses physical key hash','physical_count_key_hash' in data and 'book_balance_ids_snapshot' in data)
# isolate current StockCountLine section to prove no editable history fields
m=re.search(r'### ENT-IC-05 — StockCountLine(.*?)(?=\n### ENT-IC-06)',data,re.S); line_sec=m.group(1) if m else ''
ck('StockCountLine no longer stores first/recount quantities directly','first_count_quantity' not in line_sec and 'recount_quantity' not in line_sec)
ck('ApprovalCase supports stock-count subject','subject_type' in data and 'STOCK_COUNT_SESSION' in data and 'subject_id' in data)
ck('ApprovalCase operation_id nullable for stock count','operation_id' in data and 'Nullable' in re.search(r'### ENT-IC-02 — ApprovalCase(.*?)(?=\n### ENT-IC-03)',data,re.S).group(1))
ck('ApprovalCase stores excluded actors','excluded_actor_ids' in data)
ck('ApprovalCase supports request recount','REQUEST_RECOUNT' in data and 'predecessor_case_id' in data and 'superseded_by_case_id' in data)
ck('InventoryLock records barrier before cutoff','barrier_acquired_at' in data and 'cutoff_ledger_sequence' in data)
# BC / technical
for token in ['BC-IC-01','BC-IC-02','BC-IC-03','BC-IC-08']: ck(f'{token} present',token in bc)
bc01=re.search(r'### BC-IC-01 — Open stock count(.*?)(?=\n### BC-IC-02)',bc,re.S).group(1)
ck('BC-IC-01 atomic open orders barrier before cutoff',bc01.find('scope barrier')>=0 and bc01.find('scope barrier')<bc01.find('cutoff'))
ck('BC-IC-02 zero variance completes without approval','zero variance' in bc.lower() and 'ApprovalCase' in bc)
ck('BC-IC-03 rechecks risk/value basis','CountAdjustmentBasis' in bc and 'stale' in bc.lower())
ck('BC-IC-08 cancellation preserves immutable evidence','BC-IC-08' in bc and 'evidence' in bc.lower())
for token in ['API-C-14','API-C-15','API-C-16','API-C-27','COUNT_SCOPE_HAS_UNRESOLVED_VALUATION','COUNT_APPROVAL_SNAPSHOT_STALE','COUNT_VALUE_BASIS_STALE']:
    ck(f'technical contract contains {token}',token in tech)
ck('technical lock enforcement covers prospective keys','prospective PhysicalCountKey' in tech)
ck('technical zero variance has no ApprovalCase','Zero variance completes + unlocks atomically without ApprovalCase' in tech)
# Trace and registries
for i in range(1,6):
    st=next((x for x in trace.get('stories',[]) if x.get('story')==f'UC-08-0{i}'),None)
    ck(f'trace UC08-{i:02d} includes DR171..177',st is not None and all(f'T7-DR-{n}' in st.get('decisions',[]) for n in range(171,178)))
ck('contract registry BC-IC-01 amended',find_id(creg,'BC-IC-01').get('version')=='4.2.5-amendment')
ck('contract registry BC-IC-02 immutable submission finality','StockCountSubmission' in find_id(creg,'BC-IC-02').get('finality_semantics',''))
ck('contract registry BC-IC-03 stock-count subject finality','STOCK_COUNT_SESSION' in find_id(creg,'BC-IC-03').get('finality_semantics',''))
act=find_id(actions,'ACT-09-CANCEL');ck('cancel action exact screen ownership',act and act.get('screen_ids')==['SCR-044','SCR-045'],act)
for sid in [f'SCR-{i:03d}' for i in range(42,48)]: ck(f'{sid} current registry is v3.10.0',find_id(reg,sid) is not None and '3.10.0' in str(find_id(reg,sid).get('prototype_status','')))
ck('SCR046 registry does not own cancel','ACT-09-CANCEL' not in (find_id(reg,'SCR-046').get('action_ids') or []))
ck('SCR042 registry does not own cancel','ACT-09-CANCEL' not in (find_id(reg,'SCR-042').get('action_ids') or []))
# legacy catalog parity
sg=find_id(cat,'SG-09'); legacy={x['id']:x for x in sg.get('screens',[])} if sg else {}
ck('legacy list has no cancel',legacy.get('SCR-09-01',{}).get('secondary_action') is None)
ck('legacy count owns cancel',legacy.get('SCR-09-03',{}).get('secondary_action')=='ACT-09-CANCEL')
ck('legacy recount owns cancel',legacy.get('SCR-09-04',{}).get('secondary_action')=='ACT-09-CANCEL')
ck('legacy approval has no cancel',legacy.get('SCR-09-05',{}).get('secondary_action') is None)
# Flow / screens / component contract
ck('UIF08 rendered v3.10.0','RENDERED_v3.10.0' in flow)
ck('UIF08 has 16 transitions',len(re.findall(r'\| `UIF-08-T\d+` \|',flow))==16)
ck('UIF08 zero first count goes to result','UIF-08-T06' in flow and 'no ApprovalCase' in flow)
ck('UIF08 zero recount goes to result','UIF-08-T08' in flow and 'no adjustment' in flow)
ck('UIF08 cancel only count/recount','Cancel chỉ ở session context `SCR-044/SCR-045`' in flow)
ck('UIF08 UNKNOWN hands to BJ17','UIF-08-T16' in flow and 'BJ17' in flow)
ck('SCR044 blind contract excludes book','book/variance/proxy' in screens[44].lower() and 'ACT-09-CANCEL' in screens[44])
ck('SCR045 contract has round and basis status','round' in screens[45].lower() and 'PRICE_BASIS_REQUIRED' in screens[45])
ck('SCR046 contract is independent approval','independent' in screens[46].lower() and 'ACT-09-CANCEL' not in screens[46])
ck('SCR047 has zero/no-adjustment result','ZERO_VARIANCE_NO_ADJUSTMENT' in screens[47])
ck('component usage maps cancel only 044/045','cancellation is contextual on SCR-044/SCR-045 only' in cu)
# Runtime static
for token in ['decisions:[171,172,173,174,175,176,177]','getRoundHistory','COUNT_SCOPE_HAS_UNRESOLVED_VALUATION','SELF_APPROVAL_NOT_ALLOWED','data-v350-action="handoff-unknown"']:
    ck(f'runtime overlay contains {token[:34]}',token in overlay)
ck('runtime validates blank first count','const missing=Object.keys(BOOK).some' in overlay)
ck('runtime validates blank recount','const missing=ids.some' in overlay)
ck('runtime new session resets immutable-round fixture','roundHistory=[]' in overlay and "ic08Counts={amox:'',glove:''}" in overlay)
ck('runtime no counter price input','data-v3100-surplus-price' not in overlay and 'người đếm không nhập giá' in overlay)
# Browser focused interaction + geometry

def inline(root):
    h=(root/'index.html').read_text()
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=root/fn.split('?')[0];h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text()}</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=root/fn.split('?')[0];h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>' if p.exists() else '')
    return h
errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1450,'height':1050});p.set_default_timeout(5000);p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(inline(HTML),wait_until='load',timeout=30000)
    def go(s,st='READY'):p.evaluate('([s,t])=>{activeFlowId="UIF-08";activeScreenId=s;stateByScreen[s]=t;render()}',[s,st]);p.wait_for_timeout(12)
    def state():return p.evaluate('()=>({screen:activeScreenId,state:stateByScreen[activeScreenId]})')
    go('SCR-042');ck('runtime list retains search/filter',p.locator('[data-v350-ic08-list-search]').count()==1 and p.locator('[data-v350-ic08-filter]').count()==3)
    ck('runtime list has no cancel',p.locator('[data-v3100-ic08-action="cancel-open"]').count()==0)
    p.click('[data-v3100-ic08-action="new"]');p.click('[data-v3100-ic08-action="open"]');p.click('[data-v3100-ic08-action="confirm-open"]')
    txt=p.locator('#app-screen').inner_text();ck('runtime blind hides book and variance','Theo sổ' not in txt and 'Chênh lệch' not in txt)
    ck('runtime blind exposes physical states','Bán được' in txt and 'Cách ly' in txt)
    p.click('[data-v3100-ic08-action="submit-first"]');p.click('[data-v3100-ic08-action="confirm-first"]');ck('runtime blank first count rejected',state()['state']=='VALIDATION_ERROR')
    p.evaluate('ic08Counts={amox:"20",glove:"6"};stateByScreen["SCR-044"]="BLIND_COUNT";render()');p.click('[data-v3100-ic08-action="submit-first"]');p.click('[data-v3100-ic08-action="confirm-first"]');ck('runtime zero variance direct result',state()['screen']=='SCR-047' and 'Không cần tạo điều chỉnh' in p.locator('#app-screen').inner_text())
    # fresh nonzero session
    go('SCR-042');p.click('[data-v3100-ic08-action="new"]');p.click('[data-v3100-ic08-action="open"]');p.click('[data-v3100-ic08-action="confirm-open"]');p.evaluate('ic08Counts={amox:"18",glove:"7"};render()');p.click('[data-v3100-ic08-action="submit-first"]');p.click('[data-v3100-ic08-action="confirm-first"]');ck('runtime nonzero first routes recount',state()['screen']=='SCR-045')
    p.click('[data-v3100-ic08-action="submit-recount"]');p.click('[data-v3100-ic08-action="confirm-recount"]');ck('runtime blank recount rejected',state()['state']=='VALIDATION_ERROR')
    p.evaluate('ic08Recounts={amox:"18",glove:"7"};stateByScreen["SCR-045"]="RECOUNT_REQUIRED";render()');p.click('[data-v3100-ic08-action="submit-recount"]');p.click('[data-v3100-ic08-action="confirm-recount"]');ck('runtime nonzero recount routes approval task',state()['screen']=='SCR-042' and state()['state']=='PENDING_APPROVAL')
    go('SCR-046','APPROVAL_REQUIRED');p.evaluate('window.__VET45_V350__.setActor("module");render()');p.click('[data-v3100-ic08-action="approve"]');ck('runtime contributor self-approval blocked',state()['state']=='SELF_APPROVAL_NOT_ALLOWED')
    p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-046"]="APPROVAL_REQUIRED";render()');p.click('[data-v3100-ic08-action="request-review"]');p.fill('[data-v3100-review-reason]','Kiểm lại vị trí hàng');p.click('[data-v3100-ic08-action="confirm-review"]');ck('runtime request recount advances round','Đếm lại lần 2' in p.locator('#app-screen').inner_text())
    hist=p.evaluate('window.__VET45_V3100__.getRoundHistory()');ck('runtime immutable history retains FIRST and RECOUNT',[x['type'] for x in hist]==['FIRST','RECOUNT'],hist)
    go('SCR-044','BLIND_COUNT');p.click('[data-v3100-ic08-action="cancel-open"]');p.fill('[data-v3100-cancel-reason]','Sai phạm vi');p.click('[data-v3100-ic08-action="confirm-cancel"]');ck('runtime cancel returns authoritative cancelled result',state()['screen']=='SCR-047' and state()['state']=='CANCELLED')
    go('SCR-047','UNKNOWN');btn=p.locator('[data-v350-action="handoff-unknown"]');ck('runtime UNKNOWN preserves exact operation identity',btn.count()==1 and btn.get_attribute('data-operation')=='KK-1709-01')
    # all BJ08 screens representative geometry
    bad=[]
    for sid,st in [('SCR-042','READY'),('SCR-043','READY'),('SCR-044','BLIND_COUNT'),('SCR-045','RECOUNT_REQUIRED'),('SCR-046','APPROVAL_REQUIRED'),('SCR-047','COMPLETED')]:
        go(sid,st); x=p.evaluate('''()=>{const r=document.querySelector('#app-screen'),c=r.querySelector('.app-content');return {w:r.offsetWidth,h:r.offsetHeight,x:r.scrollWidth-r.clientWidth,cx:c?(c.scrollWidth-c.clientWidth):0}}''')
        if x['w']!=402 or x['h']!=874 or x['x']>.75 or x['cx']>.75:bad.append((sid,x))
    ck('BJ08 representative screens fit 402x874 without horizontal overflow',not bad,bad)
    ck('BJ08 focused browser has no page errors',not errors,errors)
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.10.0','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'scope':'Wave 4 / BJ08 forensic semantic, trace, runtime and interaction review','checks':checks,'browserErrors':errors}
(QA/'BJ08-DEEP-REVIEW-QA-v3.10.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
(QA/'BJ08-DEEP-REVIEW-QA-v3.10.0.md').write_text('\n'.join(['# BJ08 Deep Review QA — v3.10.0','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','',f'Scope: {out["scope"]}.','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']:print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
