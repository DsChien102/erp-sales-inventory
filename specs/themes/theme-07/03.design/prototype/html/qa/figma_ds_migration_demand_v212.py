from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,collections
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent

def inline_html(root):
    idx=(root/'index.html').read_text(encoding='utf-8')
    css='\n'.join((root/x).read_text(encoding='utf-8') for x in ['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css'])
    data=(root/'workbench-data.js').read_text(encoding='utf-8')
    fmap=(root/'figma-ds-runtime-map.js').read_text(encoding='utf-8')
    app=(root/'app.js').read_text(encoding='utf-8')
    return (idx.replace('<link rel="stylesheet" href="figma-ds.exact.css" />','')
      .replace('<link rel="stylesheet" href="figma-ds.styles.exact.css" />','')
      .replace('<link rel="stylesheet" href="tokens.generated.css" />','')
      .replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>')
      .replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
      .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
      .replace('<script src="app.js"></script>',f'<script>{app}</script>'))

def data(root):
    s=(root/'workbench-data.js').read_text(encoding='utf-8')
    return json.loads(re.sub(r'^window\.VET45_HARNESS_DATA\s*=\s*','',s).rstrip().rstrip(';'))

def prep():
    return '''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
      if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
      if(x.f==='UIF-03'&&x.s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}
      if(x.f==='UIF-13'&&x.s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
      if(x.f==='UIF-14'&&x.s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}
      render();}'''

d=data(ROOT); screens={s['id']:s for s in d['screens']}; flows=d['flows']
by_uif={}; global_nodes=collections.Counter(); global_names=collections.Counter(); templates=collections.Counter(); renders=0
html=inline_html(ROOT)
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100});p.set_content(html,wait_until='load')
    for f in flows:
        u={'flow':f['id'],'bj':f.get('bj'),'name':f.get('name'),'screenOccurrences':len(f['screens']),'stateRenders':0,'figmaNodes':collections.Counter(),'dsNames':collections.Counter(),'templates':collections.Counter()}
        for sid in f['screens']:
            for st in screens[sid].get('states') or ['READY']:
                renders+=1;u['stateRenders']+=1;p.evaluate(prep(),{'f':f['id'],'s':sid,'st':st})
                rows=p.locator('#app-screen [data-figma-node],#app-screen [data-ds-component],#app-screen [data-theme-component]').evaluate_all('''els=>els.map(e=>({node:e.dataset.figmaNode||'',name:e.dataset.dsComponent||e.dataset.themeComponent||'',tpl:e.dataset.figmaTemplate||''}))''')
                shell=p.locator('#app-screen .v-page-scaffold')
                if shell.count():
                    t=shell.get_attribute('data-figma-template') or ''
                    if t: u['templates'][t]+=1;templates[t]+=1
                for r in rows:
                    if r['node']:u['figmaNodes'][r['node']]+=1;global_nodes[r['node']]+=1
                    if r['name']:u['dsNames'][r['name']]+=1;global_names[r['name']]+=1
        u['figmaNodes']=dict(u['figmaNodes'].most_common());u['dsNames']=dict(u['dsNames'].most_common());u['templates']=dict(u['templates'].most_common())
        by_uif[f['id']]=u
    b.close()
result={'release':'2.1.2','note':'Demand inventory is based on legacy semantic annotations and is for migration planning only; it is NOT proof of implementation conformance.','renders':renders,'uifs':by_uif,'global':{'figmaNodes':dict(global_nodes.most_common()),'dsNames':dict(global_names.most_common()),'templates':dict(templates.most_common())}}
(OUT/'FIGMA-DS-MIGRATION-DEMAND-v2.1.2.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
lines=['# Figma DS Migration Demand — v2.1.2','',f'**497-state planning inventory:** {renders} renders across {len(flows)} UIFs.','', '> This is a demand/prioritization inventory from legacy semantic annotations. It does not claim those assets are structurally implemented yet.','', '## Highest-demand canonical targets','']
for name,count in global_names.most_common(30): lines.append(f'- `{name}` — {count} annotated render occurrences')
lines += ['','## Page-template demand','']
for name,count in templates.most_common(): lines.append(f'- `{name}` — {count} state renders')
lines += ['','## UIF matrix','']
for fid,u in by_uif.items():
    top=', '.join(f'{k} ({v})' for k,v in list(u['dsNames'].items())[:8])
    lines.append(f'- **{fid} / {u["bj"]}** — {u["stateRenders"]} states · top targets: {top}')
(OUT/'FIGMA-DS-MIGRATION-DEMAND-v2.1.2.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({'renders':renders,'top':global_names.most_common(15),'templates':templates.most_common()},ensure_ascii=False))
