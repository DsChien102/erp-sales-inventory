#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, re, subprocess
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[6]
HTML=ROOT/'specs/themes/theme-07/prototype/html'
QA=HTML/'qa'
CONTRACTS=ROOT/'specs/themes/theme-07/prototype/contracts'
checks=[]

def add(name, ok, detail=''):
    checks.append({'name':name,'pass':bool(ok),'detail':detail})

def load(p):
    return json.loads(Path(p).read_text(encoding='utf-8'))

def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()

manifest=load(HTML/'manifest.json')
proto=load(HTML/'prototype.manifest.json')
migration=load(CONTRACTS/'figma-ds/UIF-MIGRATION-STATUS.json')
runtime=load(HTML/'figma-ds-runtime/runtime-registry.json')
release=load(ROOT/'RELEASE-MANIFEST-v2.7.3.json')
cross=load(QA/'CROSS-BJ-UI-HARDENING-QA-v2.7.3.json')
bj05=load(QA/'BJ05-FIGMA-DS-QA-v2.7.3.json')
listrow=load(QA/'LIST-ROW-FULL-AUDIT-v2.7.3.json')
inforow=load(QA/'INFO-ROW-GROUP-FULL-AUDIT-v2.7.3.json')
bj04=load(QA/'BJ04-FIGMA-DS-QA-v2.6.0.json')
bj02a=load(QA/'BJ02-INPUT-UX-QA-v2.5.4.json')
bj02b=load(QA/'BJ02-REVIEW-DENSITY-QA-v2.5.5.json')
allflow=load(QA/'ALL-FLOWS-RUNTIME-SMOKE-v2.7.3.json')
mobile=load(QA/'MOBILE-PROTOTYPE-CONTRACT-QA-v2.7.3.json')
app=(HTML/'app.js').read_text(encoding='utf-8')
index=(HTML/'index.html').read_text(encoding='utf-8')
css=(HTML/'v273-ui-hardening.css').read_text(encoding='utf-8')

scope=['UIF-01','UIF-02','UIF-04','UIF-05','UIF-08']
add('HTML manifest release/parent/status', manifest.get('version')=='2.7.3' and manifest.get('parent')=='2.7.2' and manifest.get('status')=='CROSS_BJ_UI_HARDENING_REVIEW_READY')
add('Release manifest release/parent', release.get('release')=='2.7.3' and release.get('parent')=='2.7.2')
add('Business behavior unchanged', release.get('businessBehaviorChanged') is False)
add('No new feature component created', release.get('newFeatureComponentsCreated')==0)
add('Migrated Product scope exact', migration.get('productWiringScope')==scope and runtime.get('productWiringScope')==scope)
add('Migration release current', migration.get('release')=='2.7.3')
add('Runtime release/status current', runtime.get('release')=='2.7.3' and runtime.get('status')=='WORKING_FREEZE_CROSS_BJ_UI_HARDENING_REVIEW_READY')
add('Runtime cross-BJ hardening record present', isinstance(runtime.get('crossBjUiHardeningV273'), dict))
add('Mobile manifest contract', proto.get('productKind')=='mobile_app' and proto.get('defaultViewport')=={'width':402,'height':874} and proto.get('offline') is True and proto.get('inspect')=={'enabled':True,'selectable':True})
add('Mobile manifest lists non-empty', all(isinstance(proto.get(k),list) and proto.get(k) for k in ('uiFlows','screens','roles','states','scenarios','devicePresets')))
add('Only mobile product viewport selector remains', 'data-viewport="wide"' not in index and 'data-viewport="mobile"' in index)
add('Product/workbench/runtime markers present', 'data-mobile-product' in app and 'data-review-workbench' in index and '__VET45_PROTOTYPE__' in app)
add('No external HTTP(S) resource references', not re.search(r'(?:src|href)=["\']https?://', '\n'.join(p.read_text(encoding='utf-8',errors='replace') for p in HTML.rglob('*') if p.is_file() and p.suffix.lower() in {'.html','.css','.js'}), re.I))
add('v2.7.3 CSS contains no raw hex/rgb colors', not re.search(r'#[0-9a-fA-F]{3,8}\b|\brgba?\s*\(', css))
add('v2.7.3 correction CSS scoped to migrated Product UIFs', 'data-active-uif' in css and all(u in css for u in scope))
add('Sparse BJ01/BJ05 identities use compact Status context', 'data-ds-role="inventory-product-summary"' in app and 'data-ds-role="picking-product-summary"' in app and 'ds24ContextStatusRow' in app)
add('BJ02 loaded line Product context uses compact Status context', 'data-ds-role="receiving-line-product-summary"' in app and 'ds24ContextStatusRow' in app)
add('BJ05 queue uses Disabled Navigation state', 'if(o.queue==="WAITING")' in app and "type:'Navigation',state:'Disabled',disabled:true" in app)
add('Disabled List Row parent opacity rule present', '--vet45-v2-opacity-disabled' in css or 'opacity-disabled' in css)

