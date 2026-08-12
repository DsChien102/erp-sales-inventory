#!/usr/bin/env python3
from __future__ import annotations
import json, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
checks=[]; failures=[]
def ck(name, cond, detail=''):
    ok=bool(cond); checks.append({'name':name,'passed':ok,'detail':str(detail)})
    if not ok: failures.append(f'{name}: {detail}')
def load(rel): return json.loads((root/rel).read_text(encoding='utf-8'))

# Current browser-prototype authorities
reg=load('prototype/contracts/screen-registry.json')
flows=load('prototype/flows/ui-flow-registry.json')
wb=load('prototype/html/workbench-data.json')
manifest=load('prototype/html/manifest.json')
pm=load('prototype/html/prototype.manifest.json')
rr=load('prototype/contracts/runtime-state-registry-v3.6.0.json')

ck('current-version:screen-registry', reg.get('version')=='3.6.0', reg.get('version'))
ck('current-version:flow-registry', flows.get('patch_version')=='3.6.0', flows.get('patch_version'))
ck('current-version:workbench', wb.get('version')=='3.6.0', wb.get('version'))
ck('current-version:manifest', manifest.get('version')=='3.6.0', manifest.get('version'))
ck('current-version:prototype-manifest', pm.get('version')=='3.6.0', pm.get('version'))
ck('current-version:runtime-registry', rr.get('version')=='3.6.0', rr.get('version'))

business=[f for f in wb['flows'] if f['id'].startswith('UIF-')]
support=[f for f in wb['flows'] if f['id'].startswith('CAP-')]
routes=sum(len(f['screens']) for f in wb['flows'])
unique={sid for f in wb['flows'] for sid in f['screens']}
sm={s['id']:s for s in wb['screens']}
route_states=sum(len(sm[sid].get('states',[])) for f in wb['flows'] for sid in f['screens'])
ck('scope:17-business-journeys',len(business)==17,len(business))
ck('scope:1-supporting-capability',len(support)==1 and support[0]['id']=='CAP-01',[f['id'] for f in support])
ck('scope:89-route-occurrences',routes==89,routes)
ck('scope:77-active-unique-screens',len(unique)==77,len(unique))
ck('scope:518-route-states',route_states==518,route_states)
ck('scope:cap-screens',set(['SCR-062','SCR-063','SCR-064','SCR-065']).issubset(unique),sorted(set(['SCR-062','SCR-063','SCR-064','SCR-065'])-unique))

flow_ids=[f['id'] for f in flows['flows']]
ck('flow-registry:18',len(flow_ids)==18,len(flow_ids))
ck('flow-registry:matches-workbench',set(flow_ids)==set(f['id'] for f in wb['flows']),sorted(set(flow_ids)^set(f['id'] for f in wb['flows'])))
ck('flow-registry:docs',all((root/'prototype/flows'/f['file']).is_file() for f in flows['flows']))
ck('screen-contracts:active',all((root/'prototype/contracts/screens'/f'{sid}.md').is_file() for sid in unique))
ck('registry:supporting-rendered',all(next(s for s in reg['screens'] if s['id']==sid).get('prototype_status')=='RENDERED_v3.6.0' for sid in ['SCR-062','SCR-063','SCR-064','SCR-065']))

# Authority contract
figma=str(manifest.get('authority',{}).get('figma','')).lower()
html=str(manifest.get('authority',{}).get('theme7Design','')).lower()
ck('authority:html-theme7-design','html' in html and 'theme 7' in html,html)
ck('authority:figma-ds-reference-only','design system' in figma and 'not' in figma,figma)

# Current QA evidence
qas={
 'static':'prototype/html/qa/STATIC-CONSISTENCY-QA-v3.6.0.json',
 'flow':'prototype/html/qa/FLOW-LOGIC-E2E-QA-v3.6.0.json',
 'ui':'prototype/html/qa/RUNTIME-UI-QA-v3.6.0.json',
 'full':'prototype/html/qa/FULL-THEME-COMPLETION-QA-v3.6.0.json',
}
for name,rel in qas.items():
    p=root/rel
    ck(f'qa:{name}:exists',p.is_file(),rel)
    if p.is_file():
        q=json.loads(p.read_text(encoding='utf-8'))
        ok = (q.get('status')=='PASS') or (isinstance(q.get('passed'), int) and q.get('passed')==q.get('total'))
        ck(f'qa:{name}:pass',ok,q.get('status') or f"{q.get('passed')}/{q.get('total')}")

# Lock key UX/product decisions in the executable correction layer.
js=(root/'prototype/html/v360-full-theme-completion.js').read_text(encoding='utf-8')
css=(root/'prototype/html/v360-full-theme-completion.css').read_text(encoding='utf-8')
ck('bj08:cancel-inside-session','data-ic08-action=\"cancel-open\"' in js and 'SCR-044' in js and 'SCR-045' in js)
ck('feedback:semantic-toast','toast' in js.lower())
ck('stable-screen-exit:guard','stable' in js.lower() and 'exit' in js.lower())
ck('vchip:single-row','flex-wrap: nowrap' in css or 'flex-wrap:nowrap' in css)

# Historical v4.3.1 package evidence remains preserved but is no longer the current runtime authority.
hist=(root/'validation/validate-package.py').is_file() and (root/'validation/validation-report.json').is_file()
ck('historical-package-evidence:preserved',hist)

status='PASS' if not failures else 'FAIL'
result={'version':'3.6.0','status':status,'checks':len(checks),'passed':sum(c['passed'] for c in checks),'failed':len(failures),'failures':failures,'scope':{'businessJourneys':17,'supportingCapabilities':1,'canonicalRouteOccurrences':89,'activeUniqueScreens':77,'declaredRouteStates':518},'evidenceBoundary':'Browser prototype; backend transaction/database/outbox/network atomicity is not asserted.'}
print(json.dumps(result,ensure_ascii=False,indent=2))
sys.exit(0 if status=='PASS' else 1)
