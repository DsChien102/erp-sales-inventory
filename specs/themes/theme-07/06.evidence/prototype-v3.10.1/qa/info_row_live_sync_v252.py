from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8')
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css']
css='\n'.join((ROOT/x).read_text(encoding='utf-8') for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
for s in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{s}"></script>',f'<script>{(ROOT/s).read_text(encoding="utf-8")}</script>')

data=json.loads(re.sub(r'^window\.VET45_HARNESS_DATA\s*=\s*','',(ROOT/'workbench-data.js').read_text(encoding='utf-8')).rstrip().rstrip(';'))
screens={s['id']:s for s in data['screens']}
errors=[]; runtime_errors=[]; results=[]; renders=0
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    for f in data['flows']:
        for sid in f['screens']:
            for st in screens[sid].get('states') or ['READY']:
                renders += 1
                try:
                    rows=p.evaluate('''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
                      if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
                      if(x.f==='UIF-03'&&x.s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}
                      if(x.f==='UIF-13'&&x.s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
                      if(x.f==='UIF-14'&&x.s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}
                      render();
                      return [...document.querySelectorAll('.figma-calibrated-shell [data-ds-component="DS v2 / Info Row"]')].map(e=>{const cs=getComputedStyle(e),r=e.getBoundingClientRect(),a=e.firstElementChild?.getBoundingClientRect(),z=e.lastElementChild?.getBoundingClientRect(),zcs=e.lastElementChild?getComputedStyle(e.lastElementChild):null,lcs=e.firstElementChild?getComputedStyle(e.firstElementChild):null;return {text:(e.innerText||'').split('\\n').join(' | ').slice(0,160),w:Math.round(r.width*10)/10,h:Math.round(r.height*10)/10,display:cs.display,align:cs.alignItems,justify:cs.justifyContent,gap:cs.columnGap,lastAlign:zcs?.textAlign||'',labelFont:lcs?`${lcs.fontFamily}/${lcs.fontSize}/${lcs.lineHeight}/${lcs.fontWeight}`:'',valueFont:zcs?`${zcs.fontFamily}/${zcs.fontSize}/${zcs.lineHeight}/${zcs.fontWeight}`:'',outside:!!(a&&z&&(a.left<r.left-1||z.right>r.right+1)),overlap:!!(a&&z&&a.right>z.left+0.5)};});}''',{'f':f['id'],'s':sid,'st':st})
                    for row in rows:
                        row.update({'flow':f['id'],'screen':sid,'state':st}); results.append(row)
                except Exception as e:
                    runtime_errors.append({'flow':f['id'],'screen':sid,'state':st,'error':str(e)})
    b.close()

fails=[]
for x in results:
    ok=(abs(x['w']-338)<=1 and abs(x['h']-44)<=1 and x['display']=='flex' and x['align']=='center' and x['justify']=='space-between' and x['gap'] in ('0px','normal') and x['lastAlign']=='right' and not x['outside'] and not x['overlap'] and '/13px/20px/400' in x['labelFont'] and '/14px/20px/600' in x['valueFont'])
    if not ok: fails.append(x)
status='PASS' if not fails and not errors and not runtime_errors and renders==497 else 'FAIL'
res={'status':status,'stateRenders':renders,'instances':len(results),'failures':fails,'browserErrors':errors,'runtimeErrors':runtime_errors,'sourceNode':'525:351','expected':{'width':338,'height':44,'justify':'space-between','gap':0,'label':'Inter 13/20 400','value':'Inter 14/20 600 right'}}
(OUT/'INFO-ROW-LIVE-SYNC-QA-v2.5.2.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
md=['# Info Row live Figma sync QA — v2.5.2','',f'**Result: {status} · {renders}/497 state renders · {len(results)} visible Info Row instances checked**','', '- Source: live Figma `DS v2 / Info Row` (`525:351`), refreshed 2026-09-10.','- Expected: 338×44, justify-between, gap 0, Inter 13/20 Regular label, Inter 14/20 SemiBold right-aligned value.','- Long/multiline values are deliberately not mapped to Info Row; they use a VText layout composition instead of mutating the component.','',f'- Browser errors: **{len(errors)}**',f'- Runtime errors: **{len(runtime_errors)}**',f'- Geometry/anatomy/content-overlap failures: **{len(fails)}**']
if runtime_errors:
    md+=['','## Runtime errors','']+[f"- {x['flow']}/{x['screen']}/{x['state']}: `{x['error']}`" for x in runtime_errors[:100]]
if fails:
    md+=['','## Info Row failures','']+[f"- {x['flow']}/{x['screen']}/{x['state']} `{x['text']}` — {x}" for x in fails[:100]]
(OUT/'INFO-ROW-LIVE-SYNC-QA-v2.5.2.md').write_text('\n'.join(md)+'\n',encoding='utf-8')
print(status,'renders',renders,'instances',len(results),'fails',len(fails),'browser',len(errors),'runtime',len(runtime_errors))
for x in fails[:20]: print(x)
for x in runtime_errors[:10]: print('RUNTIME',x)
raise SystemExit(0 if status=='PASS' else 1)
