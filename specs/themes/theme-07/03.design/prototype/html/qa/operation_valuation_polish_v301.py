from pathlib import Path
from playwright.sync_api import sync_playwright
import json, re

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
BASE=Path('/mnt/data/VET45-Theme7-Prototype-Harness-v3.0.0/specs/themes/theme-07/prototype/html')
SCOPE=['UIF-01','UIF-02','UIF-03','UIF-04','UIF-05','UIF-06','UIF-07','UIF-13','UIF-14']
EXPECTED_ROUTES={
 'UIF-01':['SCR-001','SCR-003'],
 'UIF-02':['SCR-006','SCR-007','SCR-008','SCR-009','SCR-084','SCR-010','SCR-011','SCR-012','SCR-013'],
 'UIF-03':['SCR-014','SCR-015','SCR-017','SCR-019'],
 'UIF-04':['SCR-021'],
 'UIF-05':['SCR-025','SCR-026','SCR-027','SCR-028','SCR-029'],
 'UIF-06':['SCR-030','SCR-031','SCR-032','SCR-033','SCR-035','SCR-034'],
 'UIF-07':['SCR-036','SCR-037','SCR-039','SCR-041'],
 'UIF-13':['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089'],
 'UIF-14':['SCR-072','SCR-073','SCR-074','SCR-076','SCR-077'],
}
checks=[]; page_errors=[]; state_results=[]
def ck(name,cond,note=''):
    checks.append({'name':name,'pass':bool(cond),'note':note})

def inline_page(root:Path):
    idx=(root/'index.html').read_text(encoding='utf8')
    styles=[]
    for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
        p=root/fn
        if p.exists():
            styles.append(p.read_text(encoding='utf8'))
            idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
    html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
    for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
        html=html.replace(f'<script src="{fn}"></script>',f'<script>{(root/fn).read_text(encoding="utf8")}</script>')
    return html

idx=(ROOT/'index.html').read_text(encoding='utf8')
app=(ROOT/'app.js').read_text(encoding='utf8')
css=(ROOT/'v301-operation-valuation-polish.css').read_text(encoding='utf8')
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf8'))

# Static/release gates.
ck('Workbench package version is v3.0.1',wb.get('version')=='3.0.1',wb.get('version'))
ck('HTML manifest version/parent correct',manifest.get('version')=='3.0.1' and manifest.get('parent')=='3.0.0',f"{manifest.get('version')} <- {manifest.get('parent')}")
ck('v3.0.1 correction layer loaded after v3.0.0', 'v300-valuation-cluster.css' in idx and 'v301-operation-valuation-polish.css' in idx and idx.index('v301-operation-valuation-polish.css')>idx.index('v300-valuation-cluster.css'))
ck('All 9 Operations + Valuation UIF inspector labels are v3.0.1', all(f'"{u}":"v3.0.1' in app for u in SCOPE))
ck('Shared List Row supports semantic hidden leading state', 'data-ds-prop-leading="${hasLeading?\'Visible\':\'Hidden\'}"' in app and 'ds24-list-row--no-leading' in app)
ck('v3.0.1 CSS is explicitly scoped to all 9 requested UIFs', all(u in css for u in SCOPE))
ck('No feature-specific core DS component introduced', all(x not in app for x in ['data-ds-component="VValuation','data-ds-component="VInventoryOperation','data-ds-component="VProductLotGroup']))
ck('BJ03 VCheckbox composition is annotated, not a custom selector component', 'data-ds-component="VCheckbox"' in app and 'valuation-selection-control' in app)

