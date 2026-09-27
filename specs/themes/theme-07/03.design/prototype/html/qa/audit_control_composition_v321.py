from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,sys
ROOT=Path(__file__).resolve().parents[1]
BASE=Path('/mnt/data/v321_work/VET45-Theme7-Prototype-Harness-v3.2.0/specs/themes/theme-07/prototype/html')
SCOPE=['UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-15','UIF-16','UIF-17']
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
app=(ROOT/'app.js').read_text()
idx=(ROOT/'index.html').read_text()
css=(ROOT/'v321-ds-composition-correction.css').read_text()
ck('version 3.2.1',m.get('version')=='3.2.1' and m.get('parentVersion')=='3.2.0' and w.get('version')=='3.2.1',f"{m.get('version')} <- {m.get('parentVersion')} / {w.get('version')}")
ck('v321 stylesheet loaded last','v321-ds-composition-correction.css' in idx and idx.index('v321-ds-composition-correction.css')>idx.index('v320-audit-control-ui-correction.css'))
ck('legacy count-card helper removed','Theme7StockCountLine' not in app and 'Theme7StockRecountLine' not in app and 'ds24-count-card' not in app)
ck('redundant headings removed','Phiên đang thực hiện' not in app and "ds24SectionTitle('Hàng cần đếm')" not in app and 'ioSectionTitle("Lịch sử")' not in app)
ck('canonical chip wrapper used in audit/control','ac321CanonicalChips' in app and 'ac321-chip-wrap' in css)
ck('BJ07 flattened product-lot hierarchy CSS present','io07-grouped-collection .io07-allocation-list > .ds24-list-row' in css)

errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1500,'height':1100})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(inline(ROOT),wait_until='load',timeout=30000)
    states=p.evaluate('''scope=>{
      let out=[];
      for(const f of flowCatalog.filter(x=>scope.includes(x.id))){
        for(const sid of f.screens){
          const sc=screens.find(x=>x.id===sid);
          for(const st of (sc?.states||['READY'])){
            let err='';
            try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render()}catch(e){err=String(e)}
            const root=document.querySelector('#app-screen'),ct=root?.querySelector('.content');
            out.push({u:f.id,s:sid,st,err,w:root?.offsetWidth,h:root?.offsetHeight,x:(root?.scrollWidth||0)-(root?.clientWidth||0),cx:ct?(ct.scrollWidth-ct.clientWidth):0,text:(root?.innerText||'').trim()});
          }
        }
      }
      return out;
    }''',SCOPE)
    bad=[x for x in states if x['err'] or x['w']!=402 or x['h']!=874 or x['x']>.75 or x['cx']>.75 or not x['text']]
    ck('all 269 audit/control states render without overflow',len(states)==269 and not bad,f"states={len(states)} bad={bad[:2]}")
    ck('no browser errors',not errors,errors[:3])
    # cumulative regression: every declared state across all 17 journeys must still render cleanly.
    all_states=p.evaluate('''()=>{
      let out=[];
      for(const f of flowCatalog){
        for(const sid of f.screens){
          const sc=screens.find(x=>x.id===sid);
          for(const st of (sc?.states||['READY'])){
            let err='';
            try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render()}catch(e){err=String(e)}
            const root=document.querySelector('#app-screen'),ct=root?.querySelector('.content');
            out.push({u:f.id,s:sid,st,err,w:root?.offsetWidth,h:root?.offsetHeight,x:(root?.scrollWidth||0)-(root?.clientWidth||0),cx:ct?(ct.scrollWidth-ct.clientWidth):0,text:(root?.innerText||'').trim()});
          }
        }
      }
      return out;
    }''')
    all_bad=[x for x in all_states if x['err'] or x['w']!=402 or x['h']!=874 or x['x']>.75 or x['cx']>.75 or not x['text']]
    ck('full cumulative harness 497 states render cleanly',len(all_states)==497 and not all_bad,f"states={len(all_states)} bad={all_bad[:2]}")
    # topology unchanged from 3.2.0
    topo=p.evaluate('''scope=>Object.fromEntries(flowCatalog.filter(f=>scope.includes(f.id)).map(f=>[f.id,f.screens.map(sid=>{const s=screens.find(x=>x.id===sid);return [sid,s?.states||[],(s?.actions||[]).map(a=>a.id)]})]))''',SCOPE)
    if BASE.exists():
        p2=b.new_page(viewport={'width':1200,'height':900}); p2.set_content(inline(BASE),wait_until='load',timeout=30000)
        old=p2.evaluate('''scope=>Object.fromEntries(flowCatalog.filter(f=>scope.includes(f.id)).map(f=>[f.id,f.screens.map(sid=>{const s=screens.find(x=>x.id===sid);return [sid,s?.states||[],(s?.actions||[]).map(a=>a.id)]})]))''',SCOPE)
        ck('audit/control screen-state-action topology unchanged',topo==old)
        p2.close()
    # BJ08 count visual structure
    def show(u,s,st='READY'):
        p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render()}',{'u':u,'s':s,'st':st})
    show('UIF-08','SCR-044','BLIND_COUNT')
    ck('SCR044 one grouped collection, no per-product cards',p.locator('.ac310-product-control-list').count()==1 and p.locator('.ac310-product-control-group').count()>=2 and p.locator('.ds24-count-card').count()==0)
    ck('SCR044 product context uses canonical List Row',p.locator('.ac310-product-control-group > [data-ds-component="DS v2 / List Row"]').count()>=2)
    show('UIF-08','SCR-045','RECOUNT_REQUIRED')
    ck('SCR045 recount uses canonical facts + quantity field',p.locator('.ac310-control-indent [data-ds-component="DS v2 / Key-value Row"]').count()>=4 and p.locator('.ac310-control-indent .ds24-field').count()>=2)
    # Chip must be fully visible; wrapping is allowed, clipping is not.
    show('UIF-09','SCR-036','READY')
    chips=p.locator('.ds24-chip-scroll .ds24-chip')
    rects=chips.evaluate_all('els=>els.map(e=>{const r=e.getBoundingClientRect(),p=e.parentElement.getBoundingClientRect();return {l:r.left,r:r.right,pl:p.left,pr:p.right,w:r.width,text:e.textContent}})')
    ck('VChip labels are whole and not horizontally clipped',len(rects)==6 and all(x['l']>=x['pl']-.5 and x['r']<=x['pr']+.5 for x in rects),rects)
    # BJ07 preparation hierarchy
    show('UIF-07','SCR-037','READY')
    ck('BJ07 uses one product/lot collection surface',p.locator('.io07-grouped-collection').count()==1)
    child=p.locator('.io07-grouped-collection .io07-allocation-list > .ds24-list-row').evaluate_all('els=>els.map(e=>getComputedStyle(e).borderRadius+"|"+getComputedStyle(e).borderTopWidth)')
    ck('BJ07 lot rows no longer render as peer cards',bool(child) and all(x.startswith('0px|') for x in child),child[:4])
    b.close()

passed=sum(x[1] for x in checks)
print(('PASS' if passed==len(checks) else 'FAIL'),passed,'/',len(checks))
for n,ok,note in checks:
    if not ok: print('FAIL',n,'::',note)
Path(__file__).with_name('AUDIT-CONTROL-COMPOSITION-QA-v3.2.1.json').write_text(json.dumps({'passed':passed,'total':len(checks),'checks':[{'name':n,'pass':ok,'note':note} for n,ok,note in checks]},ensure_ascii=False,indent=2))
sys.exit(0 if passed==len(checks) else 1)
