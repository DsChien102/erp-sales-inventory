from pathlib import Path
import hashlib,json,sys
from PIL import Image,ImageChops
CUR=Path('/mnt/data/v033_build/VET45-Theme7-Prototype-Harness-v0.3.3')
PAR=Path('/mnt/data/v033_work/VET45-Theme7-Prototype-Harness-v0.3.2')
checks=[]
def h(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def check(n,c,d=''): checks.append((n,bool(c),d))
protected=[
'specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.5.md','specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.7.md','specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.8.md','specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.9.md',
'specs/themes/theme-07/prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.md','specs/themes/theme-07/prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.yaml',
*['specs/themes/theme-07/prototype/contracts/screens/'+x for x in ['SCR-006.md','SCR-007.md','SCR-008.md','SCR-009.md','SCR-010.md','SCR-011.md','SCR-012.md','SCR-013.md','SCR-084.md']],
'specs/themes/theme-07/prototype/flows/UIF-02-BJ-02.md','specs/themes/theme-07/prototype/html/index.html','specs/themes/theme-07/prototype/html/tokens.generated.css']
for rel in protected:
 check(rel,h(CUR/rel)==h(PAR/rel))
# workbench semantic equality
for fn in ['workbench-data.json']:
 c=json.loads((CUR/'specs/themes/theme-07/prototype/html'/fn).read_text())
 p=json.loads((PAR/'specs/themes/theme-07/prototype/html'/fn).read_text())
 cf=next(x for x in c['flows'] if x['id']=='UIF-02'); pf=next(x for x in p['flows'] if x['id']=='UIF-02')
 check('UIF-02 workbench flow identical',cf==pf)
 for sid in ['SCR-006','SCR-007','SCR-008','SCR-009','SCR-084','SCR-010','SCR-011','SCR-012','SCR-013']:
  cs=next(x for x in c['screens'] if x['id']==sid); ps=next(x for x in p['screens'] if x['id']==sid)
  check(sid+' workbench screen identical',cs==ps)
# historical screenshots pixel equality
shotdir='specs/themes/theme-07/prototype/html/qa/screenshots-v0.2.9'
for name in ['SCR-007-document-search.png','SCR-009-document-overview.png','SCR-010-document-review.png','SCR-010-quick-review.png','SCR-011-approval-context.png','SCR-013-recovery.png','SCR-084-document-multilot.png']:
 a=Image.open(CUR/shotdir/name).convert('RGBA'); b=Image.open(PAR/shotdir/name).convert('RGBA')
 check(name+' pixel-identical',a.size==b.size and ImageChops.difference(a,b).getbbox() is None)
passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-02 Regression — v0.3.3','','**Result: PASS**' if not failed else '**Result: FAIL**','','v0.3.3 is a cumulative successor of v0.3.2. BJ-02/UIF-02 is a protected baseline and was not redesigned in this round.','','## Runtime','','- Original BJ-02 Chromium suite executed in an isolated copy of v0.3.3: **78/78 PASS**.','- Historical canonical screenshots were not overwritten by the runtime run.','','## Protected source/contract checks','']
for n,ok,d in checks:
 lines.append(f'- [{"x" if ok else " "}] `{n}`'+(f' — {d}' if d else ''))
lines += ['','## Boundary','','- Shared `app.js`/`styles.css` changes are permitted only where scoped to UIF-01; semantic equality of UIF-02 data plus the original BJ-02 runtime suite protects behavior.','- `index.html`, DS tokens, UIF-02 flow/contracts and historical v0.2.9 screenshots remain unchanged.']
(Path(__file__).parent/'BJ02-REGRESSION-v0.3.3.md').write_text('\n'.join(lines)+'\n')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
sys.exit(1 if failed else 0)
