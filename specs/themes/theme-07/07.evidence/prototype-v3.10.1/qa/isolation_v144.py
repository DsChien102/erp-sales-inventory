from pathlib import Path
import hashlib

CHILD=Path(__file__).resolve().parents[6]  # package root
PARENT=CHILD.parent/'VET45-Theme7-Prototype-Harness-v1.4.3'
OUT=Path(__file__).resolve().parent

def files(root): return {p.relative_to(root) for p in root.rglob('*') if p.is_file()}
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20), b''): h.update(b)
    return h.hexdigest()

def same_tree(prefix):
    pp=PARENT/prefix; cc=CHILD/prefix
    pf=files(pp) if pp.exists() else set(); cf=files(cc) if cc.exists() else set()
    return pf==cf and all(sha(pp/r)==sha(cc/r) for r in pf)

pf=files(PARENT); cf=files(CHILD)
mods=[r for r in sorted(pf&cf) if sha(PARENT/r)!=sha(CHILD/r)]
adds=sorted(cf-pf); removed=sorted(pf-cf)
checks=[]
def ck(n,c): checks.append((n,bool(c)))

allowed_srs={
Path('specs/themes/theme-07/srs/02-business-journeys/03-BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan.md'),
Path('specs/themes/theme-07/srs/03-domain-foundation.md'),
Path('specs/themes/theme-07/srs/04-data-entities.md'),
Path('specs/themes/theme-07/srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-01-chon-pham-vi-can-dinh-gia.md'),
Path('specs/themes/theme-07/srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-02-xac-dinh-gia-nhap-thuc-te.md'),
Path('specs/themes/theme-07/srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-03-xac-nhan-gia-tri.md'),
Path('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md'),
Path('specs/themes/theme-07/srs/07-technical-contracts.md'),
}
modified_srs={r for r in mods if str(r).startswith('specs/themes/theme-07/srs/')}

ck('Parent exists',PARENT.exists())
ck('No parent file removed',not removed)
ck('Frozen-source byte-identical',same_tree(Path('specs/themes/theme-07/harness/frozen-source')))
ck('Know-how byte-identical',same_tree(Path('specs/themes/theme-07/know-how')))
ck('Only allowed current SRS files changed',modified_srs <= allowed_srs)
ck('All intended SRS foundation files changed',allowed_srs <= modified_srs)
ck('No non-target individual UIF flow markdown changed',all((not str(r).startswith('specs/themes/theme-07/prototype/flows/UIF-')) or r==Path('specs/themes/theme-07/prototype/flows/UIF-03-BJ-03.md') for r in mods))
ck('No non-target component-usage file changed',all((not str(r).startswith('specs/themes/theme-07/prototype/contracts/component-usage/UIF-')) or r in {Path('specs/themes/theme-07/prototype/contracts/component-usage/UIF-03-COMPONENT-USAGE.md'),Path('specs/themes/theme-07/prototype/contracts/component-usage/UIF-03-COMPONENT-USAGE.yaml')} for r in mods))
ck('No non-target screen contract changed',all((not str(r).startswith('specs/themes/theme-07/prototype/contracts/screens/SCR-')) or r.name in {'SCR-014.md','SCR-015.md','SCR-016.md','SCR-017.md','SCR-019.md'} for r in mods))
ck('No outbound contract changed',same_tree(Path('specs/themes/theme-07/outbound')))
ck('No migration history changed',same_tree(Path('specs/themes/theme-07/migration')))
ck('No design-readiness history changed',same_tree(Path('specs/themes/theme-07/design-readiness')))
ck('Protected runtime report passes', 'PASS · 181/181' in (OUT/'REGRESSION-PROTECTED-FLOWS-v1.4.4.md').read_text(encoding='utf8'))
ck('All-flow runtime report passes','PASS · 87' in (OUT/'ALL-FLOWS-RUNTIME-SMOKE-v1.4.4.md').read_text(encoding='utf8'))
ck('BJ03 foundation report passes','PASS · 38/38' in (OUT/'BJ03-FOUNDATION-QA-v1.4.4.md').read_text(encoding='utf8'))
ck('BJ03 static report passes','PASS · 27/27' in (OUT/'BJ03-STATIC-CONFORMANCE-v1.4.4.md').read_text(encoding='utf8'))

failed=[n for n,v in checks if not v]
lines=[
'# Isolation Report v1.4.4 — BJ03 Inventory Valuation Foundation','',
f'**Result: {"PASS" if not failed else "FAIL"} · {sum(v for _,v in checks)}/{len(checks)} checks**','',
'- Parent: `v1.4.3`.','- Target: BJ03/UIF03 valuation foundation plus the minimum shared current-SRS foundation needed to make its domain/data/BC/API trace internally consistent.','- Inventory Operations, UIF13 and all other UIF runtime behavior are protected by exact rendered-text/topology regression.','- `harness/frozen-source` remains historical and byte-identical; corrections are applied only to current SRS.','',
'## File delta','',f'- Modified parent files: **{len(mods)}**',f'- Added files: **{len(adds)}** (including QA script/report)',f'- Removed files: **{len(removed)}**','',
'## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]+['','## Modified parent files','']+[f'- `{r}`' for r in mods]
if failed:
    lines += ['','## Failures','']+[f'- {x}' for x in failed]
(OUT/'ISOLATION-REPORT-v1.4.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),sum(v for _,v in checks),'/',len(checks),'modified',len(mods),'added_before_report',len(adds),'removed',len(removed))
if failed: raise SystemExit(1)
