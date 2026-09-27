from pathlib import Path
import hashlib

CHILD=Path(__file__).resolve().parents[6]
PARENT=Path('/mnt/data/v145_parent/VET45-Theme7-Prototype-Harness-v1.4.4')
OUT=Path(__file__).resolve().parent

def files(root): return {p.relative_to(root) for p in root.rglob('*') if p.is_file()}
def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(1<<20),b''): h.update(block)
    return h.hexdigest()
def same_tree(rel):
    a=PARENT/rel; b=CHILD/rel
    af=files(a) if a.exists() else set(); bf=files(b) if b.exists() else set()
    return af==bf and all(sha(a/r)==sha(b/r) for r in af)

pf,cf=files(PARENT),files(CHILD)
mods=sorted(r for r in pf&cf if sha(PARENT/r)!=sha(CHILD/r))
adds=sorted(cf-pf); removed=sorted(pf-cf)
checks=[]
def ck(name,cond): checks.append((name,bool(cond)))

allowed_srs={
 Path('specs/themes/theme-07/srs/02-business-journeys/13-BJ-13-ghi-nhan-chi-phi-mua-den-muon.md'),
 Path('specs/themes/theme-07/srs/04-data-entities.md'),
 Path('specs/themes/theme-07/srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-01-xac-dinh-nguon-va-pham-vi.md'),
 Path('specs/themes/theme-07/srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-02-tinh-va-phan-bo-chi-phi.md'),
 Path('specs/themes/theme-07/srs/05-use-cases/BJ-13-ghi-nhan-chi-phi-mua-den-muon/UC-13-03-xac-nhan-ghi-nhan-chi-phi.md'),
 Path('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'),
 Path('specs/themes/theme-07/srs/07-technical-contracts.md'),
}
modified_srs={r for r in mods if str(r).startswith('specs/themes/theme-07/srs/')}
allowed_component_usage={'UIF-03-COMPONENT-USAGE.md','UIF-03-COMPONENT-USAGE.yaml','UIF-13-COMPONENT-USAGE.md','UIF-13-COMPONENT-USAGE.yaml'}
allowed_screen_contracts={'SCR-014.md','SCR-015.md','SCR-017.md','SCR-018.md','SCR-019.md'}
new_screen_contracts={f'SCR-{n:03d}.md' for n in range(85,90)}

ck('Parent exists',PARENT.exists())
ck('No parent file removed',not removed)
ck('Frozen source byte-identical',same_tree(Path('specs/themes/theme-07/harness/frozen-source')))
ck('Know-how byte-identical',same_tree(Path('specs/themes/theme-07/know-how')))
ck('Outbound byte-identical',same_tree(Path('specs/themes/theme-07/outbound')))
ck('Migration history byte-identical',same_tree(Path('specs/themes/theme-07/migration')))
ck('Design-readiness history byte-identical',same_tree(Path('specs/themes/theme-07/design-readiness')))
ck('Only intended current-SRS files changed',modified_srs<=allowed_srs)
ck('All intended BJ13/shared valuation SRS files changed',allowed_srs<=modified_srs)
ck('Inventory Operations BJ01-07 business journeys unchanged',same_tree(Path('specs/themes/theme-07/srs/02-business-journeys')) is False and all(sha(PARENT/r)==sha(CHILD/r) for r in pf&cf if str(r).startswith('specs/themes/theme-07/srs/02-business-journeys/') and '13-BJ-13-' not in str(r)))
ck('All non-BJ13 use-case trees unchanged',all(sha(PARENT/r)==sha(CHILD/r) for r in pf&cf if str(r).startswith('specs/themes/theme-07/srs/05-use-cases/') and '/BJ-13-' not in str(r)))
ck('Only UIF13 individual flow markdown changed',all((not str(r).startswith('specs/themes/theme-07/prototype/flows/UIF-')) or r.name=='UIF-13-BJ-13.md' for r in mods))
ck('Only UIF03/UIF13 component-usage contracts changed',all((not str(r).startswith('specs/themes/theme-07/prototype/contracts/component-usage/UIF-')) or r.name in allowed_component_usage for r in mods))
ck('Only boundary/retired old screens changed',all((not str(r).startswith('specs/themes/theme-07/prototype/contracts/screens/SCR-')) or r.name in allowed_screen_contracts for r in mods))
ck('Only SCR085..089 added as new screen contracts',all((not str(r).startswith('specs/themes/theme-07/prototype/contracts/screens/SCR-')) or r.name in new_screen_contracts for r in adds))
ck('BJ13 static QA PASS', 'PASS · 33/33' in (OUT/'BJ13-STATIC-QA-v1.4.5.md').read_text(encoding='utf8'))
ck('BJ13 end-user QA PASS', 'PASS · 36/36' in (OUT/'BJ13-END-USER-QA-v1.4.5.md').read_text(encoding='utf8'))
ck('Protected flow regression PASS', 'PASS · 100/100' in (OUT/'REGRESSION-PROTECTED-FLOWS-v1.4.5.md').read_text(encoding='utf8'))
ck('BJ03 foundation regression PASS', 'PASS · 38/38' in (OUT/'BJ03-FOUNDATION-QA-v1.4.4.md').read_text(encoding='utf8'))
ck('All-flow runtime PASS', 'PASS · 87' in (OUT/'ALL-FLOWS-RUNTIME-SMOKE-v1.4.5.md').read_text(encoding='utf8'))
ck('Visual QA PASS', 'PASS · 23/23' in (OUT/'VISUAL-QA-v1.4.5.md').read_text(encoding='utf8'))

failed=[n for n,v in checks if not v]
lines=[
 '# Isolation Report v1.4.5 — BJ13/UIF13 Deep Product Correction','',
 f'**Result: {"PASS" if not failed else "FAIL"} · {sum(v for _,v in checks)}/{len(checks)} checks**','',
 '- Parent: `v1.4.4`.','- Target: BJ13/UIF13 plus minimum shared current valuation data/BC/API contracts and the UIF03/BJ13 screen-ownership boundary cleanup.','- Historical frozen source, know-how, outbound, migration and design-readiness evidence stay immutable.','',
 f'- Parent files modified: **{len(mods)}**',f'- Files added: **{len(adds)}**',f'- Files removed: **{len(removed)}**','',
 '## Checks','']+[f'- [{"x" if ok else " "}] {name}' for name,ok in checks]
lines += ['','## Modified parent files','']+[f'- `{r}`' for r in mods]
lines += ['','## Added files','']+[f'- `{r}`' for r in adds]
if removed: lines += ['','## Removed files','']+[f'- `{r}`' for r in removed]
(OUT/'ISOLATION-REPORT-v1.4.5.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),sum(v for _,v in checks),'/',len(checks),'modified',len(mods),'added',len(adds),'removed',len(removed))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
