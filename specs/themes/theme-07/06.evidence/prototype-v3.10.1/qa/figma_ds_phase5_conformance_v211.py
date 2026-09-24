from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
PARENT=Path('/mnt/data/work_t07_v210/VET45-Theme7-Prototype-Harness-v2.1.0')
BAD={'CONTEXTUAL_CARD','MIGRATION_TARGET','OPEN_DS_GAP','UNMAPPED'}
RESULT_SURFACES={'result','status / entry','validation result'}

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

def prepare_js():
    return '''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
      if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
      if(x.f==='UIF-03'&&x.s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}
      if(x.f==='UIF-13'&&x.s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
      if(x.f==='UIF-14'&&x.s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}
      render();}'''

checks=[]; issues=[]; page_errors=[]; statuses={}; total=0; annotated=0; state_templates=0

def ck(name,cond,detail=''): checks.append((name,bool(cond),detail))
def issue(kind,f,s,st,detail): issues.append({'kind':kind,'flow':f,'screen':s,'state':st,'detail':detail})

d=parse_data(ROOT); flows=d['flows']; screens={s['id']:s for s in d['screens']}
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
map_json=json.loads((ROOT.parent/'contracts/figma-ds/html-figma-ds-mapping.json').read_text(encoding='utf-8'))
app_src=(ROOT/'app.js').read_text(encoding='utf-8')
active_occurrences=sum(len(f['screens']) for f in flows); distinct=set(s for f in flows for s in f['screens'])
expected_states=sum(len(screens[s].get('states') or ['READY']) for f in flows for s in f['screens'])
ck('release = 2.1.1',d.get('version')=='2.1.1' and manifest.get('version')=='2.1.1' and map_json.get('release')=='2.1.1')
ck('parent = 2.1.0',manifest.get('parent')=='2.1.0' and map_json.get('source',{}).get('parent')=='2.1.0')
ck('Phase 5 manifest',manifest.get('figmaMigration',{}).get('phase')==5)
ck('17 active UIFs',len(flows)==17)
ck('73 distinct canonical active screens',len(distinct)==73,f'{len(distinct)}')
ck('85 flow/screen occurrences',active_occurrences==85,f'{active_occurrences}')
ck('497 active state renders expected',expected_states==497,f'{expected_states}')
ck('no VQuantitySelector annotation','data-ds-component="VQuantitySelector"' not in app_src)
ck('no direct generic VCard annotation','data-ds-component="VCard"' not in app_src)
ck('success result helper is VSection composition','function resultHero' in app_src and 'data-composed-from="VIcon,VText"' in app_src)
# Static base template check for all business result/status/validation surfaces.
base_result_wrong=[]
for f in flows:
    for sid in f['screens']:
        if screens[sid].get('surface') in RESULT_SURFACES:
            # evaluate by parsing literal table safely enough: exact pair must be Detail in source
            if f'"{sid}":"Mobile / Detail"' not in app_src.split(f'"{f["id"]}":',1)[1].split('},',1)[0]:
                base_result_wrong.append(f'{f["id"]}/{sid}/{screens[sid].get("surface")}')
