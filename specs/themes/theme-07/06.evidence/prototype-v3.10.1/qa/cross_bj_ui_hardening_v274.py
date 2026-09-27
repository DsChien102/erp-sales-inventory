from pathlib import Path
from playwright.sync_api import sync_playwright
import json, re

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v274-cross-bj-captures'; CAP.mkdir(exist_ok=True)
MIGRATED={
 'UIF-01':['SCR-001','SCR-003'],
 'UIF-02':['SCR-006','SCR-007','SCR-008','SCR-009','SCR-084','SCR-010','SCR-011','SCR-012','SCR-013'],
 'UIF-04':['SCR-021'],
 'UIF-05':['SCR-025','SCR-026','SCR-027','SCR-028','SCR-029'],
 'UIF-08':['SCR-042','SCR-043','SCR-044','SCR-045','SCR-046','SCR-047'],
}
checks=[]; errors=[]
def ck(name,ok,detail=''): checks.append({'name':name,'pass':bool(ok),'detail':detail})

def build():
    idx=(ROOT/'index.html').read_text()
    # QA is deterministic/offline: browser uses locally installed fonts and all CSS is inlined.
    for line in list(idx.splitlines()):
        if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
            idx=idx.replace(line+'\n','').replace(line,'')
    css=[]
    for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
        path=ROOT/fn
        if path.exists():
            css.append(path.read_text())
            idx=idx.replace(f'<link rel="stylesheet" href="{fn}" />','')
    idx=idx.replace('</head>','<style>'+"\n".join(css)+'</style></head>')
    for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
        idx=idx.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text()}</script>')
    return idx

