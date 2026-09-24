from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
for x in cssfiles:
    idx=idx.replace(f'<link rel="stylesheet" href="{x}" />','')
# Keep Google Inter link in the test document; add bundled CSS inline.
idx=idx.replace('</head>',f'<style>{css}</style></head>')
data=(ROOT/'workbench-data.js').read_text(); fmap=(ROOT/'figma-ds-runtime-map.js').read_text(); app=(ROOT/'app.js').read_text()
html=(idx.replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
         .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
         .replace('<script src="app.js"></script>',f'<script>{app}</script>'))
checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def px(v): return round(float(str(v).replace('px','')),2)
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(html,wait_until='networkidle',timeout=30000)
    try: p.evaluate("document.fonts.ready")
    except: pass
    def set_screen(screen,state='READY'):
        p.evaluate('([s,st])=>{activeFlowId="UIF-01";activeScreenId=s;stateByScreen[s]=st;render();}',[screen,state])
    def cs(sel,props):
        return p.eval_on_selector(sel,'(el,ps)=>{const s=getComputedStyle(el);const o={};ps.forEach(k=>o[k]=s[k]);const r=el.getBoundingClientRect();o.__w=r.width;o.__h=r.height;return o}',props)
    set_screen('SCR-001','READY')
    shell=cs('#app-screen .v-page-scaffold',['fontFamily','backgroundColor'])
    chk('BJ01 shell is exact 402x874',abs(shell['__w']-402)<.2 and abs(shell['__h']-874)<.2,str((shell['__w'],shell['__h'])))
    chk('Inter is the active first font family','Inter' in shell['fontFamily'],shell['fontFamily'])
    chk('Inter webfont is actually available to the browser',p.evaluate("document.fonts.check('14px Inter')"))
    search=cs('.ds24-search',['height','paddingLeft','paddingRight','columnGap','borderRadius','borderTopWidth','fontFamily'])
    chk('VSearchBar geometry matches Figma',abs(search['__w']-370)<.2 and abs(search['__h']-44)<.2 and px(search['paddingLeft'])==16 and px(search['columnGap'])==8 and px(search['borderRadius'])==8 and px(search['borderTopWidth'])==1,str(search))
    search_icon=cs('.ds24-search > .icon',['width','height'])
    chk('VSearchBar icon is canonical 20x20',search_icon['__w']==20 and search_icon['__h']==20,str(search_icon))
    chip=cs('.ds24-chip',['height','paddingLeft','borderRadius','fontSize','lineHeight','fontWeight'])
    chk('VChip visual geometry/type matches Figma',abs(chip['__h']-34)<.2 and px(chip['paddingLeft'])==12 and px(chip['fontSize'])==12 and px(chip['lineHeight'])==16 and chip['fontWeight']=='600',str(chip))
    row=cs('.ds24-list-row',['height','paddingLeft','paddingRight','columnGap','borderRadius','borderTopWidth'])
    chk('List Row geometry matches Figma 525:519',abs(row['__w']-370)<.2 and abs(row['__h']-76)<.2 and px(row['paddingLeft'])==16 and px(row['paddingRight'])==24 and px(row['columnGap'])==12 and px(row['borderRadius'])==12 and px(row['borderTopWidth'])==1,str(row))
    lead=cs('.ds24-list-row__leading',['width','height']); trail=cs('.ds24-list-row__trailing .icon',['width','height'])
    chk('List Row leading/trailing icons are 20x20',lead['__w']==20 and lead['__h']==20 and trail['__w']==20 and trail['__h']==20,str((lead,trail)))
    title=cs('.ds24-list-row__copy strong',['fontSize','lineHeight','fontWeight']); sub=cs('.ds24-list-row__copy small',['fontSize','lineHeight','fontWeight'])
    chk('List Row text styles match Label/Default + Body/Small',px(title['fontSize'])==14 and px(title['lineHeight'])==20 and title['fontWeight']=='600' and px(sub['fontSize'])==13 and px(sub['lineHeight'])==20 and sub['fontWeight']=='400',str((title,sub)))
    chk('Product navigation row does not fake extra trailing anatomy',p.locator('.ds24-list-row__trailing').first.locator('.ds24-badge,.ds24-row-quantity').count()==0)
    # detail
    set_screen('SCR-003','READY')
    info=cs('.ds24-info-row',['height','columnGap','justifyContent','borderBottomWidth'])
    chk('Info Row uses canonical metadata anatomy',abs(info['__h']-44)<.2 and px(info['columnGap'])==8 and info['justifyContent']=='flex-start' and px(info['borderBottomWidth'])==0,str(info))
    metric=cs('.ds24-metric',['paddingLeft','rowGap','borderRadius','borderTopWidth'])
    chk('Theme7 availability Product UI consumes DS spacing/border/radius',abs(metric['__w']-370)<.2 and px(metric['paddingLeft'])==16 and px(metric['rowGap'])==8 and px(metric['borderRadius'])==16 and px(metric['borderTopWidth'])==1,str(metric))
    # stale banner
    set_screen('SCR-003','STALE')
    ban=cs('.v-banner',['paddingLeft','columnGap','borderRadius','borderTopWidth','marginTop','marginBottom'])
    bi=cs('.v-banner-icon',['width','height','borderRadius','backgroundColor']); bic=cs('.v-banner-icon .icon',['width','height'])
    bt=cs('.v-banner-copy strong',['fontSize','lineHeight','fontWeight']); bb=cs('.v-banner-copy span',['fontSize','lineHeight','fontWeight'])
    chk('VBanner container matches canonical Figma',abs(ban['__w']-370)<.2 and px(ban['paddingLeft'])==16 and px(ban['columnGap'])==12 and px(ban['borderRadius'])==12 and px(ban['borderTopWidth'])==1 and px(ban['marginTop'])==0 and px(ban['marginBottom'])==0,str(ban))
    chk('VBanner semantic icon has no fake circle and is 20x20',bi['__w']==20 and bi['__h']==20 and px(bi['borderRadius'])==0 and bi['backgroundColor']=='rgba(0, 0, 0, 0)' and bic['__w']==20 and bic['__h']==20,str((bi,bic)))
    chk('VBanner typography matches Figma',px(bt['fontSize'])==14 and px(bt['lineHeight'])==20 and bt['fontWeight']=='600' and px(bb['fontSize'])==13 and px(bb['lineHeight'])==20 and bb['fontWeight']=='400',str((bt,bb)))
    # back icon exact size on nested detail
    back=cs('.app-back-button .icon',['width','height'])
    chk('VAppBar Back icon is canonical 24x24',back['__w']==24 and back['__h']==24,str(back))
    # LOT and provenance contextual overlays.
    set_screen('SCR-003','READY')
    p.locator('[data-bj01-lot]').first.click()
    sheet=cs('.ds24-sheet',['paddingLeft','paddingTop','rowGap','borderTopLeftRadius','backgroundColor'])
    chk('BJ01 LOT contextual sheet uses DS sheet spacing/radius token',abs(sheet['__w']-402)<.2 and px(sheet['paddingLeft'])==16 and px(sheet['paddingTop'])==12 and px(sheet['rowGap'])==12 and px(sheet['borderTopLeftRadius'])==16,str(sheet))
    chk('BJ01 LOT sheet has no horizontal overflow',p.eval_on_selector('.ds24-sheet','el=>el.scrollWidth<=el.clientWidth+.5'))
    p.locator('[data-bj01-close-lot]').click(position={'x':5,'y':5})
    set_screen('SCR-003','READY'); p.locator('[data-bj01-provenance]').click()
    chk('BJ01 provenance opens one contextual dialog',p.locator('[data-theme-component="Theme7ContextSheet"][role="dialog"]').count()==1)
    # overflow all main states
    states=[('SCR-001','READY'),('SCR-001','EMPTY'),('SCR-001','FILTER_EMPTY'),('SCR-001','STALE'),('SCR-003','READY'),('SCR-003','STALE'),('SCR-003','LOADING'),('SCR-003','PERMISSION_DENIED')]
    ov=[]
    for s,st in states:
        set_screen(s,st)
        d=p.eval_on_selector('#app-screen .v-page-scaffold','el=>({sw:el.scrollWidth,cw:el.clientWidth,sh:el.scrollHeight,ch:el.clientHeight})')
        ov.append((s,st,d))
    chk('BJ01 main states have no horizontal overflow',all(x[2]['sw']<=x[2]['cw']+.5 for x in ov),str(ov))
    # screenshot ready+stale+detail
    cap=OUT/'v241-bj01-captures'; cap.mkdir(exist_ok=True)
    for s,st,name in [('SCR-001','READY','01-list-ready'),('SCR-003','READY','02-detail-ready'),('SCR-003','STALE','03-detail-stale')]:
        set_screen(s,st); p.locator('#app-screen').screenshot(path=str(cap/f'{name}.png'))
    b.close()
chk('No browser page errors',not errors,'; '.join(errors))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ01-FIGMA-DS-FIDELITY-QA-v2.4.1.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ01 Figma DS Fidelity QA — v2.4.1','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','']
for x in checks: lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] and not x['pass'] else ''))
(OUT/'BJ01-FIGMA-DS-FIDELITY-QA-v2.4.1.md').write_text('\n'.join(lines)+'\n')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
if status!='PASS': raise SystemExit(1)
