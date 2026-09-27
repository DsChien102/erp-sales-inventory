from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
PROTO=ROOT.parent
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf-8'))
app=(ROOT/'app.js').read_text(encoding='utf-8'); css=(ROOT/'styles.css').read_text(encoding='utf-8'); idx=(ROOT/'index.html').read_text(encoding='utf-8')
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
flows={f['id']:f for f in wb['flows']}; screens={s['id']:s for s in wb['screens']}
checks=[]
def ck(name,cond): checks.append((name,bool(cond)))
TARGET=[f'SCR-{i:03d}' for i in range(48,54)]+[f'SCR-{i:03d}' for i in range(78,84)]
ck('Workbench version = 1.7.0',wb.get('version')=='1.7.0')
ck('Manifest version = 1.7.0',manifest.get('version')=='1.7.0')
ck('Index review badge = v1.7.0','v1.7.0 · Correction & Recovery · BJ11 · BJ16 · BJ17' in idx)
ck('UIF11 canonical screen order',flows['UIF-11']['screens']==['SCR-048','SCR-049','SCR-052','SCR-050','SCR-053','SCR-051'])
ck('UIF11 independent entry surfaces',set(flows['UIF-11']['entry'])=={'SCR-048','SCR-049','SCR-051'})
ck('UIF16 canonical screen order',flows['UIF-16']['screens']==['SCR-078','SCR-079','SCR-080','SCR-081','SCR-082','SCR-083'])
ck('UIF17 canonical screen order',flows['UIF-17']['screens']==['SCR-078','SCR-079','SCR-080','SCR-082','SCR-083'])
ck('SCR050 trace maps UC11 prepare/approve',screens['SCR-050']['uc']==['UC-11-03','UC-11-04'])
ck('SCR050 only visible submit action',[a['id'] for a in screens['SCR-050']['actions']]==['ACT-10-SUBMIT'])
ck('SCR050 Save Draft is trace-only',screens['SCR-050']['traceActions']==['ACT-10-SAVE-DRAFT'])
ck('SCR053 result has no visible mutation action',screens['SCR-053']['actions']==[] and 'ACT-10-CORRECT' in screens['SCR-053']['traceActions'])
ck('SCR083 result has no visible mutation action',screens['SCR-083']['actions']==[] and 'ACT-15-RECONCILE' in screens['SCR-083']['traceActions'])
ck('UIF11 renderer registry installed',all(x in app for x in ['"SCR-048":render048CR11','"SCR-053":render053CR11']))
ck('UIF16/17 shared renderer registry installed',all(x in app for x in ['"SCR-078":render078CR','"SCR-083":render083CR']))
ck('Approver URL entry resolver exists','activeFlowId === "UIF-11" && entryMode === "approver"' in app and 'activeScreenId = "SCR-051"' in app)
ck('Operation-context resolver exists','activeFlowId === "UIF-11" && entryMode === "operation-context"' in app)
ck('Case-context resolver exists','activeFlowId === "UIF-16" && entryMode === "case-context"' in app)
ck('UNKNOWN-context resolver exists','activeFlowId === "UIF-17" && entryMode === "unknown-context"' in app)
# flow docs contracts
for f in ['UIF-11-BJ-11.md','UIF-16-BJ-16.md','UIF-17-BJ-17.md']:
    t=(PROTO/'flows'/f).read_text(encoding='utf-8')
    ck(f'{f} has v1.7.0 Product correction','v1.7.0 Product correction' in t)
    ck(f'{f} blocks architecture explanation in Product UI','Product UI' in t and ('không render' in t or 'không phải' in t))
# screen contracts
for sid in TARGET:
    t=(PROTO/'contracts/screens'/f'{sid}.md').read_text(encoding='utf-8')
    ck(f'{sid} contract corrected', 'PRODUCT_CORRECTED_v1.7.0' in t)
    ck(f'{sid} contract 402x874', '402×874' in t)
# scoped CSS marker + target selectors
ck('v1.7 CSS block exists','v1.7.0' in css and 'Correction & Recovery' in css)
ck('v1.7 CSS is target-scoped', 'body[data-active-uif="UIF-11"]' in css and 'body[data-active-uif="UIF-16"]' in css and 'body[data-active-uif="UIF-17"]' in css)
# static negative checks in targeted metadata/renderer section
start=app.index('// v1.7.0 — Correction & Recovery')
end=app.index('const renderers =',start)
section=app[start:end]
for bad in ['payload hash','CommandReceipt','Outbox','Ledger mutation','8.420']:
    ck(f'No target Product copy: {bad}',bad.lower() not in section.lower())
# technical words can exist in code comments; ensure they are not field/CTA labels
for pat in [r'>\s*Retry\s*<',r'>\s*Replay\s*<',r'label>Hash',r'"Dựng lại projection"',r'"Lưu nháp operation"']:
    ck(f'No raw target Product control /{pat}/',re.search(pat,section,re.I) is None)
# registry status
sr=json.loads((PROTO/'contracts/screen-registry.json').read_text(encoding='utf-8'))
ck('Screen registry version = 1.7.0',sr.get('version')=='1.7.0')
reg={s['id']:s for s in sr['screens']}
ck('All target screen-registry entries corrected',all(reg[x]['prototype_status']=='PRODUCT_CORRECTED_v1.7.0' for x in TARGET))
uf=json.loads((PROTO/'flows/ui-flow-registry.json').read_text(encoding='utf-8'))
ufm={f['id']:f for f in uf['flows']}
ck('UI flow registry patch = 1.7.0',uf.get('patch_version')=='1.7.0')
ck('Target UIF registry corrected',all(ufm[x]['prototype_status']=='GROUP_PRODUCT_CORRECTED_v1.7.0' for x in ['UIF-11','UIF-16','UIF-17']))
# immutable source claim is checked separately by hash QA, here ensure docs state parent
ck('Root README states v1.6.0 parent','successor of **v1.6.0**' in (ROOT.parents[4]/'README.md').read_text(encoding='utf-8'))
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Correction & Recovery Static QA v1.7.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'CORRECTION-RECOVERY-STATIC-QA-v1.7.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
