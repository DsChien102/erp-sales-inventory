#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v398-bj13-captures'; CAP.mkdir(exist_ok=True)

def read(rel): return (PKG/rel).read_text(encoding='utf-8')
def jread(rel): return json.loads((PKG/rel).read_text(encoding='utf-8'))
def find_id(o,target):
    if isinstance(o,dict):
        if o.get('id')==target:return o
        for v in o.values():
            r=find_id(v,target)
            if r:return r
    elif isinstance(o,list):
        for v in o:
            r=find_id(v,target)
            if r:return r
    return None

def inline_html():
    h=(ROOT/'index.html').read_text(encoding='utf-8')
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
        p=ROOT/fn.split('?')[0]
        h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text(encoding="utf-8")}</style>' if p.exists() else '',h,count=1)
    for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
        p=ROOT/fn.split('?')[0]
        h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
    return h

checks=[]; errors=[]; console_errors=[]; shots=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':str(note)[:1800]})
def shot(p,name,label):
    p.locator('#device-preview').screenshot(path=str(CAP/name));shots.append({'file':name,'label':label})

def go(p,screen,state='READY'):
    p.evaluate('([s,st])=>{activeFlowId="UIF-13";activeScreenId=s;stateByScreen[s]=st;render();}',[screen,state])

# Static authority / semantic traceability
bj=read('specs/themes/theme-07/srs/02-business-journeys/13-BJ-13-ghi-nhan-chi-phi-mua-den-muon.md')
bc=read('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md')
data=read('specs/themes/theme-07/srs/04-data-entities.md')
tech=read('specs/themes/theme-07/srs/07-technical-contracts.md')
dec=read('specs/themes/theme-07/know-how/decisions/decision-register.md')
flow=read('specs/themes/theme-07/prototype/flows/UIF-13-BJ-13.md')
uc1=read('specs/themes/theme-07/srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-01-xac-dinh-nguon-va-pham-vi.md')
uc2=read('specs/themes/theme-07/srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-02-tinh-va-phan-bo-chi-phi.md')
uc3=read('specs/themes/theme-07/srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-03-xac-nhan-ghi-nhan-chi-phi.md')
screens={i:read(f'specs/themes/theme-07/prototype/contracts/screens/SCR-{i:03d}.md') for i in range(85,90)}
manifest=jread('specs/themes/theme-07/prototype/html/manifest.json')
acts=jread('specs/themes/theme-07/prototype/contracts/action-registry.json')
reg=jread('specs/themes/theme-07/prototype/contracts/screen-registry.json')
wb=jread('specs/themes/theme-07/prototype/html/workbench-data.json')
inner=read('specs/themes/theme-07/prototype/html/index.html')
js=read('specs/themes/theme-07/prototype/html/v398-bj13-semantic-hardening.js')

ck('Decision register version is v4.2.3 late-cost amendment','v4.2.3' in dec and 'LATE_LANDED_COST_DEEP_REVIEW_AMENDMENT' in dec)
ck('Approved BJ13 decisions T7-DR-157..163 are registered',all(f'T7-DR-{i}' in dec for i in range(157,164)))
ck('Decision range is continuous through 163','T7-DR-163' in dec and '163 quyết định' in dec)
ck('BJ13 stable economic identity is source_component_key independent of revision','source_component_key' in bj and 'revision không tạo cost mới' in bj)
ck('BJ13 target scope is authoritative source/policy contract','target_scope_key/version/hash' in bj and 'authoritative target scope' in bj.lower())
ck('BJ13 allocation targets 1..N ValuationExposure','1..N valuation exposures' in bj or '1..N `ValuationExposure`' in bj)
ck('BJ13 immutable metric uses initial/direct value or normalized quantity','initial/direct value' in bj and 'normalized quantity' in bj)
ck('BJ13 rounding residual uses stable exposure order','stable exposure order' in bj and 'row order UI' in bj)
ck('BJ13 freshness rechecks complete basis and allocation hashes','late_cost_basis_hash + allocation_hash' in bj)
ck('BJ13 one source component has one DIRECT/LATE accounting route','DIRECT/LATE routing' in bj and 'một source component có đúng một accounting route' in bj)
ck('BJ13 per-allocation periods and dirty Product+posting period are explicit','original/posting period' in bj and 'Product + posting period' in bj)
ck('BJ13 supports 1..N posting-period adjustment batches','1..N adjustment batch' in bj)

