from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
for x in cssfiles: idx=idx.replace(f'<link rel="stylesheet" href="{x}" />','')
idx=idx.replace('</head>',f'<style>{css}</style></head>')
for s in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    idx=idx.replace(f'<script src="{s}"></script>',f'<script>{(ROOT/s).read_text()}</script>')
errors=[]; rows=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(idx,wait_until='load')
    flow=p.evaluate("flowCatalog.find(f=>f.id==='UIF-02')")
    for sid in flow['screens']:
        states=p.evaluate("sid=>screens.find(x=>x.id===sid)?.states||['READY']",sid)
        for st in states:
            p.evaluate("([sid,st])=>{activeFlowId='UIF-02';activeScreenId=sid;stateByScreen[sid]=st;flowMode=sid==='SCR-008'?'quick':flowMode; if(sid==='SCR-009'||sid==='SCR-084'||sid==='SCR-010'||sid==='SCR-011'){ if(!bj02Lines.length){flowMode='document';selectedDocumentId='PN-260816-04';resetBj02Receipt('document');} if(sid==='SCR-084'&&!lineEditorDraft)beginLineEditor(bj02Lines[0]?.id||null);} renderAppScreen();}",[sid,st])
            metrics=p.evaluate('''()=>{const shell=document.querySelector('.figma-calibrated-shell');const root=document.querySelector('#app-screen');const rr=shell?.getBoundingClientRect();const bad=[];root?.querySelectorAll('*').forEach(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);if(!r.width||!r.height||s.display==='none'||s.visibility==='hidden')return; if(rr&&(r.left<rr.left-1||r.right>rr.right+1))bad.push({kind:'horizontal',tag:e.tagName,cls:String(e.className||'').slice(0,80),text:(e.innerText||'').trim().slice(0,60)}); const text=(e.innerText||'').trim(); if(text && (s.overflow==='hidden'||s.overflowX==='hidden'||s.overflowY==='hidden') && (e.scrollWidth>e.clientWidth+2||e.scrollHeight>e.clientHeight+2))bad.push({kind:'clip',tag:e.tagName,cls:String(e.className||'').slice(0,80),text:text.slice(0,60),sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight});});return {horizontal:(shell?.scrollWidth||0)-(shell?.clientWidth||0),bad:bad.slice(0,20),text:(root?.innerText||'').trim().length};}''')
            rows.append({'screen':sid,'state':st,**metrics})
    b.close()
fail=[r for r in rows if r['horizontal']>1 or r['bad'] or r['text']==0]
status='PASS' if not fail and not errors else 'FAIL'
res={'status':status,'renders':len(rows),'failures':fail,'browserErrors':errors}
(OUT/'BJ02-STATE-LAYOUT-QA-v2.5.5.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
md=['# BJ02 State/Layout QA — v2.5.5','',f'**Result: {status} · {len(rows)} state renders**','',f'- Layout/clip failures: **{len(fail)}**',f'- Browser errors: **{len(errors)}**']
if fail:
    md += ['','## Failures','']+[f"- {x['screen']} / {x['state']} — horizontal={x['horizontal']} bad={x['bad'][:2]}" for x in fail]
(OUT/'BJ02-STATE-LAYOUT-QA-v2.5.5.md').write_text('\n'.join(md)+'\n')
print(status,len(rows),'renders fail',len(fail),'errors',len(errors))
for x in fail[:10]: print('FAIL',x['screen'],x['state'],x['horizontal'],x['bad'][:1])
raise SystemExit(0 if status=='PASS' else 1)
