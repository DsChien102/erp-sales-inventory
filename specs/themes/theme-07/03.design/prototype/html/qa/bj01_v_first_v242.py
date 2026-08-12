from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
# QA runs offline: strip remote font/preconnect tags; system Inter is available.
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
for x in cssfiles:
    idx=idx.replace(f'<link rel="stylesheet" href="{x}" />','')
idx=idx.replace('</head>',f'<style>{css}</style></head>')
data=(ROOT/'workbench-data.js').read_text(); fmap=(ROOT/'figma-ds-runtime-map.js').read_text(); app=(ROOT/'app.js').read_text()
html=(idx.replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
         .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
         .replace('<script src="app.js"></script>',f'<script>{app}</script>'))
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def px(v): return round(float(str(v).replace('px','')),2)

# Static contract/source gates for the V-first correction.
chk('No custom Theme7ContextSheet shell remains in BJ01 renderer','Theme7ContextSheet' not in app)
for legacy in ['Theme7InventoryQuickFilters','Theme7InventoryProductList','Theme7InventoryProductIdentity','Theme7InventoryProductRow','Theme7InventoryLotRow','Theme7InventoryProvenanceEntry']:
    chk(f'No redundant {legacy} component identity remains in BJ01 renderer',legacy not in app)
try:
    rm=json.loads((ROOT/'../contracts/figma-ds/html-figma-ds-mapping.json').resolve().read_text())
    vb=rm['componentMappings']['VBottomSheet']
    chk('Runtime/source map resolves VBottomSheet to live Figma node',vb.get('status')=='EXACT' and vb.get('nodeId')=='4695:6353',str(vb))