APP=(ROOT/'app.js').read_text(); CSS=(ROOT/'v273-ui-hardening.css').read_text()+'\n'+(ROOT/'v274-figma-ds-hard-gate.css').read_text()
ck('v2.7.4 hardening CSS uses semantic tokens only', not re.search(r'#[0-9a-fA-F]{3,8}\b|rgba?\(',CSS))
ck('Summary Card is no longer claimed for BJ01/BJ05 product identity', 'data-ds-role="inventory-product-summary" data-ds-component="DS v2 / Summary Card"' not in APP and 'data-ds-role="picking-product-summary" data-ds-component="DS v2 / Summary Card"' not in APP)
ck('List Row Disabled state is implemented centrally', 'data-ds-prop-state="${effectiveState}"' in APP and 'aria-disabled="true"' in APP)
ck('BJ05 queue waiting state stays Navigation rather than changing type', "type:'Navigation',state:rowDisabled?'Disabled':'Default'" in APP)

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(build(),wait_until='load',timeout=30000)

    def render(uif,sid,state='READY',setup=''):
        p.evaluate(f"()=>{{activeFlowId='{uif}';{setup}activeScreenId='{sid}';stateByScreen['{sid}']='{state}';render();}}")
    def geom(loc):
        return loc.evaluate("e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {x:r.x,y:r.y,w:r.width,h:r.height,right:r.right,bottom:r.bottom,opacity:s.opacity,overflow:s.overflow,overflowX:s.overflowX,overflowY:s.overflowY}}")
    def root_ok():
        return p.locator('#app-screen .v-page-scaffold').evaluate("e=>({w:e.getBoundingClientRect().width,h:e.getBoundingClientRect().height,sw:e.scrollWidth,cw:e.clientWidth})")
    def clipped_text():
        return p.locator('#app-screen .v-page-scaffold').evaluate("""root=>{
          const visible=e=>{const s=getComputedStyle(e),r=e.getBoundingClientRect();return s.display!=='none'&&s.visibility!=='hidden'&&r.width>0&&r.height>0};
          const inScroller=e=>{let a=e.parentElement;while(a&&a!==root){const s=getComputedStyle(a);if((s.overflowX==='auto'||s.overflowX==='scroll')&&a.scrollWidth>a.clientWidth+1)return true;a=a.parentElement;}return false};
          return [...root.querySelectorAll('p,span,strong,small,h1,h2,h3,label')].filter(visible).filter(e=>!inScroller(e)).map(e=>{const s=getComputedStyle(e);return {t:(e.textContent||'').trim().slice(0,80),sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight,ov:s.overflow,ws:s.whiteSpace}}).filter(x=>(x.sw>x.cw+1||x.sh>x.ch+1)&&(x.ov==='hidden'||x.ov==='clip'));
        }""")

    # Full review of all structurally migrated BJ screens at their canonical render state.
    render_results=[]
    state_override={('UIF-08','SCR-044'):'BLIND_COUNT',('UIF-08','SCR-045'):'RECOUNT_REQUIRED',('UIF-08','SCR-046'):'APPROVAL_REQUIRED'}
    setup_override={('UIF-05','SCR-026'):"io05SelectedOrderId='SO-260827-21';",('UIF-05','SCR-027'):"io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';",('UIF-05','SCR-028'):"io05SelectedOrderId='SO-260827-21';io05ResetHandover();",('UIF-05','SCR-029'):"io05SelectedOrderId='SO-260827-21';"}
    for uif,sids in MIGRATED.items():
        for sid in sids:
            st=state_override.get((uif,sid),'READY'); setup=setup_override.get((uif,sid),'')
            render(uif,sid,st,setup)
            r=root_ok(); clips=clipped_text()
            render_results.append({'uif':uif,'screen':sid,'state':st,'root':r,'clips':clips})
    ck('All 23 migrated BJ screens render at exact 402x874',len(render_results)==23 and all(abs(x['root']['w']-402)<.5 and abs(x['root']['h']-874)<.5 for x in render_results),render_results)
    ck('All 23 migrated BJ screens have no root horizontal overflow',all(x['root']['sw']<=x['root']['cw']+1 for x in render_results),[x for x in render_results if x['root']['sw']>x['root']['cw']+1])
    ck('No visible clipped text in migrated canonical renders outside intentional horizontal scrollers',all(not x['clips'] for x in render_results),[{'uif':x['uif'],'screen':x['screen'],'clips':x['clips']} for x in render_results if x['clips']])

    # BJ05 queue collection: same variant/anatomy; availability is State.
    render('UIF-05','SCR-025','READY')
    rows=p.locator('[data-io05-order]')
    q=[rows.nth(i).evaluate("e=>{const r=e.getBoundingClientRect();return {type:e.dataset.dsPropType,state:e.dataset.dsPropState,density:e.dataset.dsPropDensity,w:r.width,h:r.height,tag:e.tagName,disabled:e.disabled===true,aria:e.getAttribute('aria-disabled'),chev:!!e.querySelector('[data-ds-icon=\"VIcons.chevronRight\"]')}}") for i in range(rows.count())]
    ck('SCR-025 peer order rows all remain Navigation/Default-density 370x76 with chevron',len(q)>=2 and all(x['type']=='Navigation' and x['density']=='Default' and abs(x['w']-370)<.5 and abs(x['h']-76)<.5 and x['chev'] for x in q),q)
    waiting=[x for x in q if x['state']=='Disabled']
    ck('SCR-025 waiting order uses true Disabled Navigation state',len(waiting)==1 and waiting[0]['tag']=='BUTTON' and waiting[0]['disabled'] and waiting[0]['aria']=='true',q)
    active=[x for x in q if x['state']=='Default']
    ck('SCR-025 actionable order stays enabled Navigation peer',len(active)>=1 and all(not x['disabled'] for x in active),q)
    p.locator('#app-screen').screenshot(path=str(CAP/'SCR025-QUEUE-CONSISTENT.png'))

    # BJ05 order detail waiting scenario: same list family, all disabled instead of changing row type.
    render('UIF-05','SCR-026','SHORTAGE',"io05SelectedOrderId='SO-260827-24';")
    lr=p.locator('[data-io05-line]')
    vals=[lr.nth(i).evaluate("e=>{const r=e.getBoundingClientRect();return {type:e.dataset.dsPropType,state:e.dataset.dsPropState,density:e.dataset.dsPropDensity,w:r.width,h:r.height,disabled:e.disabled===true,chev:!!e.querySelector('[data-ds-icon=\"VIcons.chevronRight\"]')}}") for i in range(lr.count())]
    ck('SCR-026 waiting collection remains same Navigation/Default geometry and chevrons',len(vals)>0 and all(x['type']=='Navigation' and x['state']=='Disabled' and x['density']=='Default' and abs(x['w']-370)<.5 and abs(x['h']-76)<.5 and x['disabled'] and x['chev'] for x in vals),vals)

    # BJ01 product detail: Compact context row + grouped supporting facts, no blank fixed Summary Card.
    render('UIF-01','SCR-003','READY',"bj01SelectedProductId='P-001';")
    ctx=p.locator('[data-ds-role="inventory-product-summary"]'); cg=geom(ctx)
    ck('BJ01 identity uses canonical Status/Compact List Row 370x52',ctx.count()==1 and ctx.get_attribute('data-ds-component')=='DS v2 / List Row' and ctx.get_attribute('data-ds-prop-type')=='Status' and ctx.get_attribute('data-ds-prop-density')=='Compact' and abs(cg['w']-370)<.5 and abs(cg['h']-52)<.5,cg)
    support=p.locator('.ds24-availability--supporting'); sg=geom(support)
    ck('BJ01 supporting quantities are grouped in content-sized 370px information surface',support.count()==1 and abs(sg['w']-370)<.5 and sg['h']<180,sg)
    ck('BJ01 product detail contains no product Summary Card',p.locator('[data-ds-role="inventory-product-summary"][data-ds-component="DS v2 / Summary Card"]').count()==0)
    p.locator('#app-screen').screenshot(path=str(CAP/'BJ01-SCR003-COMPACT-CONTEXT.png'))

    # BJ02 actual editor state: exercise the real selected-product identity, not an unused helper.
    p.evaluate("()=>{activeFlowId='UIF-02';flowMode='document';resetBj02Receipt('document');beginLineEditor(bj02Lines[0].id);}")
    p.wait_for_timeout(50)
    b2=p.locator('[data-ds-role="receiving-line-product-summary"]'); b2g=geom(b2)
    ck('BJ02 real line editor uses Status/Compact List Row for product context',b2.count()==1 and b2.get_attribute('data-ds-prop-type')=='Status' and b2.get_attribute('data-ds-prop-density')=='Compact' and abs(b2g['w']-370)<.5 and abs(b2g['h']-52)<.5,b2g)
    ck('BJ02 selected-product context has no fixed Summary Card blank space',p.locator('#app-screen [data-ds-component="DS v2 / Summary Card"][data-ds-role*="product"]').count()==0)
    ck('BJ02 line editor has no horizontal overflow',root_ok()['sw']<=root_ok()['cw']+1,root_ok())
    p.locator('#app-screen').screenshot(path=str(CAP/'BJ02-SCR084-PRODUCT-CONTEXT.png'))

    # BJ02 record-card width regression detected in v2.7.2 review.
    render('UIF-02','SCR-009','READY')
    cards=p.locator('.bj02-record-card')
    overflow_cards=[]
    for i in range(cards.count()):
        d=cards.nth(i).evaluate("e=>({sw:e.scrollWidth,cw:e.clientWidth,inner:[...e.querySelectorAll('.bj02-record-support')].map(x=>({sw:x.scrollWidth,cw:x.clientWidth}))})")
        if d['sw']>d['cw']+1 or any(x['sw']>x['cw']+1 for x in d['inner']): overflow_cards.append(d)
    ck('BJ02 receipt record cards no longer have inherited 2px internal overflow',not overflow_cards,overflow_cards)

    # BJ05 product context.
    render('UIF-05','SCR-027','READY',"io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';")
    pctx=p.locator('[data-ds-role="picking-product-summary"]'); pg=geom(pctx)
    ck('BJ05 product identity uses Status/Compact List Row 370x52',pctx.count()==1 and pctx.get_attribute('data-ds-prop-type')=='Status' and pctx.get_attribute('data-ds-prop-density')=='Compact' and abs(pg['w']-370)<.5 and abs(pg['h']-52)<.5,pg)
    ck('BJ05 picking detail no longer uses fixed Summary Card for sparse identity',p.locator('[data-ds-role="picking-product-summary"][data-ds-component="DS v2 / Summary Card"]').count()==0)
    p.locator('#app-screen').screenshot(path=str(CAP/'BJ05-SCR027-COMPACT-CONTEXT.png'))

    # Compact List Row live-Figma geometry everywhere it appears in migrated scope.
    compact=[]
    for uif,sids in MIGRATED.items():
        for sid in sids:
            render(uif,sid,state_override.get((uif,sid),'READY'),setup_override.get((uif,sid),''))
            for x in p.locator('[data-ds-component="DS v2 / List Row"][data-ds-prop-density="Compact"]').evaluate_all("els=>els.map(e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,h:r.height,pad:s.padding,gap:s.gap,radius:s.borderRadius}})"):
                compact.append({'uif':uif,'screen':sid,**x})
    ck('Every rendered Compact List Row in migrated scope matches live Figma 370x52/p4-16/gap8/r8',len(compact)>0 and all(abs(x['w']-370)<.5 and abs(x['h']-52)<.5 and x['pad']=='4px 16px' and x['gap']=='8px' and x['radius']=='8px' for x in compact),compact)

    # Scroll/safe-area check on the longest BJ05 review screen.
    render('UIF-05','SCR-028','PARTIAL_ALLOWED',"io05SelectedOrderId='SO-260827-21';io05ResetHandover();")
    content=p.locator('.app-content'); footer=p.locator('.app-actions')
    if content.count() and footer.count():
        p.eval_on_selector('.app-content','e=>e.scrollTop=e.scrollHeight')
        last=p.locator('.app-content > *').last
        lg=geom(last); fg=geom(footer)
        ck('SCR-028 last content remains reachable above sticky footer at max scroll',lg['bottom']<=fg['y']+1,{'last':lg,'footer':fg})
    else:
        ck('SCR-028 last content remains reachable above sticky footer at max scroll',False,'missing content/footer')

    # Disabled opacity from DS parent state.
    render('UIF-05','SCR-025','READY')
    dis=p.locator('[data-io05-order][data-ds-prop-state="Disabled"]'); dg=geom(dis)
    ck('Disabled Navigation uses DS parent opacity 0.4 without anatomy change',dis.count()==1 and abs(float(dg['opacity'])-.4)<.01,dg)

    b.close()

