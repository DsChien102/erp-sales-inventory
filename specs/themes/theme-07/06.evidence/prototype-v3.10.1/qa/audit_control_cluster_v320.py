from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
BASE=Path('/mnt/data/v320_work/VET45-Theme7-Prototype-Harness-v3.1.0/specs/themes/theme-07/prototype/html')
SCOPE=['UIF-08','UIF-09','UIF-10','UIF-11','UIF-12','UIF-15','UIF-16','UIF-17']
EXPECTED={
 'UIF-08':['SCR-042','SCR-043','SCR-044','SCR-045','SCR-046','SCR-047'],
 'UIF-09':['SCR-036','SCR-037','SCR-038','SCR-041','SCR-056'],
 'UIF-10':['SCR-036','SCR-037','SCR-040','SCR-041'],
 'UIF-11':['SCR-048','SCR-049','SCR-052','SCR-050','SCR-053','SCR-051'],
 'UIF-12':['SCR-066','SCR-067','SCR-068','SCR-069','SCR-070','SCR-071'],
 'UIF-15':['SCR-054','SCR-055','SCR-056','SCR-057','SCR-058','SCR-059'],
 'UIF-16':['SCR-078','SCR-079','SCR-080','SCR-081','SCR-082','SCR-083'],
 'UIF-17':['SCR-078','SCR-079','SCR-080','SCR-082','SCR-083'],
}
checks=[]; page_errors=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})