except Exception as e:
    chk('Runtime/source map resolves VBottomSheet to live Figma node',False,str(e))

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_default_timeout(5000)
    p.set_content(html,wait_until='load',timeout=30000)
    def set_screen(screen,state='READY'):
        p.evaluate('([s,st])=>{activeFlowId="UIF-01";activeScreenId=s;stateByScreen[s]=st;render();}',[screen,state])
    def cs(sel,props):
        return p.eval_on_selector(sel,'(el,ps)=>{const s=getComputedStyle(el);const o={};ps.forEach(k=>o[k]=s[k]);const r=el.getBoundingClientRect();o.__w=r.width;o.__h=r.height;return o}',props)

    set_screen('SCR-001','READY')
    shell=cs('#app-screen .v-page-scaffold',['fontFamily','backgroundColor'])
    chk('BJ01 shell is exact 402x874',abs(shell['__w']-402)<.2 and abs(shell['__h']-874)<.2,str((shell['__w'],shell['__h'])))
    chk('Inter is active','Inter' in shell['fontFamily'],shell['fontFamily'])
    chk('Inter is available to browser',p.evaluate("document.fonts.check('14px Inter')"))
    search=cs('.ds24-search',['height','paddingLeft','paddingRight','columnGap','borderRadius','borderTopWidth'])
    chk('VSearchBar geometry matches live Figma',abs(search['__w']-370)<.2 and abs(search['__h']-44)<.2 and px(search['paddingLeft'])==16 and px(search['columnGap'])==8 and px(search['borderRadius'])==8 and px(search['borderTopWidth'])==1,str(search))
    chip=cs('.ds24-chip',['height','paddingLeft','fontSize','lineHeight','fontWeight'])
    chk('VChip geometry/type matches live Figma',abs(chip['__h']-34)<.2 and px(chip['paddingLeft'])==12 and px(chip['fontSize'])==12 and px(chip['lineHeight'])==16 and chip['fontWeight']=='600',str(chip))
    row=cs('.ds24-list-row',['height','paddingLeft','paddingRight','columnGap','borderRadius','borderTopWidth'])
    chk('List Row geometry matches live Figma',abs(row['__w']-370)<.2 and abs(row['__h']-76)<.2 and px(row['paddingLeft'])==16 and px(row['paddingRight'])==24 and px(row['columnGap'])==12 and px(row['borderRadius'])==12 and px(row['borderTopWidth'])==1,str(row))
    chk('Product rows use DS List Row directly without Theme7 component identity',p.locator('.ds24-list-row[data-bj01-product][data-theme-component]').count()==0)
    chk('Product navigation row keeps canonical trailing anatomy',p.locator('.ds24-list-row__trailing').first.locator('.ds24-badge,.ds24-row-quantity').count()==0)

    set_screen('SCR-003','READY')
    info=cs('.ds24-info-row',['height','columnGap','justifyContent','borderBottomWidth'])
    chk('Info Row uses canonical metadata anatomy',abs(info['__h']-44)<.2 and px(info['columnGap'])==8 and info['justifyContent']=='flex-start' and px(info['borderBottomWidth'])==0,str(info))
    metric=cs('.ds24-metric',['paddingLeft','rowGap','borderRadius','borderTopWidth'])
    chk('Availability remains justified Product composition using DS geometry',abs(metric['__w']-370)<.2 and px(metric['paddingLeft'])==16 and px(metric['rowGap'])==8 and px(metric['borderRadius'])==16 and px(metric['borderTopWidth'])==1,str(metric))
    chk('LOT/provenance navigation rows have no redundant Theme7 component identity',p.locator('[data-bj01-lot][data-theme-component], [data-bj01-provenance][data-theme-component]').count()==0)

    # Stale VBanner regression.
    set_screen('SCR-003','STALE')
    ban=cs('.v-banner',['paddingLeft','columnGap','borderRadius','borderTopWidth'])
    bi=cs('.v-banner-icon',['width','height','borderRadius','backgroundColor']); bic=cs('.v-banner-icon .icon',['width','height'])
    chk('VBanner container remains exact',abs(ban['__w']-370)<.2 and px(ban['paddingLeft'])==16 and px(ban['columnGap'])==12 and px(ban['borderRadius'])==12 and px(ban['borderTopWidth'])==1,str(ban))
    chk('VBanner semantic icon remains direct 20x20',bi['__w']==20 and bi['__h']==20 and px(bi['borderRadius'])==0 and bi['backgroundColor']=='rgba(0, 0, 0, 0)' and bic['__w']==20 and bic['__h']==20,str((bi,bic)))
    back=cs('.app-back-button .icon',['width','height'])
    chk('VAppBar Back icon remains 24x24',back['__w']==24 and back['__h']==24,str(back))

    # VBottomSheet exact live component gate.
    set_screen('SCR-003','READY')
    p.locator('[data-bj01-lot]').first.click()
    chk('LOT overlay is canonical VBottomSheet',p.locator('.ds24-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"]').count()==1)
    sheet=cs('.ds24-sheet',['paddingLeft','paddingRight','paddingTop','paddingBottom','rowGap','borderTopLeftRadius','backgroundColor'])
    chk('VBottomSheet shell matches live Figma geometry',abs(sheet['__w']-402)<.2 and px(sheet['paddingLeft'])==16 and px(sheet['paddingRight'])==16 and px(sheet['paddingTop'])==12 and px(sheet['paddingBottom'])==44 and px(sheet['rowGap'])==12 and px(sheet['borderTopLeftRadius'])==20,str(sheet))
    handle=cs('.ds24-sheet__handle',['width','height','borderRadius'])
    chk('VBottomSheet handle matches 48x4 pill',handle['__w']==48 and handle['__h']==4 and px(handle['borderRadius'])>=2,str(handle))
    title=cs('.ds24-sheet > h3',['width','minHeight','fontSize','lineHeight','fontWeight','letterSpacing'])
    chk('VBottomSheet title matches H3 contract',abs(title['__w']-370)<.2 and px(title['minHeight'])==28 and px(title['fontSize'])==18 and px(title['lineHeight'])==24 and title['fontWeight']=='600',str(title))
    content=cs('.ds24-sheet__body',['width','rowGap'])
    chk('VBottomSheet Product content stays in 370px slot',abs(content['__w']-370)<.2 and px(content['rowGap'])==12,str(content))
    chk('LOT VBottomSheet has no horizontal overflow',p.eval_on_selector('.ds24-sheet','el=>el.scrollWidth<=el.clientWidth+.5'))
    p.locator('[data-bj01-close-lot]').click(position={'x':5,'y':5})
    set_screen('SCR-003','READY'); p.locator('[data-bj01-provenance]').click()
    chk('Provenance opens exactly one canonical VBottomSheet',p.locator('.ds24-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"][role="dialog"]').count()==1)
    p.locator('[data-bj01-close-provenance]').click(position={'x':5,'y':5})

    # Main-state overflow regression.
    states=[('SCR-001','READY'),('SCR-001','EMPTY'),('SCR-001','FILTER_EMPTY'),('SCR-001','STALE'),('SCR-003','READY'),('SCR-003','STALE'),('SCR-003','LOADING'),('SCR-003','PERMISSION_DENIED')]
    ov=[]
    for s,st in states:
        set_screen(s,st)
        d=p.eval_on_selector('#app-screen .v-page-scaffold','el=>({sw:el.scrollWidth,cw:el.clientWidth,sh:el.scrollHeight,ch:el.clientHeight})')
        ov.append((s,st,d))
    chk('BJ01 main states have no horizontal overflow',all(x[2]['sw']<=x[2]['cw']+.5 for x in ov),str(ov))

    cap=OUT/'v242-bj01-captures'; cap.mkdir(exist_ok=True)
    for s,st,name in [('SCR-001','READY','01-list-ready'),('SCR-003','READY','02-detail-ready'),('SCR-003','STALE','03-detail-stale')]:
        set_screen(s,st); p.locator('#app-screen').screenshot(path=str(cap/f'{name}.png'))
    set_screen('SCR-003','READY'); p.locator('[data-bj01-lot]').first.click(); p.locator('#app-screen').screenshot(path=str(cap/'04-lot-vbottomsheet.png'))
    b.close()

chk('No browser page errors',not errors,'; '.join(errors))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ01-V-FIRST-DS-QA-v2.4.2.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ01 V-first Design System QA — v2.4.2','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','',
       'Gate: matching V-component → existing non-V component → existing Pattern/Template → Product composition → new component only after proven gap.','']
for x in checks: lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] and not x['pass'] else ''))
(OUT/'BJ01-V-FIRST-DS-QA-v2.4.2.md').write_text('\n'.join(lines)+'\n')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
if status!='PASS': raise SystemExit(1)