ck('result/status/validation base archetypes are Mobile / Detail',not base_result_wrong,', '.join(base_result_wrong))

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
                    p.evaluate(prepare_js(),{'f':f['id'],'s':sid,'st':st})
                    shell=p.locator('#app-screen .v-page-scaffold')
                    if shell.count()!=1:
                        issue('SHELL',f['id'],sid,st,f'count={shell.count()}'); continue
                    tpl=shell.get_attribute('data-figma-template')
                    if tpl=='Mobile / State': state_templates+=1
                    state_check=p.evaluate('''()=>{const sh=document.querySelector('#app-screen .v-page-scaffold'); const vis=e=>{if(!e)return false;const r=e.getBoundingClientRect(),c=getComputedStyle(e);return r.width>0&&r.height>0&&c.display!=='none'&&c.visibility!=='hidden'}; const es=[...document.querySelectorAll('#app-screen [data-ds-component="VEmptyState"]')].filter(vis); return {tpl:sh?.dataset.figmaTemplate,emptyVisible:es.length,centered:document.querySelector('#app-screen .app-content')?.classList.contains('app-content--centered')||false};}''')
                    if tpl=='Mobile / State' and (state_check['emptyVisible']<1 or not state_check['centered']):
                        issue('STATE_TEMPLATE',f['id'],sid,st,state_check)
                    # Owned VEmpty* slots must only exist under an actual VEmptyState.
                    stray=p.evaluate('''()=>[...document.querySelectorAll('#app-screen [data-ds-component="VEmptyMedia"],#app-screen [data-ds-component="VEmptyTitle"],#app-screen [data-ds-component="VEmptyDescription"]')].filter(e=>!e.closest('[data-ds-component="VEmptyState"]')).map(e=>e.dataset.dsComponent+':'+(e.textContent||'').trim().slice(0,60))''')
                    if stray: issue('STRAY_EMPTY_SLOT',f['id'],sid,st,stray)
                    # Mapping statuses.
                    rows=p.locator('#app-screen [data-ds-component],#app-screen [data-theme-component],#app-screen [data-ds-internal]').evaluate_all('''els=>els.map(e=>{const m=resolveFigmaMapping(e);return {status:m.status,name:m.name}})''')
                    annotated+=len(rows)
                    for r in rows:
                        statuses[r['status']]=statuses.get(r['status'],0)+1
                        if r['status'] in BAD: issue('MAPPING',f['id'],sid,st,r)
                    # Exact Info Row geometry + typography responsibility.
                    info=p.evaluate('''()=>{const vis=e=>{const r=e.getBoundingClientRect(),c=getComputedStyle(e);return r.width>0&&r.height>0&&c.display!=='none'&&c.visibility!=='hidden'}; return [...document.querySelectorAll('#app-screen [data-ds-component="DS v2 / Info Row"]')].filter(vis).map(e=>{const c=getComputedStyle(e),a=e.firstElementChild?.getBoundingClientRect(),z=e.lastElementChild?.getBoundingClientRect(),r=e.getBoundingClientRect();return {display:c.display,gap:parseFloat(c.gap)||0,h:r.height,overlap:a&&z?Math.max(0,a.right-z.left):0,label:e.firstElementChild?.textContent?.trim().slice(0,40),value:e.lastElementChild?.textContent?.trim().slice(0,40)}})}''')
                    for r in info:
                        if r['display']!='flex' or r['gap']<7.5 or r['h']<43.5 or r['overlap']>0.5:
                            issue('INFO_ROW',f['id'],sid,st,r)
                    # Visible textarea must resolve to VTextarea; direct VTextField+textarea is forbidden.
                    tx=p.evaluate('''()=>{const vis=e=>{const r=e.getBoundingClientRect(),c=getComputedStyle(e);return r.width>0&&r.height>0&&c.display!=='none'&&c.visibility!=='hidden'};return [...document.querySelectorAll('#app-screen textarea')].filter(vis).map(t=>{const o=t.closest('[data-ds-component]');const m=o?resolveFigmaMapping(o):null;const inputFrame=t.closest('.input-shell--textarea');const r=(inputFrame||t).getBoundingClientRect(),c=getComputedStyle(t);return {owner:o?.dataset.dsComponent||null,resolved:m?.name||null,h:r.height,resize:c.resize}})}''')
                    for r in tx:
                        if r['owner']=='VTextField' or r['resolved']!='VTextarea' or r['h']<87.5 or r['resize']!='none': issue('TEXTAREA',f['id'],sid,st,r)
                    # Raw implementation/null leakage in visible Product text.
                    text=p.locator('#app-screen').inner_text()
                    raw=re.findall(r'(?i)(?<![\w-])(null|undefined|nan|infinity)(?![\w-])',text)
                    if raw: issue('RAW_VALUE',f['id'],sid,st,raw[:8])
                    # Geometry and hit targets.
                    geo=p.evaluate('''()=>{const q=s=>document.querySelector('#app-screen '+s);const sh=q('.v-page-scaffold'),sb=q('.app-statusbar'),ah=q('.app-header'),ct=q('.app-content'),ft=q('.app-actions');const cs=ct?getComputedStyle(ct):null;const hits=[...document.querySelectorAll('#app-screen button:not([hidden]),#app-screen input:not([type="hidden"]),#app-screen select')].filter(x=>{const r=x.getBoundingClientRect(),c=getComputedStyle(x);return r.width>0&&r.height>0&&c.display!=='none'&&c.visibility!=='hidden'}).map(x=>x.getBoundingClientRect().height);const prim=[...document.querySelectorAll('#app-screen .button--primary:not([hidden])')].filter(x=>{const r=x.getBoundingClientRect(),c=getComputedStyle(x);return r.width>0&&r.height>0&&c.display!=='none'&&c.visibility!=='hidden'}).length;return {shell:[sh?.getBoundingClientRect().width,sh?.getBoundingClientRect().height],status:sb?.getBoundingClientRect().height,header:ah?.getBoundingClientRect().height,padL:cs?parseFloat(cs.paddingLeft):null,padR:cs?parseFloat(cs.paddingRight):null,footer:ft?ft.getBoundingClientRect().height:null,minHit:hits.length?Math.min(...hits):null,overflow:sh?sh.scrollWidth-sh.clientWidth:0,primary:prim};}''')
                    if tuple(round(x or 0) for x in geo['shell'])!=(402,874): issue('GEOMETRY',f['id'],sid,st,geo)
                    if round(geo['status'] or 0)!=24 or round(geo['header'] or 0)!=56: issue('GEOMETRY',f['id'],sid,st,geo)
                    if round(geo['padL'] or 0)!=16 or round(geo['padR'] or 0)!=16: issue('GUTTER',f['id'],sid,st,geo)
                    if geo['footer'] is not None and geo['footer']>0 and round(geo['footer'])!=92: issue('FOOTER',f['id'],sid,st,geo)
                    if geo['minHit'] is not None and geo['minHit']<43.5: issue('TOUCH',f['id'],sid,st,geo['minHit'])
                    if geo['overflow']>0.5: issue('OVERFLOW',f['id'],sid,st,geo['overflow'])
                    if geo['primary']>1: issue('PRIMARY_ACTION',f['id'],sid,st,geo['primary'])
                except Exception as e: issue('RUNTIME',f['id'],sid,st,str(e))
    # Specific money-field check in opening-balance form.
    p.evaluate(prepare_js(),{'f':'UIF-12','s':'SCR-067','st':'READY'})
    money=p.evaluate('''()=>{const i=document.querySelector('[data-cf12-control-value]');const o=i?.closest('[data-ds-component]');const m=o?resolveFigmaMapping(o):null;return {owner:o?.dataset.dsComponent||null,resolved:m?.name||null,value:i?.value||'',inputmode:i?.inputMode||'',suffix:o?.querySelector('.money-suffix')?.textContent?.trim()||''}}''')
    if money['resolved']!='VMoneyField' or money['owner']!='VMoneyField' or '.' not in money['value'] or money.get('suffix')!='₫': issue('MONEY_FIELD','UIF-12','SCR-067','READY',money)
    # Interaction: formatted VMoneyField input normalizes to the numeric business value and re-renders formatted.
    p.locator('[data-cf12-control-value]').fill('400.000.000')
    normalized=p.evaluate('()=>cf12ControlValue')
    p.evaluate('()=>render()')
    money_after=p.locator('[data-cf12-control-value]').input_value()
    if normalized!='400000000' or money_after!='400.000.000': issue('MONEY_INTERACTION','UIF-12','SCR-067','READY',{'normalized':normalized,'rendered':money_after})
    b.close()