add('Cross-BJ hardening QA 24/24', cross.get('status')=='PASS' and cross.get('passed')==cross.get('total')==24 and cross.get('migratedScreensReviewed')==23 and not cross.get('browserErrors'))
add('BJ05 regression QA 71/71', bj05.get('status')=='PASS' and bj05.get('passed')==bj05.get('total')==71 and not bj05.get('browserErrors'))
add('List Row audit 32/0', listrow.get('status')=='PASS' and listrow.get('instances')==32 and not listrow.get('issues') and not listrow.get('browserErrors'))
add('Info Row audit 264/0', inforow.get('status')=='PASS' and inforow.get('instances')==264 and not inforow.get('issues') and not inforow.get('browserErrors'))
add('BJ04 regression 34/34', bj04.get('status')=='PASS' and bj04.get('passed')==bj04.get('total')==34 and not bj04.get('browserErrors'))
add('BJ02 input UX regression 20/20', bj02a.get('status')=='PASS' and bj02a.get('passed')==bj02a.get('total')==20 and not bj02a.get('browserErrors'))
add('BJ02 review density regression 18/18', bj02b.get('status')=='PASS' and bj02b.get('passed')==bj02b.get('total')==18 and not bj02b.get('browserErrors'))
add('All-flow runtime smoke 85/85', allflow.get('status')=='PASS' and allflow.get('renders')==85 and not allflow.get('failures') and not allflow.get('errors'))
add('Official mobile prototype validator', mobile.get('status')=='PASS' and all(v==0 for v in mobile.get('counts',{}).values()))

visual=QA/'v273-migrated-all'
pngs=sorted(visual.glob('*.png'))
dims=[]
for p in pngs:
    with Image.open(p) as im: dims.append(im.size)
add('All 23 migrated canonical visual captures exist', len(pngs)==23, f'{len(pngs)} PNGs')
add('All canonical visual captures are 402x874', bool(dims) and all(d==(402,874) for d in dims), str(sorted(set(dims))))
focused=QA/'v273-cross-bj-captures'
focus_pngs=sorted(focused.glob('*.png'))
focus_dims=[]
for p in focus_pngs:
    with Image.open(p) as im: focus_dims.append(im.size)
add('Focused correction visual evidence 4/4 at 402x874', len(focus_pngs)==4 and all(d==(402,874) for d in focus_dims))
visual_md=(QA/'CROSS-BJ-VISUAL-QA-v2.7.3.md').read_text(encoding='utf-8')
add('Manual cross-BJ visual review recorded PASS', '**Result: PASS**' in visual_md)

js1=subprocess.run(['node','--check',str(HTML/'app.js')],capture_output=True,text=True)
js2=subprocess.run(['node','--check',str(HTML/'workbench-data.js')],capture_output=True,text=True)
add('JavaScript syntax PASS', js1.returncode==0 and js2.returncode==0)
add('Action registry preserved', sha(CONTRACTS/'action-registry.json')=='35f59f04480d6a41f24e1735a88ac14e478319bc57f85e842ac5ff885f6b332a')
add('Screen registry preserved', sha(CONTRACTS/'screen-registry.json')=='20d3abc7a229ba54aaa436942ffa767f9914b9af2e8c8e6f901b4049ceab5ebf')

contract_text='\n'.join((CONTRACTS/'screens'/f).read_text(encoding='utf-8',errors='replace') for f in ['SCR-003.md','SCR-084.md','SCR-025.md','SCR-026.md','SCR-027.md'])
add('UI contracts record v2.7.3 corrections', 'v2.7.3' in contract_text and 'Disabled' in contract_text and ('Summary Card' in contract_text or 'summary' in contract_text.lower()))
usage_text='\n'.join((CONTRACTS/'component-usage'/f).read_text(encoding='utf-8',errors='replace') for f in ['UIF-01-COMPONENT-USAGE.md','UIF-02-COMPONENT-USAGE.md','UIF-05-COMPONENT-USAGE.md'])
add('Component-usage contracts updated', 'v2.7.3' in usage_text and 'Compact' in usage_text and 'Disabled' in usage_text)

status='PASS' if all(c['pass'] for c in checks) else 'FAIL'
res={'release':'2.7.3','status':status,'passed':sum(c['pass'] for c in checks),'total':len(checks),'failed':[c for c in checks if not c['pass']],'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.7.3.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Release Validation — VET45 Theme 7 v2.7.3','',f'**Result: {status} · {res["passed"]}/{res["total"]} release checks**','',
       'Scope: cross-BJ Product UI hardening after reviewing every structurally migrated Product UIF (`UIF-01 / 02 / 04 / 05 / 08`) and all 23 canonical screens. Business behavior is unchanged.','',
       '## Release gates','']
for c in checks:
    mark='PASS' if c['pass'] else 'FAIL'
    extra=f' — {c["detail"]}' if c.get('detail') else ''
    lines.append(f'- **{mark}** — {c["name"]}{extra}')
lines += ['', '## Design decisions locked', '',
          '- A record collection keeps one `DS v2 / List Row` Type and Density; availability changes through component State, not through a different anatomy.',
          '- Disabled Navigation retains the same chevron, geometry and trailing rhythm; disabled appearance is applied at the parent state.',
          '- `DS v2 / Summary Card` is not a generic sparse identity header. Product/context identity uses a more appropriate canonical primitive such as compact Status List Row when that semantic fits.',
          '- Supporting read-only facts use grouped surfaces with Info/Key-value rows; low-value data is never added merely to fill empty card space.',
          '- Composition correction reviews live Figma DS and Patterns/Templates first, then mature cross-theme Product UI available in the Figma file before HTML implementation.',
          '- Horizontal scrollers may overflow internally by design, but Product root and visible copy must remain within the 402px viewport.', '']
(ROOT/'RELEASE-VALIDATION-v2.7.3.md').write_text('\n'.join(lines),encoding='utf-8')
print(status, res['passed'], res['total'])
if status!='PASS':
    for c in res['failed']: print('FAIL:',c['name'],c.get('detail',''))
    raise SystemExit(1)