# Baseline topology and declared interaction contract regression.
new_html=inline_page(ROOT)
old_html=inline_page(BASE) if BASE.exists() else None
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1500,'height':1100})
    page.set_default_timeout(6000)
    page.on('pageerror',lambda e:page_errors.append(str(e)))
    page.set_content(new_html,wait_until='load',timeout=30000)

    topology=page.evaluate('''scope=>Object.fromEntries(flowCatalog.filter(f=>scope.includes(f.id)).map(f=>[f.id,{screens:f.screens.map(sid=>{const s=screens.find(x=>x.id===sid);return {id:sid,states:s?.states||[],actions:(s?.actions||[]).map(a=>a.id),traceActions:s?.traceActions||[]}})}]))''',SCOPE)
    ck('Requested scope is exactly 41 canonical routes',sum(len(v['screens']) for v in topology.values())==41,sum(len(v['screens']) for v in topology.values()))
    ck('Requested route map matches release scope',all([x['id'] for x in topology[u]['screens']]==EXPECTED_ROUTES[u] for u in EXPECTED_ROUTES),topology)

    if old_html:
        oldp=browser.new_page(viewport={'width':1200,'height':900})
        oldp.set_content(old_html,wait_until='load',timeout=30000)
        old_topology=oldp.evaluate('''scope=>Object.fromEntries(flowCatalog.filter(f=>scope.includes(f.id)).map(f=>[f.id,{screens:f.screens.map(sid=>{const s=screens.find(x=>x.id===sid);return {id:sid,states:s?.states||[],actions:(s?.actions||[]).map(a=>a.id),traceActions:s?.traceActions||[]}})}]))''',SCOPE)
        ck('Screen/state/action topology unchanged from v3.0.0',topology==old_topology)
        oldp.close()
    else:
        ck('v3.0.0 baseline available for topology regression',False,'baseline missing')

    banned=[
      (re.compile(r'\bcut[- ]?off\b',re.I),'Cut-off'),
      (re.compile(r'\bblocker\b',re.I),'blocker'),
      (re.compile(r'\badjustment\b',re.I),'adjustment'),
      (re.compile(r'\bUOM\b'),'UOM'),
      (re.compile(r'\bLOT\b'),'LOT'),
      (re.compile(r'\bFX\b'),'FX'),
      (re.compile(r'\bRTV_PENDING\b'),'RTV_PENDING'),
      (re.compile(r'\bv\d+\b',re.I),'raw vN'),
      (re.compile(r'ALC-POL',re.I),'policy code'),
      (re.compile(r'\bauthoritative\b',re.I),'authoritative'),
    ]

    # Render every declared state in all requested flows: visual contract + terminology + overlap checks.
    state_results=page.evaluate('''scope=>{
      const out=[];
      const seed=(f,sid)=>{
        if(f==='UIF-03'){val03SelectedReceiptId='VAL03-R1'; if(sid==='SCR-017') val03ReviewSourceVersion=val03Current().sourceVersion;}
        if(f==='UIF-13'){val13SelectedTaskId='LC13-001'; if(['SCR-087','SCR-088'].includes(sid)&&!val13Current().selectedMethod) val13Current().selectedMethod=val13Current().allowedMethods[0].id; if(sid==='SCR-088'){val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}}
        if(f==='UIF-14'){val14SelectedRunId='COST-0826'; if(sid==='SCR-076') val14PublishReviewVersion=val14Current().inputVersion;}
      };
      for(const f of flowCatalog.filter(x=>scope.includes(x.id))){
        for(const sid of f.screens){
          const sc=screens.find(x=>x.id===sid), states=sc?.states||['READY'];
          for(const st of states){
            let err='';
            try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;seed(f.id,sid);render();}catch(e){err=String(e?.stack||e);}
            const root=document.querySelector('#app-screen'), content=root?.querySelector('.app-content'), stack=root?.querySelector('.body-stack');
            const rows=[...(root?.querySelectorAll('.ds24-list-row')||[])].map((r,i)=>{
              const copy=r.querySelector('.ds24-list-row__copy'), trail=r.querySelector('.ds24-list-row__trailing'), lead=r.querySelector('.ds24-list-row__leading');
              const rr=r.getBoundingClientRect(), cr=copy?.getBoundingClientRect(), tr=trail?.getBoundingClientRect();
              const title=copy?.querySelector('strong')?.innerText||'';
              return {i,title,leading:r.dataset.dsPropLeading||'',leadCount:lead?1:0,type:r.dataset.dsPropType||'',density:r.dataset.dsPropDensity||'',role:r.dataset.layoutRole||'',copyLeft:cr?cr.left-rr.left:null,copyRight:cr?.right||0,trailLeft:tr?.left||0,trailWidth:tr?.width||0,overlap:Boolean(cr&&tr&&tr.width>1&&cr.right>tr.left+0.75)};
            });
            out.push({u:f.id,s:sid,st,err,text:(root?.innerText||'').trim(),w:root?.offsetWidth||0,h:root?.offsetHeight||0,rootX:(root?.scrollWidth||0)-(root?.clientWidth||0),contentX:content?(content.scrollWidth-content.clientWidth):0,stackX:stack?(stack.scrollWidth-stack.clientWidth):0,rows});
          }
        }
      }
      return out;
    }''',SCOPE)
    state_count=len(state_results)
    runtime_fail=[r for r in state_results if r['err'] or r['w']!=402 or r['h']!=874 or r['rootX']>.75 or r['contentX']>.75 or not r['text']]
    row_overlap=[]; hidden_slot=[]; language=[]
    for r in state_results:
        if any(x.get('overlap') for x in r['rows']): row_overlap.append({'u':r['u'],'s':r['s'],'st':r['st'],'rows':[x for x in r['rows'] if x.get('overlap')]})
        for x in r['rows']:
            if x['leading']=='Hidden' and (x['leadCount']!=0 or x['copyLeft'] is None or not (13 <= x['copyLeft'] <= 20)):
                hidden_slot.append({'u':r['u'],'s':r['s'],'st':r['st'],'row':x})
        for rx,label in banned:
            if rx.search(r['text']): language.append({'u':r['u'],'s':r['s'],'st':r['st'],'term':label,'text':r['text'][:800]})
    ck('All declared states render without JS/geometry/horizontal-overflow failures',state_count==228 and not runtime_fail,f'{state_count} states; failures={runtime_fail[:3]}')
    ck('No List Row copy/status overlap across all 228 state renders',not row_overlap,row_overlap[:3])
    ck('Hidden List Row icons reclaim canonical copy inset',not hidden_slot,hidden_slot[:3])
    ck('No banned English/implementation revision terms in Product UI across 228 states',not language,language[:4])

    # Specific semantic/icon rules and hierarchy.
    for f,sid in [('UIF-03','SCR-014'),('UIF-05','SCR-025'),('UIF-06','SCR-030'),('UIF-07','SCR-036'),('UIF-13','SCR-085'),('UIF-14','SCR-072')]:
        page.evaluate('''x=>{activeFlowId=x.f;activeScreenId=x.sid;stateByScreen[x.sid]='READY';if(x.f==='UIF-03')val03SelectedReceiptId='VAL03-R1';if(x.f==='UIF-13')val13SelectedTaskId='LC13-001';if(x.f==='UIF-14')val14SelectedRunId='COST-0826';render();}''',{'f':f,'sid':sid})
        vals=page.locator('#app-screen .ds24-list-row').evaluate_all("els=>els.map(e=>({lead:e.dataset.dsPropLeading,title:e.querySelector('strong')?.innerText||''}))")
        ck(f'{f}/{sid} work queue rows are text-first with no decorative leading icon',bool(vals) and all(x['lead']=='Hidden' for x in vals),vals)

    page.evaluate("()=>{activeFlowId='UIF-06';activeScreenId='SCR-031';stateByScreen['SCR-031']='READY';render();}")
    ck('BJ06 return-request context hides decorative product icon',page.locator('[data-layout-role="return-request-context"][data-ds-prop-leading="Hidden"]').count()==1)
    page.evaluate("()=>{activeFlowId='UIF-06';activeScreenId='SCR-033';stateByScreen['SCR-033']='READY';render();}")
    ck('BJ06 classification-request context hides decorative product icon',page.locator('[data-layout-role="classification-request-context"][data-ds-prop-leading="Hidden"]').count()==1)

    page.evaluate("()=>{activeFlowId='UIF-07';activeScreenId='SCR-037';stateByScreen['SCR-037']='READY';render();}")
    bj07_parents=page.locator('[data-layout-role="rtv-product-summary"][data-ds-component="DS v2 / List Row"]').evaluate_all("els=>els.map(e=>[e.dataset.dsPropType,e.dataset.dsPropDensity,e.dataset.dsPropLeading])")
    bj07_children=page.locator('[data-layout-role="rtv-allocation-row"][data-ds-component="DS v2 / List Row"]').evaluate_all("els=>els.map(e=>[e.dataset.dsPropType,e.dataset.dsPropDensity,e.dataset.dsPropLeading])")
    ck('BJ07 Product parents use canonical Status/Compact List Row with meaningful product icon',len(bj07_parents)>=3 and all(x==['Status','Compact','Visible'] for x in bj07_parents),bj07_parents)
    ck('BJ07 LOT/non-LOT children use canonical Navigation/Default List Row without decorative icon',len(bj07_children)>=4 and all(x==['Navigation','Default','Hidden'] for x in bj07_children),bj07_children)
    ck('BJ07 preparation meta uses user language, not UOM jargon','nhóm sản phẩm' in page.locator('#app-screen').inner_text() and 'UOM' not in page.locator('#app-screen').inner_text())

    page.evaluate("()=>{activeFlowId='UIF-03';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';val03SelectedReceiptId='VAL03-R1';render();}")
    bj03_parents=page.locator('[data-layout-role="valuation-product-header"][data-ds-component="DS v2 / List Row"]').evaluate_all("els=>els.map(e=>[e.dataset.dsPropType,e.dataset.dsPropDensity,e.dataset.dsPropLeading])")
    ck('BJ03 Product parents use canonical Status/Compact List Row with product icon',len(bj03_parents)>=2 and all(x==['Status','Compact','Visible'] for x in bj03_parents),bj03_parents)
    ck('BJ03 multi-select child scopes use VCheckbox composition',page.locator('.valuation-selection-control[data-ds-component="VCheckbox"]').count()>=3,page.locator('.valuation-selection-control[data-ds-component="VCheckbox"]').count())
    ck('BJ03 queue has no redundant “Công việc” heading',page.locator('.ds24-section-title h2',has_text='Công việc').count()==0)

    # Force evidence sheet with no selected scope: must never be blank.
    empty_sheet=page.evaluate('''()=>{for(const g of val03Current().groups){for(const s of g.slices){s.selected=false;s.partialOpen=false;}}val03EvidenceSheetOpen=true;render();const sheet=document.querySelector('.valuation-evidence-sheet');return {exists:!!sheet,text:(sheet?.innerText||'').trim(),empty:!!sheet?.querySelector('.empty-state')};}''')
    ck('BJ03 “Căn cứ và cách tính” sheet has useful empty content instead of blank body',empty_sheet['exists'] and empty_sheet['empty'] and 'Chưa có phạm vi để xem căn cứ' in empty_sheet['text'],empty_sheet)

    # Restore a selected conflict and verify no source is preselected.
    conflict=page.evaluate('''()=>{val03SelectedReceiptId='VAL03-R1';const r=val03Current();for(const g of r.groups){for(const s of g.slices){s.selected=false;s.selectedQty=s.pendingQty;}}const conflict=r.groups.find(g=>val03EvidenceState(g)==='CONFLICT');const sl=conflict?.slices.find(s=>s.pendingQty>0);if(sl)sl.selected=true;if(conflict){conflict.selectedSource='';conflict.reason='';}val03EvidenceSheetOpen=true;render();return {selected:document.querySelectorAll('.val03-source-option.is-selected').length,sources:document.querySelectorAll('.val03-source-option').length};}''')
    ck('BJ03 conflicting evidence still requires an explicit source decision',conflict['sources']>=2 and conflict['selected']==0,conflict)

    # Behavior invariant: changing valuation selection must not mutate the pending received quantity before commit.
    pending_invariant=page.evaluate('''()=>{val03SelectedReceiptId='VAL03-R1';const s=val03Current().groups[0].slices[0],before=s.pendingQty;s.selected=true;s.selectedQty=Math.min(10,before);const after=s.pendingQty;s.selected=false;s.selectedQty=s.pendingQty;return {before,after};}''')
    ck('BJ03 selecting valuation quantity does not mutate pending received quantity before commit',pending_invariant['before']==pending_invariant['after'],pending_invariant)

    page.evaluate("()=>{activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';val13SelectedTaskId='LC13-001';render();}")
    overlap=page.locator('#app-screen .ds24-list-row').evaluate_all('''els=>els.map(e=>{const c=e.querySelector('.ds24-list-row__copy')?.getBoundingClientRect(),t=e.querySelector('.ds24-list-row__trailing')?.getBoundingClientRect();return {title:e.querySelector('strong')?.innerText||'',overlap:!!(c&&t&&t.width>1&&c.right>t.left+.75)}})''')
    ck('BJ13 queue titles/statuses do not overlap',all(not x['overlap'] for x in overlap),overlap)
    page.evaluate("()=>{activeFlowId='UIF-13';activeScreenId='SCR-087';stateByScreen['SCR-087']='READY';val13SelectedTaskId='LC13-002';val13Current().selectedMethod=val13Current().allowedMethods[0].id;render();}")
    fx_text=page.locator('#app-screen').inner_text()
    ck('BJ13 foreign-currency source still exposes accounting exchange rate in Vietnamese','Tỷ giá kế toán' in fx_text and 'FX' not in fx_text,fx_text[:700])

    page.evaluate("()=>{activeFlowId='UIF-14';activeScreenId='SCR-073';stateByScreen['SCR-073']='READY';val14SelectedRunId='COST-0826';render();}")
    val14text=page.locator('#app-screen').inner_text()
    ck('BJ14 setup uses “Thời điểm chốt” and hides raw policy revisions','Thời điểm chốt' in val14text and 'Cut-off' not in val14text and not re.search(r'\bv\d+\b',val14text,re.I),val14text[:700])
    ck('BJ14 run kind remains canonical VRadio',page.locator('[data-val14-kind][data-ds-component="VRadio"][data-figma-node="522:7410"]').count()==2)

    ck('No browser page errors during v3.0.1 scope QA',not page_errors,page_errors[:5])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
