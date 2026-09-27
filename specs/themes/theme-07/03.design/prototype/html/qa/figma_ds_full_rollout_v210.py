from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
PARENT=Path('/mnt/data/work_t07_v202/VET45-Theme7-Prototype-Harness-v2.0.2')
BAD={'CONTEXTUAL_CARD','MIGRATION_TARGET','OPEN_DS_GAP','UNMAPPED'}
ALLOWED_TEMPLATES={'Mobile / Root List','Mobile / Nested List','Mobile / Detail','Mobile / Form','Mobile / Wizard','Mobile / Search & Select','Mobile / State'}

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

def parse_data(root):
    s=(root/'workbench-data.js').read_text(encoding='utf-8')
    return json.loads(re.sub(r'^window\.VET45_HARNESS_DATA\s*=\s*','',s).rstrip().rstrip(';'))

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]; issues=[]; page_errors=[]; statuses={}; annotated=0; total=0; template_pairs=set(); bad_controls=[]
def ck(name,cond,detail=''): checks.append((name,bool(cond),detail))
def issue(kind,f,s,st,detail): issues.append({'kind':kind,'flow':f,'screen':s,'state':st,'detail':detail})

d=parse_data(ROOT); flows=d['flows']; screens={s['id']:s for s in d['screens']}
active_occurrences=sum(len(f['screens']) for f in flows)
distinct=set(s for f in flows for s in f['screens'])
expected_states=sum(len(screens[s].get('states') or ['READY']) for f in flows for s in f['screens'])
app_src=(ROOT/'app.js').read_text(encoding='utf-8')
map_json=json.loads((ROOT.parent/'contracts/figma-ds/html-figma-ds-mapping.json').read_text(encoding='utf-8'))
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
ck('release = 2.1.0',d.get('version')=='2.1.0' and manifest.get('version')=='2.1.0')
ck('17 active UIFs',len(flows)==17)
ck('73 distinct canonical active screens',len(distinct)==73,f'{len(distinct)}')
ck('85 flow/screen occurrences',active_occurrences==85,f'{active_occurrences}')
ck('497 active state renders expected',expected_states==497,f'{expected_states}')
ck('Phase 4 manifest full rollout',manifest.get('figmaMigration',{}).get('phase')==4 and manifest.get('figmaMigration',{}).get('flows')==17)
ck('runtime mapping release = 2.1.0',map_json.get('release')=='2.1.0')
ck('no VQuantitySelector annotation remains','data-ds-component="VQuantitySelector"' not in app_src)
ck('no direct generic VCard annotation remains','data-ds-component="VCard"' not in app_src)
ck('all 17 UIF IDs in migrated set',all(f'"UIF-{i:02d}"' in app_src.split('const FIGMA_MIGRATED_FLOWS',1)[1].split(']);',1)[0] for i in range(1,18)))

html=inline_html(ROOT)
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: page_errors.append(str(e)))
    p.set_content(html,wait_until='load'); p.add_style_tag(content='*{animation:none!important;transition:none!important;caret-color:transparent!important}')
    for f in flows:
        for sid in f['screens']:
            for st in screens[sid].get('states') or ['READY']:
                total+=1
                try:
                    p.evaluate('''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
                      if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
                      if(x.f==='UIF-03'&&x.s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}
                      if(x.f==='UIF-13'&&x.s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
                      if(x.f==='UIF-14'&&x.s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}
                      render();}''',{'f':f['id'],'s':sid,'st':st})
                    shell=p.locator('#app-screen .v-page-scaffold')
                    if shell.count()!=1:
                        issue('SHELL',f['id'],sid,st,f'count={shell.count()}'); continue
                    tpl=shell.get_attribute('data-figma-template'); tnode=shell.get_attribute('data-figma-template-node')
                    if tpl not in ALLOWED_TEMPLATES or not tnode: issue('TEMPLATE',f['id'],sid,st,f'{tpl} / {tnode}')
                    template_pairs.add((f['id'],sid,tpl,tnode))
                    rows=p.locator('#app-screen [data-ds-component],#app-screen [data-theme-component],#app-screen [data-ds-internal]').evaluate_all('''els=>els.map(e=>{const m=resolveFigmaMapping(e);return {status:m.status,name:m.name,source:m.sourceKey||e.dataset.dsComponent||e.dataset.themeComponent||e.dataset.dsInternal||''}})''')
                    annotated+=len(rows)
                    for r in rows:
                        statuses[r['status']]=statuses.get(r['status'],0)+1
                        if r['status'] in BAD: issue('MAPPING',f['id'],sid,st,r)
                    geo=p.evaluate('''()=>{const q=s=>document.querySelector('#app-screen '+s);const sh=q('.v-page-scaffold'),sb=q('.app-statusbar'),ah=q('.app-header'),ct=q('.app-content'),ft=q('.app-actions'); const cs=ct?getComputedStyle(ct):null; const buttons=[...document.querySelectorAll('#app-screen button:not([hidden])')].filter(x=>{const r=x.getBoundingClientRect(),cs=getComputedStyle(x);return cs.display!=='none'&&cs.visibility!=='hidden'&&r.width>0&&r.height>0}).map(x=>x.getBoundingClientRect().height); return {shell:[sh?.getBoundingClientRect().width,sh?.getBoundingClientRect().height],status:sb?.getBoundingClientRect().height,header:ah?.getBoundingClientRect().height,padL:cs?parseFloat(cs.paddingLeft):null,padR:cs?parseFloat(cs.paddingRight):null,footer:ft?ft.getBoundingClientRect().height:null,minButton:buttons.length?Math.min(...buttons):null,overflow:sh?sh.scrollWidth-sh.clientWidth:0};}''')
                    if tuple(round(x or 0) for x in geo['shell'])!=(402,874): issue('GEOMETRY',f['id'],sid,st,{'shell':geo['shell']})
                    if round(geo['status'] or 0)!=24 or round(geo['header'] or 0)!=56: issue('GEOMETRY',f['id'],sid,st,{'status':geo['status'],'header':geo['header']})
                    if round(geo['padL'] or 0)!=16 or round(geo['padR'] or 0)!=16: issue('GUTTER',f['id'],sid,st,{'left':geo['padL'],'right':geo['padR']})
                    if geo['footer'] is not None and geo['footer']>0 and round(geo['footer'])!=92: issue('FOOTER',f['id'],sid,st,geo['footer'])
                    if geo['minButton'] is not None and geo['minButton']<43.5: issue('TOUCH',f['id'],sid,st,geo['minButton'])
                    if geo['overflow']>0.5: issue('OVERFLOW',f['id'],sid,st,geo['overflow'])
                except Exception as e: issue('RUNTIME',f['id'],sid,st,str(e))
    b.close()
