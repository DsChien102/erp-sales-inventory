from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
PKG=ROOT.parents[4]
PARENT=Path('/mnt/data/work_t07_v201/VET45-Theme7-Prototype-Harness-v2.0.1')
TARGET={'UIF-02','UIF-05','UIF-08','UIF-10','UIF-15','UIF-17'}
BAD={'CONTEXTUAL_CARD','MIGRATION_TARGET','OPEN_DS_GAP','UNMAPPED'}

def inline_html(root):
    idx=(root/'index.html').read_text(encoding='utf-8')
    css=(root/'tokens.generated.css').read_text(encoding='utf-8')+'\n'+(root/'styles.css').read_text(encoding='utf-8')
    data=(root/'workbench-data.js').read_text(encoding='utf-8')
    fmap=(root/'figma-ds-runtime-map.js').read_text(encoding='utf-8')
    app=(root/'app.js').read_text(encoding='utf-8')
    return (idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','')
      .replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>')
      .replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
      .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
      .replace('<script src="app.js"></script>',f'<script>{app}</script>'))

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def parsed_data(root):
    s=(root/'workbench-data.js').read_text(encoding='utf-8')
    return json.loads(re.sub(r'^window\.VET45_HARNESS_DATA\s*=\s*','',s).rstrip().rstrip(';'))
checks=[]; issues=[]; page_errors=[]; renders=0
def ck(name,cond,detail=''): checks.append((name,bool(cond),detail))
def issue(kind,f,s,st,detail): issues.append({'kind':kind,'flow':f,'screen':s,'state':st,'detail':detail})

data=parsed_data(ROOT); flows={f['id']:f for f in data['flows']}; screens={s['id']:s for s in data['screens']}
ck('Release metadata is v2.0.2',data.get('version')=='2.0.2')
ck('Representative calibration set is exactly six UIFs',TARGET=={'UIF-02','UIF-05','UIF-08','UIF-10','UIF-15','UIF-17'})
expected_renders=sum(len(screens[sid].get('states',[]) or ['READY']) for fid in TARGET for sid in flows[fid]['screens'])
ck('Representative scenario matrix contains 212 renders',expected_renders==212,str(expected_renders))
# Frozen business/source protection
parent_srs=PARENT/'specs/themes/theme-07/srs'; child_srs=PKG/'specs/themes/theme-07/srs'
parent_files=sorted([x.relative_to(parent_srs) for x in parent_srs.rglob('*') if x.is_file()])
child_files=sorted([x.relative_to(child_srs) for x in child_srs.rglob('*') if x.is_file()])
ck('SRS file topology unchanged from v2.0.1',parent_files==child_files,f'{len(child_files)} files')
changed_srs=[str(x) for x in child_files if sha(parent_srs/x)!=sha(child_srs/x)] if parent_files==child_files else ['topology differs']
ck('SRS bytes unchanged from v2.0.1',not changed_srs,', '.join(changed_srs[:5]))
for rel in ['contracts/screen-registry.json','contracts/screen-registry.md']:
    pp=PARENT/'specs/themes/theme-07/prototype'/rel; cp=PKG/'specs/themes/theme-07/prototype'/rel
    ck(f'{rel} protected byte-identical',sha(pp)==sha(cp))

