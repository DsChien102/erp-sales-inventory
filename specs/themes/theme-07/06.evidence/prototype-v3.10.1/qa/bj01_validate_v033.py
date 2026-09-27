from pathlib import Path
import json, sys
ROOT=Path(__file__).resolve().parents[1]
PROTO=ROOT.parent
CONTRACTS=PROTO/'contracts'
FLOWS=PROTO/'flows'
checks=[]

def check(name, cond, detail=''):
    checks.append((name,bool(cond),detail))

def text(p): return p.read_text(encoding='utf8')
manifest=json.loads(text(ROOT/'manifest.json'))
lock=json.loads(text(CONTRACTS/'FLUTTER-DS-LOCK.json'))
profile=text(CONTRACTS/'design-system-profile.md')
usage=text(CONTRACTS/'component-usage/UIF-01-COMPONENT-USAGE.md')
app=text(ROOT/'app.js')
css=text(ROOT/'styles.css')
idx=text(ROOT/'index.html')
tokens=text(ROOT/'tokens.generated.css')
flow=text(FLOWS/'UIF-01-BJ-01.md')
s1=text(CONTRACTS/'screens/SCR-001.md')
s3=text(CONTRACTS/'screens/SCR-003.md')
s4=text(CONTRACTS/'screens/SCR-004.md')
s5=text(CONTRACTS/'screens/SCR-005.md')

check('manifest version 0.3.3',manifest.get('version')=='0.3.3',str(manifest.get('version')))
check('HTML policy remains renderer-only',lock.get('htmlPolicy')=='renderer_only_not_design_system',str(lock.get('htmlPolicy')))
check('Flutter DS lock source recorded',bool(lock.get('sourceFile')) and bool(lock.get('sourceSha256')))
check('authority chain places Flutter DS above HTML renderer','Flutter DS public API/defaults' in profile and 'HTML prototype' in profile)
check('UIF01 usage declares Flutter DS authority','FLUTTER-DS-LOCK.json' in usage and 'HTML chỉ render composition' in usage)
for comp in ['VPageScaffold','VAppBar','VPagePadding','VSearchBar','VChip','VCard','VBadge','VBanner','VEmptyState','VButton','VBottomSheet']:
    check(f'UIF01 usage maps {comp}',comp in usage)
check('usage forbids custom close icon','không custom close icon' in usage.lower())
check('usage keeps one VCard list, not card per product','không card-per-product' in usage)
check('usage keeps one summary VCard, not metric grid','không metric-card grid' in usage)

start=app.index('function bj01ProductById')
end=app.index('const renderers =',start)
bj=app[start:end]
check('SCR001 uses public VSearchBar renderer','data-ds-component="VSearchBar"' in bj and 'search.standard' in bj)
check('SCR001 filters map VChip','data-ds-component="VChip"' in bj)
check('SCR001 list maps VCard','bj01-list-card' in bj and 'data-ds-component="VCard"' in bj)
check('Product row is documented Theme7 composition','Theme7InventoryProductRow' in bj and 'VText,VBadge,VIcon' in bj)
check('SCR003 summary maps VCard','bj01-summary-card' in bj)
check('LOW/OUT maps VBanner','vBanner(' in bj and 'item.status==="danger"?"error":"warning"' in bj)
check('LOT row is documented Theme7 composition','Theme7InventoryLotRow' in bj)
check('Provenance entry maps interactive VCard','bj01-provenance-card' in bj and 'card.interactive' in bj)
check('Query/recovery actions map VButton.secondary','VButtonVariant.secondary' in bj)
check('LOT and provenance overlays map VBottomSheet',bj.count('data-ds-component="VBottomSheet"')>=2)
check('No custom bottom-sheet close button','aria-label="Đóng"' not in bj and 'app-icon-button' not in bj)
check('No segmented Tra cứu/Cần chú ý control','data-bj01-mode' not in bj and 'Tra cứu / Cần chú ý' not in bj)
check('No tracking policy labels','Theo lô' not in bj and 'Không theo lô' not in bj)
check('No duplicate Available supporting row',"bj01QuantityRow('Khả dụng'" not in bj)
check('No technical English in BJ01 visible slice',all(x not in bj.lower() for x in ['snapshot','inventory projection','cut-off']))

selector_lines=[ln.strip() for ln in css.splitlines() if '.bj01-' in ln and '{' in ln]
unscoped=[ln for ln in selector_lines if not ln.startswith('body[data-active-uif="UIF-01"]')]
check('All BJ01 CSS selectors scoped to UIF01',not unscoped,'; '.join(unscoped[:3]))
check('BJ01 CSS does not define its own search visual shell', '.bj01-search-box' not in css and 'body[data-active-uif="UIF-01"] .bj01-search { margin:0; }' in css)
check('BJ01 CSS does not define its own chip component', '.bj01-chip' not in css)
check('BJ01 CSS does not define custom banner component', '.bj01-attention-row' not in css and '.bj01-attention-list' not in css)
check('Index remains shared workbench shell','device-preview' in idx and 'workbench-data.js' in idx)
check('Screen contracts contain Component Composition Contract',all('Component Composition Contract' in x for x in [s1,s3,s4,s5]))
check('SCR004/SCR005 explicitly use VBottomSheet','VBottomSheet' in s4 and 'VBottomSheet' in s5)
check('Flow contract locks Flutter DS composition','Flutter DS composition lock' in flow and 'FLUTTER-DS-LOCK.json' in flow)

passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-01 Flutter DS Static Conformance v0.3.3','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', 'Grounded in package-local `FLUTTER-DS-LOCK.json`, `design-system-profile.md`, Screen Design Contract and UIF-01 component-usage contract.','', '## Checks','']
for n,ok,d in checks: lines.append(f'- [{"x" if ok else " "}] {n}'+(f' — {d}' if d else ''))
lines += ['', '## Boundary','', '- Checks source/contract/component mapping and BJ01 CSS scoping.', '- Browser behavior/geometry is covered separately by `BJ01-RUNTIME-QA-v0.3.3.md`.', '- External Vercel pixel parity is not asserted because the visual-reference site is unavailable from this runtime; the locked local Flutter DS profile remains the authority available to this build.']
(OUT:=Path(__file__).resolve().parent/'BJ01-DS-CONFORMANCE-v0.3.3.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
sys.exit(1 if failed else 0)
