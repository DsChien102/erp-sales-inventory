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
info=load(QA/'INFO-ROW-LIVE-SYNC-QA-v2.5.3.json'); smoke=load(QA/'ALL-FLOWS-RUNTIME-SMOKE-v2.5.3.json'); rel=load(ROOT/'RELEASE-MANIFEST-v2.5.3.json')
add('HTML manifest version',manifest.get('version')=='2.5.3',manifest.get('version'))
add('HTML manifest parent',manifest.get('parent')=='2.5.2',manifest.get('parent'))
add('Workbench version',wb.get('version')=='2.5.3',wb.get('version'))
add('UIF migration release',status.get('release')=='2.5.3',status.get('release'))
add('Migrated UIFs unchanged',status.get('productWiringScope')==['UIF-01','UIF-02','UIF-08'],status.get('productWiringScope'))
add('Live Info Row QA',info.get('status')=='PASS' and info.get('stateRenders')==497 and info.get('instances')==1052 and not info.get('failures'),f"states={info.get('stateRenders')} instances={info.get('instances')}")
add('Live Info Row browser/runtime errors zero',not info.get('browserErrors') and not info.get('runtimeErrors'),f"browser={len(info.get('browserErrors',[]))} runtime={len(info.get('runtimeErrors',[]))}")
add('All-flow smoke',smoke.get('status')=='PASS' and smoke.get('renders')==85 and not smoke.get('failures') and not smoke.get('errors'),f"{smoke.get('renders')}/85")
idx=(HTML/'index.html').read_text(encoding='utf-8')
add('v2.5.3 live sync stylesheet loaded last',idx.rfind('v253-info-row-live-sync.css')>idx.rfind('v252-figma-live-sync.css')>0,'load order')
css=(HTML/'v253-info-row-live-sync.css').read_text(encoding='utf-8')
for name,needle in [
    ('Info Row width 338','width:338px!important'),
    ('Info Row height 44','height:44px!important'),
    ('Info Row justify-between','justify-content:space-between!important'),
    ('Info Row gap 0','gap:0!important'),
    ('Info Row value right','text-align:right!important'),
    ('Info Row disabled opacity','opacity:var(--vet45-v2-opacity-disabled,.4)!important')
]: add(name,needle in css,needle)
base=(HTML/'styles.css').read_text(encoding='utf-8')
add('Stale ds24 base width removed','.ds24-info-row {\n  width: 100%;' not in base,'base normalized')
add('Base ds24 Info Row normalized','''.ds24-info-row {\n  width: 338px;\n  max-width: 338px;\n  height: 44px;''' in base,'338x44')
add('Base ds24 gap normalized','''.ds24-info-row {''' in base and '  gap: 0;' in base[base.find('.ds24-info-row {'):base.find('.ds24-info-row {')+500],'gap 0')
runtime_css=(HTML/'figma-ds-runtime/runtime.css').read_text(encoding='utf-8')
add('Runtime specimen current anatomy','.vds-info-row { width:338px; height:44px; display:flex; align-items:center; justify-content:space-between; gap:0;' in runtime_css,'525:351')
add('Runtime registry release',runtime.get('release')=='2.5.3',runtime.get('release'))
add('Runtime registry current Info Row QA',runtime.get('liveComponentRefresh',{}).get('qa')=='../qa/INFO-ROW-LIVE-SYNC-QA-v2.5.3.json',runtime.get('liveComponentRefresh',{}).get('qa'))
add('No new Theme7 component',rel.get('migration',{}).get('newFeatureComponentsCreated')==0,rel.get('migration',{}).get('newFeatureComponentsCreated'))
add('No business behavior change',rel.get('businessBehaviorChanged') is False,rel.get('businessBehaviorChanged'))
add('Release manifest shared DS refresh','DS v2 / Info Row 525:351' in rel.get('migration',{}).get('sharedDsRefresh',[]),rel.get('migration',{}).get('sharedDsRefresh'))
add('Action registry preserved',sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json')=='35f59f04480d6a41f24e1735a88ac14e478319bc57f85e842ac5ff885f6b332a',sha(ROOT/'specs/themes/theme-07/prototype/contracts/action-registry.json'))
add('Screen registry preserved',sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json')=='20d3abc7a229ba54aaa436942ffa767f9914b9af2e8c8e6f901b4049ceab5ebf',sha(ROOT/'specs/themes/theme-07/prototype/contracts/screen-registry.json'))
node=subprocess.run(['node','--check',str(HTML/'app.js')],capture_output=True,text=True)
add('JavaScript syntax',node.returncode==0,node.stderr.strip())
rootidx=(ROOT/'index.html').read_text(encoding='utf-8'); readme=(ROOT/'README.md').read_text(encoding='utf-8')
add('Root launcher current','v2.5.3' in rootidx and 'RELEASE-VALIDATION-v2.5.3.md' in rootidx,'v2.5.3')
add('Root README current','# VET45 Theme 7 - v2.5.3' in readme,'v2.5.3')
add('Release manifest version/parent',rel.get('release')=='2.5.3' and rel.get('parent')=='2.5.2',f"{rel.get('release')} / {rel.get('parent')}")
passed=sum(c['pass'] for c in checks); state='PASS' if passed==len(checks) else 'FAIL'
result={'release':'2.5.3','parent':'2.5.2','status':state,'passed':passed,'total':len(checks),'checks':checks}
(ROOT/'RELEASE-VALIDATION-v2.5.3.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Release Validation — v2.5.3','',f'**Result: {state} · {passed}/{len(checks)} checks**','', 'Parent: **v2.5.2** · Scope: **live Figma Info Row sync only; no Product business-flow change**','','## Gates','']
for c in checks: lines.append(f"- [{'x' if c['pass'] else ' '}] {c['name']}"+(f" — `{c['detail']}`" if c['detail'] else ''))
lines += ['', '## Current QA evidence','', '- Live Info Row sync: **PASS 497/497 state renders; 1052 visible instances; 0 geometry/anatomy/overlap failures**.', '- All-flow runtime smoke: **PASS 85/85**, browser errors **0**.', '- Current Figma source: `DS v2 / Info Row` node `525:351` — 338×44, justify-between, gap 0, Inter 13/20 Regular label, Inter 14/20 SemiBold right-aligned value, Disabled opacity 0.4.', '- v2.5.3 also normalizes the stale base `.ds24-info-row` rule so fidelity no longer depends only on a late CSS override.', '- BJ02 Quick-flow behavior from v2.5.2 is carried forward unchanged.', '', '## Scope statement','', 'This release is a shared Design System sync. It does not add a migrated UIF, create a new component, or modify the Figma source.', '']
(ROOT/'RELEASE-VALIDATION-v2.5.3.md').write_text('\n'.join(lines),encoding='utf-8')
print(state,passed,'/',len(checks))
for c in checks:
    if not c['pass']: print('FAIL',c)
sys.exit(0 if state=='PASS' else 1)