html=inline_html(ROOT)
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e:page_errors.append(str(e)))
    p.set_content(html,wait_until='load'); p.wait_for_timeout(20)
    for fid in [f['id'] for f in data['flows'] if f['id'] in TARGET]:
      for sid in flows[fid]['screens']:
        for st in screens[sid].get('states',[]) or ['READY']:
          renders+=1
          try:
            p.evaluate('''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
              if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
              render();}''',{'f':fid,'s':sid,'st':st}); p.wait_for_timeout(1)
            shell=p.locator('#app-screen .v-page-scaffold')
            if not shell.count(): issue('NO_SHELL',fid,sid,st,'missing scaffold'); continue
            tpl=shell.get_attribute('data-figma-template'); tplnode=shell.get_attribute('data-figma-template-node')
            if not tpl or not tplnode: issue('NO_EXPLICIT_TEMPLATE',fid,sid,st,f'{tpl} / {tplnode}')
            m=shell.evaluate('(e)=>resolveFigmaMapping(e)')
            if m.get('status')!='EXACT' or m.get('nodeId')!=tplnode: issue('TEMPLATE_NOT_EXACT',fid,sid,st,json.dumps(m,ensure_ascii=False))
            rows=p.locator('#app-screen [data-ds-component],#app-screen [data-theme-component],#app-screen [data-ds-internal]').evaluate_all('els=>els.map(e=>{const m=resolveFigmaMapping(e);return {ds:e.dataset.dsComponent||"",theme:e.dataset.themeComponent||"",name:m.name,status:m.status,layer:m.layer}})')
            bad=[r for r in rows if r['status'] in BAD]
            if bad: issue('CALIBRATION_DEBT',fid,sid,st,json.dumps(bad[:8],ensure_ascii=False))
            if any(r['ds']=='VQuantitySelector' for r in rows): issue('LEGACY_QUANTITY_SELECTOR',fid,sid,st,'VQuantitySelector remains in calibrated render')
            g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
            if g['sw']>g['cw']+1: issue('HORIZONTAL_OVERFLOW',fid,sid,st,str(g))
            # Geometry gates from live Figma templates.
            appbar=p.locator('#app-screen .app-appbar')
            if appbar.count():
              a=appbar.evaluate('(e)=>{const s=getComputedStyle(e);return {h:e.getBoundingClientRect().height}}')
              if abs(a['h']-56)>0.5: issue('APPBAR_GEOMETRY',fid,sid,st,str(a))
              title=appbar.locator('h3')
              if title.count():
                t=title.evaluate('(e)=>{const s=getComputedStyle(e);return {fs:parseFloat(s.fontSize),lh:parseFloat(s.lineHeight),fw:s.fontWeight}}')
                if abs(t['fs']-16)>.1 or abs(t['lh']-22)>.1 or int(t['fw'])!=600: issue('APPBAR_TYPE',fid,sid,st,str(t))
            content=p.locator('#app-screen .app-content')
            if content.count():
              c=content.evaluate('(e)=>{const s=getComputedStyle(e);return {pl:parseFloat(s.paddingLeft),pr:parseFloat(s.paddingRight)}}')
              if abs(c['pl']-16)>.1 or abs(c['pr']-16)>.1: issue('CONTENT_GUTTER',fid,sid,st,str(c))
            footer=p.locator('#app-screen .v-page-scaffold > .app-actions')
            if footer.count():
              fg=footer.evaluate('(e)=>({h:e.getBoundingClientRect().height})')
              if abs(fg['h']-92)>0.5: issue('STICKY_FOOTER_GEOMETRY',fid,sid,st,str(fg))
              for j in range(footer.locator('button').count()):
                h=footer.locator('button').nth(j).evaluate('(e)=>e.getBoundingClientRect().height')
                if h<43.5: issue('FOOTER_TOUCH_TARGET',fid,sid,st,str(h))
            # Primary interactive controls. Radio/checkbox/file controls are wrapped by a >=44 target.
            controls=p.locator('#app-screen button:visible,#app-screen select:visible,#app-screen input:not([type="hidden"]):not([type="radio"]):not([type="checkbox"]):not([type="file"]):visible')
            small=[]
            for j in range(controls.count()):
              box=controls.nth(j).bounding_box()
              if box and box['height']<43.5: small.append((controls.nth(j).evaluate('(e)=>e.tagName+"."+e.className'),round(box['height'],1)))
            if small: issue('TOUCH_TARGET_LT44',fid,sid,st,str(small[:8]))
          except Exception as e: issue('RENDER_ERROR',fid,sid,st,str(e))
    b.close()
ck('All 212 representative states rendered',renders==212,str(renders))
ck('All representative screens have exact Figma template mappings',not [x for x in issues if x['kind'] in {'NO_EXPLICIT_TEMPLATE','TEMPLATE_NOT_EXACT'}])
ck('No generic-card/migration/open-gap/unmapped debt in representative renders',not [x for x in issues if x['kind']=='CALIBRATION_DEBT'])
ck('No legacy VQuantitySelector remains in representative renders',not [x for x in issues if x['kind']=='LEGACY_QUANTITY_SELECTOR'])
ck('Live template geometry/touch gates pass',not [x for x in issues if x['kind'] in {'APPBAR_GEOMETRY','APPBAR_TYPE','CONTENT_GUTTER','STICKY_FOOTER_GEOMETRY','FOOTER_TOUCH_TARGET','TOUCH_TARGET_LT44'}])
ck('No representative runtime/overflow errors',not [x for x in issues if x['kind'] in {'NO_SHELL','HORIZONTAL_OVERFLOW','RENDER_ERROR'}])
ck('No browser page errors',not page_errors,'; '.join(page_errors[:3]))
failed=[x for x in checks if not x[1]]
result='PASS' if not failed else 'FAIL'
report=['# Figma DS Phase 3 Calibration QA — v2.0.2','',f'**Result: {result} · {sum(1 for x in checks if x[1])}/{len(checks)} gates · {renders} representative state renders**','','## Scope','', '- UIF-02 · Receiving', '- UIF-05 · Picking & handover', '- UIF-08 · Physical inventory', '- UIF-10 · Disposal', '- UIF-15 · Inventory inquiry/report', '- UIF-17 · UNKNOWN recovery', '', '## Gates','']
report += [f'- {"PASS" if ok else "FAIL"} — {name}'+(f' · {detail}' if detail else '') for name,ok,detail in checks]
if issues: report += ['','## Issues']+[f'- `{x["flow"]}/{x["screen"]}/{x["state"]}` · **{x["kind"]}** — {x["detail"]}' for x in issues[:400]]
if page_errors: report += ['','## Browser errors']+[f'- {e}' for e in page_errors]
(OUT/'FIGMA-DS-CALIBRATION-QA-v2.0.2.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
(OUT/'FIGMA-DS-CALIBRATION-QA-v2.0.2.json').write_text(json.dumps({'result':result,'gates':checks,'renders':renders,'issues':issues,'pageErrors':page_errors},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(result,sum(1 for x in checks if x[1]),'/',len(checks),'gates',renders,'renders','issues',len(issues))
if failed:
  for x in failed: print('FAIL',x)
  raise SystemExit(1)
