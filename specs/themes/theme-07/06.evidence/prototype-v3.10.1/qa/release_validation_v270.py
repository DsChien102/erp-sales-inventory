from pathlib import Path
import json, hashlib, subprocess, re, struct

HTML=Path(__file__).resolve().parents[1]
THEME=HTML.parents[1]
ROOT=HTML.parents[4]
checks=[]
def chk(name, ok, note=''):
    checks.append({'name':name,'pass':bool(ok),'note':str(note) if note else ''})
def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def png_size(p):
    b=Path(p).read_bytes()[:24]
    if b[:8] != b'\x89PNG\r\n\x1a\n': return None
    return struct.unpack('>II', b[16:24])

readme=(ROOT/'README.md').read_text()
launcher=(ROOT/'index.html').read_text()
manifest=json.loads((HTML/'manifest.json').read_text())
wb=json.loads((HTML/'workbench-data.json').read_text())
wbjs=(HTML/'workbench-data.js').read_text()
idx=(HTML/'index.html').read_text()
app=(HTML/'app.js').read_text()
css=(HTML/'v270-bj05-ds-fidelity.css').read_text()
flow=(THEME/'prototype/flows/UIF-05-BJ-05.md').read_text()
usage=(THEME/'prototype/contracts/component-usage/UIF-05-COMPONENT-USAGE.md').read_text()
migration=json.loads((THEME/'prototype/contracts/figma-ds/UIF-MIGRATION-STATUS.json').read_text())
runtime=json.loads((HTML/'figma-ds-runtime/runtime-registry.json').read_text())
relmanifest=json.loads((ROOT/'RELEASE-MANIFEST-v2.7.0.json').read_text())
bjqa=json.loads((HTML/'qa/BJ05-FIGMA-DS-QA-v2.7.0.json').read_text())
flowqa=json.loads((HTML/'qa/ALL-FLOWS-RUNTIME-SMOKE-v2.7.0.json').read_text())
bj04qa=json.loads((HTML/'qa/BJ04-FIGMA-DS-QA-v2.6.0.json').read_text())
chunk=app[app.find('function bj05DsTone'):app.find('function render030IO06')]

