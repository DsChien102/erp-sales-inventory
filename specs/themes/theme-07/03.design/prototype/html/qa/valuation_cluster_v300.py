from pathlib import Path
from playwright.sync_api import sync_playwright
import re, json, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
BASE=Path('/mnt/data/v294/VET45-Theme7-Prototype-Harness-v2.9.4/specs/themes/theme-07/prototype/html')
checks=[]; errors=[]; routes=[]
def ck(name, cond, note=''):
    checks.append({'name':name,'pass':bool(cond),'note':note})
idx=(ROOT/'index.html').read_text(encoding='utf8')
app=(ROOT/'app.js').read_text(encoding='utf8')
css=(ROOT/'v300-valuation-cluster.css').read_text(encoding='utf8')
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf8'))
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))

# Release/static gates
ck('Workbench package version is v3.0.0', wb.get('version')=='3.0.0', wb.get('version'))
ck('HTML manifest version/parent correct', manifest.get('version')=='3.0.0' and manifest.get('parent')=='2.9.4', f"{manifest.get('version')} <- {manifest.get('parent')}")
ck('v3.0.0 correction layer loaded after v2.9.4', 'v294-product-lot-hierarchy.css' in idx and 'v300-valuation-cluster.css' in idx and idx.index('v300-valuation-cluster.css')>idx.index('v294-product-lot-hierarchy.css'))
ck('Inspector labels all three valuation UIFs as v3.0.0', all(f'"{u}":"v3.0.0' in app for u in ['UIF-03','UIF-13','UIF-14']))
ck('No custom two-option segmented control in BJ14 renderer', 'VSegmentedButton' not in app[app.index('function val14KindChoices'):app.index('function val14CreateRun')])
ck('BJ14 run-kind uses canonical VRadio node', app.count('data-ds-component="VRadio" data-figma-node="522:7410"')>=1)
ck('BJ03 evidence uses canonical VBottomSheet node', 'data-ds-component="VBottomSheet" data-figma-node="4695:6353"' in app)
ck('Valuation CSS explicitly scopes all three UIFs', all(u in css for u in ['UIF-03','UIF-13','UIF-14']))
ck('No new valuation core component family introduced', 'data-ds-component="VValuation' not in app and 'VValuation' not in css)

# Business handlers should stay byte-for-byte unchanged from v2.9.4.
def handler_block(text,uif):
    start=text.find(f'document.addEventListener("click",(event)=>{{if(activeFlowId!=="{uif}")return;')
    if start<0: return ''
    end=text.find('\n',start)
    return text[start:end]
if BASE.exists():
    old=(BASE/'app.js').read_text(encoding='utf8')
    for u in ['UIF-03','UIF-13','UIF-14']:
        a=handler_block(app,u); b=handler_block(old,u)
        ck(f'{u} click/commit handler unchanged from v2.9.4', bool(a) and a==b, hashlib.sha256(a.encode()).hexdigest()[:12] if a else 'missing')
else:
    ck('v2.9.4 baseline available for handler regression',False,'baseline missing')

# Compose a fully inlined page so every correction layer participates.
styles=[]
clean_idx=idx
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf8'))
        clean_idx=clean_idx.replace(f'<link rel="stylesheet" href="{fn}" />','')
html=clean_idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf8")}</script>')

