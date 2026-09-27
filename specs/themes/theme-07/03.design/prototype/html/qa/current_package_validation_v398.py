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
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})

focused=load('BJ13-DEEP-REVIEW-QA-v3.9.8.json')
fresh=load('BJ13-FRESH-EYE-QA-v3.9.8.json')
prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.9.8.json')
frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.8.json')
enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.8.json')
flowqa=load('FLOW-LOGIC-E2E-QA-v3.9.8.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.8.json')
runtime=load('RUNTIME-UI-QA-v3.9.8.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.8.json')
device=load('DEVICE-FRAME-QA-v3.9.8.json')
wave2=load('WAVE-2-CROSS-BJ-AUDIT-v3.9.6.json')
proto=j('specs/themes/theme-07/prototype/prototype.manifest.json'); outer=j('specs/themes/theme-07/prototype/html/prototype.manifest.json'); manifest=j('specs/themes/theme-07/prototype/html/manifest.json')
wb=j('specs/themes/theme-07/prototype/html/workbench-data.json'); reg=j('specs/themes/theme-07/prototype/contracts/screen-registry.json'); cat=j('specs/themes/theme-07/prototype/contracts/screen-catalog.json'); acts=j('specs/themes/theme-07/prototype/contracts/action-registry.json'); creg=j('specs/themes/theme-07/harness/contract-registry.json')
readme=r('README.md'); root_index=r('index.html'); html_index=r('specs/themes/theme-07/prototype/html/index.html'); dec=r('specs/themes/theme-07/know-how/decisions/decision-register.md'); data=r('specs/themes/theme-07/srs/04-data-entities.md'); bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'); tech=r('specs/themes/theme-07/srs/07-technical-contracts.md'); flow=r('specs/themes/theme-07/prototype/flows/UIF-13-BJ-13.md'); inv=r('specs/themes/theme-07/design-readiness/03-screen-inventory.md'); overlay=r('specs/themes/theme-07/prototype/html/v398-bj13-semantic-hardening.js')

