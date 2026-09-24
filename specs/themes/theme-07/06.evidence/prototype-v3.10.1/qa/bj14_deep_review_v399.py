#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v399-bj14-captures'; CAP.mkdir(exist_ok=True)
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
checks=[]; errors=[]; console_errors=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':str(note)[:1600]})
def shot(p,name): p.locator('#device-preview').screenshot(path=str(CAP/name))
def go(p,s,st='READY'):
    p.evaluate('([s,st])=>{activeFlowId="UIF-14";activeScreenId=s;stateByScreen[s]=st;render();}',[s,st])

# source/contract evidence
dec=read('specs/themes/theme-07/know-how/decisions/decision-register.md')
bj=read('specs/themes/theme-07/srs/02-business-journeys/14-BJ-14-tinh-va-cong-bo-gia-von.md')
data=read('specs/themes/theme-07/srs/04-data-entities.md')
bc=read('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md')
tech=read('specs/themes/theme-07/srs/07-technical-contracts.md')
flow=read('specs/themes/theme-07/prototype/flows/UIF-14-BJ-14.md')
ucdir='specs/themes/theme-07/srs/05-use-cases/BJ-14-tinh-va-cong-bo-gia-von'
uc1=read(ucdir+'/UC-14-01-xac-dinh-ky-pham-vi-va-chinh-sach.md')
uc2=read(ucdir+'/UC-14-02-tinh-gia-von-va-phat-hien-blocker.md')
uc3=read(ucdir+'/UC-14-03-ra-soat-ket-qua.md')
uc4=read(ucdir+'/UC-14-04-cong-bo-gia-von.md')
screens={i:read(f'specs/themes/theme-07/prototype/contracts/screens/SCR-{i:03d}.md') for i in [72,73,74,76,77]}
acts=jread('specs/themes/theme-07/prototype/contracts/action-registry.json')
reg=jread('specs/themes/theme-07/prototype/contracts/screen-registry.json')
creg=jread('specs/themes/theme-07/harness/contract-registry.json')
trace=jread('specs/themes/theme-07/harness/trace-index.json')
manifest=jread('specs/themes/theme-07/prototype/html/manifest.json')
index=read('specs/themes/theme-07/prototype/html/index.html')
overlay=read('specs/themes/theme-07/prototype/html/v399-bj14-semantic-hardening.js')

