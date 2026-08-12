from pathlib import Path
import hashlib
CHILD=Path(__file__).resolve().parents[6]
PARENT=Path('/mnt/data/t07_v180_src/VET45-Theme7-Prototype-Harness-v1.8.0')
OUT=Path(__file__).resolve().parent
def h(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]; diffs=[]
ps=PARENT/'specs/themes/theme-07/srs'; cs=CHILD/'specs/themes/theme-07/srs'
pfiles=sorted(x.relative_to(ps) for x in ps.rglob('*') if x.is_file()); cfiles=sorted(x.relative_to(cs) for x in cs.rglob('*') if x.is_file()); checks.append(('SRS file set exact',pfiles==cfiles))
for rel in sorted(set(pfiles)&set(cfiles)):
 if h(ps/rel)!=h(cs/rel): diffs.append(str(rel))
checks.append((f'All {len(pfiles)} SRS files byte-identical',not diffs))
pm=PARENT/'specs/themes/theme-07/theme.manifest.yaml'; cm=CHILD/'specs/themes/theme-07/theme.manifest.yaml'; checks.append(('theme.manifest.yaml byte-identical',h(pm)==h(cm)))
failed=[n for n,v in checks if not v];passed=sum(v for _,v in checks)
lines=['# Frozen-source Immutability QA v1.9.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} gates**','','- Parent: v1.8.0.','- Child: v1.9.0.','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if diffs: lines+=['','## SRS byte diffs']+[f'- {x}' for x in diffs]
(OUT/'SOURCE-IMMUTABILITY-QA-v1.9.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8'); print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: raise SystemExit(1)
