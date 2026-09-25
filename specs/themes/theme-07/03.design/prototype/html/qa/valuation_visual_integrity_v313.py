from pathlib import Path
from playwright.sync_api import sync_playwright
import re,json
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists(): styles.append(q.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{q.read_text(encoding="utf-8")}</script>' if q.exists() else '')
checks=[]; errors=[]
def ck(name,cond,detail=''): checks.append({'name':name,'pass':bool(cond),'detail':detail})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load')
    # canonical phone geometry and valuation padding
    geom=p.evaluate("""() => { const app=document.querySelector('#app-screen'); const dev=document.querySelector('.device-preview'); return {appW:getComputedStyle(app).width,appH:getComputedStyle(app).height,devW:getComputedStyle(dev).width,devH:getComputedStyle(dev).height}; }""")
    ck('Product canvas width 402',geom['appW']=='402px',str(geom))
    ck('Product canvas height 874',geom['appH']=='874px',str(geom))
    for flow,screen in [('UIF-03','SCR-014'),('UIF-13','SCR-085'),('UIF-14','SCR-072')]:
        p.evaluate(f"activeFlowId='{flow}';activeScreenId='{screen}';stateByScreen['{screen}']='READY';render()")
        g=p.evaluate("""() => { const c=document.querySelector('.app-content'); const s=document.querySelector('#app-screen'); const cs=getComputedStyle(c); return {pl:cs.paddingLeft,pr:cs.paddingRight,overflow:s.scrollWidth-s.clientWidth,contentOverflow:c.scrollWidth-c.clientWidth}; }""")
        ck(f'{flow} mobile edge 16',g['pl']=='16px' and g['pr']=='16px',str(g))
        ck(f'{flow} no horizontal overflow',g['overflow']<=1 and g['contentOverflow']<=1,str(g))
    # BJ03 sheet geometry + touch targets
    p.evaluate("activeFlowId='UIF-03';activeScreenId='SCR-014';render()")
    p.locator('[data-v313-val03-receipt="VAL03-R2"]').click(); p.locator('[data-v313-val03-add-basis]').click()
    sheet=p.evaluate("""() => { const s=document.querySelector('.v313-sheet'); const h=document.querySelector('.v313-sheet__handle'); const cs=getComputedStyle(s), ch=getComputedStyle(h); return {handleW:ch.width,handleH:ch.height,pb:cs.paddingBottom,r1:cs.borderTopLeftRadius,r2:cs.borderTopRightRadius,maxH:cs.maxHeight}; }""")
    ck('Bottom sheet handle 48×4',sheet['handleW']=='48px' and sheet['handleH']=='4px',str(sheet))
    ck('Bottom sheet bottom safe area 44',sheet['pb']=='44px',str(sheet))
    ck('Bottom sheet top radius 20',sheet['r1']=='20px' and sheet['r2']=='20px',str(sheet))
    # interactive elements owned by v313 must be >=44 px tall
    targets=p.evaluate("""() => Array.from(document.querySelectorAll('.v313-sheet button,.v313-sheet input,.v313-sheet select,.v313-text-action,.v313-segment button,.v313-details summary')).filter(e=>{const r=e.getBoundingClientRect(),cs=getComputedStyle(e);return cs.display!=='none'&&cs.visibility!=='hidden'&&r.width>0&&r.height>0}).map(e=>({tag:e.tagName,cls:e.className,h:e.getBoundingClientRect().height,text:(e.textContent||e.getAttribute('placeholder')||'').trim().slice(0,50)}))""")
    bad=[x for x in targets if x['h']<43.5]
    ck('v3.13 interactive targets >=44px',not bad,json.dumps(bad,ensure_ascii=False))
    # BJ13 allocation control preserves minimum touch height
    p.evaluate("activeFlowId='UIF-13';activeScreenId='SCR-085';render()")
    p.locator('[data-v313-val13-task="LC13-004"]').click()
    heights=p.evaluate("""() => Array.from(document.querySelectorAll('#app-screen .v313-control,#app-screen button')).filter(e=>e.getBoundingClientRect().width>0).map(e=>e.getBoundingClientRect().height)""")
    ck('BJ13 controls >=44',bool(heights) and min(heights)>=43.5,str(heights))
    # BJ14 publication sheet + method lock/read-only
    p.evaluate("activeFlowId='UIF-14';activeScreenId='SCR-072';render()")
    p.locator('[data-v313-val14-run="COST-0826"]').click()
    ck('BJ14 method has no select/radio',p.locator('#app-screen select,#app-screen input[type=radio]').count()==0)
    p.locator('[data-v313-val14-open-publish]').click()
    pub=p.evaluate("""() => {const s=document.querySelector('.v313-sheet');return {exists:!!s,w:s?getComputedStyle(s).width:null,pb:s?getComputedStyle(s).paddingBottom:null,overflow:s?s.scrollWidth-s.clientWidth:null};}""")
    ck('Publication sheet canonical width/safe area',pub['exists'] and pub['w']=='402px' and pub['pb']=='44px' and pub['overflow']<=1,str(pub))
    # disabled state uses 0.4 opacity
    op=p.evaluate("""() => { const b=document.querySelector('.v313-sheet button'); b.disabled=true; return getComputedStyle(b).opacity; }""")
    ck('Disabled opacity 0.4',abs(float(op)-0.4)<0.01,op)
    b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
payload={'status':status,'checks':checks,'errors':errors}
(OUT/'VALUATION-VISUAL-INTEGRITY-v3.13.0.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# Valuation Visual Integrity v3.13.0','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} {x['detail']}" for x in checks]+['',f'- Browser errors: {len(errors)}']
(OUT/'VALUATION-VISUAL-INTEGRITY-v3.13.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    print([x for x in checks if not x['pass']],errors); raise SystemExit(1)
