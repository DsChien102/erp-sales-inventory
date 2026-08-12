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
def ck(name,cond,note=''):checks.append({'name':name,'pass':bool(cond),'note':note})

focused=load('BJ03-DEEP-REVIEW-QA-v3.9.7.json')
fresh=load('BJ03-FRESH-EYE-QA-v3.9.7.json')
prior=load('PRIOR-LOCKED-BJ-REGRESSION-v3.9.7.json')
frozen=load('FROZEN-SOURCE-IMMUTABILITY-QA-v3.9.7.json')
enduser=load('FULL-THEME-END-USER-HARDENING-QA-v3.9.7.json')
flowqa=load('FLOW-LOGIC-E2E-QA-v3.9.7.json')
smoke=load('ALL-FLOWS-RUNTIME-SMOKE-v3.9.7.json')
runtime=load('RUNTIME-UI-QA-v3.9.7.json')
coh=load('REPRESENTATIVE-COHERENCE-QA-v3.9.7.json')
device=load('DEVICE-FRAME-QA-v3.9.7.json')
wave2=load('WAVE-2-CROSS-BJ-AUDIT-v3.9.6.json')
proto=j('specs/themes/theme-07/prototype/prototype.manifest.json'); outer=j('specs/themes/theme-07/prototype/html/prototype.manifest.json'); manifest=j('specs/themes/theme-07/prototype/html/manifest.json')
wb=j('specs/themes/theme-07/prototype/html/workbench-data.json'); reg=j('specs/themes/theme-07/prototype/contracts/screen-registry.json'); cat=j('specs/themes/theme-07/prototype/contracts/screen-catalog.json'); acts=j('specs/themes/theme-07/prototype/contracts/action-registry.json'); creg=j('specs/themes/theme-07/harness/contract-registry.json')
readme=r('README.md'); root_index=r('index.html'); html_index=r('specs/themes/theme-07/prototype/html/index.html'); dec=r('specs/themes/theme-07/know-how/decisions/decision-register.md'); data=r('specs/themes/theme-07/srs/04-data-entities.md'); bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'); tech=r('specs/themes/theme-07/srs/07-technical-contracts.md'); flow=r('specs/themes/theme-07/prototype/flows/UIF-03-BJ-03.md')

ck('root package identifies v3.9.7','v3.9.7' in readme and 'v3.9.7' in root_index)
ck('prototype manifests identify v3.9.7 parent v3.9.6',proto.get('version')=='3.9.7' and proto.get('parentVersion')=='3.9.6' and outer.get('version')=='3.9.7' and outer.get('parentVersion')=='3.9.6' and manifest.get('version')=='3.9.7' and manifest.get('parentVersion')=='3.9.6')
ck('current registries identify v3.9.7',wb.get('version')=='3.9.7' and reg.get('version')=='3.9.7' and cat.get('version')=='3.9.7' and cat.get('package_version')=='3.9.7')
ck('v3.9.7 BJ03 CSS/JS load after v3.9.6 BJ04 hardening','v397-bj03-semantic-hardening.css' in html_index and 'v397-bj03-semantic-hardening.js' in html_index and html_index.index('v397-bj03-semantic-hardening.css')>html_index.index('v396-bj04-semantic-hardening.css') and html_index.index('v397-bj03-semantic-hardening.js')>html_index.index('v396-bj04-semantic-hardening.js'))
ck('BJ03 focused deep review passes',focused.get('status')=='PASS' and focused.get('passed')==focused.get('total')==61,f"{focused.get('passed')}/{focused.get('total')}")
ck('BJ03 fresh-eye re-walk passes',fresh.get('status')=='PASS' and fresh.get('passed')==fresh.get('total')==13,f"{fresh.get('passed')}/{fresh.get('total')}")
ck('prior locked BJ regression passes',prior.get('status')=='PASS' and prior.get('passed')==prior.get('total')==17,f"{prior.get('passed')}/{prior.get('total')}")
ck('frozen-source remains byte-identical',frozen.get('status')=='PASS' and frozen.get('filesCompared')==108 and not frozen.get('changed') and not frozen.get('added') and not frozen.get('removed'),frozen)
ck('Wave 2 horizontal audit remains PASS baseline',wave2.get('status')=='PASS' and wave2.get('passed')==wave2.get('total')==30,f"{wave2.get('passed')}/{wave2.get('total')}")
ck('full-theme end-user regression passes',enduser.get('status')=='PASS' and enduser.get('passed')==enduser.get('total')==19)
ck('flow/logic E2E passes',flowqa.get('status')=='PASS' and flowqa.get('checks')==21)
ck('all-flow smoke passes 89 route renders',smoke.get('status')=='PASS' and smoke.get('renders')==89 and not smoke.get('failures') and not smoke.get('errors'))
ck('runtime UI passes 514 declared states and 89 routes',runtime.get('passed')==runtime.get('total')==14 and runtime.get('declared_states')==514 and runtime.get('canonical_routes')==89)
ck('representative coherence passes',coh.get('passed')==coh.get('total')==8)
ck('device frame passes all 89 screens',device.get('status')=='PASS' and device.get('passed')==device.get('total')==7 and device.get('screensChecked')==89)
ck('approved T7-DR-150..156 are present',all(f'T7-DR-{i}' in dec for i in range(150,157)))
ck('ReceiptValuation stores complete basis and UOM normalization',all(x in data for x in ['valuation_basis_key','basis_hash','direct_cost_basis_snapshot','transaction_uom_snapshot','normalized_direct_unit_cost_base','confirmed_value_amount']))
ck('Official Cost is base-UOM scoped',all(x in data for x in ['**VND / base UOM**','base_uom_id','base_uom_version']))
ck('BC-IV-01/05 split mutation from preview','BC-IV-01' in bc and 'BC-IV-05' in bc and 'read-only' in bc.lower())
ck('API-Q-11 preview contract is documented','API-Q-11' in tech and 'basis_version/basis_hash' in tech)
ck('Active UIF03 flow excludes retired SCR-016','SCR-016' in flow and 'không thuộc active' in flow.lower() and find_id(wb,'SCR-016')['uifs']==[])
ck('Historical SCR-016 has no active UC mapping',find_id(reg,'SCR-016')['related_use_cases']==[])
ck('ACT-03 confirm action uses basis/scope freshness','basis_version/basis_hash' in find_id(acts,'ACT-03-CONFIRM-COST')['confirmation'])
ck('Harness registry includes new preview BC/API',find_id(creg,'BC-IV-05') is not None and find_id(creg,'API-Q-11') is not None)
ck('Harness mutation BC-IV-01 belongs to UC03-03 only',find_id(creg,'BC-IV-01')['stories']==['UC-03-03'])
ck('current manifest product approval is BJ03 v3.9.7',manifest.get('productApproval')=='BJ03_DEEP_REVIEW_QA_v3.9.7')
ck('current manifest scope names Wave 3 BJ03','Wave 3 / BJ03' in manifest.get('scope',''))
ck('v3.9.7 runtime overlay is declared exactly once',html_index.count('v397-bj03-semantic-hardening.js')==1 and html_index.count('v397-bj03-semantic-hardening.css')==1)

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.7','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.7.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(QA/'CURRENT-PACKAGE-VALIDATION-v3.9.7.md').write_text('\n'.join(['# Current Package Validation — v3.9.7','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': `{x["note"]}`' if not x['pass'] and x['note']!='' else '') for x in checks])+'\n',encoding='utf-8')
print(status,out['passed'],out['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']:print('FAIL',x['name'],'::',x['note'])
    sys.exit(1)
