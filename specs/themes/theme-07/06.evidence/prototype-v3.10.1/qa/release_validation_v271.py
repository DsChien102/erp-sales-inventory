from pathlib import Path
import json, hashlib, re, subprocess, struct

HTML = Path(__file__).resolve().parents[1]
THEME = HTML.parents[1]
ROOT = HTML.parents[4]
checks = []

def chk(name, ok, note=''):
    checks.append({'name': name, 'pass': bool(ok), 'note': str(note) if note else ''})

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def png_size(path):
    b = Path(path).read_bytes()[:24]
    if b[:8] != b'\x89PNG\r\n\x1a\n':
        return None
    return struct.unpack('>II', b[16:24])

readme = (ROOT/'README.md').read_text()
launcher = (ROOT/'index.html').read_text()
manifest = json.loads((HTML/'manifest.json').read_text())
idx = (HTML/'index.html').read_text()
app = (HTML/'app.js').read_text()
css = (HTML/'v271-figma-ds-corrections.css').read_text()
migration = json.loads((THEME/'prototype/contracts/figma-ds/UIF-MIGRATION-STATUS.json').read_text())
runtime = json.loads((HTML/'figma-ds-runtime/runtime-registry.json').read_text())
relmanifest = json.loads((ROOT/'RELEASE-MANIFEST-v2.7.1.json').read_text())
primitive = json.loads((HTML/'qa/FIGMA-DS-PRIMITIVES-QA-v2.7.1.json').read_text())
listqa = json.loads((HTML/'qa/LIST-ROW-FULL-AUDIT-v2.7.1.json').read_text())
infoqa = json.loads((HTML/'qa/INFO-ROW-GROUP-FULL-AUDIT-v2.7.1.json').read_text())
bj05qa = json.loads((HTML/'qa/BJ05-FIGMA-DS-QA-v2.7.1.json').read_text())
flowqa = json.loads((HTML/'qa/ALL-FLOWS-RUNTIME-SMOKE-v2.7.1.json').read_text())
bj04qa = json.loads((HTML/'qa/BJ04-FIGMA-DS-QA-v2.6.0.json').read_text())
visual = (HTML/'qa/FIGMA-DS-VISUAL-QA-v2.7.1.md')

chk('Root README identifies v2.7.1 and parent v2.7.0', '# VET45 Theme 7 - v2.7.1' in readme and '**Parent:** v2.7.0' in readme)
chk('Launcher targets BJ05 and v2.7.1 release validation', 'VET45 Theme 7 - v2.7.1' in launcher and 'uif=UIF-05&screen=SCR-025&state=READY' in launcher and 'RELEASE-VALIDATION-v2.7.1.md' in launcher)
chk('HTML manifest is cumulative from v2.7.0', manifest.get('version') == '2.7.1' and manifest.get('parent') == '2.7.0')
chk('v2.7.1 correction CSS is wired after v2.7.0 BJ05 layer', 'v271-figma-ds-corrections.css' in idx and 'v270-bj05-ds-fidelity.css' in idx and idx.index('v271-figma-ds-corrections.css') > idx.index('v270-bj05-ds-fidelity.css'))
chk('Correction CSS introduces no raw color values', not re.search(r'#[0-9a-fA-F]{3,8}|rgba?\(', css))
chk('Live List Row node 525:519 is release-locked', '525:519' in relmanifest.get('designAuthority',{}).get('nodes',''))
chk('Live Info Row node 525:351 is release-locked', '525:351' in relmanifest.get('designAuthority',{}).get('nodes',''))
chk('Live Key-value Row node 525:358 is release-locked', '525:358' in relmanifest.get('designAuthority',{}).get('nodes',''))
chk('Live VToast node 526:4305 is release-locked', '526:4305' in relmanifest.get('designAuthority',{}).get('nodes',''))
chk('List Row density locks Default=76 and Compact=52', 'Default=76px' in relmanifest.get('primitiveLocks',{}).get('listRow','') and 'Compact=52px' in relmanifest.get('primitiveLocks',{}).get('listRow',''))
chk('List Row affordance semantics are explicit', all(x in relmanifest.get('primitiveLocks',{}).get('listRow','') for x in ['Navigation owns chevron','Status has none','Selection owns selection control']))
chk('Info Row grouping preserves transparent 338x44 primitive', 'Transparent 338x44' in relmanifest.get('primitiveLocks',{}).get('infoRow',''))
chk('VToast release lock is 370x56 with semantic leading circle', '370x56' in relmanifest.get('primitiveLocks',{}).get('toast','') and 'semantic 24px leading circle' in relmanifest.get('primitiveLocks',{}).get('toast',''))
chk('Shared primitive QA passes 31/31', primitive.get('status')=='PASS' and primitive.get('passed')==31 and primitive.get('total')==31)
chk('Full List Row audit passes 30 rendered canonical instances', listqa.get('status')=='PASS' and listqa.get('instances')==30 and not listqa.get('issues') and not listqa.get('errors'))
chk('Full Info Row audit passes 265 rendered instances', infoqa.get('status')=='PASS' and infoqa.get('instances')==265 and not infoqa.get('issues') and not infoqa.get('errors'))
chk('BJ05 Product/DS QA passes 71/71', bj05qa.get('status')=='PASS' and bj05qa.get('passed')==71 and bj05qa.get('total')==71)
chk('All-flow runtime smoke passes 85 active renders', flowqa.get('status')=='PASS' and flowqa.get('renders')==85 and not flowqa.get('failures') and not flowqa.get('errors'))
chk('BJ04 regression remains 34/34', bj04qa.get('status')=='PASS' and bj04qa.get('passed')==34 and bj04qa.get('total')==34)
chk('UIF-05 migration remains review-ready', migration.get('release')=='2.7.1' and 'UIF-05' in migration.get('productWiringScope',[]) and next(x for x in migration['uifs'] if x['uif']=='UIF-05')['productApproval']=='REVIEW_READY')
chk('Runtime registry records shared primitive correction', runtime.get('release')=='2.7.1' and runtime.get('sharedPrimitiveCorrection',{}).get('release')=='2.7.1')
chk('No new feature component created', relmanifest.get('migration',{}).get('newFeatureComponentsCreated')==0)
chk('BJ05 business behavior unchanged', relmanifest.get('businessBehaviorChanged') is False)
chk('BJ05 physical stock commit boundary retained', 'actual handover is the physical stock decrease commit point' in runtime.get('bj05',{}).get('businessLocks',[]))
chk('BJ05 cross-UOM aggregation remains prohibited', 'partial handover remains per allocation and never aggregates different UOM quantities' in runtime.get('bj05',{}).get('businessLocks',[]))
chk('UNKNOWN no-blind-retry rule retained', 'UNKNOWN does not blind retry the commit' in runtime.get('bj05',{}).get('businessLocks',[]))
js = subprocess.run(['node','--check',str(HTML/'app.js')], capture_output=True, text=True)
chk('app.js syntax passes Node check', js.returncode==0, js.stderr.strip())
chk('Action registry hash remains preserved', sha(THEME/'prototype/contracts/action-registry.json')=='35f59f04480d6a41f24e1735a88ac14e478319bc57f85e842ac5ff885f6b332a')
chk('Screen registry hash remains preserved', sha(THEME/'prototype/contracts/screen-registry.json')=='20d3abc7a229ba54aaa436942ffa767f9914b9af2e8c8e6f901b4049ceab5ebf')
chk('Visual QA report is PASS', visual.exists() and '**Result: PASS**' in visual.read_text())
capdir = HTML/'qa/v271-bj05-captures'
caps = sorted(capdir.glob('*.png'))
chk('BJ05 has 10 canonical 402x874 captures', len(caps)==10 and all(png_size(p)==(402,874) for p in caps), f'count={len(caps)} sizes={sorted(set(png_size(p) for p in caps))}')
shared = HTML/'qa/v271-shared-captures'
sharedcaps = sorted(shared.glob('*.png'))
chk('Shared primitive visual evidence exists', len(sharedcaps)>=3 and all(png_size(p)==(402,874) for p in sharedcaps), f'count={len(sharedcaps)} sizes={sorted(set(png_size(p) for p in sharedcaps))}')
chk('Inherited package-validator gap is documented, not hidden', 'prototype.manifest.json' in relmanifest.get('knownInheritedPackageValidatorGap',''))

