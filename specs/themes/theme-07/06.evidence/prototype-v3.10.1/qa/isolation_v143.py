from pathlib import Path
import hashlib, json

P=Path('/mnt/data/v143_parent/VET45-Theme7-Prototype-Harness-v1.4.2')
C=Path('/mnt/data/v143_work/VET45-Theme7-Prototype-Harness-v1.4.3')
OUT=C/'specs/themes/theme-07/prototype/html/qa/ISOLATION-REPORT-v1.4.3.md'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def files(root):
    return {p.relative_to(root):p for p in root.rglob('*') if p.is_file() and '__pycache__' not in p.parts}

allowed_mod_exact={
 'README.md',
 'specs/themes/theme-07/prototype/HARNESS-FINAL-REPORT.md',
 'specs/themes/theme-07/prototype/HARNESS-STATUS.yaml',
 'specs/themes/theme-07/prototype/README.md',
 'specs/themes/theme-07/prototype/contracts/README.md',
 'specs/themes/theme-07/prototype/contracts/bj-ui-flow-map.md',
 'specs/themes/theme-07/prototype/contracts/navigation-areas.md',
 'specs/themes/theme-07/prototype/contracts/screen-registry.json',
 'specs/themes/theme-07/prototype/contracts/screen-registry.md',
 'specs/themes/theme-07/prototype/flows/README.md',
 'specs/themes/theme-07/prototype/flows/ui-flow-registry.json',
 'specs/themes/theme-07/prototype/html/README.md',
 'specs/themes/theme-07/prototype/html/app.js',
 'specs/themes/theme-07/prototype/html/manifest.json',
 'specs/themes/theme-07/prototype/html/workbench-data.js',
 'specs/themes/theme-07/prototype/html/workbench-data.json',
 'specs/themes/theme-07/prototype/reviews/LOCAL-REVIEW-UIF-04.md',
}
allowed_screen_ids={'003','009','011','013','014','020','021','022','023','024','025','030','031','034','035','036','037','041'}
allowed_flow_ids={'01','02','03','04','05','06','07'}

def allowed_modified(r):
    s=r.as_posix()
    if s in allowed_mod_exact: return True
    if s.startswith('specs/themes/theme-07/prototype/contracts/screens/SCR-') and s.endswith('.md'):
        return Path(s).stem.replace('SCR-','') in allowed_screen_ids
    if s.startswith('specs/themes/theme-07/prototype/flows/UIF-') and s.endswith('.md'):
        name=Path(s).name
        return any(name.startswith(f'UIF-{x}-') for x in allowed_flow_ids)
    return False

def allowed_added(r):
    s=r.as_posix()
    if s=='specs/themes/theme-07/prototype/contracts/entry-architecture.md': return True
    if s=='specs/themes/theme-07/prototype/html/CHANGELOG-v1.4.3.md': return True
    if s=='specs/themes/theme-07/prototype/reviews/INVENTORY-OPS-BJ03-ENTRY-CONTINUITY-v1.4.3.md': return True
    if s.startswith('specs/themes/theme-07/prototype/html/qa/'):
        return ('v1.4.3' in s or s.endswith('_v143.py') or '/screenshots-v1.4.3/' in s)
    return False

pf=files(P); cf=files(C)
modified=sorted(r for r in pf.keys()&cf.keys() if sha(pf[r])!=sha(cf[r]))
added=sorted(cf.keys()-pf.keys()); removed=sorted(pf.keys()-cf.keys())
unauth_mod=[r for r in modified if not allowed_modified(r)]
unauth_add=[r for r in added if not allowed_added(r)]

