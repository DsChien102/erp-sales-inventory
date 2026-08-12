#!/usr/bin/env python3
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[6]
HTML=ROOT/'specs/themes/theme-07/prototype/html'; QA=HTML/'qa'
def load(name): return json.loads((QA/name).read_text(encoding='utf-8'))
def j(rel): return json.loads((ROOT/rel).read_text(encoding='utf-8'))
def r(rel): return (ROOT/rel).read_text(encoding='utf-8')
def find_id(o,target):
    if isinstance(o,dict):
        if o.get('id')==target:return o
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
focused=load('BJ14-DEEP-REVIEW-QA-v3.9.9.json');fresh=load('BJ14-FRESH-EYE-QA-v3.9.9.json');prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.9.9.json');wave3=load('WAVE-3-CROSS-BJ-AUDIT-v3.9.9.json');frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.9.json');enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.9.json');flowqa=load('FLOW-LOGIC-E2E-QA-v3.9.9.json');smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.9.json');runtime=load('RUNTIME-UI-QA-v3.9.9.json');coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.9.json');device=load('DEVICE-FRAME-QA-v3.9.9.json')
proto=j('specs/themes/theme-07/prototype/prototype.manifest.json');outer=j('specs/themes/theme-07/prototype/html/prototype.manifest.json');manifest=j('specs/themes/theme-07/prototype/html/manifest.json');wb=j('specs/themes/theme-07/prototype/html/workbench-data.json');reg=j('specs/themes/theme-07/prototype/contracts/screen-registry.json');cat=j('specs/themes/theme-07/prototype/contracts/screen-catalog.json');acts=j('specs/themes/theme-07/prototype/contracts/action-registry.json');creg=j('specs/themes/theme-07/harness/contract-registry.json');trace=j('specs/themes/theme-07/harness/trace-index.json')
readme=r('README.md');root_index=r('index.html');html_index=r('specs/themes/theme-07/prototype/html/index.html');dec=r('specs/themes/theme-07/know-how/decisions/decision-register.md');bj14=r('specs/themes/theme-07/srs/02-business-journeys/14-BJ-14-tinh-va-cong-bo-gia-von.md');data=r('specs/themes/theme-07/srs/04-data-entities.md');bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md');tech=r('specs/themes/theme-07/srs/07-technical-contracts.md');flow14=r('specs/themes/theme-07/prototype/flows/UIF-14-BJ-14.md');uc3=r('specs/themes/theme-07/srs/05-use-cases/BJ-14-tinh-va-cong-bo-gia-von/UC-14-03-ra-soat-ket-qua.md');uc4=r('specs/themes/theme-07/srs/05-use-cases/BJ-14-tinh-va-cong-bo-gia-von/UC-14-04-cong-bo-gia-von.md');overlay=r('specs/themes/theme-07/prototype/html/v399-bj14-semantic-hardening.js')
ck('root package identifies v3.9.9','v3.9.9' in readme and 'v3.9.9' in root_index)
ck('prototype manifests identify v3.9.9 parent v3.9.8',proto.get('version')=='3.9.9' and proto.get('parentVersion')=='3.9.8' and outer.get('version')=='3.9.9' and outer.get('parentVersion')=='3.9.8' and manifest.get('version')=='3.9.9' and manifest.get('parentVersion')=='3.9.8')
ck('current registries identify v3.9.9',wb.get('version')=='3.9.9' and reg.get('version')=='3.9.9' and cat.get('version')=='3.9.9' and cat.get('package_version')=='3.9.9' and acts.get('version')=='3.9.9')
ck('v3.9.9 assets load after v3.9.8 hardening',html_index.count('v399-bj14-semantic-hardening.js')==1 and html_index.count('v399-bj14-semantic-hardening.css')==1 and html_index.index('v399-bj14-semantic-hardening.js')>html_index.index('v398-bj13-semantic-hardening.js') and html_index.index('v399-bj14-semantic-hardening.css')>html_index.index('v398-bj13-semantic-hardening.css'))
ck('BJ14 focused deep review passes',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==72)
ck('BJ14 fresh-eye passes',fresh.get('status')=='PASS' and fresh.get('passed')==fresh.get('total')==16)
ck('prior locked regression passes',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==26)
ck('Wave 3 cross-BJ audit passes',wave3.get('status')=='PASS' and wave3.get('passed')==wave3.get('total')==35)
ck('frozen source parent-ZIP comparison passes 108/108',frozen.get('status')=='PASS' and frozen.get('filesCompared')==frozen.get('candidateFiles')==108 and not frozen.get('added') and not frozen.get('removed') and not frozen.get('changed'))
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19)
ck('flow logic passes 21 checks',flowqa.get('status')=='PASS' and len(flowqa.get('pass',[]))==21 and flowqa.get('version')=='3.9.9')
ck('all-flow smoke passes 89 renders',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI passes 514 states / 89 routes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==514 and runtime.get('canonical_routes')==89 and runtime.get('version')=='3.9.9')
ck('representative coherence passes',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.9.9')
ck('device frame passes all 89 screens',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('approved DR164..170 exist as real rows',all(f'**`T7-DR-{i}`' in dec for i in range(164,171)))
ck('BJ14 binds unified valuation ordering','valuation_sequence + within_transaction_ordinal' in bj14 and 'cutoff_valuation_sequence' in bj14)
ck('data entities carry shared valuation ordering','valuation_sequence' in data and 'within_transaction_ordinal' in data and 'InventoryMovement' in data and 'InventoryValueMovement' in data)
ck('ProductCostResult entity exists','ProductCostResult' in data and 'target_cumulative_cogs_vnd' in data and 'authoritative_cogs_baseline_vnd' in data and 'authoritative_carrying_value_vnd' in data)
ck('successor reconciliation is incremental','incremental reconciliation delta' in bj14 and 'reconciliation_baseline_hash' in data)
ck('Official Cost cannot backdate before publication commit','backdate' in bj14.lower() and 'publication commit' in bj14.lower() and 'effective_from' in data)
ck('run separates run type / calculation / posting period',all(x in data for x in ['run_type','calculation_period_id','posting_period_id']))
ck('dirty scope is Product plus posting period', 'Product + posting period' in bj14 and all(x in data for x in ['dirty_scope_snapshot','dirty_scope_version','dirty_scope_hash']))
ck('weighted-average edge states are explicit','NO_NEW_COST_BASIS' in bj14 and 'NEGATIVE_QUANTITY' in bj14 and 'NEGATIVE_VALUATION_RESULT' in bj14)
ck('BC-IV-02 is calculate-only without ledger mutation','BC-IV-02' in bc and 'không ledger mutation' in bc)
ck('BC-IV-03 owns atomic publication','BC-IV-03' in bc and 'incremental reconciliation delta' in bc and 'OfficialCostVersion' in bc)
ck('UC14-03 is read-only review','API-Q-10' in uc3 and 'BC-IV-03' not in uc3 and 'idempotency' not in uc3.lower())
ck('UC14-04 owns publication finality','BC-IV-03' in uc4 and 'UNKNOWN' in uc4 and 'publication identity' in uc4)
ck('technical contracts expose calculate/read/publish APIs',all(x in tech for x in ['API-C-21','API-Q-10','API-C-22','EVT-IV-04']))
ck('EVT-IV-04 preserves product result and predecessor lineage','product_result' in tech.lower() and 'predecessor' in tech.lower() and 'scope' in tech.lower())
ck('contract registry no longer assigns BC-IV-03 to UC14-03',find_id(creg,'BC-IV-03') is not None and 'UC-14-03' not in json.dumps(find_id(creg,'BC-IV-03'),ensure_ascii=False))
ck('trace index maps UC14-03 query-only', 'API-Q-10' in json.dumps(trace,ensure_ascii=False) and 'UC-14-03' in json.dumps(trace,ensure_ascii=False))
ck('active UIF14 keeps SCR075 retired','SCR-072' in flow14 and 'SCR-073' in flow14 and 'SCR-074' in flow14 and 'SCR-076' in flow14 and 'SCR-077' in flow14 and 'SCR-075' in flow14 and 'retir' in flow14.lower())
ck('current screen registry hardens active BJ14 surfaces',all(find_id(reg,f'SCR-{n}') and '3.9.9' in str(find_id(reg,f'SCR-{n}').get('prototype_status','')) for n in ['072','073','074','076','077']))
ck('runtime uses unified cutoff and ProductCostResult semantics','cutoffValuationSequence' in overlay and 'productResults' in overlay and 'productResultSetHash' in overlay)
ck('runtime dirty scope is source-owned/read-only','scopeOrigin' in overlay and 'DIRTY_SCOPE' in overlay and 'data-val14-scope' in overlay)
ck('runtime publish is forward-effective','effectiveAt=nowLabel' in overlay and 'Khi công bố' in overlay)
ck('runtime stale guard uses run input hash','runInputHash' in overlay and 'val14PublishReviewVersion' in overlay)
ck('runtime UNKNOWN hands same publication to BJ17','data-v350-action="handoff-unknown"' in overlay and 'UIF-14' in overlay and 'Không gửi lại lệnh công bố' in overlay)
ck('manifest marks BJ14 lock candidate',manifest.get('status')=='WAVE_3_BJ14_DEEP_REVIEW_LOCK_CANDIDATE' and manifest.get('productApproval')=='BJ14_DEEP_REVIEW_QA_v3.9.9')
ck('BJ14 visual evidence contains five focused captures',len(list((QA/'v399-bj14-captures').glob('*.png')))==5)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.9','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.9.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.9.md').write_text('\n'.join(['# Current Package Validation — v3.9.9','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
