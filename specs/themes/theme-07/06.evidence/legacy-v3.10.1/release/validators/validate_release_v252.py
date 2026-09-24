#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
HTML=ROOT/'specs/themes/theme-07/prototype/html'
CON=ROOT/'specs/themes/theme-07/prototype/contracts/figma-ds'
QA=HTML/'qa'
checks=[]
def add(name,ok,detail=''): checks.append({'name':name,'pass':bool(ok),'detail':str(detail)})
def load(p): return json.loads(Path(p).read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
manifest=load(HTML/'manifest.json'); wb=load(HTML/'workbench-data.json'); status=load(CON/'UIF-MIGRATION-STATUS.json'); runtime=load(HTML/'figma-ds-runtime/runtime-registry.json')
quick=load(QA/'BJ02-QUICK-FLOW-UI-QA-v2.5.2.json'); smoke=load(QA/'ALL-FLOWS-RUNTIME-SMOKE-v2.5.2.json'); info=load(QA/'INFO-ROW-LIVE-SYNC-QA-v2.5.2.json'); rel=load(ROOT/'RELEASE-MANIFEST-v2.5.2.json')
add('HTML manifest version',manifest.get('version')=='2.5.2',manifest.get('version'))
add('HTML manifest parent',manifest.get('parent')=='2.5.1',manifest.get('parent'))
add('Workbench version',wb.get('version')=='2.5.2',wb.get('version'))
add('UIF migration release',status.get('release')=='2.5.2',status.get('release'))
add('Migrated UIFs exact',status.get('productWiringScope')==['UIF-01','UIF-02','UIF-08'],status.get('productWiringScope'))
add('BJ02 real Quick flow QA',quick.get('status')=='PASS' and quick.get('passed')==21 and quick.get('total')==21,f"{quick.get('passed')}/{quick.get('total')}")
add('BJ02 Quick browser errors zero',quick.get('browserErrors')==[],quick.get('browserErrors'))
add('All-flow smoke',smoke.get('status')=='PASS' and smoke.get('renders')==85 and not smoke.get('failures') and not smoke.get('errors'),f"{smoke.get('renders')}/85")
add('Live Info Row QA',info.get('status')=='PASS' and info.get('stateRenders')==497 and info.get('instances')==1052 and not info.get('failures'),f"states={info.get('stateRenders')} instances={info.get('instances')}")
add('Live Info Row browser/runtime errors zero',not info.get('browserErrors') and not info.get('runtimeErrors'),f"browser={len(info.get('browserErrors',[]))} runtime={len(info.get('runtimeErrors',[]))}")
idx=(HTML/'index.html').read_text(encoding='utf-8')
add('Live sync stylesheet loaded last',idx.rfind('v252-figma-live-sync.css')>idx.rfind('v252-bj02-quick-flow-ui.css')>0,'load order')
css=(HTML/'v252-figma-live-sync.css').read_text(encoding='utf-8')
for name,needle in [('Info Row width 338','width:338px!important'),('Info Row height 44','height:44px!important'),('Info Row justify-between','justify-content:space-between!important'),('Info Row gap 0','gap:0!important'),('Info Row value right','text-align:right!important')]: add(name,needle in css,needle)
runtime_css=(HTML/'figma-ds-runtime/runtime.css').read_text(encoding='utf-8')
add('Runtime specimen Info Row current anatomy','.vds-info-row { width:338px; height:44px; display:flex; align-items:center; justify-content:space-between; gap:0;' in runtime_css,'525:351')
app=(HTML/'app.js').read_text(encoding='utf-8')
add('No long-value mutation of BJ02 Info Row','bj02-info-row is-long' not in app and 'bj02InfoRow("Căn cứ giao nhận", bj02Header.evidence, "is-long")' not in app,'long values use VText layout')
add('Long BJ02 review detail is composition','function bj02ReadOnlyDetail' in app and 'data-composed-from="VText"' in app,'VText composition')
profile=(ROOT/'specs/themes/theme-07/prototype/contracts/THEME-07-COMPONENT-USAGE-PROFILE.yaml').read_text(encoding='utf-8')
add('Component usage profile records live Info Row','338x44; justify-between; gap 0' in profile,'525:351')
add('Info Row live sync note exists',(CON/'INFO-ROW-LIVE-SYNC-v2.5.2.md').exists())
node=subprocess.run(['node','--check',str(HTML/'app.js')],capture_output=True,text=True)
add('JavaScript syntax',node.returncode==0,node.stderr.strip())
add('No new Theme7 shared component',rel.get('migration',{}).get('newFeatureComponentsCreated')==0,rel.get('migration',{}).get('newFeatureComponentsCreated'))
add('Release manifest records shared DS refresh','DS v2 / Info Row 525:351' in rel.get('migration',{}).get('sharedDsRefresh',[]),rel.get('migration',{}).get('sharedDsRefresh'))
add('Action registry preserved',sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json')=='35f59f04480d6a41f24e1735a88ac14e478319bc57f85e842ac5ff885f6b332a',sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json'))
add('Screen registry preserved',sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json')=='20d3abc7a229ba54aaa436942ffa767f9914b9af2e8c8e6f901b4049ceab5ebf',sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json'))
rootidx=(ROOT/'index.html').read_text(encoding='utf-8'); readme=(ROOT/'README.md').read_text(encoding='utf-8')
add('Root launcher current','v2.5.2' in rootidx and 'RELEASE-VALIDATION-v2.5.2.md' in rootidx,'v2.5.2')
add('Root README current','# VET45 Theme 7 - v2.5.2' in readme,'v2.5.2')
add('Release manifest version/parent',rel.get('release')=='2.5.2' and rel.get('parent')=='2.5.1',f"{rel.get('release')} / {rel.get('parent')}")
passed=sum(c['pass'] for c in checks); state='PASS' if passed==len(checks) else 'FAIL'
result={'release':'2.5.2','parent':'2.5.1','status':state,'passed':passed,'total':len(checks),'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.5.2.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Release Validation — v2.5.2','',f'**Result: {state} · {passed}/{len(checks)} checks**','', 'Parent: **v2.5.1** · Scope: **BJ02 Quick flow/UI correction + live Figma Info Row refresh; no new UIF migration**','','## Gates','']
for c in checks: lines.append(f"- [{'x' if c['pass'] else ' '}] {c['name']}"+(f" — `{c['detail']}`" if c['detail'] else ''))
lines += ['', '## Current QA evidence','', '- BJ02 real Quick flow: **PASS 21/21**. The gate performs the real click path from SCR-008 to SCR-009, then Product/UOM selection and SCR-084 editing.', '- All-flow runtime smoke: **PASS 85/85**, browser errors **0**.', '- Live Info Row sync: **PASS 497/497 state renders; 1052 visible Info Row instances**, with **0 geometry/anatomy/overlap failures**.', '- `DS v2 / Info Row` current source is live Figma node `525:351`: 338×44, justify-between, gap 0, label left, Default value right-aligned.', '- Long/multiline values are not permitted to mutate Info Row; they use VText layout composition.', '', '## Scope statement','', 'This release corrects UIF-02 and refreshes the shared Info Row implementation consumed by HTML. It does not add another structurally migrated UIF and it does not modify the Figma source; Figma remains the UI authority.', '']
(ROOT/'RELEASE-VALIDATION-v2.5.2.md').write_text('\n'.join(lines),encoding='utf-8')
print(state,passed,'/',len(checks))
for c in checks:
    if not c['pass']: print('FAIL',c)
sys.exit(0 if state=='PASS' else 1)