ck('497/497 states rendered',total==497,f'{total}')
ck('Mobile / State only for true centered VEmptyState',not any(i['kind']=='STATE_TEMPLATE' for i in issues),f'{state_templates} dynamic State renders')
ck('VEmpty owned slots never used as success/result anatomy',not any(i['kind']=='STRAY_EMPTY_SLOT' for i in issues))
ck('no bad active mapping status',not any(i['kind']=='MAPPING' for i in issues),json.dumps(statuses,ensure_ascii=False,sort_keys=True))
ck('all visible exact Info Rows match 44px / 8px canonical rhythm',not any(i['kind']=='INFO_ROW' for i in issues))
ck('all visible multiline inputs resolve to canonical VTextarea',not any(i['kind']=='TEXTAREA' for i in issues))
ck('opening balance monetary control resolves to VMoneyField',not any(i['kind']=='MONEY_FIELD' for i in issues),json.dumps([i['detail'] for i in issues if i['kind']=='MONEY_FIELD'],ensure_ascii=False))
ck('VMoneyField formatting preserves numeric business value',not any(i['kind']=='MONEY_INTERACTION' for i in issues))
ck('no visible null/undefined/NaN/Infinity leakage',not any(i['kind']=='RAW_VALUE' for i in issues))
ck('402x874 + 24/56 + 16 gutters + 92 footer',not any(i['kind'] in {'GEOMETRY','GUTTER','FOOTER'} for i in issues))
ck('all visible controls >=44px',not any(i['kind']=='TOUCH' for i in issues))
ck('no horizontal overflow',not any(i['kind']=='OVERFLOW' for i in issues))
ck('at most one visible Primary action per screen',not any(i['kind']=='PRIMARY_ACTION' for i in issues))
ck('no runtime/page errors',not any(i['kind']=='RUNTIME' for i in issues) and not page_errors,f'page_errors={page_errors}')
# Frozen source/registry vs exact v2.1.0 parent.
parent_proto=PARENT/'specs/themes/theme-07/prototype'; child_proto=ROOT.parent
parent_srs=PARENT/'specs/themes/theme-07/srs'; child_srs=ROOT.parents[1]/'srs'
parent_files=sorted(p.relative_to(parent_srs) for p in parent_srs.rglob('*') if p.is_file()); child_files=sorted(p.relative_to(child_srs) for p in child_srs.rglob('*') if p.is_file())
srs_same=parent_files==child_files and all(sha(parent_srs/r)==sha(child_srs/r) for r in parent_files)
ck('106 SRS files byte-identical to v2.1.0',srs_same and len(parent_files)==106,f'{len(parent_files)}')
for rel in ['contracts/screen-registry.json','contracts/screen-registry.md']:
    pp=parent_proto/rel; cp=child_proto/rel; ck(f'{rel} byte-identical to v2.1.0',pp.exists() and cp.exists() and sha(pp)==sha(cp))