checks=[]
def ck(n,c): checks.append((n,bool(c)))
ck('No parent file removed',not removed)
ck('All modified parent files are inside approved entry/journey scope',not unauth_mod)
ck('All new files are entry contract or v1.4.3 evidence/review/changelog',not unauth_add)
ck('No SRS file changed',not any(r.as_posix().startswith('specs/themes/theme-07/srs/') for r in modified))
ck('No know-how file changed',not any('/know-how/' in '/'+r.as_posix()+'/' for r in modified))
ck('No outbound/migration/validation source changed',not any(any(x in r.as_posix() for x in ['/outbound/','/migration/','/validation/']) for r in modified))
ck('No Flutter DS lock/component-usage/style token file changed',not any(any(x in r.as_posix() for x in ['FLUTTER-DS-LOCK','component-usage/','tokens.generated.css','styles.css']) for r in modified))
# Protected non-target flow docs and component contracts must stay byte-identical.
protected=[f'{i:02d}' for i in range(8,18)]
flow_mod=[r.as_posix() for r in modified if '/prototype/flows/UIF-' in '/'+r.as_posix() and not any(f'/UIF-{x}-' in '/'+r.as_posix() for x in allowed_flow_ids)]
ck('UIF08-UIF17 flow documents are byte-identical to parent',not flow_mod)
comp_mod=[r.as_posix() for r in modified if '/prototype/contracts/component-usage/' in '/'+r.as_posix()]
ck('All component-usage contracts are byte-identical to parent',not comp_mod)
ck('Product styling is byte-identical to parent',sha(P/'specs/themes/theme-07/prototype/html/styles.css')==sha(C/'specs/themes/theme-07/prototype/html/styles.css') and sha(P/'specs/themes/theme-07/prototype/html/tokens.generated.css')==sha(C/'specs/themes/theme-07/prototype/html/tokens.generated.css'))
# Machine trace must not resurrect invalid UIF07 transition IDs.
reg=json.loads((C/'specs/themes/theme-07/prototype/contracts/screen-registry.json').read_text(encoding='utf8'))
stale=[]
for s in reg['screens']:
    dr=s.get('design_readiness') or {}
    for key in ('entry_transition_ids','exit_transition_ids','evidence_sources'):
        for x in dr.get(key,[]) or []:
            if isinstance(x,str) and x in {'UIF-07-T09','UIF-07-T10','UIF-07-T11'}: stale.append((s['id'],key,x))
ck('No stale UIF07 T09/T10/T11 machine-registry references remain',not stale)
# Runtime protected report is a mandatory isolation gate.
prot=(C/'specs/themes/theme-07/prototype/html/qa/REGRESSION-PROTECTED-FLOWS-v1.4.3.md')
ck('Protected UIF08-UIF17 runtime regression is PASS',prot.is_file() and '**Result: PASS · 121/121 checks**' in prot.read_text(encoding='utf8'))
ck('No pycache artifacts packaged',not any('__pycache__' in p.parts for p in C.rglob('*')))
ck('Only prototype/root README changed outside prototype subtree',all(r.as_posix()=='README.md' or r.as_posix().startswith('specs/themes/theme-07/prototype/') for r in modified))

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Isolation Report v1.4.3','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       '- Parent: `VET45-Theme7-Prototype-Harness-v1.4.2`.',
       '- Child: `VET45-Theme7-Prototype-Harness-v1.4.3`.',
       '- Scope: Inventory Operations + BJ03 entry architecture and journey continuity; no business-rule/lifecycle/commit change.',
       f'- Modified parent files: **{len(modified)}**.',f'- Added files: **{len(added)}**.',f'- Removed files: **{len(removed)}**.','',
       '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
lines += ['','## Modified parent files','']+[f'- `{r.as_posix()}`' for r in modified]
lines += ['','## Added files','']+[f'- `{r.as_posix()}`' for r in added]
if removed: lines += ['','## Removed files','']+[f'- `{r.as_posix()}`' for r in removed]
if unauth_mod: lines += ['','## Unauthorized modifications','']+[f'- `{r.as_posix()}`' for r in unauth_mod]
if unauth_add: lines += ['','## Unauthorized additions','']+[f'- `{r.as_posix()}`' for r in unauth_add]
if stale: lines += ['','## Stale registry refs','']+[f'- `{x}`' for x in stale]
OUT.write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'modified',len(modified),'added',len(added),'removed',len(removed))
if failed:
    print('\n'.join(failed));
    if unauth_mod: print('unauthorized modified:',*[x.as_posix() for x in unauth_mod],sep='\n')
    if unauth_add: print('unauthorized added:',*[x.as_posix() for x in unauth_add],sep='\n')
    raise SystemExit(1)