chk('Root README identifies v2.7.0 and parent v2.6.0', '# VET45 Theme 7 - v2.7.0' in readme and '**Parent:** v2.6.0' in readme)
chk('Launcher targets BJ05 and v2.7.0', 'VET45 Theme 7 - v2.7.0' in launcher and 'uif=UIF-05&screen=SCR-025&state=READY' in launcher)
chk('HTML manifest is cumulative from v2.6.0', manifest.get('version')=='2.7.0' and manifest.get('parent')=='2.6.0')
chk('Workbench JSON version is 2.7.0', wb.get('version')=='2.7.0')
chk('Workbench JS version is 2.7.0', '"version": "2.7.0"' in wbjs)
chk('UIF-05 active flow remains SCR-025..029', next(f for f in wb['flows'] if f['id']=='UIF-05')['screens']==['SCR-025','SCR-026','SCR-027','SCR-028','SCR-029'])
chk('v270 fidelity CSS is wired after v260 layer', 'v270-bj05-ds-fidelity.css' in idx and idx.index('v270-bj05-ds-fidelity.css')>idx.index('v260-bj04-ds-fidelity.css'))
chk('BJ05 fidelity CSS is UIF-05 scoped', all(s.strip().startswith('body[data-active-uif="UIF-05"]') for b in re.sub(r'/\*.*?\*/','',css,flags=re.S).split('}') if '{' in b for s in b.split('{',1)[0].split(',') if s.strip() and not s.strip().startswith('@')))
chk('BJ05 fidelity CSS introduces no raw color values', not re.search(r'#[0-9a-fA-F]{3,8}|rgba?\(',css))
chk('Active BJ05 renderer does not use generic VCard/read-card wrappers', 'ioReadCard(' not in chunk and 'data-ds-component="VCard"' not in chunk)
chk('Active BJ05 renderer does not use VQuantitySelector', 'VQuantitySelector' not in chunk)
chk('LOT override uses live Form Sheet node 1353:6355', 'data-ds-pattern="DS v2 / Form Sheet"' in chunk and 'data-figma-node="1353:6355"' in chunk)
chk('LOT override uses selection row + VRadio + VTextarea', 'data-ds-prop-type="Selection"' in chunk and 'data-ds-component="VRadio"' in chunk and 'data-ds-component="VTextarea"' in chunk)
chk('LOT change uses contextual DS Link', 'data-ds-component="DS v2 / Link"' in chunk)
chk('Physical stock boundary remains source-grounded', 'actual handover quantity' in flow and 'Pick chưa giảm physical' in (THEME/'prototype/contracts/screens/SCR-026.md').read_text())
chk('Stale correction remains source-grounded', 'reset phần pick đó về 0' in flow and 'physical-correction' in flow)
chk('UNKNOWN no-blind-retry remains source-grounded', 'UNKNOWN không blind retry' in flow)
chk('Component usage contract declares live Figma DS authority', 'Live Figma Design System is the UI authority' in usage and 'Flutter Design System remains UI authority' not in usage)
chk('Screen contracts carry v2.7.0 expression notes', all('## v2.7.0 — Figma DS expression' in (THEME/f'prototype/contracts/screens/SCR-{n:03d}.md').read_text() for n in [25,26,27,28,29]))
chk('Migration status includes UIF-05 review-ready', migration.get('release')=='2.7.0' and 'UIF-05' in migration.get('productWiringScope',[]) and next(x for x in migration['uifs'] if x['uif']=='UIF-05')['productApproval']=='REVIEW_READY')
chk('Runtime registry includes UIF-05 cumulative wiring', runtime.get('release')=='2.7.0' and 'UIF-05' in runtime.get('productWiringScope',[]) and runtime.get('bj05',{}).get('migrationRelease')=='2.7.0')
chk('Release manifest declares zero new feature components', relmanifest.get('migration',{}).get('newFeatureComponentsCreated')==0)
chk('BJ05 Product/DS QA passes 71/71', bjqa.get('status')=='PASS' and bjqa.get('passed')==71 and bjqa.get('total')==71, f"{bjqa.get('passed')}/{bjqa.get('total')}")
chk('All-flow runtime smoke passes 85 renders', flowqa.get('status')=='PASS' and flowqa.get('renders')==85 and not flowqa.get('failures') and not flowqa.get('errors'))
chk('BJ04 regression remains 34/34', bj04qa.get('status')=='PASS' and bj04qa.get('passed')==34 and bj04qa.get('total')==34)
js=subprocess.run(['node','--check',str(HTML/'app.js')],capture_output=True,text=True)
chk('app.js syntax passes Node check', js.returncode==0, js.stderr.strip())
chk('Action registry hash remains preserved', sha(THEME/'prototype/contracts/action-registry.json')=='35f59f04480d6a41f24e1735a88ac14e478319bc57f85e842ac5ff885f6b332a')
chk('Screen registry hash remains preserved', sha(THEME/'prototype/contracts/screen-registry.json')=='20d3abc7a229ba54aaa436942ffa767f9914b9af2e8c8e6f901b4049ceab5ebf')
visual=HTML/'qa/BJ05-VISUAL-QA-v2.7.0.md'
chk('BJ05 visual QA report is PASS', visual.exists() and '**Result: PASS**' in visual.read_text())
capdir=HTML/'qa/v270-bj05-captures'
caps=sorted(capdir.glob('*.png'))
chk('BJ05 has 10 canonical visual captures', len(caps)==10 and all(png_size(p)==(402,874) for p in caps), f"count={len(caps)} sizes={sorted(set(png_size(p) for p in caps))}")
chk('Release manifest records inherited package-validator gap rather than fabricating a manifest', 'parent v2.6.0 package already lacks' in relmanifest.get('knownInheritedPackageValidatorGap','').lower())

passed=sum(x['pass'] for x in checks); total=len(checks); status='PASS' if passed==total else 'FAIL'
out={'status':status,'passed':passed,'total':total,'failed':[x for x in checks if not x['pass']],'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.7.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
lines=['# Release Validation — v2.7.0','',f'**Result: {status} · {passed}/{total} release checks**','','## Scope','','BJ05/UIF-05 structural Figma DS migration and correction only. Parent v2.6.0 behavior and prior migrated UIF-01/UIF-02/UIF-04/UIF-08 are retained.','','## Checks','']
for x in checks:
    line=f"- [{'x' if x['pass'] else ' '}] {x['name']}"
    if x['note'] and not x['pass']: line += f" — {x['note']}"
    lines.append(line+'.')
lines += ['','## QA evidence','',
          '- `specs/themes/theme-07/prototype/html/qa/BJ05-FIGMA-DS-QA-v2.7.0.md`',
          '- `specs/themes/theme-07/prototype/html/qa/ALL-FLOWS-RUNTIME-SMOKE-v2.7.0.md`',
          '- `specs/themes/theme-07/prototype/html/qa/BJ05-VISUAL-QA-v2.7.0.md`',
          '- `specs/themes/theme-07/prototype/html/qa/v270-bj05-captures/`',
          '',
          '## Inherited package-validator note','',
          'The legacy full-package validator cannot start because the parent v2.6.0 archive already lacks `specs/themes/theme-07/prototype/prototype.manifest.json`. This release does not create that unrelated artifact. BJ05 is gated by targeted Product/DS QA, full-flow runtime smoke, prior-BJ regression, JavaScript syntax and visual review.']
(ROOT/'RELEASE-VALIDATION-v2.7.0.md').write_text('\n'.join(lines)+'\n')
print(status,passed,total)
if status!='PASS':
    for x in out['failed']: print('FAIL',x)
    raise SystemExit(1)