ck('BC-IV-06 input uses stable key, revision, route, scope and exposure versions',all(x in bc for x in ['source_component_key','source revision/evidence','target-scope contract','expected exposure/metric/period versions']))
ck('BC-IV-06 blocks LATE preview until all target exposures initial-valued','mọi target exposure đã có initial valuation' in bc)
ck('BC-IV-06 derives late_cost_basis_hash and allocation_hash',all(x in bc for x in ['late_cost_basis_hash','allocation_hash','stable exposure order']))
ck('BC-IV-04 dedups by stable economic key, not revision','dedup theo **stable economic key**' in bc)
ck('BC-IV-04 creates 1..N posting-period batches atomically','1..N `LATE_LANDED_COST` ValuationAdjustmentBatch' in bc and 'all-or-nothing' in bc)
ck('BC-IV-04 dirty scope is Product + posting period','Product + posting period' in bc)
ck('BC-IV-04 does not auto-publish Official Cost','không auto-publish Official Cost' in bc)

ck('LateLandedCost entity stores stable source_component_key','source_component_key' in data and 'economic source component' in data.lower())
ck('LateLandedCost source revision is provenance/freshness only','source_revision' in data and 'provenance/freshness only' in data.lower())
ck('LateLandedCost uniqueness is tenant + stable source_component_key','Unique `(tenant_id, source_component_key)`' in data)
ck('LateLandedCost stores target scope key/version/hash',all(x in data for x in ['target_scope_key','target_scope_version','target_scope_hash']))
ck('LateLandedCost stores late_cost_basis_hash and allocation_hash',all(x in data for x in ['late_cost_basis_hash','allocation_hash']))
ck('LateLandedCost stores 1..N adjustment_batch_ids','adjustment_batch_ids' in data and '1..N batch IDs' in data)
ck('ValuationExposure is explicitly defined as immutable derived target','ValuationExposure' in data and 'immutable' in data.lower())
ck('Allocation stores valuation exposure key/version/hash',all(x in data for x in ['valuation_exposure_key','valuation_exposure_version','valuation_exposure_hash']))
ck('Allocation stores initial-valued quantity/value and RV lineage',all(x in data for x in ['initial_valued_base_quantity','initial_direct_value_vnd','receipt_valuation_references']))
ck('Allocation stores metric snapshot and stable-order rounding',all(x in data for x in ['allocation_metric','metric_version','metric_hash','stable exposure order']))
ck('Allocation natural key uses stable component + exposure, not revision','stable source_component_key + valuation_exposure_key' in data)
ck('Allocation stores receipt business date, original period and posting period',all(x in data for x in ['receipt_business_date','original_period_id','posting_period_id']))
ck('Allocation dirty scope is Product + posting period','Product + posting period' in data)

ck('Technical matrix API-Q-12 exposes stable key/scope/exposure/metric/period preview','API-Q-12' in tech and 'Stable component/route' in tech and 'ValuationExposure/metric snapshots' in tech)
ck('Technical matrix API-C-23 writes 1..N posting-period batches','1..N posting-period adjustment batches/value movements' in tech)
ck('BJ13 payload contract exists','### 5.3 BJ13 late landed cost payload contract' in tech)
ck('Preview payload uses initial/direct value before previous late costs','before prior late-cost adjustments' in tech)
ck('Preview timeout is safe refetch, not business UNKNOWN','safe refetch, not business UNKNOWN' in tech)
ck('Commit rejects any source/tax/FX/policy/scope/exposure/metric/period change','Any selected source/tax/FX/policy/scope/exposure/metric/period change' in tech)
ck('Commit economic uniqueness excludes source revision','source revision is **not** part of economic uniqueness' in tech)
ck('EVT-IV-05 carries stable key, hashes, batch IDs and per-allocation periods','stable `source_component_key`' in tech and '`adjustment_batch_ids`' in tech and 'per-allocation `{receipt_business_date, original_period_id, posting_period_id}`' in tech)

