from pathlib import Path
import hashlib
P=Path('/mnt/data/v142_work/VET45-Theme7-Prototype-Harness-v1.4.1')
C=Path('/mnt/data/v142_work/VET45-Theme7-Prototype-Harness-v1.4.2')
OUT=C/'specs/themes/theme-07/prototype/html/qa/ISOLATION-REPORT-v1.4.2.md'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def files(root): return {p.relative_to(root):p for p in root.rglob('*') if p.is_file() and '__pycache__' not in p.parts}

def allowed_modified(r):
    s=str(r)
    exact={
      'README.md',
      'specs/themes/theme-07/prototype/html/README.md',
      'specs/themes/theme-07/prototype/html/app.js',
      'specs/themes/theme-07/prototype/html/styles.css',
      'specs/themes/theme-07/prototype/html/workbench-data.js',
      'specs/themes/theme-07/prototype/html/manifest.json',
      'specs/themes/theme-07/prototype/flows/UIF-02-BJ-02.md',
    }
    if s in exact: return True
    if s.startswith('specs/themes/theme-07/prototype/contracts/component-usage/UIF-') and s.endswith('-COMPONENT-USAGE.yaml'):
        return Path(s).name.split('-')[1] in {'02','03','05','06','07'}
    if s.startswith('specs/themes/theme-07/prototype/contracts/screens/SCR-') and s.endswith('.md'):
        sid=Path(s).stem.replace('SCR-','')
        return sid in {'009','010','011','012','015','016','017','019','025','026','027','028','031','034','035','037','039','041'}
    return False

def allowed_added(r):
    s=str(r)
    if s=='specs/themes/theme-07/prototype/html/CHANGELOG-v1.4.2.md': return True
    if s=='specs/themes/theme-07/prototype/reviews/BJ01-BJ07-BJ03-SEMANTIC-HIERARCHY-v1.4.2.md': return True
    if s.startswith('specs/themes/theme-07/prototype/html/qa/'):
        return ('v1.4.2' in s or s.endswith('_v142.py') or '/screenshots-v1.4.2/' in s)
    return False

pf=files(P); cf=files(C)
modified=sorted(r for r in pf.keys()&cf.keys() if sha(pf[r])!=sha(cf[r]))
added=sorted(cf.keys()-pf.keys())
removed=sorted(pf.keys()-cf.keys())
unauth_mod=[r for r in modified if not allowed_modified(r)]
unauth_add=[r for r in added if not allowed_added(r)]

checks=[]
def ck(n,c): checks.append((n,bool(c)))
ck('No parent file removed',not removed)
ck('All modified parent files are inside approved semantic-correction scope',not unauth_mod)
ck('All new files are release evidence/review/changelog only',not unauth_add)
ck('No SRS file changed',not any(str(r).startswith('specs/themes/theme-07/srs/') for r in modified))
ck('No know-how file changed',not any('/know-how/' in '/'+str(r)+'/' for r in modified))
ck('No data-entity/use-case/business-rule source changed',not any(any(x in str(r).lower() for x in ['/data-','/usecase','business-rule','domain-foundation']) for r in modified))
ck('Only UIF02 flow copy changed; no other flow file changed',[str(r) for r in modified if '/prototype/flows/' in '/'+str(r)]==['specs/themes/theme-07/prototype/flows/UIF-02-BJ-02.md'])
ck('UIF07 active flow file is byte-identical to parent',sha(P/'specs/themes/theme-07/prototype/flows/UIF-07-BJ-07.md')==sha(C/'specs/themes/theme-07/prototype/flows/UIF-07-BJ-07.md'))
ck('UIF01 flow file is byte-identical to parent',sha(P/'specs/themes/theme-07/prototype/flows/UIF-01-BJ-01.md')==sha(C/'specs/themes/theme-07/prototype/flows/UIF-01-BJ-01.md'))
ck('UIF04 flow file is byte-identical to parent',sha(P/'specs/themes/theme-07/prototype/flows/UIF-04-BJ-04.md')==sha(C/'specs/themes/theme-07/prototype/flows/UIF-04-BJ-04.md'))
ck('UIF13 flow file is byte-identical to parent',sha(P/'specs/themes/theme-07/prototype/flows/UIF-13-BJ-13.md')==sha(C/'specs/themes/theme-07/prototype/flows/UIF-13-BJ-13.md'))
ck('No screen/flow registry file removed',not removed)

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Isolation Report v1.4.2','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       '- Parent: `VET45-Theme7-Prototype-Harness-v1.4.1`.',
       '- Child: `VET45-Theme7-Prototype-Harness-v1.4.2`.',
       '- Scope: Inventory Operations + BJ03 semantic hierarchy correction; no business-rule/lifecycle/commit change.',
       f'- Modified parent files: **{len(modified)}**.',
       f'- Added files: **{len(added)}**.',
       f'- Removed files: **{len(removed)}**.','',
       '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
lines += ['','## Modified parent files','']+[f'- `{r}`' for r in modified]
lines += ['','## Added files','']+[f'- `{r}`' for r in added]
if removed: lines += ['','## Removed files','']+[f'- `{r}`' for r in removed]
if unauth_mod: lines += ['','## Unauthorized modifications','']+[f'- `{r}`' for r in unauth_mod]
if unauth_add: lines += ['','## Unauthorized additions','']+[f'- `{r}`' for r in unauth_add]
OUT.write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'modified',len(modified),'added',len(added),'removed',len(removed))
if failed:
    print('\n'.join(failed));
    if unauth_mod: print('unauth mod',*unauth_mod,sep='\n')
    if unauth_add: print('unauth add',*unauth_add,sep='\n')
    raise SystemExit(1)
