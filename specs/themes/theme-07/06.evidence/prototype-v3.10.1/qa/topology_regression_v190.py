from pathlib import Path
import json
CHILD=Path(__file__).resolve().parents[1]
PARENT=Path('/mnt/data/t07_v180_src/VET45-Theme7-Prototype-Harness-v1.8.0/specs/themes/theme-07/prototype/html')
OUT=Path(__file__).resolve().parent
p=json.load(open(PARENT/'workbench-data.json')); c=json.load(open(CHILD/'workbench-data.json'))
checks=[]
def ck(n,x):checks.append((n,bool(x)))
ck('Flow order and IDs exact',[f['id'] for f in p['flows']]==[f['id'] for f in c['flows']])
pm={f['id']:f for f in p['flows']};cm={f['id']:f for f in c['flows']}
ck('All 17 flow screen topologies exact',all(pm[k]['screens']==cm[k]['screens'] for k in pm))
ck('Run order exact',p['runOrder']==c['runOrder'])
ps={s['id']:s for s in p['screens']};cs={s['id']:s for s in c['screens']}
ck('Workbench screen ID set exact',set(ps)==set(cs))
ck('Registered state sets exact',all(ps[k].get('states')==cs[k].get('states') for k in ps))
active=set(s for f in c['flows'] for s in f['screens']);ck('73 active canonical screens preserved',len(active)==73)
failed=[n for n,v in checks if not v];passed=sum(v for _,v in checks)
lines=['# Topology Regression QA v1.9.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} gates**','','- Parent: v1.8.0.','- Child: v1.9.0.','- Holistic hardening may change Product copy/action ownership metadata, but does not invent/rebuild BJ topology.','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'TOPOLOGY-REGRESSION-QA-v1.9.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8');print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:raise SystemExit(1)