ck('497/497 states rendered',total==497,f'{total}')
ck('all active states have explicit Figma template',not any(i['kind']=='TEMPLATE' for i in issues))
ck('no bad active mapping status',not any(i['kind']=='MAPPING' for i in issues),json.dumps(statuses,ensure_ascii=False,sort_keys=True))
ck('402x874 + 24/56 + 16 gutters + 92 footer',not any(i['kind'] in {'GEOMETRY','GUTTER','FOOTER'} for i in issues))
ck('all visible buttons >=44px',not any(i['kind']=='TOUCH' for i in issues))
ck('no horizontal overflow',not any(i['kind']=='OVERFLOW' for i in issues))
ck('no runtime/page errors',not any(i['kind']=='RUNTIME' for i in issues) and not page_errors,f'page_errors={page_errors}')

# Frozen product source / canonical screen registry
parent_proto=PARENT/'specs/themes/theme-07/prototype'; child_proto=ROOT.parent
parent_srs=PARENT/'specs/themes/theme-07/srs'; child_srs=ROOT.parents[1]/'srs'
parent_files=sorted(p.relative_to(parent_srs) for p in parent_srs.rglob('*') if p.is_file())
child_files=sorted(p.relative_to(child_srs) for p in child_srs.rglob('*') if p.is_file())
srs_same=parent_files==child_files and all(sha(parent_srs/r)==sha(child_srs/r) for r in parent_files)
ck('106 SRS files byte-identical to v2.0.2',srs_same and len(parent_files)==106,f'{len(parent_files)}')
for rel in ['contracts/screen-registry.json','contracts/screen-registry.md']:
    pp=parent_proto/rel; cp=child_proto/rel; ck(f'{rel} byte-identical',pp.exists() and cp.exists() and sha(pp)==sha(cp))
pp=PARENT/'specs/themes/theme-07/theme.manifest.yaml'; cp=ROOT.parents[1]/'theme.manifest.yaml'; ck('theme.manifest.yaml byte-identical',pp.exists() and cp.exists() and sha(pp)==sha(cp))

passed=sum(1 for _,ok,_ in checks if ok); result='PASS' if passed==len(checks) and not issues and not page_errors else 'FAIL'
json_out={'release':'2.1.0','result':result,'checks':len(checks),'passed':passed,'renders':total,'annotatedMappings':annotated,'statusCounts':statuses,'issues':issues,'pageErrors':page_errors,'templatePairs':len(template_pairs)}
(OUT/'FIGMA-DS-FULL-ROLLOUT-QA-v2.1.0.json').write_text(json.dumps(json_out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Theme 7 — Figma DS Full Rollout QA v2.1.0','',f'**Result: {result} · {passed}/{len(checks)} gates · {total} state renders**','',f'- Active mapping annotations resolved: **{annotated}**',f'- Mapping statuses: `{json.dumps(statuses,ensure_ascii=False,sort_keys=True)}`',f'- Runtime issues: **{len(issues)}**',f'- Browser page errors: **{len(page_errors)}**','', '## Gates','']
lines += [f'- [{"x" if ok else " "}] {name}' + (f' — {detail}' if detail else '') for name,ok,detail in checks]
if issues:
    lines += ['','## Issues','']+[f'- `{x["kind"]}` {x["flow"]}/{x["screen"]}/{x["state"]}: `{x["detail"]}`' for x in issues[:100]]
(OUT/'FIGMA-DS-FULL-ROLLOUT-QA-v2.1.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({'result':result,'passed':passed,'checks':len(checks),'renders':total,'annotations':annotated,'statuses':statuses,'issues':len(issues),'pageErrors':len(page_errors)},ensure_ascii=False))