pp=PARENT/'specs/themes/theme-07/theme.manifest.yaml'; cp=ROOT.parents[1]/'theme.manifest.yaml'; ck('theme.manifest.yaml byte-identical to v2.1.0',pp.exists() and cp.exists() and sha(pp)==sha(cp))

passed=sum(1 for _,ok,_ in checks if ok); result='PASS' if passed==len(checks) and not issues and not page_errors else 'FAIL'
out={'release':'2.1.1','result':result,'checks':len(checks),'passed':passed,'renders':total,'stateTemplateRenders':state_templates,'annotatedMappings':annotated,'statusCounts':statuses,'issues':issues,'pageErrors':page_errors}
(OUT/'FIGMA-DS-PHASE5-CONFORMANCE-QA-v2.1.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Theme 7 — Figma DS Phase 5 Conformance QA v2.1.1','',f'**Result: {result} · {passed}/{len(checks)} gates · {total} state renders**','',f'- Dynamic `Mobile / State` renders: **{state_templates}** (only true centered VEmptyState surfaces)',f'- Mapped annotations resolved: **{annotated}**',f'- Mapping statuses: `{json.dumps(statuses,ensure_ascii=False,sort_keys=True)}`',f'- Runtime issues: **{len(issues)}**',f'- Browser page errors: **{len(page_errors)}**','','## Gates','']
lines += [f'- [{"x" if ok else " "}] {name}' + (f' — {detail}' if detail else '') for name,ok,detail in checks]
if issues:
    lines += ['','## Issues','']+[f'- `{x["kind"]}` {x["flow"]}/{x["screen"]}/{x["state"]}: `{x["detail"]}`' for x in issues[:150]]
(OUT/'FIGMA-DS-PHASE5-CONFORMANCE-QA-v2.1.1.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps({'result':result,'passed':passed,'checks':len(checks),'renders':total,'stateTemplates':state_templates,'annotations':annotated,'issues':len(issues),'pageErrors':len(page_errors),'kinds':{k:sum(1 for i in issues if i['kind']==k) for k in sorted(set(i['kind'] for i in issues))}},ensure_ascii=False))
