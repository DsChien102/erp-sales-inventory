from pathlib import Path
import json,re,sys
ROOT=Path(__file__).resolve().parents[2]  # prototype
HTML=ROOT/'html'
CONTRACTS=ROOT/'contracts'
FLOWS=ROOT/'flows'
checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})
wb=json.loads((HTML/'workbench-data.json').read_text())
reg=json.loads((CONTRACTS/'screen-registry.json').read_text())
rr=json.loads((CONTRACTS/'runtime-state-registry-v3.5.0.json').read_text())
wm={x['id']:x for x in wb['screens']}; rm={x['id']:x for x in reg['screens']}
active_routes=[(f['id'],sid) for f in wb['flows'] for sid in f['screens']]
active_ids=sorted({sid for _,sid in active_routes})
ck('17 business-journey flows',len(wb['flows'])==17,f"flows={len(wb['flows'])}")
ck('85 canonical flow-screen routes',len(active_routes)==85,f"routes={len(active_routes)} unique_screens={len(active_ids)}")
missing_contracts=[sid for sid in active_ids if not (CONTRACTS/'screens'/f'{sid}.md').exists()]
ck('every active screen has a screen contract',not missing_contracts,missing_contracts)
missing_flow_docs=[f['id'] for f in wb['flows'] if not list(FLOWS.glob(f"{f['id']}-*.md"))]
ck('every active flow has a flow document',not missing_flow_docs,missing_flow_docs)
drift=[]
for sid in active_ids:
    if sid not in wm or sid not in rm:
        drift.append((sid,'missing'))
        continue
    if wm[sid].get('name')!=rm[sid].get('name'): drift.append((sid,'name',rm[sid].get('name'),wm[sid].get('name')))
    if wm[sid].get('states')!=rm[sid].get('states'): drift.append((sid,'states',rm[sid].get('states'),wm[sid].get('states')))
ck('active screen registry/workbench names and states are aligned',not drift,drift[:10])
ck('registry and workbench release version',wb.get('version')=='3.5.0' and reg.get('version')=='3.5.0',f"wb={wb.get('version')} registry={reg.get('version')}")
rrm={x['id']:x for x in rr['screens']}
rr_drift=[]
for sid in active_ids:
    if sid not in rrm:
        rr_drift.append((sid,'missing'))
        continue
    if rrm[sid].get('name')!=wm[sid].get('name'): rr_drift.append((sid,'name',rrm[sid].get('name'),wm[sid].get('name')))
    if rrm[sid].get('states')!=wm[sid].get('states'): rr_drift.append((sid,'states',rrm[sid].get('states'),wm[sid].get('states')))
ck('runtime-state registry is synchronized to workbench',not rr_drift,rr_drift[:10])
rr_count=sum(len(rrm[sid].get('states',[])) for _,sid in active_routes)
ck('runtime-state registry covers 500 declared route-states',rr_count==500 and rr.get('declaredStateRenders')==500,f"route_states={rr_count} declared={rr.get('declaredStateRenders')}")
# Newly reachable states introduced by correction layer must be declared in workbench/registry.
js=(HTML/'v350-flow-logic-correction.js').read_text()
assign={}
for sid,state in re.findall(r'stateByScreen\[\s*["\'](SCR-\d+)["\']\s*\]\s*=\s*["\']([A-Z0-9_]+)["\']',js): assign.setdefault(sid,set()).add(state)
undeclared=[]
for sid,states in assign.items():
    declared=set(wm.get(sid,{}).get('states',[]))
    for st in states-declared:
        undeclared.append((sid,st,sorted(declared)))
ck('v3.5 reachable literal states are declared',not undeclared,undeclared[:10])
# BJ02 canonical quick behavior must no longer contain the stale no-auto-open decision.
bj02='\n'.join(p.read_text() for p in FLOWS.glob('UIF-02-*.md'))
ck('BJ02 Quick canonical behavior is unambiguous','không tự mở editor' not in bj02 and 'mở ngay `SCR-084`' in bj02,'stale phrase present' if 'không tự mở editor' in bj02 else '')
# Current runtime reports must be discoverable from README while historical validation files are explicitly labeled historical/static.
root=ROOT.parents[3]
root_readme=(root/'README.md').read_text()
ck('root README points to v3.5 validation','RELEASE-VALIDATION-v3.5.0.md' in root_readme and 'v3.5.0' in root_readme)
for p in [CONTRACTS/'validation-report.md',FLOWS/'validation-report.md']:
    if p.exists(): ck(f'{p.parent.name} old validation report is labeled historical','Historical/static report.' in p.read_text(),str(p))
out={'version':'3.5.0','passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(HTML/'qa'/'STATIC-CONSISTENCY-QA-v3.5.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
md=['# Static Consistency QA — v3.5.0','',f"**Result: {out['passed']}/{out['total']} PASS**",'']
for x in checks: md.append(f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}" + (f": {x['note']}" if x['note'] and not x['pass'] else ''))
(HTML/'qa'/'STATIC-CONSISTENCY-QA-v3.5.0.md').write_text('\n'.join(md)+'\n')
print(('PASS' if out['passed']==out['total'] else 'FAIL'),out['passed'],'/',out['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],'::',x['note'])
sys.exit(0 if out['passed']==out['total'] else 1)
