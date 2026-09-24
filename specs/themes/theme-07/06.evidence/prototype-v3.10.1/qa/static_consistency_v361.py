from pathlib import Path
import json,re,sys
ROOT=Path(__file__).resolve().parents[2]
HTML=ROOT/'html'; CONTRACTS=ROOT/'contracts'; FLOWS=ROOT/'flows'
checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})
wb=json.loads((HTML/'workbench-data.json').read_text())
reg=json.loads((CONTRACTS/'screen-registry.json').read_text())
rr=json.loads((CONTRACTS/'runtime-state-registry-v3.6.1.json').read_text())
wm={x['id']:x for x in wb['screens']}; rm={x['id']:x for x in reg['screens']}
active_routes=[(f['id'],sid) for f in wb['flows'] for sid in f['screens']]
active_ids=sorted({sid for _,sid in active_routes})
bj=[f for f in wb['flows'] if f['id'].startswith('UIF-')]; caps=[f for f in wb['flows'] if f['id'].startswith('CAP-')]
ck('17 business journeys + 1 supporting capability',len(bj)==17 and len(caps)==1,f"bj={len(bj)} cap={len(caps)} total={len(wb['flows'])}")
ck('89 canonical flow-screen occurrences',len(active_routes)==89,f"routes={len(active_routes)} unique={len(active_ids)}")
ck('77 active unique screens',len(active_ids)==77,f"unique={len(active_ids)}")
missing_contracts=[sid for sid in active_ids if not (CONTRACTS/'screens'/f'{sid}.md').exists()]
ck('every active screen has a screen contract',not missing_contracts,missing_contracts)
missing_flow_docs=[]
for f in wb['flows']:
    pat=f"{f['id']}-*.md"
    if not list(FLOWS.glob(pat)): missing_flow_docs.append(f['id'])
ck('every active flow/support capability has a flow document',not missing_flow_docs,missing_flow_docs)
drift=[]
for sid in active_ids:
    if sid not in wm or sid not in rm: drift.append((sid,'missing')); continue
    if wm[sid].get('name')!=rm[sid].get('name'): drift.append((sid,'name',rm[sid].get('name'),wm[sid].get('name')))
    if wm[sid].get('states')!=rm[sid].get('states'): drift.append((sid,'states',rm[sid].get('states'),wm[sid].get('states')))
ck('active screen registry/workbench names and states aligned',not drift,drift[:10])
ck('registry/workbench version v3.6.1',wb.get('version')=='3.6.1' and reg.get('version')=='3.6.1',f"wb={wb.get('version')} reg={reg.get('version')}")
rrm={x['id']:x for x in rr['screens']}; rr_drift=[]
for sid in active_ids:
    if sid not in rrm: rr_drift.append((sid,'missing')); continue
    if rrm[sid].get('name')!=wm[sid].get('name'): rr_drift.append((sid,'name'))
    if rrm[sid].get('states')!=wm[sid].get('states'): rr_drift.append((sid,'states'))
ck('runtime-state registry synchronized',not rr_drift,rr_drift[:10])
rr_count=sum(len(rrm[sid].get('states',[])) for _,sid in active_routes)
ck('runtime registry covers 518 route-states',rr_count==518 and rr.get('declaredStateRenders')==518,f"route_states={rr_count} declared={rr.get('declaredStateRenders')}")
# supporting capability rendered and documented
for sid in ['SCR-062','SCR-063','SCR-064','SCR-065']:
    ck(f'{sid} supporting screen remains rendered',rm[sid].get('prototype_status')=='RENDERED_v3.6.0',rm[sid].get('prototype_status'))
