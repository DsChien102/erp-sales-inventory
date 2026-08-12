from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; PROTO=ROOT.parent
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf-8')); app=(ROOT/'app.js').read_text(encoding='utf-8'); css=(ROOT/'styles.css').read_text(encoding='utf-8'); idx=(ROOT/'index.html').read_text(encoding='utf-8'); manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
flows={f['id']:f for f in wb['flows']}; screens={s['id']:s for s in wb['screens']}; target=[f'SCR-{i:03d}' for i in range(54,60)]+[f'SCR-{i:03d}' for i in range(66,72)]
checks=[]
def ck(n,c): checks.append((n,bool(c)))
ck('Workbench version = 1.8.0',wb.get('version')=='1.8.0'); ck('Manifest version = 1.8.0',manifest.get('version')=='1.8.0'); ck('Index review badge = v1.8.0','v1.8.0 · Control Foundation & Inquiry · BJ12 · BJ15' in idx)
ck('UIF12 canonical screens',flows['UIF-12']['screens']==['SCR-066','SCR-067','SCR-068','SCR-069','SCR-070','SCR-071']); ck('UIF12 independent entry surfaces',set(flows['UIF-12']['entry'])=={'SCR-066','SCR-070'}); ck('UIF15 canonical screens',flows['UIF-15']['screens']==['SCR-054','SCR-055','SCR-056','SCR-057','SCR-058','SCR-059'])
ck('SCR070 approval only visible action',[a['id'] for a in screens['SCR-070']['actions']]==['ACT-COMMON-DECIDE']); ck('SCR070 commit trace-only',screens['SCR-070']['traceActions']==['ACT-13-COMMIT']); ck('SCR071 no visible mutation action',screens['SCR-071']['actions']==[] and screens['SCR-071']['traceActions']==['ACT-13-COMMIT']); ck('SCR059 export trace-only',screens['SCR-059']['actions']==[] and screens['SCR-059']['traceActions']==['ACT-11-EXPORT'])
ck('Approver URL resolver exists','activeFlowId === "UIF-12" && entryMode === "approver"' in app and 'activeScreenId = "SCR-070"' in app)
for x in ['"SCR-054":render054CF15','"SCR-059":render059CF15','"SCR-066":render066CF12','"SCR-071":render071CF12']: ck('Renderer installed '+x,x in app)
for f in ['UIF-12-BJ-12.md','UIF-15-BJ-15.md']:
 t=(PROTO/'flows'/f).read_text(encoding='utf-8'); ck(f+' v1.8 correction','v1.8.0 Product correction' in t); ck(f+' frozen-source declaration','Source SRS frozen' in t)
ck('UIF12 maker does not navigate to approver','Không có mũi tên maker `SCR-069 → SCR-070`' in (PROTO/'flows/UIF-12-BJ-12.md').read_text(encoding='utf-8'))
for sid in target:
 t=(PROTO/'contracts/screens'/f'{sid}.md').read_text(encoding='utf-8'); ck(sid+' contract corrected','PRODUCT_CORRECTED_v1.8.0' in t); ck(sid+' contract 402x874','402×874' in t)
for f in ['UIF-12-COMPONENT-USAGE.md','UIF-12-COMPONENT-USAGE.yaml','UIF-15-COMPONENT-USAGE.md','UIF-15-COMPONENT-USAGE.yaml']:
 t=(PROTO/'contracts/component-usage'/f).read_text(encoding='utf-8'); ck(f+' corrected','PRODUCT_CORRECTED_v1.8.0' in t)
ck('v1.8 CSS block target-scoped','v1.8.0 — Control Foundation & Inquiry' in css and 'body[data-active-uif="UIF-12"]' in css and 'body[data-active-uif="UIF-15"]' in css)
sec=app[app.index('// v1.8.0 — Control Foundation & Inquiry'):app.index('const renderers =',app.index('// v1.8.0 — Control Foundation & Inquiry'))]
for bad in ['hash','idempotency','outbox','retry','replay','operation id','movement id','event id','batch']: ck('No target renderer term: '+bad,bad.lower() not in sec.lower())
ck('BJ12 uses user control totals','Tổng số lượng kiểm soát' in sec and 'Tổng giá trị kiểm soát' in sec); ck('BJ15 warns against mixed-UOM total','Không cộng các số lượng khác đơn vị thành một tổng giả.' in sec); ck('BJ15 finance restriction omits values','state!=="FINANCIAL_RESTRICTED"' in sec)
sr=json.loads((PROTO/'contracts/screen-registry.json').read_text(encoding='utf-8')); reg={s['id']:s for s in sr['screens']}; ck('Screen registry version = 1.8.0',sr.get('version')=='1.8.0'); ck('All target screens corrected',all(reg[x]['prototype_status']=='PRODUCT_CORRECTED_v1.8.0' for x in target)); ck('All target data anatomy corrected',all(reg[x]['design_readiness']['data_contract_level']=='PRODUCT_SEMANTIC_ANATOMY_v1.8.0' for x in target))
uf=json.loads((PROTO/'flows/ui-flow-registry.json').read_text(encoding='utf-8')); fm={f['id']:f for f in uf['flows']}; ck('UI flow patch = 1.8.0',uf.get('patch_version')=='1.8.0'); ck('UIF12/UIF15 corrected',all(fm[x]['prototype_status']=='GROUP_PRODUCT_CORRECTED_v1.8.0' for x in ['UIF-12','UIF-15'])); ck('UIF12 registry has approver entry',set(fm['UIF-12']['entry_screen_ids'])=={'SCR-066','SCR-070'})
ck('README states v1.7.0 parent','successor of **v1.7.0**' in (ROOT.parents[4]/'README.md').read_text(encoding='utf-8'))
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Control Foundation & Inquiry Static QA v1.8.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'CONTROL-FOUNDATION-INQUIRY-STATIC-QA-v1.8.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed)); raise SystemExit(1)