passed = sum(x['pass'] for x in checks)
total = len(checks)
status = 'PASS' if passed == total else 'FAIL'
out = {'status':status,'passed':passed,'total':total,'failed':[x for x in checks if not x['pass']],'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.7.1.json').write_text(json.dumps(out, ensure_ascii=False, indent=2)+'\n')
lines = [
    '# Release Validation — v2.7.1','',
    f'**Result: {status} · {passed}/{total} release checks**','',
    '## Scope','',
    'Shared live-Figma primitive correction over parent v2.7.0: List Row, Info Row grouping, Key-value Row and VToast, plus BJ05 re-QA. Business behavior is unchanged.','',
    '## Checks',''
]
for x in checks:
    line = f"- [{'x' if x['pass'] else ' '}] {x['name']}"
    if x['note'] and not x['pass']:
        line += f" — {x['note']}"
    lines.append(line + '.')
lines += [
    '', '## QA evidence','',
    '- `specs/themes/theme-07/prototype/html/qa/FIGMA-DS-PRIMITIVES-QA-v2.7.1.md`',
    '- `specs/themes/theme-07/prototype/html/qa/LIST-ROW-FULL-AUDIT-v2.7.1.md`',
    '- `specs/themes/theme-07/prototype/html/qa/INFO-ROW-GROUP-FULL-AUDIT-v2.7.1.md`',
    '- `specs/themes/theme-07/prototype/html/qa/BJ05-FIGMA-DS-QA-v2.7.1.md`',
    '- `specs/themes/theme-07/prototype/html/qa/ALL-FLOWS-RUNTIME-SMOKE-v2.7.1.md`',
    '- `specs/themes/theme-07/prototype/html/qa/FIGMA-DS-VISUAL-QA-v2.7.1.md`',
    '- `specs/themes/theme-07/prototype/html/qa/v271-bj05-captures/`',
    '- `specs/themes/theme-07/prototype/html/qa/v271-shared-captures/`',
    '', '## Inherited package-validator note','',
    'The legacy full-package validator still cannot start because the cumulative parent lineage lacks `specs/themes/theme-07/prototype/prototype.manifest.json`. v2.7.1 does not fabricate that unrelated artifact; release quality is gated by shared-primitive audits, BJ05 Product/DS QA, all-flow runtime smoke, BJ04 regression, JavaScript syntax, registry integrity and visual evidence.'
]
(ROOT/'RELEASE-VALIDATION-v2.7.1.md').write_text('\n'.join(lines)+'\n')
print(status, passed, total)
if status != 'PASS':
    for x in out['failed']:
        print('FAIL', x)
    raise SystemExit(1)
