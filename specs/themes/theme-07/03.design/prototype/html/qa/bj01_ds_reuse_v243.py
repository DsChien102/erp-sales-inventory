from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
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

chk('Theme7AvailabilitySummary is removed from BJ01 renderer','Theme7AvailabilitySummary' not in app)
chk('BJ01 renderer uses canonical Key-value Row source','data-ds-component="DS v2 / Key-value Row"' in app and 'data-figma-node="525:358"' in app)
try:
    rm=json.loads((ROOT/'../contracts/figma-ds/html-figma-ds-mapping.json').resolve().read_text())
    chk('Global selection priority puts valid V_component first',rm['componentSelectionPriority'][0]=='V_COMPONENT_IF_SEMANTICALLY_VALID',str(rm['componentSelectionPriority']))
    chk('Selection priority requires existing component before new component',rm['componentSelectionPriority'].index('EXISTING_NON_V_COMPONENT') < rm['componentSelectionPriority'].index('NEW_COMPONENT_ONLY_AFTER_PROVEN_REUSABLE_GAP'),str(rm['componentSelectionPriority']))
except Exception as e:
    chk('Global selection priority map is readable',False,str(e))

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_default_timeout(5000); p.set_content(html,wait_until='load',timeout=30000)
    def set_screen(screen,state='READY'):
        p.evaluate('([s,st])=>{activeFlowId="UIF-01";activeScreenId=s;stateByScreen[s]=st;render();}',[screen,state])
    def cs(sel,props):
        return p.eval_on_selector(sel,'(el,ps)=>{const s=getComputedStyle(el);const o={};ps.forEach(k=>o[k]=s[k]);const r=el.getBoundingClientRect();o.__w=r.width;o.__h=r.height;return o}',props)

    set_screen('SCR-003','READY')
    chk('No custom availability component identity is rendered',p.locator('[data-theme-component="Theme7AvailabilitySummary"]').count()==0)
    chk('No legacy custom availability card is rendered',p.locator('.ds24-metric').count()==0)
    kv=p.locator('[data-ds-component="DS v2 / Key-value Row"][data-ds-prop-state="Emphasis"]')
    chk('Exactly one primary Key-value Row is rendered',kv.count()==1 and kv.locator('span').inner_text().strip()=='Khả dụng')
    k=cs('[data-ds-component="DS v2 / Key-value Row"][data-ds-prop-state="Emphasis"]',['height','paddingLeft','paddingRight','borderRadius','backgroundColor','justifyContent'])
    chk('Key-value Row Emphasis anatomy matches live Figma',abs(k['__w']-370)<.2 and abs(k['__h']-44)<.2 and px(k['paddingLeft'])==12 and px(k['paddingRight'])==12 and px(k['borderRadius'])==8 and k['justifyContent']=='space-between',str(k))
    lab=cs('[data-ds-component="DS v2 / Key-value Row"] > span',['fontFamily','fontSize','lineHeight','fontWeight','color'])
    val=cs('[data-ds-component="DS v2 / Key-value Row"] > strong',['fontFamily','fontSize','lineHeight','fontWeight','color'])
    chk('Key-value Emphasis label type matches live Figma', 'Inter' in lab['fontFamily'] and px(lab['fontSize'])==14 and px(lab['lineHeight'])==20 and lab['fontWeight']=='600',str(lab))
    chk('Key-value Emphasis value type matches live Figma', 'Inter' in val['fontFamily'] and px(val['fontSize'])==16 and px(val['lineHeight'])==22 and val['fontWeight']=='600',str(val))
    av=cs('.ds24-availability',['rowGap','paddingLeft','borderTopWidth','backgroundColor'])
    chk('Availability wrapper is layout-only, not a visual component',abs(av['__w']-370)<.2 and px(av['rowGap'])==8 and px(av['paddingLeft'])==0 and px(av['borderTopWidth'])==0 and av['backgroundColor']=='rgba(0, 0, 0, 0)',str(av))
    infos=p.locator('.ds24-availability [data-ds-component="DS v2 / Info Row"]')
    chk('Supporting quantities reuse exactly three canonical Info Rows',infos.count()==3,[infos.nth(i).inner_text() for i in range(infos.count())])
    info=cs('.ds24-availability .ds24-info-row',['height','columnGap','justifyContent','borderBottomWidth'])
    chk('Supporting Info Row anatomy remains canonical',abs(info['__h']-44)<.2 and px(info['columnGap'])==8 and info['justifyContent']=='flex-start' and px(info['borderBottomWidth'])==0,str(info))
    chk('Khả dụng appears once as primary detail outcome',p.locator('.ds24-availability').get_by_text('Khả dụng',exact=True).count()==1)
    chk('SCR-003 creates no Theme7 component identity',p.locator('#app-screen [data-theme-component]').count()==0)

    # Existing V-component priority regression on BJ01 surfaces.
    set_screen('SCR-001','READY')
    chk('Search reuses VSearchBar',p.locator('[data-ds-component="VSearchBar"]').count()==1)
    chk('Quick filters reuse VChip directly',p.locator('[data-bj01-filter][data-ds-component="VChip"]').count()>=5)
    chk('Product rows reuse canonical List Row without Theme wrapper',p.locator('[data-bj01-product][data-ds-component="DS v2 / List Row"][data-theme-component]').count()==0)
    chk('SCR-001 creates no Theme7 component identity',p.locator('#app-screen [data-theme-component]').count()==0)

    # Same no-new-component rule inside LOT VBottomSheet.
    set_screen('SCR-003','READY'); p.locator('[data-bj01-lot]').first.click()
    chk('LOT overlay reuses VBottomSheet',p.locator('.ds24-sheet[data-ds-component="VBottomSheet"][data-figma-node="4695:6353"]').count()==1)
    chk('LOT availability reuses Key-value Row Emphasis',p.locator('.ds24-sheet [data-ds-component="DS v2 / Key-value Row"][data-ds-prop-state="Emphasis"]').count()==1)
    chk('LOT supporting quantities reuse three Info Rows',p.locator('.ds24-sheet .ds24-availability [data-ds-component="DS v2 / Info Row"]').count()==3)
    chk('LOT overlay has no custom availability component',p.locator('.ds24-sheet [data-theme-component="Theme7AvailabilitySummary"], .ds24-sheet .ds24-metric').count()==0)
    chk('LOT VBottomSheet has no horizontal overflow',p.eval_on_selector('.ds24-sheet','el=>el.scrollWidth<=el.clientWidth+.5'))

    # Stale VBanner and main overflow regression.
    p.locator('[data-bj01-close-lot]').click(position={'x':5,'y':5}); set_screen('SCR-003','STALE')
    ban=cs('.v-banner',['paddingLeft','columnGap','borderRadius','borderTopWidth'])
    chk('VBanner fidelity remains intact',abs(ban['__w']-370)<.2 and px(ban['paddingLeft'])==16 and px(ban['columnGap'])==12 and px(ban['borderRadius'])==12 and px(ban['borderTopWidth'])==1,str(ban))
    states=[('SCR-001','READY'),('SCR-001','EMPTY'),('SCR-001','FILTER_EMPTY'),('SCR-001','STALE'),('SCR-003','READY'),('SCR-003','STALE'),('SCR-003','LOADING'),('SCR-003','PERMISSION_DENIED')]
    ov=[]
    for s,st in states:
        set_screen(s,st)
        d=p.eval_on_selector('#app-screen .v-page-scaffold','el=>({sw:el.scrollWidth,cw:el.clientWidth})')
        ov.append((s,st,d))
    chk('BJ01 main states have no horizontal overflow',all(x[2]['sw']<=x[2]['cw']+.5 for x in ov),str(ov))

    cap=OUT/'v243-bj01-captures'; cap.mkdir(exist_ok=True)
    for s,st,name in [('SCR-001','READY','01-list-ready'),('SCR-003','READY','02-detail-ready'),('SCR-003','STALE','03-detail-stale')]:
        set_screen(s,st); p.locator('#app-screen').screenshot(path=str(cap/f'{name}.png'))
    set_screen('SCR-003','READY'); p.locator('[data-bj01-lot]').first.click(); p.locator('#app-screen').screenshot(path=str(cap/'04-lot-vbottomsheet.png'))
    b.close()

chk('No browser page errors',not errors,'; '.join(errors))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ01-DS-REUSE-QA-v2.4.3.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ01 Design System Reuse QA — v2.4.3','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','',
       'Gate: valid V_component → existing non-V component → existing Pattern/Template → layout composition → new component only after proven reusable gap.','']
for x in checks: lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] and not x['pass'] else ''))
(OUT/'BJ01-DS-REUSE-QA-v2.4.3.md').write_text('\n'.join(lines)+'\n')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
if status!='PASS': raise SystemExit(1)