ck('UC13-01 active mapping is SCR-085/086','SCR-085' in uc1 and 'SCR-086' in uc1 and 'SCR-014' not in uc1.split('## Wave 3 semantic lock')[-1])
ck('UC13-02 active mapping is SCR-087','SCR-087' in uc2 and 'SCR-018' not in uc2.split('## Wave 3 semantic lock')[-1])
ck('UC13-03 active mapping is SCR-088/089','SCR-088' in uc3 and 'SCR-089' in uc3)
ck('All five BJ13 screen contracts carry Wave 3 semantic lock',all('Wave 3 deep-review lock' in screens[i] for i in range(85,90)))
ck('UIF-13 flow carries Wave 3 semantic lock','semantic lock' in flow and 'v3.9.8' in flow)
ck('Screen registry maps SCR-085/086 to UC-13-01',find_id(reg,'SCR-085')['related_use_cases']==['UC-13-01'] and find_id(reg,'SCR-086')['related_use_cases']==['UC-13-01'])
ck('Screen registry maps SCR-087 to UC-13-02',find_id(reg,'SCR-087')['related_use_cases']==['UC-13-02'])
ck('Screen registry maps SCR-088/089 to UC-13-03',find_id(reg,'SCR-088')['related_use_cases']==['UC-13-03'] and find_id(reg,'SCR-089')['related_use_cases']==['UC-13-03'])
ck('Workbench maps BJ13 screens consistently',find_id(wb,'SCR-085')['uc']==['UC-13-01'] and find_id(wb,'SCR-087')['uc']==['UC-13-02'] and find_id(wb,'SCR-089')['uc']==['UC-13-03'])
a=find_id(acts,'ACT-03-RECORD-LATE-COST')
ck('Action registry late-cost commit references v3.9.8 complete hash recheck','v3.9.8' in a.get('harness_note','') and 'late_cost_basis_hash + allocation_hash' in a.get('confirmation',''))
ck('Inner HTML loads v398 BJ13 overlay after v397','v398-bj13-semantic-hardening.js' in inner and inner.find('v398-bj13-semantic-hardening.js')>inner.find('v397-bj03-semantic-hardening.js'))
ck('v398 runtime overlay exposes approved semantic helpers',all(x in js for x in ['lateCostBasisHash','allocationHash','metricSnapshot','dirtyScopes','periodGroups','economicIdentity','touchExposure','shuffleTargets']))
ck('Current manifest is v3.9.8 on parent v3.9.7',manifest.get('version')=='3.9.8' and manifest.get('parent')=='3.9.7')
ck('Current manifest product approval targets BJ13 deep review',manifest.get('productApproval')=='BJ13_DEEP_REVIEW_QA_v3.9.8')

