from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1];OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists(): styles.append(q.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>','<script>'+q.read_text(encoding='utf-8')+'</script>' if q.exists() else '')
active={'UIF-03':['SCR-014','SCR-015','SCR-017','SCR-019'],'UIF-13':['SCR-085','SCR-086','SCR-088','SCR-089'],'UIF-14':['SCR-072','SCR-074','SCR-077']}
checks=[];errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100});p.set_default_timeout(4000);p.on('pageerror',lambda e:errors.append(str(e)));p.set_content(html,wait_until='load')
    for flow,ids in active.items():
        for sid in ids:
            states=p.evaluate(f"screens.find(s=>s.id==='{sid}')?.states||['READY']")
            for state in states:
                before=len(errors)
                try:
                    p.evaluate(f"activeFlowId='{flow}';activeScreenId='{sid}';stateByScreen['{sid}']={json.dumps(state)};render()")
                    g=p.evaluate("""() => {const app=document.querySelector('#app-screen'),content=document.querySelector('.app-content');return {w:app.scrollWidth-app.clientWidth,c:content?content.scrollWidth-content.clientWidth:0,text:(app.innerText||'').slice(0,120),legacy:!!app.querySelector('.v313-sheet,[data-val03-source]')};}""")
                    ok=g['w']<=1 and g['c']<=1 and not g['legacy'] and len(errors)==before
                    checks.append({'flow':flow,'screen':sid,'state':state,'pass':ok,'geometry':g})
                except Exception as e:
                    checks.append({'flow':flow,'screen':sid,'state':state,'pass':False,'error':str(e)})
    b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
payload={'status':status,'version':'4.5.0','renders':len(checks),'passed':sum(x['pass'] for x in checks),'checks':checks,'browserErrors':errors}
(OUT/'VALUATION-FULL-STATE-SMOKE-v4.5.0.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(status,payload['passed'],'/',payload['renders'],'errors',len(errors))
if status!='PASS':
    print([x for x in checks if not x['pass']][:10]);print(errors[:10]);raise SystemExit(1)