ck('Decision register is v4.2.4 costing-run amendment','v4.2.4' in dec and 'COSTING_RUN_DEEP_REVIEW_AMENDMENT' in dec)
ck('Approved decisions T7-DR-164..170 are registered',all(f't7-dr-{i}' in dec.lower() for i in range(164,171)))
ck('Decision chain preserves prior 001..163','T7-DR-001' in dec and 'T7-DR-163' in dec)
ck('BJ14 locks unified valuation timeline','cutoff_valuation_sequence' in bj and 'valuation_sequence + within_transaction_ordinal' in bj)
ck('BJ14 locks ProductCostResult as authoritative per Product','ProductCostResult' in bj and 'run totals chỉ là aggregate' in bj)
ck('BJ14 successor posts incremental reconciliation only','incremental reconciliation delta' in bj and 'Rerun cùng facts phải ra delta 0' in bj)
ck('BJ14 separates run/calculation/posting periods',all(x in bj for x in ['run_type','calculation_period_id','posting_period_id']))
ck('BJ14 forbids Official Cost backdate before publication','không được backdate trước publication commit' in bj)
ck('BJ14 dirty scope is exact Product + posting-period set','Product + posting period' in bj and 'dirty_scope_snapshot/version/hash' in bj)
ck('BJ14 edge cases include negative and NO_NEW_COST_BASIS',all(x in bj for x in ['NEGATIVE_QUANTITY','NEGATIVE_VALUATION_RESULT','NO_NEW_COST_BASIS']))
ck('InventoryMovement has common valuation ordering',all(x in data for x in ['valuation_sequence','within_transaction_ordinal']))
ck('InventoryValueMovement shares common valuation ordering',data.count('valuation_sequence')>=2 and data.count('within_transaction_ordinal')>=2)
ck('CostCalculationRun stores run type and separate periods',all(x in data for x in ['run_type','calculation_period_id','posting_period_id','scope_origin']))
ck('CostCalculationRun stores authoritative dirty scope and cutoff',all(x in data for x in ['dirty_scope_snapshot','dirty_scope_version','dirty_scope_hash','cutoff_valuation_sequence']))
ck('ProductCostResult entity exists','ENT-IV-09' in data and 'ProductCostResult' in data)
ck('ProductCostResult stores baseline/target/delta hashes',all(x in data for x in ['target_cumulative_cogs_vnd','authoritative_cogs_baseline_vnd','cogs_reconciliation_delta_vnd','target_ending_inventory_value_vnd','authoritative_carrying_value_vnd','ending_inventory_reconciliation_delta_vnd','result_hash']))
ck('OfficialCostVersion no-backdate rule exists','effective_from' in data and 'không được trước `published_at`' in data)
ck('ValuationAdjustmentBatch snapshots reconciliation cutoff/baseline','cutoff_valuation_sequence' in data and 'reconciliation_baseline_hash' in data)
ck('BC-IV-02 is calculate-only/no ledger mutation','BC-IV-02' in bc and '**không ledger mutation**' in bc)
ck('BC-IV-02 calculates both methods on ordered timeline','valuation_sequence + within_transaction_ordinal' in bc and 'moving/periodic weighted average' in bc)
ck('BC-IV-03 publishes per-Product incremental deltas','target cumulative COGS - authoritative COGS already posted' in bc and 'target ending inventory value - current authoritative carrying value' in bc)
ck('BC-IV-03 only creates non-zero adjustment lines','create only non-zero adjustment lines' in bc)
ck('BC-IV-03 clears exact dirty causes','clear exactly reconciled Product+posting-period dirty causes' in bc)
ck('BC-IV-03 blocks backdated effective time','COST_EFFECTIVE_TIME_IN_PAST' in bc)
ck('UC14-03 is read-only API-Q-10','API-Q-10' in uc3 and 'read-only review' in uc3)
ck('UC14-03 does not own BC-IV-03','BC-IV-03' not in uc3.split('## Wave 3 BJ14 deep-review lock')[0])
ck('UC14-03 has no mutation UNKNOWN in deep-review lock','không có mutation UNKNOWN' in uc3)
ck('UC14-04 owns BC-IV-03 publish','BC-IV-03' in uc4 and 'PublishInventoryCost' in uc4)
ck('UC14-04 rechecks hashes/period/effective time','run_input_hash' in uc4 and 'ProductCostResult hash' in uc4 and 'effective-time rule' in uc4)
ck('UIF14 active route excludes SCR-075','SCR-075' in flow and 'retired khỏi active UIF14' in flow)
ck('UIF14 review is navigation then publish mutation','S074 -->|READY_FOR_REVIEW| S076' in flow and 'MUTATION: ACT-14-PUBLISH' in flow)
ck('UIF14 guard says dirty scope source-owned','source-owned' in flow and 'user không tùy ý bỏ Product' in flow)
ck('SCR072 contract traces authoritative dirty work','dirty' in screens[72].lower() and 'posting' in screens[72].lower())
ck('SCR073 contract locks dirty scope/read-only','dirty' in screens[73].lower() and 'read-only' in screens[73].lower())
ck('SCR074 contract exposes ProductCostResult aggregation','ProductCostResult' in screens[74])
ck('SCR076 contract is read-only final review','read-only' in screens[76].lower())
ck('SCR077 contract is authoritative result/UNKNOWN-safe','authoritative' in screens[77].lower() and 'UNKNOWN' in screens[77])
ck('ACT-14-CALCULATE remains BC-IV-02',find_id(acts,'ACT-14-CALCULATE').get('bc')=='BC-IV-02')
ck('ACT-14-PUBLISH remains BC-IV-03',find_id(acts,'ACT-14-PUBLISH').get('bc')=='BC-IV-03')
ck('Harness BC-IV-03 trace owns UC14-04 only',find_id(creg,'BC-IV-03').get('stories')==['UC-14-04'])
ck('Harness API-Q-10 now traces UC14-03','UC-14-03' in (find_id(creg,'API-Q-10').get('stories') or []))
ck('Harness API-C-22 publish traces UC14-04 only',find_id(creg,'API-C-22').get('stories')==['UC-14-04'])
# trace index structures
story14=next(x for x in trace.get('stories',[]) if x.get('story')=='UC-14-03')
ck('Trace index UC14-03 has no mutation behavioral contract',story14.get('contracts')==[])
links=[]
for v in trace.values():
    if isinstance(v,list): links.extend([x for x in v if isinstance(x,dict) and x.get('uc')=='UC-14-03'])