# Runtime / UX / deterministic semantics
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.on('console',lambda m: console_errors.append(m.text) if m.type=='error' else None)
    p.set_default_timeout(8000); p.set_content(inline_html(),wait_until='load',timeout=30000)
    ck('Runtime identifies v3.9.8',p.evaluate('window.__VET45_PROTOTYPE__.version')=='3.9.8')
    ck('v3.9.8 BJ13 helper is loaded',p.evaluate('typeof window.val13V398')=='object')

    go(p,'SCR-085')
    txt=p.locator('#app-screen').inner_text()
    actionable=p.locator('[data-val13-task="LC13-001"]'); waiting=p.locator('[data-val13-task="LC13-005"]')
    ck('Actionable late-cost row has no redundant normal-state badge',actionable.count()==1 and 'Có thể xử lý' not in actionable.inner_text(), actionable.inner_text() if actionable.count() else 'missing')
    ck('Waiting for initial valuation is explicit and non-actionable',waiting.count()==1 and waiting.get_attribute('aria-disabled')=='true' and 'Đang chờ' in waiting.inner_text(),waiting.inner_text() if waiting.count() else 'missing')
    ck('Undefined aging text is removed from worklist','Chờ 4 ngày' not in txt and 'Chờ 6 ngày' not in txt,txt[:1400])
    shot(p,'01-SCR085-WORKLIST.png','BJ13 worklist — only exception state is emphasized')

    p.evaluate("()=>{val13SelectedTaskId='LC13-001';val13ResetTaskDraft(val13Current());activeFlowId='UIF-13';activeScreenId='SCR-086';stateByScreen['SCR-086']='READY';render();}")
    txt=p.locator('#app-screen').inner_text()
    ck('Source scope UI hides raw source revision','Lần cập nhật nguồn' not in txt and 'sourceVersion' not in txt,txt[:1400])
    ck('Source scope UI hides fixture evidence filename','VC-8842.pdf' not in txt,txt[:1400])
    ck('Fixed authoritative scope has no user toggle controls',p.locator('[data-val13-target]').count()==0 and p.locator('[data-valuation-exposure]').count()==3)
    ck('Fixed scope shows source-linked business rows','Nobivac DHPPi' in txt and 'Amoxicillin LA' in txt and 'Vaccine Canine X' in txt,txt[:1400])
    shot(p,'02-SCR086-FIXED-SCOPE.png','BJ13 source/policy-authoritative fixed target scope')

    # Stable economic identity but revision change invalidates basis.
    before=p.evaluate("()=>({key:val13V398.economicIdentity(),basis:val13V398.lateCostBasisHash(),rev:val13Current().sourceVersion})")
    p.evaluate('()=>val13ApplySourceUpdate()')
    after=p.evaluate("()=>({key:val13V398.economicIdentity(),basis:val13V398.lateCostBasisHash(),rev:val13Current().sourceVersion})")
    ck('Source revision preserves economic identity',before['key']==after['key'] and after['rev']==before['rev']+1,(before,after))
    ck('Source revision changes complete basis freshness hash',before['basis']!=after['basis'],(before,after))

    # Fresh page for deterministic allocation.
    p.goto('about:blank'); p.set_content(inline_html(),wait_until='load',timeout=30000)
    p.evaluate("()=>{val13SelectedTaskId='LC13-001';val13ResetTaskDraft(val13Current());val13Current().selectedMethod='FIXTURE_VALUE';activeFlowId='UIF-13';activeScreenId='SCR-087';stateByScreen['SCR-087']='READY';render();}")
    a1=p.evaluate("()=>Object.fromEntries(val13V398.allocate().map(x=>[x.valuationExposureKey,x.allocatedAmount]))")
    p.evaluate('()=>val13V398.shuffleTargets()')
    a2=p.evaluate("()=>Object.fromEntries(val13V398.allocate().map(x=>[x.valuationExposureKey,x.allocatedAmount]))")
    ck('Allocation is invariant to UI/source row order',a1==a2,(a1,a2))
    metric_ok=p.evaluate("()=>val13V398.allocate().every(x=>x.allocationMetric.unit==='initial_direct_value_vnd' && x.allocationMetric.metricValue===x.initialDirectValue)")
    ck('Value allocation metric uses immutable initial direct value',metric_ok)
    dirty=p.evaluate('()=>val13V398.dirtyScopes().map(x=>x.label)')
    ck('Dirty scopes are Product + posting period',all('09/2026' in x for x in dirty) and not any('hộp' in x or 'chai' in x or 'lọ' in x for x in dirty),dirty)
    txt=p.locator('#app-screen').inner_text()
    ck('Allocation helper avoids architecture narration','Áp dụng chính sách phân bổ hiện hành' not in txt,txt[:1300])
    shot(p,'03-SCR087-ALLOCATION.png','BJ13 deterministic allocation preview')

    # Open review normally then mutate exposure to prove hash-based stale guard.
    p.locator('[data-val13-action="open-review"]').click()
    ck('Normal flow reaches final review',p.evaluate('activeScreenId')=='SCR-088')
    txt=p.locator('#app-screen').inner_text()
    ck('Review prioritizes amount, method, allocation, period and dirty scope',all(x in txt for x in ['Chi phí sẽ ghi','Phương pháp','Phân bổ sẽ ghi','Kỳ ghi nhận','Cần tính lại']),txt[:1800])
    shot(p,'04-SCR088-REVIEW.png','BJ13 final review — decision-relevant financial facts only')
    p.evaluate("()=>val13V398.touchExposure('LC13-T1')")
    p.locator('[data-val13-action="confirm-late-cost"]').click()
    stale_txt=p.locator('#app-screen').inner_text()
    ck('Changed valuation exposure invalidates review before mutation',p.evaluate("stateByScreen['SCR-088']")=='SOURCE_CHANGED' and 'đã thay đổi' in stale_txt.lower(),stale_txt[:1200])

    # Clean commit and result.
    p.goto('about:blank'); p.set_content(inline_html(),wait_until='load',timeout=30000)
    p.evaluate("()=>{val13SelectedTaskId='LC13-001';val13ResetTaskDraft(val13Current());val13Current().selectedMethod='FIXTURE_VALUE';activeFlowId='UIF-13';activeScreenId='SCR-087';stateByScreen['SCR-087']='READY';render();}")
    p.locator('[data-val13-action="open-review"]').click(); p.locator('[data-val13-action="confirm-late-cost"]').click()
    ck('Clean commit reaches authoritative result',p.evaluate('activeScreenId')=='SCR-089' and p.evaluate("stateByScreen['SCR-089']")=='COMPLETED')
    res=p.evaluate('()=>val13LastResult')
    ck('Commit result preserves stable source component identity',res.get('sourceComponentKey')=='LCOMP-001',res.get('sourceComponentKey'))
    ck('Commit result persists basis and allocation hashes',bool(res.get('lateCostBasisHash')) and bool(res.get('allocationHash')))
    ck('Commit result returns posting-period adjustment batches',len(res.get('adjustmentBatches',[]))>=1,res.get('adjustmentBatches'))
    result_txt=p.locator('#app-screen').inner_text()
    ck('Result dirty scope is Product + posting period, not UOM','09/2026' in result_txt and 'Cần tính lại' in result_txt, result_txt[:1800])
    ck('Result does not expose raw revision/hash/operation identity',not any(x in result_txt.lower() for x in ['source revision','sourceversion','late_cost_basis_hash','allocation_hash','operationid','lần cập nhật nguồn']),result_txt[:1800])
    ck('Result does not narrate BJ14 implementation','BJ14' not in result_txt and 'successor' not in result_txt.lower(),result_txt[:1800])
    shot(p,'05-SCR089-RESULT.png','BJ13 authoritative committed result')

    # Period grouping capability: mutate one exposure to another posting period and ensure multi-batch grouping is deterministic.
    p.goto('about:blank'); p.set_content(inline_html(),wait_until='load',timeout=30000)
    groups=p.evaluate("()=>{val13SelectedTaskId='LC13-001';const t=val13Current();t.targets[2].postingPeriod='10/2026';t.targets[2].originalPeriod='10/2026';return val13V398.periodGroups(t).map(g=>g.postingPeriod).sort();}")
    ck('One late-cost component can resolve 1..N posting-period groups',groups==['09/2026','10/2026'],groups)

    # Financial masking must not leave monetary/source-sensitive facts in DOM.
    go(p,'SCR-087','FINANCIAL_MASKED')
    masked=p.locator('#app-screen').inner_text()
    ck('FINANCIAL_MASKED is server-style masked surface','Không có quyền xem dữ liệu tài chính' in masked and '1.200.000' not in masked and 'VC-8842' not in masked,masked[:1000])
    ck('No page errors in BJ13 deep-review runtime',not errors,errors)
    ck('No console errors in BJ13 deep-review runtime',not console_errors,console_errors)
    b.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.8','scope':'Wave 3 / BJ13 Deep Review','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'consoleErrors':console_errors,'captures':shots}
(QA/'BJ13-DEEP-REVIEW-QA-v3.9.8.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'BJ13-DEEP-REVIEW-QA-v3.9.8.md').write_text('\n'.join(['# BJ13 Deep Review QA — v3.9.8','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','','Scope: approved D13-01…D13-07 / T7-DR-157…163 propagated through BJ/UC/contracts/entities/technical payloads/screens/runtime.','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' for x in checks]+['','## Captures']+[f'- `{s["file"]}` — {s["label"]}' for s in shots])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'],'page_errors',len(errors),'console_errors',len(console_errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
