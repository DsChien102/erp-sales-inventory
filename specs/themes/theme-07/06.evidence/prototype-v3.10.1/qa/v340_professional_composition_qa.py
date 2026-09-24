from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
SCOPE_AC=['UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-15','UIF-16','UIF-17']
checks=[]
def ck(name,cond,note=''): checks.append((name,bool(cond),note))
def inline(root):
    h=(root/'index.html').read_text()
    css=[]
    for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"\s*/?>',h):
        p=root/fn
        if p.exists(): css.append(p.read_text())
        h=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',h)
    h=h.replace('</head>','<style>'+"\n".join(css)+'</style></head>')
    for fn in re.findall(r'<script src="([^"]+\.js)"></script>',h):
        p=root/fn
        if p.exists(): h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text()}</script>')
    return h
m=json.loads((ROOT/'manifest.json').read_text())
w=json.loads((ROOT/'workbench-data.json').read_text())
idx=(ROOT/'index.html').read_text(); css=(ROOT/'v340-professional-composition.css').read_text(); js=(ROOT/'v340-professional-composition.js').read_text()
ck('version 3.4.0',m.get('version')=='3.4.0' and m.get('parentVersion')=='3.3.0' and w.get('version')=='3.4.0',f"{m.get('version')} <- {m.get('parentVersion')} / {w.get('version')}")
ck('v340 css loaded after v330','v340-professional-composition.css' in idx and idx.index('v340-professional-composition.css')>idx.index('v330-visual-hierarchy-refactor.css'))
ck('v340 js loaded after v320','v340-professional-composition.js' in idx and idx.index('v340-professional-composition.js')>idx.index('v320-audit-control-ui-correction.js'))
ck('no new DS component family declared','data-ds-component="Theme7' not in js and 'Product Count Card' not in js and 'Inventory Product Block' not in js)
ck('BJ08 variance moved into facts','["Chênh lệch",variance]' in js and 'badge:variance' not in js)
ck('BJ08 generic count badge removed from v340 group','Cần đếm' not in js)
ck('BJ07 one-boundary product group rule present','io07-grouped-collection :is(.io07-product-group,.io07-review-product)' in css and 'border-left:1px' not in css)
ck('chip wrap rule present','flex-wrap:wrap' in css and 'overflow:visible' in css)
errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1500,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(inline(ROOT),wait_until='load',timeout=30000)
    states=p.evaluate('''()=>{
      let out=[];
      for(const f of flowCatalog){
        for(const sid of f.screens){
          const sc=screens.find(x=>x.id===sid);
          for(const st of (sc?.states||['READY'])){
            let err='';
            try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render()}catch(e){err=String(e)}
            const root=document.querySelector('#app-screen'),ct=root?.querySelector('.content');
            const chips=[...root.querySelectorAll('.ds24-chip-scroll .ds24-chip,.io07-chip-scroll .ds24-chip')].map(e=>{const r=e.getBoundingClientRect(),pr=e.parentElement.getBoundingClientRect();return {l:r.left,r:r.right,pl:pr.left,pr:pr.right}});
            out.push({u:f.id,s:sid,st,err,w:root?.offsetWidth,h:root?.offsetHeight,x:(root?.scrollWidth||0)-(root?.clientWidth||0),cx:ct?(ct.scrollWidth-ct.clientWidth):0,text:(root?.innerText||'').trim(),chips});
          }
        }
      }
      return out;
    }''')
    bad=[x for x in states if x['err'] or x['w']!=402 or x['h']!=874 or x['x']>.75 or x['cx']>.75 or not x['text']]
    ck('full cumulative harness 497 states render cleanly',len(states)==497 and not bad,f"states={len(states)} bad={bad[:2]}")
    ac=[x for x in states if x['u'] in SCOPE_AC]; acbad=[x for x in ac if x['err'] or x['x']>.75 or x['cx']>.75]
    ck('audit/control 269 states render cleanly',len(ac)==269 and not acbad,f"states={len(ac)} bad={acbad[:2]}")
    clipped=[]
    for x in states:
        for c in x['chips']:
            if c['l'] < c['pl']-.75 or c['r'] > c['pr']+.75: clipped.append((x['u'],x['s'],x['st'],c))
    ck('all rendered canonical chips stay whole',not clipped,clipped[:3])
    ck('no browser errors',not errors,errors[:3])
    def show(u,s,st='READY'):
        p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render()}',{'u':u,'s':s,'st':st})
    show('UIF-08','SCR-044','BLIND_COUNT')
    ck('BJ08 count uses one boundary per product',p.locator('.ac310-product-control-group').count()>=2 and p.locator('.ac310-product-control-list').evaluate('e=>getComputedStyle(e).borderTopWidth')=='0px')
    ck('BJ08 count rows do not repeat Cần đếm','Cần đếm' not in p.locator('#app-screen').inner_text())
    show('UIF-08','SCR-045','RECOUNT_REQUIRED')
    ck('BJ08 recount presents three aligned facts per product',p.locator('.ac340-recount-facts [data-ds-component="DS v2 / Key-value Row"]').count()>=6)
    ck('BJ08 recount variance is not a badge',p.locator('.ac310-product-control-group .ds24-badge').count()==0)
    show('UIF-08','SCR-046','READY')
    ck('BJ08 approval uses grouped product review units',p.locator('.ac340-review-group').count()==2)
    show('UIF-07','SCR-037','READY')
    ck('BJ07 collection boundary removed',p.locator('.io07-grouped-collection').evaluate('e=>getComputedStyle(e).borderTopWidth')=='0px')
    pg=p.locator('.io07-product-group').evaluate_all('els=>els.map(e=>({b:getComputedStyle(e).borderTopWidth,r:getComputedStyle(e).borderRadius}))')
    ck('BJ07 each product group owns one boundary',len(pg)>=3 and all(x['b']=='1px' and x['r']!='0px' for x in pg),pg)
    child=p.locator('.io07-allocation-list > .ds24-list-row').evaluate_all('els=>els.map(e=>({r:getComputedStyle(e).borderRadius,b:getComputedStyle(e).borderLeftWidth}))')
    ck('BJ07 LOT children remain flat',bool(child) and all(x['r']=='0px' and x['b']=='0px' for x in child),child[:4])
    show('UIF-09','SCR-036','READY')
    chips=p.locator('.ds24-chip-scroll .ds24-chip')
    rects=chips.evaluate_all('els=>els.map(e=>{const r=e.getBoundingClientRect(),p=e.parentElement.getBoundingClientRect();return {l:r.left,r:r.right,pl:p.left,pr:p.right,t:e.textContent}})')
    ck('six status chips visible without clipping',len(rects)==6 and all(x['l']>=x['pl']-.75 and x['r']<=x['pr']+.75 for x in rects),rects)
    b.close()
passed=sum(1 for _,ok,_ in checks if ok)
out={'passed':passed,'total':len(checks),'checks':[{'name':n,'pass':ok,'note':note} for n,ok,note in checks]}
Path(__file__).with_name('PROFESSIONAL-COMPOSITION-QA-v3.4.0.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
print(('PASS' if passed==len(checks) else 'FAIL'),passed,'/',len(checks))
for n,ok,note in checks:
    if not ok: print('FAIL',n,'::',note)
sys.exit(0 if passed==len(checks) else 1)
