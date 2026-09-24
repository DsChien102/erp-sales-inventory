from pathlib import Path
import hashlib
CHILD=Path(__file__).resolve().parents[6]
PARENT=Path('/mnt/data/v150_parent/VET45-Theme7-Prototype-Harness-v1.4.5')
OUT=Path(__file__).resolve().parent

def files(root): return {p.relative_to(root) for p in root.rglob('*') if p.is_file()}
def sha(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for block in iter(lambda:f.read(1<<20),b''): h.update(block)
 return h.hexdigest()
def common_tree_same(rel):
 a=PARENT/rel; b=CHILD/rel
 af=files(a) if a.exists() else set(); bf=files(b) if b.exists() else set()
 return af==bf and all(sha(a/r)==sha(b/r) for r in af)

pf,cf=files(PARENT),files(CHILD)
mods=sorted(r for r in pf&cf if sha(PARENT/r)!=sha(CHILD/r)); adds=sorted(cf-pf); removed=sorted(pf-cf)
checks=[]
def ck(n,c): checks.append((n,bool(c)))

allowed_srs={
 Path('specs/themes/theme-07/srs/02-business-journeys/14-BJ-14-tinh-va-cong-bo-gia-von.md'),
 Path('specs/themes/theme-07/srs/04-data-entities.md'),
 Path('specs/themes/theme-07/srs/05-use-cases/BJ-14-tinh-va-cong-bo-gia-von/UC-14-02-tinh-gia-von-va-phat-hien-blocker.md'),
 Path('specs/themes/theme-07/srs/05-use-cases/BJ-14-tinh-va-cong-bo-gia-von/UC-14-03-ra-soat-ket-qua.md'),
 Path('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'),
 Path('specs/themes/theme-07/srs/08-ui-ux.md'),
}
modified_srs={r for r in mods if str(r).startswith('specs/themes/theme-07/srs/')}
target_flow_files={'UIF-03-BJ-03.md','UIF-13-BJ-13.md','UIF-14-BJ-14.md'}
target_cu={'UIF-03-COMPONENT-USAGE.md','UIF-03-COMPONENT-USAGE.yaml','UIF-13-COMPONENT-USAGE.md','UIF-13-COMPONENT-USAGE.yaml','UIF-14-COMPONENT-USAGE.md','UIF-14-COMPONENT-USAGE.yaml'}
target_screens={f'SCR-{n:03d}.md' for n in [14,15,16,17,19,72,73,74,75,76,77,85,86,87,88,89]}

ck('Parent v1.4.5 exists',PARENT.exists())
ck('No parent file removed',not removed)
ck('Frozen source byte-identical',common_tree_same(Path('specs/themes/theme-07/harness/frozen-source')))
ck('Know-how byte-identical',common_tree_same(Path('specs/themes/theme-07/know-how')))
ck('Outbound byte-identical',common_tree_same(Path('specs/themes/theme-07/outbound')))
ck('Migration byte-identical',common_tree_same(Path('specs/themes/theme-07/migration')))
ck('Design-readiness history byte-identical',common_tree_same(Path('specs/themes/theme-07/design-readiness')))
ck('Only intended current SRS files changed',modified_srs<=allowed_srs)
ck('No non-valuation BJ current SRS changed',all(not (str(r).startswith('specs/themes/theme-07/srs/02-business-journeys/') and '/14-BJ-14-' not in '/'+str(r)) for r in modified_srs))
ck('No non-valuation UC current SRS changed',all(not str(r).startswith('specs/themes/theme-07/srs/05-use-cases/') or '/BJ-14-' in '/'+str(r) for r in modified_srs))
ck('Only UIF03/UIF13/UIF14 individual flow markdown changed',all((not str(r).startswith('specs/themes/theme-07/prototype/flows/UIF-')) or r.name in target_flow_files for r in mods))
ck('Only valuation component-usage contracts changed',all((not str(r).startswith('specs/themes/theme-07/prototype/contracts/component-usage/UIF-')) or r.name in target_cu for r in mods))
ck('Only valuation screen contracts changed',all((not str(r).startswith('specs/themes/theme-07/prototype/contracts/screens/SCR-')) or r.name in target_screens for r in mods))
# Historical QA evidence must not be rewritten. New v1.5.0 evidence is allowed.
hist_ok=True
for r in pf&cf:
 if not str(r).startswith('specs/themes/theme-07/prototype/html/qa/'): continue
 name=str(r)
 if 'screenshots-v1.5.0/' in name or 'v1.5.0' in name or r.name.endswith('_v150.py'): continue
 if sha(PARENT/r)!=sha(CHILD/r): hist_ok=False; break
ck('Historical QA evidence byte-identical',hist_ok)
# Protected runtime regression verifies all non-target UIFs against parent.
reports={
 'Static':'INVENTORY-VALUATION-STATIC-QA-v1.5.0.md',
 'End-user':'INVENTORY-VALUATION-END-USER-QA-v1.5.0.md',
 'Scenario':'INVENTORY-VALUATION-SCENARIO-QA-v1.5.0.md',
 'Integration':'INVENTORY-VALUATION-INTEGRATION-QA-v1.5.0.md',
 'Protected regression':'REGRESSION-PROTECTED-FLOWS-v1.5.0.md',
 'All-flow runtime':'ALL-FLOWS-RUNTIME-SMOKE-v1.5.0.md',
 'Visual':'VISUAL-QA-v1.5.0.md',
}
for label,file in reports.items():
 p=OUT/file; ck(f'{label} report PASS',p.exists() and '**Result: PASS' in p.read_text(encoding='utf8'))
review=CHILD/'specs/themes/theme-07/prototype/reviews/INVENTORY-VALUATION-GROUP-PRODUCT-CORRECTION-v1.5.0.md'
ck('Current Product review exists',review.exists())
failed=[n for n,v in checks if not v]
lines=['# Isolation Report v1.5.0 — Inventory Valuation Group Product Correction','',f'**Result: {"PASS" if not failed else "FAIL"} · {sum(v for _,v in checks)}/{len(checks)} checks**','', '- Parent: `v1.4.5`.', '- Target: BJ03/UIF03 + BJ13/UIF13 + BJ14/UIF14 plus minimum shared current valuation contracts/registries/workbench needed to keep the group coherent.', '- Frozen source, know-how, outbound, migration, design-readiness and historical QA evidence remain immutable.','',f'- Parent files modified: **{len(mods)}**',f'- Files added: **{len(adds)}**',f'- Files removed: **{len(removed)}**','', '## Checks','']+[f'- [{"x" if ok else " "}] {name}' for name,ok in checks]
lines += ['','## Modified parent files','']+[f'- `{r}`' for r in mods]
lines += ['','## Added files','']+[f'- `{r}`' for r in adds]
if removed: lines += ['','## Removed files','']+[f'- `{r}`' for r in removed]
(OUT/'ISOLATION-REPORT-v1.5.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),sum(v for _,v in checks),'/',len(checks),'modified',len(mods),'added',len(adds),'removed',len(removed))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
