from pathlib import Path
import hashlib

P=Path('/mnt/data/v141_work/VET45-Theme7-Prototype-Harness-v1.4.0')
C=Path('/mnt/data/v141_work/VET45-Theme7-Prototype-Harness-v1.4.1')
OUT=Path(__file__).resolve().parent

def h(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def files(root): return {p.relative_to(root):h(p) for p in root.rglob('*') if p.is_file()}
pf=files(P); cf=files(C)
mods=sorted(k for k in pf.keys()&cf if pf[k]!=cf[k])
adds=sorted(cf.keys()-pf.keys())
dels=sorted(pf.keys()-cf.keys())

changed_screens={'SCR-001.md','SCR-003.md','SCR-008.md','SCR-009.md','SCR-084.md','SCR-021.md','SCR-025.md','SCR-026.md','SCR-027.md','SCR-028.md','SCR-029.md','SCR-030.md','SCR-031.md','SCR-032.md','SCR-033.md','SCR-034.md','SCR-035.md','SCR-036.md','SCR-037.md','SCR-039.md','SCR-041.md'}
changed_uifs={'UIF-01-COMPONENT-USAGE.md','UIF-01-COMPONENT-USAGE.yaml','UIF-02-COMPONENT-USAGE.md','UIF-02-COMPONENT-USAGE.yaml','UIF-04-COMPONENT-USAGE.md','UIF-04-COMPONENT-USAGE.yaml','UIF-05-COMPONENT-USAGE.md','UIF-05-COMPONENT-USAGE.yaml','UIF-06-COMPONENT-USAGE.md','UIF-06-COMPONENT-USAGE.yaml','UIF-07-COMPONENT-USAGE.md','UIF-07-COMPONENT-USAGE.yaml'}

def allowed_mod(r):
    s=str(r)
    if s=='README.md': return True
    if s in {'specs/themes/theme-07/prototype/html/app.js','specs/themes/theme-07/prototype/html/styles.css'}: return True
    if s.startswith('specs/themes/theme-07/prototype/contracts/screens/') and r.name in changed_screens: return True
    if s.startswith('specs/themes/theme-07/prototype/contracts/component-usage/') and r.name in changed_uifs: return True
    return False

def same_prefix(prefix):
    keys=[k for k in pf if str(k).startswith(prefix)]
    return all(k in cf and pf[k]==cf[k] for k in keys)

def same_paths(paths):
    return all(Path(x) in pf and Path(x) in cf and pf[Path(x)]==cf[Path(x)] for x in paths)

checks=[]
def ck(name,cond): checks.append((name,bool(cond)))
ck('No parent files removed',not dels)
ck('Every modified parent file is inside declared UX correction scope',all(allowed_mod(k) for k in mods))
ck('SRS tree is byte-identical to v1.4.0',same_prefix('specs/themes/theme-07/srs/'))
ck('Know-how tree is byte-identical to v1.4.0',same_prefix('specs/themes/theme-07/know-how/'))
ck('UI flow registry and flow documents are byte-identical',same_prefix('specs/themes/theme-07/prototype/flows/'))
ck('Workbench data is byte-identical',same_paths(['specs/themes/theme-07/prototype/html/workbench-data.js','specs/themes/theme-07/prototype/html/workbench-data.json']))
ck('Core screen/action registries are byte-identical',same_paths(['specs/themes/theme-07/prototype/contracts/screen-registry.json','specs/themes/theme-07/prototype/contracts/action-registry.json']))
ck('UIF03 component usage is byte-identical',same_paths(['specs/themes/theme-07/prototype/contracts/component-usage/UIF-03-COMPONENT-USAGE.md','specs/themes/theme-07/prototype/contracts/component-usage/UIF-03-COMPONENT-USAGE.yaml']))
ck('UIF03 screen contracts are byte-identical',same_paths([f'specs/themes/theme-07/prototype/contracts/screens/{x}.md' for x in ['SCR-014','SCR-015','SCR-016','SCR-017','SCR-019']]))
ck('BJ03 v1.4.0 review evidence is byte-identical',same_paths(['specs/themes/theme-07/prototype/reviews/BJ03-DEEP-CORRECTION-v1.4.0.md','specs/themes/theme-07/prototype/html/qa/BJ03-END-USER-QA-v1.4.0.md','specs/themes/theme-07/prototype/html/qa/BJ03-STATIC-CONFORMANCE-v1.4.0.md']))
ck('Prior v1.4.0 screenshot evidence is byte-identical',same_prefix('specs/themes/theme-07/prototype/html/qa/screenshots-v1.4.0/'))
ck('Prior BJ05/BJ06/BJ07 QA evidence is byte-identical',all(same_prefix(f'specs/themes/theme-07/prototype/html/qa/screenshots-v{v}/') for v in ['1.3.7','1.3.8','1.3.9']))
ck('New files are additive v1.4.1 evidence/review/changelog only',all(('v1.4.1' in str(k) or k.name.endswith('_v141.py')) for k in adds))

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Isolation Report v1.4.1','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} isolation checks**','',
       'Parent: `VET45-Theme7-Prototype-Harness-v1.4.0`  ',
       'Child: `VET45-Theme7-Prototype-Harness-v1.4.1`','',
       f'- Modified parent files: **{len(mods)}**',
       f'- Added files: **{len(adds)}**',
       f'- Removed parent files: **{len(dels)}**','',
       'Shared `app.js/styles.css` are intentionally changed for Inventory Operations; `REGRESSION-UIF03-v1.4.1.md` independently proves UIF03 rendered Product text/pixels remain equivalent to v1.4.0.','',
       '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
lines += ['','## Modified parent files','']+[f'- `{x}`' for x in mods]
lines += ['','## Added files','']+[f'- `{x}`' for x in adds]
if dels: lines += ['','## Removed parent files','']+[f'- `{x}`' for x in dels]
(OUT/'ISOLATION-REPORT-v1.4.1.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'checks; mods',len(mods),'adds',len(adds),'dels',len(dels))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