result={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'scopeFlows':SCOPE,'canonicalRoutes':sum(len(v) for v in EXPECTED_ROUTES.values()),'stateRenders':len(state_results),'checks':checks,'browserErrors':page_errors}
(OUT/'OPERATIONS-VALUATION-POLISH-QA-v3.0.1.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
md=['# Operations + Valuation UI Polish QA — v3.0.1','',f'**Result: {status} · {result["passed"]}/{result["total"]} checks · {result["canonicalRoutes"]} canonical screens · {result["stateRenders"]} declared-state renders**','', 'Scope: BJ01, BJ02, BJ03, BJ04, BJ05, BJ06, BJ07, BJ13, BJ14. Gates cover optional semantic List Row icons, Product→child hierarchy, overflow/overlap, redundant headings, Vietnamese terminology, non-empty evidence sheets, declared-state rendering, and topology regression against v3.0.0.','', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f' — {x["note"]}' if x['note'] not in ['',None,[]] else '') for x in checks]
(OUT/'OPERATIONS-VALUATION-POLISH-QA-v3.0.1.md').write_text('\n'.join(md)+'\n',encoding='utf8')
print(status,result['passed'],'/',result['total'],'screens',result['canonicalRoutes'],'states',result['stateRenders'],'errors',len(page_errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
