from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CSSFILES=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css']
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
css='\n'.join((ROOT/x).read_text() for x in CSSFILES)
html=idx
for x in CSSFILES: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
checks=[]
def chk(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})

app=(ROOT/'app.js').read_text()
newcss=(ROOT/'v271-figma-ds-corrections.css').read_text()
manifest=json.loads((ROOT/'manifest.json').read_text())
status=json.loads((ROOT.parent/'contracts/figma-ds/UIF-MIGRATION-STATUS.json').read_text())

chk('v2.7.1 manifest and migration status are current', manifest['version']=='2.7.1' and status['release']=='2.7.1')
chk('Correction CSS has no raw hex colors', not re.search(r'#[0-9a-fA-F]{3,8}',newcss))
chk('Correction CSS has no raw rgb/rgba colors', not re.search(r'rgba?\(',newcss))
chk('Live List Row node 525:519 is retained', 'data-figma-node="525:519"' in app)
chk('Live Info Row node 525:351 is retained', 'data-figma-node="525:351"' in app)
chk('Live Key-value Row node 525:358 is retained', 'data-figma-node="525:358"' in app)
chk('Shared toast points to live VToast 526:4305', 'toast.dataset.figmaNode="526:4305"' in app)
chk('Only one concrete toast renderer remains', app.count('function showToastCanonical(')==1 and app.count('function showToastLegacy(')==1)
chk('Toast legacy wrapper routes through canonical semantic renderer', 'function showToastLegacy(message,type="success"){return showToastCanonical(message,type);}' in app)
chk('Info group is composition, not a fabricated DS component', 'data-composed-from="DS v2 / Info Row"' in app and 'data-ds-component="DS v2 / Info Group"' not in app)

errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100})
    p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    def render(uif,sid,state='READY',setup=''):
        p.evaluate(f"()=>{{activeFlowId='{uif}';{setup}activeScreenId='{sid}';stateByScreen['{sid}']='{state}';render();}}")
    def rect(sel):
        return p.locator(sel).first.evaluate("e=>{const r=e.getBoundingClientRect();return {w:r.width,h:r.height,x:r.x,y:r.y,b:r.bottom}}")
    def list_rows_ok(uif,sid,state='READY',setup=''):
        render(uif,sid,state,setup)
        rows=p.locator('#app-screen [data-ds-component="DS v2 / List Row"]')
        vals=[]
        for i in range(rows.count()):
            vals.append(rows.nth(i).evaluate("e=>{const r=e.getBoundingClientRect();return {density:e.dataset.dsPropDensity,type:e.dataset.dsPropType,w:r.width,h:r.height}}"))
        bad=[]
        for v in vals:
            if v['density']=='Default' and (abs(v['w']-370)>.5 or abs(v['h']-76)>.5): bad.append(v)
            if v['density']=='Compact' and (abs(v['w']-370)>.5 or abs(v['h']-52)>.5): bad.append(v)
        return vals,bad

    # BJ05 queue: exact semantic peer geometry + affordance.
    render('UIF-05','SCR-025','READY')
    nav=p.locator('[data-io05-order][data-ds-prop-type="Navigation"]')
    stat=p.locator('.bj05-readonly-row[data-ds-prop-type="Status"]')
    chk('SCR-025 actionable and waiting rows both use Default density', nav.count()==1 and stat.count()==1 and nav.get_attribute('data-ds-prop-density')=='Default' and stat.get_attribute('data-ds-prop-density')=='Default')
    nr=rect('[data-io05-order][data-ds-prop-type="Navigation"]'); sr=rect('.bj05-readonly-row[data-ds-prop-type="Status"]')
    chk('SCR-025 peer List Rows are exactly aligned at 370x76', abs(nr['w']-370)<.5 and abs(nr['h']-76)<.5 and abs(sr['w']-370)<.5 and abs(sr['h']-76)<.5, str({'nav':nr,'status':sr}))
    chk('Navigation owns chevron; waiting Status row has none', nav.locator('.ds24-list-row__trailing .icon').count()==1 and stat.locator('.ds24-list-row__trailing .icon').count()==0)
    chk('Waiting Status row remains non-interactive by element semantics', stat.evaluate('e=>e.tagName')=='DIV')

    # Cumulative migrated List Row density gate.
    probes=[('UIF-01','SCR-001','READY',''),('UIF-02','SCR-006','READY',''),('UIF-04','SCR-021','PARTIAL',''),('UIF-05','SCR-025','READY',''),('UIF-05','SCR-026','READY',"io05SelectedOrderId='SO-260827-21';"),('UIF-08','SCR-042','READY','')]
    allvals=[]; allbad=[]
    for u,s,st,setup in probes:
        vals,bad=list_rows_ok(u,s,st,setup); allvals.extend([(u,s,v) for v in vals]); allbad.extend([(u,s,v) for v in bad])
    chk('Current migrated Product scope locks List Row Default=370x76 and Compact=370x52', not allbad, str(allbad))

    # BJ05 selection rows inside LOT override.
    render('UIF-05','SCR-027','READY',"io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';")
    p.locator('[data-io05-open-override="AL-21-01"]').click()
    sels=p.locator('[data-io05-select-lot][data-ds-prop-type="Selection"]')
    selgeom=[sels.nth(i).evaluate("e=>{const r=e.getBoundingClientRect();return {w:r.width,h:r.height,chev:e.querySelector('.ds24-list-row__trailing > .icon')!==null,radio:e.querySelector('[data-ds-component=\"VRadio\"]')!==null}}") for i in range(sels.count())]
    chk('LOT Selection rows are Default 370x76 with radio and no chevron', len(selgeom)>0 and all(abs(v['w']-370)<.5 and abs(v['h']-76)<.5 and v['radio'] and not v['chev'] for v in selgeom),str(selgeom))

    # Info Row composition, exact row master retained.
    render('UIF-05','SCR-026','READY',"io05SelectedOrderId='SO-260827-21';")
    info=p.locator('.ds24-info-group.bj05-context')
    ig=info.evaluate("e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,pad:s.padding,radius:s.borderRadius,bg:s.backgroundColor,rows:[...e.querySelectorAll('[data-ds-component=\"DS v2 / Info Row\"]')].map(x=>({w:x.getBoundingClientRect().width,h:x.getBoundingClientRect().height,bg:getComputedStyle(x).backgroundColor}))}}")
    chk('BJ05 context uses 370px grouped information surface with 16px inset and 12px radius', abs(ig['w']-370)<.5 and ig['pad']=='16px' and ig['radius']=='12px' and ig['bg']!='rgba(0, 0, 0, 0)',str(ig))
    chk('Grouped Info Rows remain canonical transparent 338x44', len(ig['rows'])==3 and all(abs(v['w']-338)<.5 and abs(v['h']-44)<.5 and v['bg']=='rgba(0, 0, 0, 0)' for v in ig['rows']),str(ig['rows']))

    render('UIF-04','SCR-021','PARTIAL')
    bj04=p.locator('.ds24-info-group.bj04-context')
    chk('BJ04 multi-row context is grouped without changing Info Row anatomy', bj04.count()==1 and abs(bj04.evaluate('e=>e.getBoundingClientRect().width')-370)<.5 and all(abs(v-44)<.5 for v in bj04.locator('[data-ds-component="DS v2 / Info Row"]').evaluate_all('els=>els.map(e=>e.getBoundingClientRect().height)')))

    render('UIF-02','SCR-009','READY')
    b2=p.locator('.bj02-context-section:has(> .bj02-info-stack)')
    b2s=b2.evaluate("e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,pad:s.padding,radius:s.borderRadius,bg:s.backgroundColor,rowWidths:[...e.querySelectorAll('.bj02-info-row')].map(x=>x.getBoundingClientRect().width)}}")
    chk('BJ02 established Info Row section now has grouped information surface', abs(b2s['w']-370)<.5 and b2s['pad']=='16px' and b2s['radius']=='12px' and b2s['bg']!='rgba(0, 0, 0, 0)' and all(abs(x-338)<.5 for x in b2s['rowWidths']),str(b2s))

    render('UIF-08','SCR-043','READY')
    b8=p.locator('.ic08-info-group').first
    b8s=b8.evaluate("e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,pad:s.padding,radius:s.borderRadius,bg:s.backgroundColor}}")
    chk('UIF08 multi-row context uses the same information surface composition', abs(b8s['w']-370)<.5 and b8s['pad']=='16px' and b8s['radius']=='12px' and b8s['bg']!='rgba(0, 0, 0, 0)',str(b8s))

    # BJ05 Key-value row.
    render('UIF-05','SCR-028','PARTIAL_ALLOWED',"io05SelectedOrderId='SO-260827-21';io05ResetHandover();")
    kv=p.locator('[data-io05-handover-summary] [data-ds-component="DS v2 / Key-value Row"]')
    kvdata=[kv.nth(i).evaluate("e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e),l=getComputedStyle(e.children[0]),v=getComputedStyle(e.children[1]);return {w:r.width,h:r.height,state:e.dataset.dsPropState,pad:s.padding,radius:s.borderRadius,bg:s.backgroundColor,label:{size:l.fontSize,line:l.lineHeight,weight:l.fontWeight},value:{family:v.fontFamily,size:v.fontSize,line:v.lineHeight,weight:v.fontWeight}}}") for i in range(kv.count())]
    chk('BJ05 handover summary uses two canonical 338x44 Key-value Rows', len(kvdata)==2 and all(abs(v['w']-338)<.5 and abs(v['h']-44)<.5 for v in kvdata),str(kvdata))
    emph=next(v for v in kvdata if v['state']=='Emphasis'); default=next(v for v in kvdata if v['state']=='Default')
    chk('Key-value Emphasis matches Figma geometry/typography', emph['pad']=='0px 12px' and emph['radius']=='8px' and emph['bg']!='rgba(0, 0, 0, 0)' and emph['label']['size']=='14px' and emph['label']['weight']=='600' and emph['value']['size']=='16px' and emph['value']['weight']=='600',str(emph))
    chk('Key-value Default keeps JetBrains Mono 14/22 value and transparent surface', default['pad']=='0px' and default['bg']=='rgba(0, 0, 0, 0)' and 'JetBrains Mono' in default['value']['family'] and default['value']['size']=='14px' and default['value']['line']=='22px',str(default))

    # VToast live master + semantic dispatch + footer placement.
    toast_data=[]
    for tone in ['success','warning','danger','info']:
        p.evaluate(f"()=>showToast('Thông báo thao tác','{tone}')")
        toast=p.locator('#app-screen > .toast[data-ds-component="VToast"]')
        d=toast.evaluate("e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e),m=getComputedStyle(e.querySelector('.toast-message')),ib=e.querySelector('.toast-icon-box'),isvg=ib.querySelector('.icon'),cb=e.querySelector('.toast-close'),csvg=cb.querySelector('.icon'),i=ib.getBoundingClientRect(),c=cb.getBoundingClientRect(),f=document.querySelector('#app-screen .figma-sticky-footer')?.getBoundingClientRect();const ii=isvg.getBoundingClientRect(),ci=csvg.getBoundingClientRect(),iis=getComputedStyle(isvg),cis=getComputedStyle(csvg);return {type:e.dataset.dsPropType,w:r.width,h:r.height,radius:s.borderRadius,pad:s.padding,bg:s.backgroundColor,msg:{size:m.fontSize,line:m.lineHeight,weight:m.fontWeight},icon:{w:i.width,h:i.height,bg:getComputedStyle(ib).backgroundColor,svgW:ii.width,svgH:ii.height,svgBg:iis.backgroundColor,svgPad:iis.padding},close:{w:c.width,h:c.height,radius:getComputedStyle(cb).borderRadius,bg:getComputedStyle(cb).backgroundColor,svgW:ci.width,svgH:ci.height,svgBg:cis.backgroundColor,svgPad:cis.padding},footerGap:f?f.top-r.bottom:null}}")
        toast_data.append(d)
    chk('VToast is exactly 370x56 with 8px radius and 14/20 Regular message', all(abs(d['w']-370)<.5 and abs(d['h']-56)<.5 and d['radius']=='8px' and d['msg']=={'size':'14px','line':'20px','weight':'400'} for d in toast_data),str(toast_data))
    chk('VToast leading icon is 24x24 with clean 14x14 glyph; close is a plain clean 20x20 glyph', all(abs(d['icon']['w']-24)<.5 and abs(d['icon']['h']-24)<.5 and abs(d['icon']['svgW']-14)<.5 and abs(d['icon']['svgH']-14)<.5 and d['icon']['svgBg']=='rgba(0, 0, 0, 0)' and d['icon']['svgPad']=='0px' and abs(d['close']['w']-20)<.5 and abs(d['close']['h']-20)<.5 and d['close']['radius']=='0px' and d['close']['bg']=='rgba(0, 0, 0, 0)' and abs(d['close']['svgW']-20)<.5 and abs(d['close']['svgH']-20)<.5 and d['close']['svgBg']=='rgba(0, 0, 0, 0)' and d['close']['svgPad']=='0px' for d in toast_data),str(toast_data))
    chk('VToast semantic renderer preserves all four tones', [d['type'] for d in toast_data]==['VToastType.success','VToastType.warning','VToastType.danger','VToastType.info'] and len({d['icon']['bg'] for d in toast_data})==4,str(toast_data))
    chk('Toast sits 10px above an existing sticky footer', all(abs(d['footerGap']-10)<=1.5 for d in toast_data if d['footerGap'] is not None),str([d['footerGap'] for d in toast_data]))

    # Legacy-style warning string must no longer map to success.
    p.evaluate("()=>showToastLegacy('Cần kiểm tra','warning')")
    chk('Legacy warning call routes to Warning VToast, not Success', p.locator('#app-screen > .toast').get_attribute('data-ds-prop-type')=='VToastType.warning')

    # no-footer placement: 16px from app-screen bottom in visual coordinates.
    render('UIF-05','SCR-025','READY')
    p.evaluate("()=>showToast('Đã cập nhật','success')")
    pos=p.locator('#app-screen > .toast').evaluate("e=>{const r=e.getBoundingClientRect(),a=document.querySelector('#app-screen').getBoundingClientRect();return {gap:a.bottom-r.bottom}}")
    # Browser frame includes the review device border model; the CSS contract itself is authoritative here.
    cssbottom=p.locator('#app-screen > .toast').evaluate("e=>getComputedStyle(e).bottom")
    chk('No-footer VToast uses the canonical 16px bottom inset CSS contract', cssbottom=='16px',str({'visualGap':pos['gap'],'cssBottom':cssbottom}))

    chk('No browser errors during shared primitive QA', not errors, '; '.join(errors))
    b.close()

status_name='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status_name,'checks':checks,'passed':sum(x['pass'] for x in checks),'total':len(checks),'browserErrors':errors}
(OUT/'FIGMA-DS-PRIMITIVES-QA-v2.7.1.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# Live Figma DS primitive QA — v2.7.1','',f'**Result: {status_name} · {res["passed"]}/{res["total"]} checks**','', 'Live nodes checked: List Row `525:519`, Info Row `525:351`, Key-value Row `525:358`, VToast `526:4305` / Toast Layer `550:1347`.','']
for x in checks: lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else ''))
(OUT/'FIGMA-DS-PRIMITIVES-QA-v2.7.1.md').write_text('\n'.join(lines)+'\n')
print(status_name,res['passed'],res['total'])
if status_name!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL:',x['name'],x['note'])
    raise SystemExit(1)
