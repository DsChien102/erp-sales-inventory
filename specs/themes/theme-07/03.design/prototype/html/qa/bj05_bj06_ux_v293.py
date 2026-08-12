from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v293-captures'; CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':900})
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)

    # BJ05 normal multi-LOT overview
    p.evaluate("()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';io05PickEditorOpen=false;io05OverrideOpen=false;activeScreenId='SCR-027';stateByScreen['SCR-027']='READY';render();}")
    rows=p.locator('#app-screen .bj05-pick-lot-list > .ds24-list-row')
    chk('SCR027 renders one canonical Navigation row per LOT',rows.count()==2 and rows.evaluate_all("els=>els.every(e=>e.dataset.dsComponent==='DS v2 / List Row'&&e.dataset.dsPropType==='Navigation'&&e.dataset.dsPropDensity==='Default')"),rows.count())
    chk('SCR027 LOT rows share exact 76px geometry',rows.evaluate_all('els=>els.every(e=>e.offsetHeight===76)'),rows.evaluate_all('els=>els.map(e=>e.offsetHeight)'))
    chk('SCR027 main overview has no inline quantity field',p.locator('#app-screen .bj05-pick-lot-list [data-ds-component="VTextField"]').count()==0)
    chk('SCR027 LOT rows expose required and picked quantity without prose blocks',rows.evaluate_all("els=>els.every(e=>/Cần \\d+/.test(e.innerText)&&/Đã lấy \\d+/.test(e.innerText))"))
    p.locator('#device-preview').screenshot(path=str(CAP/'BJ05-SCR027-COMPACT-LOTS.png'))

    # Open one LOT editor
    rows.first.click();p.wait_for_timeout(50)
    chk('LOT editor uses canonical VBottomSheet',p.locator('#app-screen .bj05-pick-editor-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"]').count()==1)
    chk('LOT editor has canonical 48x4 handle',p.locator('.bj05-pick-editor-sheet .sheet-handle').evaluate('(e)=>[e.offsetWidth,e.offsetHeight]')==[48,4])
    chk('LOT editor has no close X',p.locator('.bj05-pick-editor-sheet [aria-label="Đóng"],.bj05-pick-editor-sheet .sheet-close').count()==0)
    chk('LOT editor exposes one quantity field, not duplicate LOT forms',p.locator('.bj05-pick-editor-sheet [data-ds-component="VTextField"]').count()==1)
    sheet_h=p.locator('.bj05-pick-editor-sheet').evaluate('(e)=>e.offsetHeight')
    chk('LOT editor content-hugs and does not become near-full-screen',sheet_h<500,sheet_h)
    p.locator('#device-preview').screenshot(path=str(CAP/'BJ05-SCR027-LOT-EDITOR.png'))
    p.locator('[data-io05-pick-draft]').fill('3')
    p.locator('[data-io05-action="update-pick-allocation"]').click();p.wait_for_timeout(30)
    chk('Updating one LOT returns to compact overview',p.locator('.bj05-pick-editor-sheet').count()==0 and 'Đã lấy 3' in rows.first.inner_text())

    # Stress many LOTs: overview remains rows rather than stacked editors.
    stress=p.evaluate('''()=>{const line=io05CurrentLine();const base=line.allocations[0];for(let i=0;i<6;i++){line.allocations.push({...base,id:'STRESS-'+i,lot:'ST'+String(i+1).padStart(2,'0'),suggestedLot:'ST'+String(i+1).padStart(2,'0'),qty:2,picked:0,eligibleLots:[]});}renderAppScreen();const rs=[...document.querySelectorAll('.bj05-pick-lot-list > .ds24-list-row')];const content=document.querySelector('.app-content');return {count:rs.length,heights:rs.map(x=>x.offsetHeight),fields:document.querySelectorAll('.bj05-pick-lot-list [data-ds-component="VTextField"]').length,overflow:content.scrollWidth-content.clientWidth,scrollable:content.scrollHeight>content.clientHeight};}''')
    chk('Many-LOT stress remains one 76px row per allocation',stress['count']==8 and all(h==76 for h in stress['heights']),stress)
    chk('Many-LOT stress does not multiply inline fields',stress['fields']==0,stress)
    chk('Many-LOT stress uses natural vertical scroll with no horizontal overflow',stress['scrollable'] and stress['overflow']<=1,stress)

    # BJ06 maker classification direct re-entry and semantic Back.
    p.evaluate("()=>{activeFlowId='UIF-06';io06SelectedRequestId='RET-260827-05';io06ActiveLineId='RET-L4';io06ClassificationOpen=false;activeScreenId='SCR-030';io06QueueFilter='ALL';stateByScreen['SCR-030']='READY';render();}")
    p.locator('[data-io06-request="RET-260827-05"]').click();p.wait_for_timeout(30)
    chk('Cần phân loại enters SCR033 directly',p.evaluate('()=>activeScreenId')=='SCR-033',p.evaluate('()=>activeScreenId'))
    chk('SCR033 uses compact request context instead of three-row metadata block',p.locator('[data-layout-role="classification-request-context"][data-ds-prop-type="Status"][data-ds-prop-density="Compact"]').count()==1 and p.locator('.io06-context .ds24-info-row').count()==0)
    p.locator('#device-preview').screenshot(path=str(CAP/'BJ06-SCR033-COMPACT.png'))
    p.locator('[data-io06-class-line]').first.click();p.wait_for_timeout(30)
    chk('Classification editor is canonical VBottomSheet',p.locator('.io06-classification-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"]').count()==1)
    chk('Classification editor uses one progress row and four fields',p.locator('.io06-classification-sheet [data-io06-class-progress]').count()==1 and p.locator('.io06-classification-sheet [data-ds-component="VTextField"]').count()==4)
    chk('Classification fields avoid repeated helper copy',p.locator('.io06-classification-sheet .io06-field__helper').count()==0)
    class_sheet_h=p.locator('.io06-classification-sheet').evaluate('(e)=>e.offsetHeight')
    chk('Classification sheet remains compact enough for one viewport',class_sheet_h<760,class_sheet_h)
    p.locator('#device-preview').screenshot(path=str(CAP/'BJ06-SCR033-CLASSIFICATION-SHEET.png'))
    p.locator('[data-io06-action="cancel-classification-item"]').click();p.wait_for_timeout(20)
    p.locator('#app-screen [data-back]').click();p.wait_for_timeout(30)
    chk('Back from classification returns maker queue',p.evaluate('()=>activeScreenId')=='SCR-030',p.evaluate('()=>activeScreenId'))
    chk('Back from classification never enters approver SCR034',p.evaluate('()=>activeScreenId')!='SCR-034')

    # Full maker back route 030→031→032→031→030.
    p.locator('[data-io06-request="RET-260827-03"]').click();p.wait_for_timeout(30)
    chk('Receipt request enters SCR031',p.evaluate('()=>activeScreenId')=='SCR-031')
    chk('SCR031 uses compact request context',p.locator('[data-layout-role="return-request-context"][data-ds-prop-type="Status"][data-ds-prop-density="Compact"]').count()==1)
    p.locator('#device-preview').screenshot(path=str(CAP/'BJ06-SCR031-COMPACT.png'))
    p.locator('[data-io06-line]').first.click();p.wait_for_timeout(20)
    chk('Receipt line enters SCR032',p.evaluate('()=>activeScreenId')=='SCR-032')
    p.locator('#app-screen [data-back]').click();p.wait_for_timeout(20)
    chk('Back SCR032 returns owning SCR031',p.evaluate('()=>activeScreenId')=='SCR-031')
    p.locator('#app-screen [data-back]').click();p.wait_for_timeout(20)
    chk('Back SCR031 returns SCR030',p.evaluate('()=>activeScreenId')=='SCR-030')

    # Catalog order separates maker route from actor-handoff approval.
    order=p.evaluate("()=>flowCatalog.find(f=>f.id==='UIF-06').screens")
    chk('UIF06 review catalog keeps maker route before independent approver',order==['SCR-030','SCR-031','SCR-032','SCR-033','SCR-035','SCR-034'],order)

    # CTA audit representative screens.
    cta=p.evaluate('''()=>{const out={};
      io06SelectedRequestId='RET-260827-03';activeScreenId='SCR-031';stateByScreen['SCR-031']='READY';renderAppScreen();out.scr031=[...document.querySelectorAll('#app-screen .app-actions button')].map(x=>x.textContent.trim());
      io06SelectedRequestId='RET-260827-05';io06ClassificationOpen=false;activeScreenId='SCR-033';stateByScreen['SCR-033']='READY';renderAppScreen();out.scr033=[...document.querySelectorAll('#app-screen .app-actions button')].map(x=>x.textContent.trim());
      activeScreenId='SCR-035';stateByScreen['SCR-035']='RECEIVED_PENDING_CLASSIFICATION';io06CurrentRequest().classified=false;renderAppScreen();out.scr035Intermediate=[...document.querySelectorAll('#app-screen button')].map(x=>x.textContent.trim()).filter(Boolean);
      return out;}''')
    chk('SCR031 has at most one footer primary action',len(cta['scr031'])<=1,cta['scr031'])
    chk('SCR033 has one footer completion action',cta['scr033']==['Hoàn tất phân loại'],cta['scr033'])
    chk('SCR035 intermediate retains explicit classify-now and defer choices','Phân loại ngay' in cta['scr035Intermediate'] and 'Để sau' in cta['scr035Intermediate'],cta['scr035Intermediate'])

    # Representative geometry/overflow across BJ06 screens.
    geometry=p.evaluate('''()=>{const out=[];for(const sid of ['SCR-030','SCR-031','SCR-032','SCR-033','SCR-034','SCR-035']){activeFlowId='UIF-06';if(sid==='SCR-031'||sid==='SCR-032')io06SelectedRequestId='RET-260827-03';if(sid==='SCR-032')io06ActiveLineId='RET-L1B';if(sid==='SCR-033'||sid==='SCR-035')io06SelectedRequestId='RET-260827-05';if(sid==='SCR-034')io06ApproverListMode=true;io06ClassificationOpen=false;activeScreenId=sid;stateByScreen[sid]=(sid==='SCR-034'?'TASK_LIST':'READY');renderAppScreen();const app=document.querySelector('#app-screen'),c=app.querySelector('.app-content');out.push({sid,app:[app.offsetWidth,app.offsetHeight],overflow:c?c.scrollWidth-c.clientWidth:0,bodyOverflow:document.querySelector('.body-stack')?document.querySelector('.body-stack').scrollWidth-document.querySelector('.body-stack').clientWidth:0});}return out;}''')
    chk('All BJ06 representative screens stay 402x874 with no app-content horizontal overflow',all(x['app']==[402,874] and x['overflow']<=1  for x in geometry),geometry)
    chk('No browser errors',not errors,errors[:8])
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ05-BJ06-UX-QA-v2.9.3.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'BJ05-BJ06-UX-QA-v2.9.3.md').write_text('\n'.join(['# BJ05 + BJ06 UX QA — v2.9.3','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
raise SystemExit(0 if status=='PASS' else 1)