def inline_page(root:Path):
    idx=(root/'index.html').read_text(encoding='utf8')
    styles=[]
    for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"\s*/?>',idx):
        p=root/fn
        if p.exists(): styles.append(p.read_text(encoding='utf8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
    idx=idx.replace('</head>','<style>\n'+'\n'.join(styles)+'\n</style></head>')
    for fn in re.findall(r'<script src="([^"]+\.js)"></script>',idx):
        p=root/fn
        if p.exists(): idx=idx.replace(f'<script src="{fn}"></script>',f'<script>\n{p.read_text(encoding="utf8")}\n</script>')
    return idx

idx=(ROOT/'index.html').read_text(encoding='utf8')
app=(ROOT/'app.js').read_text(encoding='utf8')
patch=(ROOT/'v310-audit-control-cluster.js').read_text(encoding='utf8')
patch320=(ROOT/'v320-audit-control-ui-correction.js').read_text(encoding='utf8')
css=(ROOT/'v310-audit-control-cluster.css').read_text(encoding='utf8')
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf8'))

# release/static gates
ck('Workbench version is v3.2.0',wb.get('version')=='3.2.0',wb.get('version'))
ck('Manifest version/parent is v3.2.0 <- v3.1.0',manifest.get('version')=='3.2.0' and manifest.get('parentVersion')=='3.1.0',f"{manifest.get('version')} <- {manifest.get('parentVersion')}")
ck('v3.2.0 CSS loads after v3.1.0 cluster', 'v310-audit-control-cluster.css' in idx and 'v320-audit-control-ui-correction.css' in idx and idx.index('v320-audit-control-ui-correction.css')>idx.index('v310-audit-control-cluster.css'))
ck('v3.2.0 JS loads after v3.1.0 cluster','v310-audit-control-cluster.js' in idx and 'v320-audit-control-ui-correction.js' in idx and idx.index('v320-audit-control-ui-correction.js')>idx.index('v310-audit-control-cluster.js'))
ck('All Audit & Control inspector labels identify v3.2.0',all(f'"{u}":"v3.2.0' in app for u in SCOPE))
ck('v3.2.0 patch preserves 8-flow Audit & Control scope',all(u in (css+(ROOT/'v320-audit-control-ui-correction.css').read_text(encoding='utf8')) for u in SCOPE))
ck('Patch uses canonical DS v2 Audit Item', 'data-ds-component="DS v2 / Audit Item"' in patch and 'data-figma-node="525:621"' in patch)
ck('Patch uses canonical VRadio for decision choices','data-ds-component="VRadio"' in patch and 'data-figma-node="522:7410"' in patch)
ck('Patch composes canonical List Row and supports hidden leading icons','ds24ListRow' in patch and 'leading:null' in patch and 'ac310RecordRow' in patch)
ck('No new feature-specific core DS family introduced',not re.search(r'data-ds-component="V(?:AuditControl|InventoryAudit|Reconciliation|Recovery|OpeningBalance)',patch))
ck('No custom two-option segmented control in Audit & Control patch','VSegmentedControl' not in patch and 'segmented' not in patch.lower())

new_html=inline_page(ROOT)
old_html=inline_page(BASE) if BASE.exists() else None
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1500,'height':1100})
    page.set_default_timeout(5000)
    page.on('pageerror',lambda e:page_errors.append(str(e)))
    page.set_content(new_html,wait_until='load',timeout=30000)

    topology=page.evaluate('''scope=>Object.fromEntries(flowCatalog.filter(f=>scope.includes(f.id)).map(f=>[f.id,{screens:f.screens.map(sid=>{const s=screens.find(x=>x.id===sid);return {id:sid,states:s?.states||[],actions:(s?.actions||[]).map(a=>a.id),traceActions:s?.traceActions||[]}})}]))''',SCOPE)
    ck('Audit & Control scope is exactly 44 canonical routes',sum(len(v['screens']) for v in topology.values())==44,sum(len(v['screens']) for v in topology.values()))
    ck('Route map matches all 8 requested BJs',all([x['id'] for x in topology[u]['screens']]==EXPECTED[u] for u in EXPECTED))
    if old_html:
        oldp=browser.new_page(viewport={'width':1200,'height':900})
        oldp.set_content(old_html,wait_until='load',timeout=30000)
        old_topology=oldp.evaluate('''scope=>Object.fromEntries(flowCatalog.filter(f=>scope.includes(f.id)).map(f=>[f.id,{screens:f.screens.map(sid=>{const s=screens.find(x=>x.id===sid);return {id:sid,states:s?.states||[],actions:(s?.actions||[]).map(a=>a.id),traceActions:s?.traceActions||[]}})}]))''',SCOPE)
        ck('Screen/state/action topology unchanged from v3.1.0',topology==old_topology)
        oldp.close()
    else: ck('v3.1.0 baseline available for topology regression',False,'baseline missing')

    banned=[
      (re.compile(r'\bcut[- ]?off\b',re.I),'Cut-off'),(re.compile(r'\bLOT\b'),'LOT'),(re.compile(r'\bUOM\b'),'UOM'),
      (re.compile(r'\bUNKNOWN\b'),'UNKNOWN'),(re.compile(r'\bledger\b',re.I),'ledger'),(re.compile(r'\brecovery\b',re.I),'recovery'),
      (re.compile(r'\bprojection\b',re.I),'projection'),(re.compile(r'\bfinality\b',re.I),'finality'),(re.compile(r'\bauthoritative\b',re.I),'authoritative'),
      (re.compile(r'\bcommit\b',re.I),'commit'),(re.compile(r'\bblocker\b',re.I),'blocker'),(re.compile(r'\bdependency\b',re.I),'dependency'),
      (re.compile(r'\bv\d+\b',re.I),'raw vN'),
    ]

    state_results=page.evaluate('''scope=>{
      const out=[];
      for(const f of flowCatalog.filter(x=>scope.includes(x.id))){
        for(const sid of f.screens){
          const sc=screens.find(x=>x.id===sid), states=sc?.states||['READY'];
          for(const st of states){
            let err='';
            try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render();}catch(e){err=String(e?.stack||e);}
            const root=document.querySelector('#app-screen'), content=root?.querySelector('.app-content'), stack=root?.querySelector('.body-stack');
            const rows=[...(root?.querySelectorAll('.ds24-list-row')||[])].map(r=>{const cr=r.querySelector('.ds24-list-row__copy')?.getBoundingClientRect(),tr=r.querySelector('.ds24-list-row__trailing')?.getBoundingClientRect(),rr=r.getBoundingClientRect();return {leading:r.dataset.dsPropLeading||'',leadCount:r.querySelectorAll('.ds24-list-row__leading').length,copyLeft:cr?cr.left-rr.left:null,copyRight:cr?.right||0,trailLeft:tr?.left||0,trailWidth:tr?.width||0,overlap:Boolean(cr&&tr&&tr.width>1&&cr.right>tr.left+.75)};});
            out.push({u:f.id,s:sid,st,err,text:(root?.innerText||'').trim(),w:root?.offsetWidth||0,h:root?.offsetHeight||0,rootX:(root?.scrollWidth||0)-(root?.clientWidth||0),contentX:content?(content.scrollWidth-content.clientWidth):0,stackX:stack?(stack.scrollWidth-stack.clientWidth):0,rows});
          }
        }
      }
      return out;
    }''',SCOPE)
    runtime_fail=[r for r in state_results if r['err'] or r['w']!=402 or r['h']!=874 or r['rootX']>.75 or r['contentX']>.75 or not r['text']]
    row_overlap=[]; hidden_slot=[]; language=[]
    for r in state_results:
        if any(x['overlap'] for x in r['rows']): row_overlap.append({'u':r['u'],'s':r['s'],'st':r['st']})
        for x in r['rows']:
            if x['leading']=='Hidden' and (x['leadCount']!=0 or x['copyLeft'] is None or not (12 <= x['copyLeft'] <= 20)):
                hidden_slot.append({'u':r['u'],'s':r['s'],'st':r['st'],'row':x})
        for rx,label in banned:
            if rx.search(r['text']): language.append({'u':r['u'],'s':r['s'],'st':r['st'],'term':label,'text':r['text'][:500]})
    ck('All 269 Audit & Control declared-state renders pass geometry/runtime',len(state_results)==269 and not runtime_fail,f"states={len(state_results)} failures={runtime_fail[:3]}")
    ck('No List Row copy/status overlap across all 269 states',not row_overlap,row_overlap[:5])
    ck('Hidden List Row icons reclaim canonical copy inset',not hidden_slot,hidden_slot[:4])
    ck('No banned English/technical/revision terms across all 269 Product UI states',not language,language[:5])

    # DS semantics / visual hierarchy samples
    def show(u,s,st='READY'):
        page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st})
    show('UIF-11','SCR-048')
    leads=page.locator('#app-screen .ds24-list-row').evaluate_all("els=>els.map(e=>e.dataset.dsPropLeading)")
    ck('BJ11 generic work queue is text-first with no decorative icons',bool(leads) and all(x=='Hidden' for x in leads),leads)
    ck('BJ11 has no oversized ad-hoc “Công việc” heading','Công việc' not in page.locator('#app-screen').inner_text())
    show('UIF-16','SCR-078')
    leads=page.locator('#app-screen .ds24-list-row').evaluate_all("els=>els.map(e=>e.dataset.dsPropLeading)")
    ck('BJ16 reconciliation queue is text-first with no decorative icons',bool(leads) and all(x=='Hidden' for x in leads),leads)
    show('UIF-17','SCR-078')
    leads=page.locator('#app-screen .ds24-list-row').evaluate_all("els=>els.map(e=>e.dataset.dsPropLeading)")
    ck('BJ17 verification queue is text-first with no decorative icons',bool(leads) and all(x=='Hidden' for x in leads),leads)
    show('UIF-09','SCR-036')
    pleads=page.locator('#app-screen .ds24-list-row').evaluate_all("els=>els.map(e=>e.dataset.dsPropLeading)")
    ck('BJ09 product rows keep meaningful product icons',bool(pleads) and all(x=='Visible' for x in pleads),pleads)
    show('UIF-10','SCR-036')
    pleads=page.locator('#app-screen .ds24-list-row').evaluate_all("els=>els.map(e=>e.dataset.dsPropLeading)")
    ck('BJ10 disposal product rows keep meaningful product icons',bool(pleads) and all(x=='Visible' for x in pleads),pleads)
    show('UIF-09','SCR-056')
    ck('BJ09 history is rendered with canonical Audit Item',page.locator('[data-ds-component="DS v2 / Audit Item"][data-figma-node="525:621"]').count()>=2)
    show('UIF-09','SCR-038')
    ck('BJ09 state decisions use canonical VRadio',page.locator('[data-ds-component="VRadio"][data-figma-node="522:7410"]').count()>=3)
    show('UIF-11','SCR-052')
    ck('BJ11 correction strategy uses VRadio instead of custom cards',page.locator('[data-ds-component="VRadio"][data-figma-node="522:7410"]').count()>=2)
    show('UIF-15','SCR-054')
    ck('BJ15 report/date choices use VRadio and no segmented control',page.locator('[data-ds-component="VRadio"][data-figma-node="522:7410"]').count()>=4 and page.locator('[data-ds-component="VSegmentedControl"]').count()==0)
    show('UIF-12','SCR-067')
    ck('BJ12 opening balance uses canonical file-drop composition',page.locator('[data-ds-component="VFileDropZone"]').count()>=1)
    show('UIF-12','SCR-068','VALIDATION_FAILED')
    ck('BJ12 validation errors are compact grouped rows, not one card per error',page.locator('.ac310-list-surface .ds24-list-row').count()>=3 and page.locator('.review-card').count()==0)

    # v3.2.0 end-user UI correction gates
    show('UIF-08','SCR-042','READY')
    t=page.locator('#app-screen').inner_text()
    ck('SCR-042 has no redundant list heading above the session collection',page.locator('.ac310-section-title,.ds24-section-title,.io-section-title').count()==0)
    ck('SCR-042 browse list exposes no destructive Hủy phiên CTA','Hủy phiên' not in t and page.locator('[data-ic08-action="cancel-open"]').count()==0)
    ck('SCR-042 remains search + filters + list + primary create action',page.locator('[data-ds-component="VSearchBar"]').count()>=1 and page.locator('.ds24-chip-scroll').count()==1 and page.locator('.ds24-list-row').count()==1 and page.locator('[data-ic08-action="create"]').count()==1)

    show('UIF-08','SCR-044','BLIND_COUNT')
    ck('SCR-044 count metadata uses List Top Bar responsibility instead of a free-standing heading',page.locator('[data-ds-component="DS v2 / List Top Bar"][data-figma-node="547:2223"]').count()==1 and page.locator('.ac310-section-title,.ds24-section-title,.io-section-title').count()==0)

    show('UIF-09','SCR-056','READY')
    ck('BJ09 history does not repeat the AppBar title as an in-content heading',page.locator('.ac310-section-title,.ds24-section-title,.io-section-title').count()==0)
    show('UIF-15','SCR-055','READY')
    ck('BJ15 inventory result list has no redundant Sản phẩm heading',page.locator('.ac310-section-title,.ds24-section-title,.io-section-title').count()==0)
    show('UIF-15','SCR-057','READY')
    ck('BJ15 source detail does not repeat timeline heading under an already-specific AppBar',page.locator('.ac310-section-title,.ds24-section-title,.io-section-title').count()==0)

    # All root browse/list screens must be free of ad-hoc content headings and visible destructive CTAs.
    root_samples=[('UIF-08','SCR-042','READY'),('UIF-09','SCR-036','READY'),('UIF-10','SCR-036','READY'),('UIF-11','SCR-048','READY'),('UIF-16','SCR-078','READY'),('UIF-17','SCR-078','READY')]
    root_issues=[]
    for u,sid,st in root_samples:
        show(u,sid,st)
        heads=page.locator('.ac310-section-title,.ds24-section-title,.io-section-title').count()
        destructive=page.locator('.ac310-danger-text,[data-ds-prop-hierarchy="Danger"],.button--danger,.ds24-button--danger').count()
        if heads or destructive: root_issues.append({'u':u,'s':sid,'headings':heads,'destructive':destructive})
    ck('All Audit & Control root browse lists avoid redundant headings and destructive list CTAs',not root_issues,root_issues)

    # Dense filter rows may scroll, but the container must explicitly preserve full labels and horizontal scrolling.
    chip_issues=[]
    for u,sid,st in [('UIF-08','SCR-042','READY'),('UIF-09','SCR-036','READY'),('UIF-11','SCR-048','READY'),('UIF-16','SCR-078','READY'),('UIF-17','SCR-078','READY')]:
        show(u,sid,st)
        for i in range(page.locator('.ds24-chip-scroll').count()):
            el=page.locator('.ds24-chip-scroll').nth(i)
            info=el.evaluate("e=>({overflow:getComputedStyle(e).overflowX,white:[...e.querySelectorAll('.ds24-chip')].every(x=>getComputedStyle(x).whiteSpace==='nowrap'),labels:[...e.querySelectorAll('.ds24-chip')].map(x=>x.textContent.trim())})")
            if info['overflow'] not in ['auto','scroll'] or not info['white']: chip_issues.append({'u':u,'s':sid,'info':info})
    ck('Dense chip filters are deliberate horizontal scrollers with complete non-wrapping labels',not chip_issues,chip_issues)

    # focused business/actor-boundary smoke (handlers are inherited from v3.0.1)
    def fresh(u,s,st):
        page.goto('about:blank')
        page.set_content(new_html,wait_until='load',timeout=30000)
        page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st})
    fresh('UIF-08','SCR-044','BLIND_COUNT')
    t=page.locator('#app-screen').inner_text(); ck('BJ08 blind count hides book quantity before first submit','Số sổ' not in t and 'Chênh lệch' not in t)
    page.click('[data-ic08-action="submit-first"]'); page.click('[data-ic08-action="confirm-submit-first"]'); ck('BJ08 first count continues to recount',page.evaluate('activeScreenId')=='SCR-045')
    page.click('[data-ic08-action="submit-recount"]'); page.click('[data-ic08-action="confirm-submit-recount"]'); ck('BJ08 maker stops at pending approval',page.evaluate('activeScreenId')=='SCR-042' and page.evaluate('stateByScreen["SCR-042"]')=='PENDING_APPROVAL')
    fresh('UIF-08','SCR-046','APPROVAL_REQUIRED'); ck('BJ08 approver has independent approve/review actions',page.locator('[data-ic08-action="approve"]').count()==1 and page.locator('[data-ic08-action="request-review"]').count()==1)

    fresh('UIF-09','SCR-038','READY'); page.click('[data-ic09-action="submit"]'); ck('BJ09 maker submit does not expose approver action',page.locator('[data-ic09-action="approve"]').count()==0 and 'chờ duyệt' in page.locator('#app-screen').inner_text().lower())
    fresh('UIF-09','SCR-038','APPROVAL_REVIEW'); ck('BJ09 approver has independent approve/reject actions',page.locator('[data-ic09-action="approve"]').count()==1 and page.locator('[data-ic09-action="reject"]').count()==1)

    fresh('UIF-10','SCR-040','APPROVAL_REVIEW'); t=page.locator('#app-screen').inner_text(); ck('BJ10 approval explicitly does not decrement physical stock','Duyệt chưa phải tiêu hủy' in t and 'Tồn vật lý chưa giảm' in t)
    fresh('UIF-10','SCR-040','COMPLETION'); ck('BJ10 physical completion remains a separate destructive action',page.locator('[data-ic10-action="complete"]').count()==1)

    fresh('UIF-11','SCR-048','READY'); page.click('[data-cr11-operation="IO-260901-014"]'); ck('BJ11 correctable work item opens detail',page.evaluate('activeScreenId')=='SCR-049')
    page.click('[data-cr11-action="open-correction"]'); ck('BJ11 correction choice is a separate step',page.evaluate('activeScreenId')=='SCR-052')
    fresh('UIF-11','SCR-049','UNKNOWN'); page.click('[data-cr11-action="handoff-unknown"]'); ck('BJ11 unknown outcome hands off to BJ17 instead of blind correction',page.evaluate('activeFlowId')=='UIF-17' and page.evaluate('activeScreenId')=='SCR-079')

    fresh('UIF-12','SCR-069','READY'); page.click('[data-cf12-action="send-approval"]'); ck('BJ12 maker stops at pending approval status',page.evaluate('activeScreenId')=='SCR-066' and page.evaluate('stateByScreen["SCR-066"]')=='PENDING_APPROVAL')
    fresh('UIF-12','SCR-070','READY'); ck('BJ12 approver has approve/reject without extra commit CTA',page.locator('[data-cf12-action="approve"]').count()==1 and page.locator('[data-cf12-action="open-reject"]').count()==1 and 'Commit' not in page.locator('#app-screen').inner_text())

    fresh('UIF-15','SCR-055','READY'); page.evaluate('()=>{cf15ReportType="STOCK_CARD";cf15Product="P-NOB";cf15SelectedProduct="P-NOB";render();}')
    ck('BJ15 stock card retains traceable movements',page.locator('[data-cf15-movement]').count()>=1)
    page.locator('[data-cf15-movement]').first.click(); ck('BJ15 movement detail exposes source trace action',page.evaluate('activeScreenId')=='SCR-056' and page.locator('[data-cf15-action="source"]').count()==1)

    fresh('UIF-16','SCR-079','PROJECTION_MISMATCH'); ck('BJ16 presentation mismatch proposes display recovery, not stock adjustment','Khôi phục số liệu hiển thị' in page.locator('#app-screen').inner_text() and page.locator('[data-cr16-action="open-plan"]').count()==1)
    fresh('UIF-16','SCR-079','CORRECTION_REQUIRED'); page.click('[data-cr16-action="handoff-correction"]'); ck('BJ16 source correction hands off to BJ11',page.evaluate('activeFlowId')=='UIF-11' and page.evaluate('activeScreenId')=='SCR-049')

    fresh('UIF-17','SCR-079','INSUFFICIENT_EVIDENCE'); ck('BJ17 insufficient evidence preserves unresolved state and blocks execution',page.locator('[data-cr17-action="execute-plan"]').count()==0 and 'Chưa đủ bằng chứng' in page.locator('#app-screen').inner_text())
    fresh('UIF-17','SCR-079','COMMITTED'); ck('BJ17 committed evidence offers finalization path without duplicate stock action',page.locator('[data-cr17-action="open-plan"]').count()==1)

    # full harness runtime regression: all 17 flows / all 497 declared-state renders
    all_results=page.evaluate('''()=>{
      const out=[];
      for(const f of flowCatalog){for(const sid of f.screens){const sc=screens.find(x=>x.id===sid);for(const st of (sc?.states||['READY'])){let err='';try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render();}catch(e){err=String(e?.stack||e);}const root=document.querySelector('#app-screen'),content=root?.querySelector('.app-content');out.push({u:f.id,s:sid,st,err,w:root?.offsetWidth||0,h:root?.offsetHeight||0,x:(root?.scrollWidth||0)-(root?.clientWidth||0),cx:content?(content.scrollWidth-content.clientWidth):0,text:(root?.innerText||'').trim().length});}}}return out;
    }''')
    all_fail=[r for r in all_results if r['err'] or r['w']!=402 or r['h']!=874 or r['x']>.75 or r['cx']>.75 or not r['text']]
    ck('Full 17-BJ harness regression passes all 497 declared-state renders',len(all_results)==497 and not all_fail,f"states={len(all_results)} failures={all_fail[:3]}")

    # canonical 85-screen device-frame gate
    canonical=page.evaluate('''()=>{const out=[];for(const f of flowCatalog){for(const sid of f.screens){const sc=screens.find(x=>x.id===sid);const st=sc?.defaultState||sc?.states?.[0]||'READY';let err='';try{activeFlowId=f.id;activeScreenId=sid;stateByScreen[sid]=st;render();}catch(e){err=String(e);}const r=document.querySelector('#app-screen'),c=r?.querySelector('.app-content');out.push({u:f.id,s:sid,err,w:r?.offsetWidth||0,h:r?.offsetHeight||0,x:(r?.scrollWidth||0)-(r?.clientWidth||0),cx:c?(c.scrollWidth-c.clientWidth):0});}}return out;}''')
    can_fail=[x for x in canonical if x['err'] or x['w']!=402 or x['h']!=874 or x['x']>.75 or x['cx']>.75]
    ck('Canonical device-frame gate passes 85/85 screens at 402×874',len(canonical)==85 and not can_fail,can_fail[:5])
    ck('No browser page errors during v3.2.0 QA',not page_errors,page_errors[:5])
    browser.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
result={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'scopeFlows':SCOPE,'canonicalRoutes':44,'scopeStateRenders':269,'fullHarnessStateRenders':497,'fullHarnessCanonicalScreens':85,'checks':checks,'browserErrors':page_errors}
(OUT/'AUDIT-CONTROL-CLUSTER-QA-v3.2.0.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
md=['# Inventory Audit & Control Cluster QA — v3.2.0','',f'**Result: {status} · {result["passed"]}/{result["total"]} checks**','',f'Scope: BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17 · 44 canonical routes · 269 declared-state renders. Full-harness regression: 85 canonical screens · 497 declared-state renders.','', '## Checks','']
for x in checks: md.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f' — {x["note"]}' if x['note'] not in ['',None,[]] else ''))
(OUT/'AUDIT-CONTROL-CLUSTER-QA-v3.2.0.md').write_text('\n'.join(md)+'\n',encoding='utf8')
print(status,result['passed'],'/',result['total'],'scope states',269,'full states',497,'errors',len(page_errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],'::',x['note'])
    raise SystemExit(1)