# BJ08 cancellation ownership
scr42=rm['SCR-042']; scr44=rm['SCR-044']
ck('BJ08 cancellation removed from browse-list contract','ACT-09-CANCEL' not in scr42.get('action_ids',[]),scr42.get('action_ids'))
ck('BJ08 cancellation owned by opened-session contract','ACT-09-CANCEL' in scr44.get('action_ids',[]),scr44.get('action_ids'))
# load cascade
idx=(HTML/'index.html').read_text();
ck('v3.6 CSS loads after v3.5.1',idx.find('v360-full-theme-completion.css')>idx.find('v351-list-chip-navigation-correction.css'))
ck('v3.6 JS loads after v3.5.1',idx.find('v360-full-theme-completion.js')>idx.find('v351-list-chip-navigation-correction.js'))
ck('v3.6.1 CSS loads after v3.6.0',idx.find('v361-footer-action-correction.css')>idx.find('v360-full-theme-completion.css'))
ck('v3.6.1 JS loads after v3.6.0',idx.find('v361-footer-action-correction.js')>idx.find('v360-full-theme-completion.js'))
v361js=(HTML/'v361-footer-action-correction.js').read_text(); v361css=(HTML/'v361-footer-action-correction.css').read_text()
ck('dual Sticky Footer normalization exists','normalizeDualFooters' in v361js and 'v361-dual-footer' in v361css)
ck('v3.6.1 footer patch is DS-variable based','#' not in v361css and 'var(--vet45-v2-' in v361css)
js=(HTML/'v360-full-theme-completion.js').read_text(); css=(HTML/'v360-full-theme-completion.css').read_text()
ck('CAP-01 effective renderers declared',all(f'renderers["{sid}"]' in js for sid in ['SCR-062','SCR-063','SCR-064','SCR-065']))
ck('BJ08 active-session cancel correction exists','injectSessionCancel' in js and 'data-ic08-action="cancel-open"' in js)
ck('representative-state coherence correction exists',all(x in js for x in ['ensureBj02ReviewFixture','ensureVal03ReviewFixture','ensureIo07ReviewFixture','ensureVal13ReviewFixture','ensureVal14ReviewFixture']))
ck('feedback/toast semantic layer exists','toastRules' in js and 'showToast' in js)
ck('single-row chip lock preserved','flex-wrap: nowrap !important' in css and 'overflow-x: auto !important' in css)
# Authority lock
manifest=json.loads((HTML/'manifest.json').read_text())
proto=json.loads((HTML/'prototype.manifest.json').read_text())
ck('HTML manifests identify v3.6.1',manifest.get('version')=='3.6.1' and manifest.get('parentVersion')=='3.6.0' and proto.get('version')=='3.6.1')
auth=manifest.get('authority',{})
auth_text=json.dumps(auth,ensure_ascii=False)
ck('authority separates business, Figma DS and HTML prototype roles','business' in auth and 'figmaDesignSystem' in auth and 'htmlPrototype' in auth and 'UI authority' in auth.get('figmaDesignSystem','') and 'design/verification' in auth.get('htmlPrototype',''),auth_text)
# docs
cap=(FLOWS/'CAP-01-SUPPORTING-POLICY.md').read_text()
ck('CAP-01 doc preserves BG-006 integration uncertainty','BG-006' in cap and 'không' in cap.lower())
for sid in ['SCR-062','SCR-063','SCR-064','SCR-065']:
    ck(f'{sid} contract exists',(CONTRACTS/'screens'/f'{sid}.md').exists())
# Workbench default representative states should be stable where possible
stable_defaults={'SCR-012':'COMPLETED','SCR-019':'COMPLETED','SCR-059':'COMPLETED','SCR-071':'COMPLETED','SCR-077':'COMPLETED','SCR-081':'READY','SCR-089':'COMPLETED'}
ck('representative result defaults are stable',all(wm[sid]['defaultState']==st for sid,st in stable_defaults.items()),[(sid,wm[sid]['defaultState']) for sid in stable_defaults])
out={'version':'3.6.1','passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(HTML/'qa'/'STATIC-CONSISTENCY-QA-v3.6.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
md=['# Static Consistency QA — v3.6.1','',f"**Result: {out['passed']}/{out['total']} PASS**",'']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']}"+(f": {x['note']}" if x['note'] and not x['pass'] else '') for x in checks]
(HTML/'qa'/'STATIC-CONSISTENCY-QA-v3.6.1.md').write_text('\n'.join(md)+'\n')
print(('PASS' if out['passed']==out['total'] else 'FAIL'),out['passed'],'/',out['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],'::',x['note'])
sys.exit(0 if out['passed']==out['total'] else 1)