ck('root package identifies v3.9.8','v3.9.8' in readme and 'v3.9.8' in root_index)
ck('prototype manifests identify v3.9.8 parent v3.9.7',proto.get('version')=='3.9.8' and proto.get('parentVersion')=='3.9.7' and outer.get('version')=='3.9.8' and outer.get('parentVersion')=='3.9.7' and manifest.get('version')=='3.9.8' and manifest.get('parentVersion')=='3.9.7')
ck('current registries identify v3.9.8',wb.get('version')=='3.9.8' and reg.get('version')=='3.9.8' and cat.get('version')=='3.9.8' and cat.get('package_version')=='3.9.8')
ck('v3.9.8 BJ13 CSS/JS load after v3.9.7 BJ03 hardening','v398-bj13-semantic-hardening.css' in html_index and 'v398-bj13-semantic-hardening.js' in html_index and html_index.index('v398-bj13-semantic-hardening.css')>html_index.index('v397-bj03-semantic-hardening.css') and html_index.index('v398-bj13-semantic-hardening.js')>html_index.index('v397-bj03-semantic-hardening.js'))
ck('BJ13 focused deep review passes',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==83,f"{focused.get('passed')}/{focused.get('total')}")
ck('BJ13 fresh-eye re-walk passes',fresh.get('status')=='PASS' and fresh.get('passed')==fresh.get('total')==16,f"{fresh.get('passed')}/{fresh.get('total')}")
ck('prior locked BJ regression passes',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==20,f"{prior.get('passed')}/{prior.get('total')}")
ck('frozen-source remains byte-identical',frozen.get('status')=='PASS' and frozen.get('filesCompared')==108 and not frozen.get('changed') and not frozen.get('added') and not frozen.get('removed'),frozen)
ck('Wave 2 horizontal audit remains PASS baseline',wave2.get('status')=='PASS' and wave2.get('passed')==wave2.get('total')==30,f"{wave2.get('passed')}/{wave2.get('total')}")
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19)
ck('flow/logic E2E passes',flowqa.get('status')=='PASS' and flowqa.get('checks')==21 and flowqa.get('version')=='3.9.8')
ck('all-flow smoke passes 89 route renders',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI passes 514 declared states and 89 routes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==514 and runtime.get('canonical_routes')==89 and runtime.get('version')=='3.9.8')
ck('representative coherence passes',coh.get('passed')==coh.get('total')==8 and coh.get('version')=='3.9.8')
ck('device frame passes all 89 screens',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('approved T7-DR-157..163 are present as decision rows',all(f'**`T7-DR-{i}`' in dec for i in range(157,164)))
ck('DR-058 uses stable economic identity and Product+posting-period dirty scope','source_component_key' in dec and 'Product + posting period' in dec)
ck('LateLandedCost uses stable component identity independent revision',all(x in data for x in ['source_component_key','source_revision','target_scope_key','late_cost_basis_hash','adjustment_batch_ids']))
ck('ValuationExposure and allocation lineage exist',all(x in data for x in ['ValuationExposure','valuation_exposure_key','valuation_exposure_version','valuation_exposure_hash','initial_valued_base_quantity','initial_direct_value']))
ck('per-allocation original/posting periods and stable metrics exist',all(x in data for x in ['allocation_metric','receipt_business_date','original_period_id','posting_period_id','allocation_hash']))
ck('BC-IV-06 preview and BC-IV-04 atomic commit are documented','BC-IV-06' in bc and 'BC-IV-04' in bc and 'late_cost_basis_hash' in bc and 'allocation_hash' in bc)
ck('API-Q-12 preview and API-C-23 commit are documented','API-Q-12' in tech and 'API-C-23' in tech and 'late_cost_basis_hash' in tech and 'valuation_exposure_key' in tech)
ck('Harness registry includes BJ13 preview and commit contracts',all(find_id(creg,x) is not None for x in ['BC-IV-06','API-Q-12','BC-IV-04','API-C-23']))
ck('Harness BJ13 preview is read-only with no mutation UNKNOWN',find_id(creg,'BC-IV-06').get('safe_failure','').startswith('Query') and 'no business UNKNOWN' in find_id(creg,'BC-IV-06').get('safe_failure',''))
ck('ACT-03 commit uses complete basis/allocation freshness','late_cost_basis_hash + allocation_hash' in find_id(acts,'ACT-03-RECORD-LATE-COST')['confirmation'])
ck('Active UIF13 flow is SCR-085 through SCR-089','SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089' in flow and 'Historical SCR-014/015/017/018/019 are not BJ13 Product surfaces.' in flow)
ck('Design-readiness inventory retires old BJ13 mappings','SCR-018' in inv and 'S1_RETIRED_FROM_ACTIVE_BJ13' in inv and '| [`SCR-085`' in inv and '| [`SCR-089`' in inv)
ck('Current screen registry maps BJ13 to 085..089',all(find_id(reg,f'SCR-{n}') and find_id(reg,f'SCR-{n}').get('related_business_journeys')==['BJ-13'] for n in ['085','086','087','088','089']))
ck('Current screens do not present source revision as economic identity','Lần cập nhật nguồn' not in ''.join(json.dumps(find_id(reg,f'SCR-{n}'),ensure_ascii=False) for n in ['085','086','087','088','089']))
ck('Runtime allocation uses stable exposure ordering','valuationExposureKey' in overlay and 'sort' in overlay and 'initialDirectValue' in overlay)
ck('Runtime UNKNOWN preserves command identity and BJ17 handoff','handoff-unknown' in overlay and 'operationId' in overlay and 'UIF-13' in overlay)
ck('Current manifest is BJ13 lock candidate',manifest.get('productApproval')=='BJ13_DEEP_REVIEW_QA_v3.9.8' and manifest.get('status')=='WAVE_3_BJ13_DEEP_REVIEW_LOCK_CANDIDATE')
ck('v3.9.8 runtime overlay declared exactly once',html_index.count('v398-bj13-semantic-hardening.js')==1 and html_index.count('v398-bj13-semantic-hardening.css')==1)
ck('BJ13 visual evidence set contains 5 captures',len(list((QA/'v398-bj13-captures').glob('*.png')))==5)

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.8','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.8.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.8.md').write_text('\n'.join(['# Current Package Validation — v3.9.8','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': `{x["note"]}`' if not x['pass'] and x['note']!='' else '') for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
