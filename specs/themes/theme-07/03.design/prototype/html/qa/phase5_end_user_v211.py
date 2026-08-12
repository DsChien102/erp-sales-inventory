from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent

def inline_html(root):
    idx=(root/'index.html').read_text(); css=(root/'tokens.generated.css').read_text()+'\n'+(root/'styles.css').read_text(); data=(root/'workbench-data.js').read_text(); fmap=(root/'figma-ds-runtime-map.js').read_text(); app=(root/'app.js').read_text()
    return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; errors=[]
def ck(name,cond,detail=''): checks.append((name,bool(cond),detail))
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: errors.append(str(e))); p.set_content(inline_html(ROOT),wait_until='load'); p.add_style_tag(content='*{animation:none!important;transition:none!important}')
    def render(f,s,st): p.evaluate('x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'f':f,'s':s,'st':st})
    render('UIF-02','SCR-012','COMPLETED')
    ck('completed receipt result uses Detail template',p.locator('#app-screen .v-page-scaffold').get_attribute('data-figma-template')=='Mobile / Detail')
    ck('completed receipt result has no synthetic VEmptyState',p.locator('#app-screen [data-ds-component="VEmptyState"]').count()==0)
    ck('completed receipt result has composed result hero',p.locator('#app-screen .result-hero[data-composed-from="VIcon,VText"]').count()==1)
    render('UIF-02','SCR-006','PERMISSION_DENIED')
    ck('permission state dynamically uses State template',p.locator('#app-screen .v-page-scaffold').get_attribute('data-figma-template')=='Mobile / State')
    ck('permission state contains canonical VEmptyState',p.locator('#app-screen [data-ds-component="VEmptyState"]').count()==1)
    render('UIF-09','SCR-038','READY')
    info=p.evaluate('''()=>[...document.querySelectorAll('#app-screen [data-ds-component="DS v2 / Info Row"]')].map(e=>({gap:parseFloat(getComputedStyle(e).gap)||0,h:e.getBoundingClientRect().height}))''')
    ck('inventory-condition Info Rows use canonical spacing',bool(info) and all(x['gap']>=7.5 and x['h']>=43.5 for x in info),json.dumps(info,ensure_ascii=False))
    tx=p.evaluate('''()=>{const t=document.querySelector('#app-screen textarea');const o=t?.closest('[data-ds-component]');const r=t?.getBoundingClientRect();return {owner:o?.dataset.dsComponent,h:r?.height,resize:t?getComputedStyle(t).resize:null}}''')
    ck('inventory-condition reason is exact VTextarea',tx.get('owner')=='VTextarea' and tx.get('h',0)>=87.5 and tx.get('resize')=='none',json.dumps(tx,ensure_ascii=False))
    render('UIF-12','SCR-067','READY')
    money=p.evaluate('''()=>{const i=document.querySelector('[data-cf12-control-value]'),o=i?.closest('[data-ds-component]');return {owner:o?.dataset.dsComponent,value:i?.value,suffix:o?.querySelector('.money-suffix')?.textContent?.trim()}}''')
    ck('opening balance value uses VMoneyField',money.get('owner')=='VMoneyField',json.dumps(money,ensure_ascii=False))
    ck('VMoneyField displays formatted VND + suffix',money.get('value')=='386.240.000' and money.get('suffix')=='₫',json.dumps(money,ensure_ascii=False))
    p.locator('[data-cf12-control-value]').fill('400.500.000'); normalized=p.evaluate('()=>cf12ControlValue'); p.evaluate('()=>render()'); rendered=p.locator('[data-cf12-control-value]').input_value()
    ck('VMoneyField display formatting preserves normalized numeric value',normalized=='400500000' and rendered=='400.500.000',f'{normalized}/{rendered}')
    render('UIF-06','SCR-033','READY'); t=p.locator('#app-screen').inner_text().lower()
    ck('classification screen never exposes raw null',all(x not in t for x in ['null','undefined','nan','infinity']))
    render('UIF-06','SCR-035','COMPLETED'); t=p.locator('#app-screen').inner_text().lower()
    ck('direct completed result never exposes raw null',all(x not in t for x in ['null','undefined','nan','infinity']))
    for f,s,st in [('UIF-09','SCR-038','READY'),('UIF-12','SCR-067','READY'),('UIF-06','SCR-035','COMPLETED')]:
        render(f,s,st); ov=p.evaluate('''()=>{const sh=document.querySelector('#app-screen .v-page-scaffold');return sh.scrollWidth-sh.clientWidth}'''); ck(f'{f}/{s} has no horizontal overflow',ov<=0.5,str(ov))
    b.close()
ck('no browser page errors',not errors,str(errors))
passed=sum(ok for _,ok,_ in checks); result='PASS' if passed==len(checks) else 'FAIL'
lines=['# Theme 7 — Phase 5 End-user QA v2.1.1','',f'**{result} {passed}/{len(checks)}**','']+[f'- [{"x" if ok else " "}] {n}'+(f' — {d}' if d else '') for n,ok,d in checks]
(OUT/'PHASE-5-END-USER-QA-v2.1.1.md').write_text('\n'.join(lines)+'\n')
(OUT/'PHASE-5-END-USER-QA-v2.1.1.json').write_text(json.dumps({'result':result,'passed':passed,'checks':len(checks),'details':[{'name':n,'pass':ok,'detail':d} for n,ok,d in checks]},ensure_ascii=False,indent=2)+'\n')
print(result,passed,'/',len(checks))