active={
 'UIF-03':['SCR-014','SCR-015','SCR-017','SCR-019'],
 'UIF-13':['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089'],
 'UIF-14':['SCR-072','SCR-073','SCR-074','SCR-076','SCR-077']
}
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1600,'height':1000})
    p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    # Render each active screen in a representative READY state.
    for u,sids in active.items():
        for sid in sids:
            pre=''
            if u=='UIF-03': pre='val03SelectedReceiptId="VAL03-R1";'
            if u=='UIF-03' and sid=='SCR-017': pre+='val03ReviewSourceVersion=val03Current().sourceVersion;'
            if u=='UIF-13': pre='val13SelectedTaskId="LC13-001";'
            if u=='UIF-13' and sid in ['SCR-087','SCR-088']: pre+='val13Current().selectedMethod=val13Current().allowedMethods[0].id;'
            if u=='UIF-13' and sid=='SCR-088': pre+='val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();'
            if u=='UIF-14': pre='val14SelectedRunId="COST-0826";'
            if u=='UIF-14' and sid=='SCR-076': pre+='val14PublishReviewVersion=val14Current().inputVersion;'
            p.evaluate(f'''()=>{{activeFlowId={u!r};activeScreenId={sid!r};stateByScreen[{sid!r}]='READY';{pre}render();}}''')
            m=p.locator('#app-screen').evaluate('''e=>{const c=e.querySelector('.app-content'),b=e.querySelector('.body-stack');return {w:e.offsetWidth,h:e.offsetHeight,sw:e.scrollWidth,cw:e.clientWidth,contentSw:c?.scrollWidth||0,contentCw:c?.clientWidth||0,bodySw:b?.scrollWidth||0,bodyCw:b?.clientWidth||0,text:(e.innerText||'').trim().length}}''')
            routes.append({'uif':u,'screen':sid,**m})
    bad=[r for r in routes if r['w']!=402 or r['h']!=874 or r['sw']>r['cw']+1 or r['contentSw']>r['contentCw']+1 or r['text']==0]
    ck('All 14 active valuation screens render 402x874 with no horizontal overflow',len(routes)==14 and not bad,bad[:4])

    # BJ03 product -> scope hierarchy and evidence behavior.
    p.evaluate("()=>{activeFlowId='UIF-03';activeScreenId='SCR-015';stateByScreen['SCR-015']='READY';val03SelectedReceiptId='VAL03-R1';render();}")
    ck('BJ03 has one dominant Product collection',p.locator('.valuation-product-collection').count()==1,p.locator('.valuation-product-collection').count())
    ck('BJ03 Product headers are visually distinct from nested scopes',p.locator('.valuation-product-header').count()>=2 and p.locator('.valuation-child-row').count()>=3)
    ck('BJ03 nested scopes are not peer cards',p.locator('.val03-product-card').count()==0 and p.locator('.valuation-child-row.review-card').count()==0)
    p.click('[data-val03-slice="VAL03-S4"]'); p.click('[data-val03-action="open-evidence-sheet"]'); p.wait_for_timeout(220)
    ck('BJ03 evidence is canonical VBottomSheet',p.locator('.valuation-evidence-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"]').count()==1)
    ck('BJ03 conflicting evidence starts unselected',p.locator('.val03-source-option.is-selected').count()==0)
    ck('BJ03 evidence sheet is fully opaque after entrance animation',p.locator('.valuation-evidence-sheet').evaluate('e=>getComputedStyle(e).opacity')=='1')

    # BJ13 one grouped selection/allocation surface and values, not badges.
    p.evaluate("()=>{activeFlowId='UIF-13';activeScreenId='SCR-087';stateByScreen['SCR-087']='READY';val13SelectedTaskId='LC13-001';val13Current().selectedMethod=val13Current().allowedMethods[0].id;render();}")
    ck('BJ13 allocation is one grouped collection',p.locator('.valuation-allocation-collection').count()==1)
    ck('BJ13 money stays plain value, not VBadge',p.locator('.valuation-allocation-row .valuation-amount').count()>=2 and p.locator('.valuation-allocation-row .ds24-badge').count()==0)
    ck('BJ13 allocation method uses canonical VSelect annotation',p.locator('[data-val13-method][data-ds-component="VSelect"][data-figma-node="522:7291"]').count()==1)

    # BJ14 immutable run UI / locked method / radio setup.
    p.evaluate("()=>{activeFlowId='UIF-14';activeScreenId='SCR-073';stateByScreen['SCR-073']='READY';val14SetupKind='PERIOD_CLOSE';render();}")
    ck('BJ14 run kind renders exactly two VRadio choices',p.locator('[data-val14-kind][data-ds-component="VRadio"]').count()==2)
    ck('BJ14 has no user-selectable costing-method control',p.locator('[data-val14-method]').count()==0)
    p.evaluate("()=>{activeFlowId='UIF-14';activeScreenId='SCR-074';stateByScreen['SCR-074']='READY';val14SelectedRunId='COST-0826';render();}")
    ck('BJ14 method comparison is one grouped surface',p.locator('.valuation-method-collection').count()==1 and p.locator('.val14-method-row').count()==2)
    ck('BJ14 policy method is semantically highlighted',p.locator('.val14-method-row.is-policy .ds24-badge').count()==1 and 'Dùng để công bố theo chính sách' in p.locator('.val14-method-row.is-policy').inner_text())
    # Ensure primary financial value does not break currency to an orphan line.
    wrap=p.locator('.val14-method-values > strong').evaluate_all('els=>els.map(e=>({scroll:e.scrollWidth,client:e.clientWidth,white:getComputedStyle(e).whiteSpace,text:e.innerText}))')
    ck('BJ14 primary method values stay one-line',all(x['white']=='nowrap' and x['scroll']<=x['client']+1 for x in wrap),wrap)
    ck('No browser JS errors',not errors,errors[:5])
    b.close()

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'activeRoutes':routes,'checks':checks,'browserErrors':errors}
(OUT/'VALUATION-CLUSTER-QA-v3.0.0.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
md=['# Inventory Valuation Cluster QA — v3.0.0','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks · {len(routes)} active screens**','', 'Scope: BJ03 + BJ13 + BJ14; Figma DS hierarchy/composition, 402×874 geometry, behavior-handler regression, contextual evidence, late-cost allocation, immutable cost-run publication.','', '## Checks','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f' — {x["note"]}' if x['note'] not in ['',None,[]] else '') for x in checks]
(OUT/'VALUATION-CLUSTER-QA-v3.0.0.md').write_text('\n'.join(md)+'\n',encoding='utf8')
print(status,res['passed'],'/',res['total'],'routes',len(routes),'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