ck('Trace index UC14-03 points to API-Q-10',any(x.get('api')=='API-Q-10' and not x.get('bc') for x in links),links[:2])
ck('Current manifest identifies BJ14 lock candidate',manifest.get('version')=='3.9.9' and manifest.get('status')=='WAVE_3_BJ14_DEEP_REVIEW_LOCK_CANDIDATE')
ck('v399 assets load after v398 assets',index.index('v399-bj14-semantic-hardening.css')>index.index('v398-bj13-semantic-hardening.css') and index.index('v399-bj14-semantic-hardening.js')>index.index('v398-bj13-semantic-hardening.js'))
ck('Runtime overlay declares approved BJ14 decision set','decisions:[164,165,166,167,168,169,170]' in overlay)
ck('Runtime overlay materializes ProductCostResult sample semantics','productResults' in overlay and 'NO_NEW_COST_BASIS' in overlay)
ck('Runtime overlay binds runInputHash/productResultSetHash','runInputHash' in overlay and 'productResultSetHash' in overlay)
ck('Runtime overlay uses authoritative dirty scope','scopeOrigin' in overlay and 'DIRTY_SCOPE' in overlay and 'v399-locked-scope' in overlay)
ck('Runtime overlay publishes command-authoritative result fields','dirtyCausesCleared' in overlay and 'officialCostVersions' in overlay and 'reconciledProducts' in overlay)
ck('Runtime overlay no longer backdates ready run','r.effectiveAt="Khi công bố"' in overlay)

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1080}); p.set_default_timeout(7000)
    p.on('pageerror',lambda e:errors.append(str(e))); p.on('console',lambda m: console_errors.append(m.text) if m.type=='error' else None)
    p.set_content(inline_html(),wait_until='load',timeout=30000)
    ck('v399 runtime overlay loaded',p.evaluate('window.__VET45_V399__?.version')=='3.9.9')
    # 072
    go(p,'SCR-072'); txt=p.locator('#app-screen').inner_text(); shot(p,'SCR-072-READY.png')
    ck('SCR072 shows dirty work in business terms','Cần tính lại' in txt and 'nguyên nhân cần đối soát' in txt,txt[:1200])
    ck('SCR072 does not expose hashes/sequences',not any(x in txt.lower() for x in ['hash','valuation_sequence','dirty_scope']),txt[:1200])
    # DIRTY row -> setup
    p.locator('[data-val14-run="COST-0903"]').click(); txt=p.locator('#app-screen').inner_text(); shot(p,'SCR-073-DIRTY.png')
    ck('Dirty row opens setup',p.evaluate('activeScreenId')=='SCR-073')
    ck('SCR073 dirty scope is read-only information group',p.locator('[data-val14-scope]').count()==0 and 'Phạm vi cần tính lại' in txt,txt[:1400])
    ck('SCR073 separates calculation/posting period language','Kỳ tính' in txt and 'Kỳ ghi nhận' in txt,txt[:1400])
    # existing ready result
    p.evaluate("()=>{val14SelectedRunId='COST-0826';activeScreenId='SCR-074';stateByScreen['SCR-074']='READY';render();}"); txt=p.locator('#app-screen').inner_text(); shot(p,'SCR-074-READY.png')
    ck('SCR074 presents Product result counts','Sản phẩm' in txt and 'Có thay đổi' in txt,txt[:1800])
    ck('SCR074 presents per-product result rows','Nobivac DHPPi' in txt and 'Amoxicillin 500mg' in txt and 'Găng tay khám' in txt,txt[:2600])
    ck('SCR074 presents incremental differences','Chênh lệch cần ghi' in txt and 'Giá vốn xuất' in txt and 'Giá trị tồn cuối' in txt,txt[:2200])
    ck('SCR074 effective copy is not backdated','Hiệu lực giá vốn\nKhi công bố' in txt or ('Hiệu lực giá vốn' in txt and 'Khi công bố' in txt),txt[:2200])
    # review
    p.locator('[data-val14-action="review-publish"]').click(); txt=p.locator('#app-screen').inner_text(); shot(p,'SCR-076-READY.png')
    ck('SCR076 review opens only after ready result',p.evaluate('activeScreenId')=='SCR-076')
    ck('SCR076 states effective-time guard','Không sớm hơn thời điểm công bố' in txt,txt[:2200])
    ck('SCR076 has one publish action',p.locator('[data-val14-action="publish"]').count()==1)
    ck('SCR076 has no method override control',p.locator('[data-val14-method], [name="method"]').count()==0)
    # stale freshness
    p.evaluate('()=>{val14ApplyInputChange();stateByScreen["SCR-076"]="READY";render();}'); txt=p.locator('#app-screen').inner_text()
    ck('Stale run cannot publish and requires successor','Dữ liệu đầu vào đã thay đổi' in txt and p.locator('[data-val14-action="publish"]').count()==0 and p.locator('[data-val14-action="successor"]').count()==1,txt[:1600])
    # restore fresh and publish
    p.evaluate("()=>{const r=val14Current();r.status='READY_FOR_REVIEW';val14PublishReviewVersion=r.runInputHash;stateByScreen['SCR-076']='READY';render();}")
    p.locator('[data-val14-action="publish"]').click(); txt=p.locator('#app-screen').inner_text(); shot(p,'SCR-077-COMPLETED.png')
    ck('Publish reaches terminal SCR077',p.evaluate('activeScreenId')=='SCR-077')
    ck('SCR077 uses command-authoritative publication facts','Lần tính' in txt and 'Sản phẩm đã đối soát' in txt and 'Phiên bản giá vốn mới' in txt,txt[:2200])
    ck('SCR077 effective timestamp is publication time','17/09/2026 · 08:41' in txt,txt[:2200])
    # unknown
    go(p,'SCR-077','UNKNOWN'); txt=p.locator('#app-screen').inner_text()
    ck('UNKNOWN explicitly forbids resubmission','Không gửi lại lệnh công bố' in txt and p.locator('[data-val14-action="publish"]').count()==0,txt[:1600])
    ck('BJ14 runtime has no browser/page errors',not errors and not console_errors,{'page':errors,'console':console_errors})
    b.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.9','scope':'Wave 3 / BJ14 deep forensic review','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'pageErrors':errors,'consoleErrors':console_errors,'captures':sorted(x.name for x in CAP.glob('*.png'))}
(QA/'BJ14-DEEP-REVIEW-QA-v3.9.9.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
(QA/'BJ14-DEEP-REVIEW-QA-v3.9.9.md').write_text('\n'.join(['# BJ14 Deep Review QA — v3.9.9','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','',f'Captures: {len(out["captures"])}','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
