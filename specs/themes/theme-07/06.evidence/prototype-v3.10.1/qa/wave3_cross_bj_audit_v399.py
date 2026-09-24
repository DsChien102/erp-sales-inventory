#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
QA=Path(__file__).resolve().parent; HTML=QA.parent; ROOT=Path(__file__).resolve().parents[6]
def r(rel):return (ROOT/rel).read_text(encoding='utf-8')
def inline_html():
 h=(HTML/'index.html').read_text();h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
 for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
  p=HTML/fn.split('?')[0];h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text()}</style>' if p.exists() else '',h,count=1)
 for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
  p=HTML/fn.split('?')[0];h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>' if p.exists() else '')
 return h
checks=[];errors=[]
def ck(n,v,note=''):checks.append({'name':n,'pass':bool(v),'note':str(note)[:1400]})
dec=r('specs/themes/theme-07/know-how/decisions/decision-register.md'); data=r('specs/themes/theme-07/srs/04-data-entities.md'); bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'); tech=r('specs/themes/theme-07/srs/07-technical-contracts.md')
bj03=r('specs/themes/theme-07/srs/02-business-journeys/03-BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan.md'); bj13=r('specs/themes/theme-07/srs/02-business-journeys/13-BJ-13-ghi-nhan-chi-phi-mua-den-muon.md'); bj14=r('specs/themes/theme-07/srs/02-business-journeys/14-BJ-14-tinh-va-cong-bo-gia-von.md')
ck('Wave3 decision chain is continuous through T7-DR-170',all(f't7-dr-{i}' in dec.lower() for i in range(150,171)))
ck('BJ03 owns initial DirectCostBasis and direct valuation','DirectCostBasis' in bj03 and 'ReceiptValuation' in bj03)
ck('BJ03 late component boundary routes to BJ13','BJ13' in bj03 and 'component đến sau' in bj03.lower())
ck('BJ13 stable economic identity prevents revision double count','source_component_key' in bj13 and 'revision' in bj13.lower())
ck('BJ13 targets immutable ValuationExposure','ValuationExposure' in bj13 and 'valuation_exposure' in bj13.lower())
ck('BJ13 has one DIRECT/LATE route per source component','DIRECT' in bj13 and 'LATE' in bj13 and 'accounting route' in bj13)
ck('BJ13 produces exact Product+posting-period dirty scope','Product + posting period' in bj13 and 'dirty' in bj13.lower())
ck('BJ14 consumes authoritative dirty Product+posting-period scope','Product + posting period' in bj14 and 'dirty_scope_snapshot/version/hash' in bj14)
ck('BJ14 consumes ordered quantity/value facts via unified valuation sequence','valuation_sequence + within_transaction_ordinal' in bj14)
ck('BJ14 ProductCostResult carries authoritative reconciliation baseline','ProductCostResult' in bj14 and 'authoritative baseline' in bj14)
ck('Successor publication is incremental rather than replay','incremental reconciliation delta' in bj14 and 'Rerun cùng facts phải ra delta 0' in bj14)
ck('Official Cost publication is forward-effective','không được backdate trước publication commit' in bj14)
ck('Direct receipt value and late cost remain immutable, not rewritten','không rewrite ReceiptValuation' in dec and 'không re-post toàn bộ lịch sử' in dec)
ck('ReceiptValuation stores direct basis lineage','DirectCostBasis' in data and 'ReceiptValuation' in data)
ck('ValuationExposure stores initial-valued quantity/value lineage','ValuationExposure' in data and 'initial_valued_base_quantity' in data and 'initial_direct_value' in data)
ck('LateLandedCost stores stable component and complete basis hash','source_component_key' in data and 'late_cost_basis_hash' in data)
ck('ProductCostResult stores target and authoritative baselines','target_cumulative_cogs_vnd' in data and 'authoritative_cogs_baseline_vnd' in data and 'authoritative_carrying_value_vnd' in data)
ck('Inventory quantity/value facts share valuation ordering fields',data.count('valuation_sequence')>=3 and data.count('within_transaction_ordinal')>=3)
ck('BC-IV-01 direct valuation remains atomic and distinct from late cost','BC-IV-01' in bc and 'ReceiptValuation' in bc)
ck('BC-IV-06 late preview remains query-only','BC-IV-06' in bc and 'không mutation' in bc.lower())
ck('BC-IV-04 late commit creates Product+posting-period dirty scopes','BC-IV-04' in bc and 'Product + posting period' in bc)
ck('BC-IV-02 calculate creates no ledger mutation','BC-IV-02' in bc and '**không ledger mutation**' in bc)
ck('BC-IV-03 publication clears exact dirty causes only after reconcile','BC-IV-03' in bc and 'clear exactly reconciled Product+posting-period dirty causes' in bc)
ck('Technical contracts expose BJ03 preview/confirm APIs','API-Q-11' in tech and 'API-C-20' in tech)
ck('Technical contracts expose BJ13 preview/commit APIs','API-Q-12' in tech and 'API-C-23' in tech)
ck('Technical contracts expose BJ14 calculate/read/publish APIs','API-C-21' in tech and 'API-Q-10' in tech and 'API-C-22' in tech)
ck('OfficialCostPublished event retains publication lineage','EVT-IV-04' in tech and 'product_result' in tech.lower() and 'predecessor' in tech.lower())
ck('No Wave3 path allows BJ13 to auto-publish Official Cost','không auto-publish Official Cost' in bc)
ck('No Wave3 path allows BJ14 to mutate commercial pricing','không tự đổi pricing' in bj14.lower() or 'không tự thay đổi pricing' in bj14.lower())
ck('Period semantics remain explicit from BJ03 through BJ14',all(x in data for x in ['receipt_business_date','original_period_id','posting_period_id','calculation_period_id']))
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1440,'height':1080});p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(inline_html(),wait_until='load',timeout=30000)
 p.evaluate("()=>{activeFlowId='UIF-03';val03SelectedReceiptId='VAL03-R1';activeScreenId='SCR-017';stateByScreen['SCR-017']='READY';render();}");t03=p.locator('#app-screen').inner_text();ck('BJ03 UI still shows direct normalized cost consequence','Quy đổi lọ' in t03 and '8.170 đ/lọ' in t03,t03[:1200])
 p.evaluate("()=>{activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render();}");t13=p.locator('#app-screen').inner_text();ck('BJ13 UI presents late-cost work separately from direct valuation','Chi phí mua bổ sung' in t13 and 'Chi phí vận chuyển' in t13,t13[:1200])
 p.evaluate("()=>{activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render();}");t14=p.locator('#app-screen').inner_text();ck('BJ14 UI exposes resulting dirty work without raw technical IDs','Cần tính lại' in t14 and 'dirty_scope' not in t14.lower(),t14[:1200])
 p.locator('[data-val14-run="COST-0903"]').click();ck('BJ14 dirty scope is read-only at setup',p.locator('[data-val14-scope]').count()==0)
 ck('Wave3 runtime walk has no browser errors',not errors,errors);b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL';out={'version':'3.9.9','scope':'Wave 3 Cross-BJ Audit — BJ03→BJ13→BJ14','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(QA/'WAVE-3-CROSS-BJ-AUDIT-v3.9.9.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n');(QA/'WAVE-3-CROSS-BJ-AUDIT-v3.9.9.md').write_text('\n'.join(['# Wave 3 Cross-BJ Audit — v3.9.9','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','','Scope: BJ03 → BJ13 → BJ14','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n');print(status,out['passed'],out['total']);
if status!='PASS':
 [print('FAIL',x['name'],'::',x['note']) for x in checks if not x['pass']];sys.exit(1)