ck('No browser page errors during cross-BJ review',not errors,errors)
passed=sum(x['pass'] for x in checks); total=len(checks); status='PASS' if passed==total else 'FAIL'
out={'release':'2.7.3','status':status,'passed':passed,'total':total,'migratedScreensReviewed':23,'checks':checks,'browserErrors':errors}
(OUT/'CROSS-BJ-UI-HARDENING-QA-v2.7.4.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
lines=['# Cross-BJ UI Hardening QA — v2.7.4','',f'**Result: {status} · {passed}/{total} checks**','', 'Scope: all structurally migrated Product UIFs `UIF-01 / UIF-02 / UIF-04 / UIF-05 / UIF-08` (23 canonical screens), plus explicit loaded/disabled/detail scenarios.','', 'Live Figma references used before implementation: `DS v2 / List Row` 525:519; `DS v2 / Summary Card` 525:552; `DS v2 / Entity Card` 525:539; Theme 1 Product detail composition references.','', '## Checks','']
for x in checks:
    lines.append(f'- [{"x" if x["pass"] else " "}] {x["name"]}'+(f' — {x["detail"]}' if (not x['pass'] and x['detail']) else ''))
(OUT/'CROSS-BJ-UI-HARDENING-QA-v2.7.4.md').write_text('\n'.join(lines)+'\n')
print(status,passed,total)
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['detail'])
    raise SystemExit(1)
