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
idx=idx.replace('</head>',f'<style>{css}</style></head>')
data=(ROOT/'workbench-data.js').read_text(); fmap=(ROOT/'figma-ds-runtime-map.js').read_text(); app=(ROOT/'app.js').read_text()
html=(idx.replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
         .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
         .replace('<script src="app.js"></script>',f'<script>{app}</script>'))

checks=[]; errors=[]
def chk(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
def px(v): return round(float(str(v).replace('px','')),2)
def close(a,b,t=.2): return abs(a-b)<=t

chk('Theme7AvailabilitySummary remains removed','Theme7AvailabilitySummary' not in app)
chk('BJ01 availability source composes only Key-value Row','data-composed-from="DS v2 / Key-value Row"' in app)
chk('JetBrains Mono is requested with Inter','family=JetBrains+Mono' in (ROOT/'index.html').read_text())

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000)
    p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(html,wait_until='domcontentloaded',timeout=30000)
    p.wait_for_timeout(1200)

    def set_screen(screen,state='READY'):
        p.evaluate('([s,st])=>{activeFlowId="UIF-01";activeScreenId=s;stateByScreen[s]=st;bj01LotOpen=false;bj01ProvenanceOpen=false;render();}',[screen,state])
    def cs(sel,props):
        return p.eval_on_selector(sel,'(el,ps)=>{const s=getComputedStyle(el);const o={};ps.forEach(k=>o[k]=s[k]);const r=el.getBoundingClientRect();o.__x=r.x;o.__y=r.y;o.__w=r.width;o.__h=r.height;return o}',props)

    set_screen('SCR-003','READY')
    rows=p.locator('.ds24-availability [data-ds-component="DS v2 / Key-value Row"]')
    chk('Availability renders four canonical Key-value Rows',rows.count()==4,[rows.nth(i).inner_text() for i in range(rows.count())])
    chk('Availability renders no Info Row',p.locator('.ds24-availability [data-ds-component="DS v2 / Info Row"]').count()==0)
    chk('Primary Khả dụng is Emphasis',p.locator('.ds24-availability [data-ds-prop-state="Emphasis"]').count()==1 and p.locator('.ds24-availability [data-ds-prop-state="Emphasis"] span').inner_text().strip()=='Khả dụng')
    chk('Supporting quantities are Default Key-value Rows',p.locator('.ds24-availability [data-ds-prop-state="Default"]').count()==3)

    emph=cs('.ds24-availability [data-ds-prop-state="Emphasis"]',['height','paddingLeft','paddingRight','borderRadius','backgroundColor','justifyContent'])
    chk('Emphasis row preserves live Figma 338x44 geometry',close(emph['__w'],338) and close(emph['__h'],44) and px(emph['paddingLeft'])==12 and px(emph['paddingRight'])==12 and px(emph['borderRadius'])==8 and emph['justifyContent']=='space-between',str(emph))
    lab=cs('.ds24-availability [data-ds-prop-state="Emphasis"] > span',['fontFamily','fontSize','lineHeight','fontWeight'])
    val=cs('.ds24-availability [data-ds-prop-state="Emphasis"] > strong',['fontFamily','fontSize','lineHeight','fontWeight'])
    chk('Emphasis label typography matches Figma','Inter' in lab['fontFamily'] and px(lab['fontSize'])==14 and px(lab['lineHeight'])==20 and lab['fontWeight']=='600',str(lab))
    chk('Emphasis value typography matches Figma','Inter' in val['fontFamily'] and px(val['fontSize'])==16 and px(val['lineHeight'])==22 and val['fontWeight']=='600',str(val))

    default=cs('.ds24-key-value-stack .ds24-key-value-row',['height','paddingLeft','justifyContent'])
    dlab=cs('.ds24-key-value-stack .ds24-key-value-row > span',['fontFamily','fontSize','lineHeight','fontWeight'])
    dval=cs('.ds24-key-value-stack .ds24-key-value-row > strong',['fontFamily','fontSize','lineHeight','fontWeight'])
    chk('Default Key-value Row preserves live Figma 338x44 geometry',close(default['__w'],338) and close(default['__h'],44) and px(default['paddingLeft'])==0 and default['justifyContent']=='space-between',str(default))
    chk('Default label typography matches Figma','Inter' in dlab['fontFamily'] and px(dlab['fontSize'])==13 and px(dlab['lineHeight'])==20 and dlab['fontWeight']=='400',str(dlab))
    chk('Default numeric value typography uses JetBrains Mono','JetBrains Mono' in dval['fontFamily'] and px(dval['fontSize'])==14 and px(dval['lineHeight'])==22 and dval['fontWeight']=='400',str(dval))
    flex_items=p.eval_on_selector_all('.ds24-availability .ds24-key-value-row > span, .ds24-availability .ds24-key-value-row > strong','els=>els.map(e=>{const s=getComputedStyle(e);return {flexShrink:s.flexShrink,whiteSpace:s.whiteSpace}})')
    chk('Key-value labels and values preserve Figma shrink-0 semantics',all(x['flexShrink']=='0' for x in flex_items),str(flex_items))
    chk('Key-value labels and values stay on one line',all(x['whiteSpace']=='nowrap' for x in flex_items),str(flex_items))
    coords=[]
    for i in range(p.locator('.ds24-key-value-stack .ds24-key-value-row').count()):
        coords.append(p.locator('.ds24-key-value-stack .ds24-key-value-row').nth(i).evaluate('e=>{const l=e.children[0].getBoundingClientRect(),v=e.children[1].getBoundingClientRect();return {labelRight:l.right,valueLeft:v.left,valueRight:v.right,gap:v.left-l.right}}'))
    chk('Supporting quantity values align on one right edge',max(x['valueRight'] for x in coords)-min(x['valueRight'] for x in coords)<.2,str(coords))
    chk('Supporting labels and values never visually stick together',min(x['gap'] for x in coords)>=24,str(coords))
    wrap=cs('.ds24-availability',['alignItems','rowGap'])
    chk('338px Key-value master is centered in 370px Product column',close(wrap['__w'],370) and wrap['alignItems']=='center' and px(wrap['rowGap'])==8,str(wrap))

    # Short VBanner in LOT overlay: title + one-line body should hug content.
    p.evaluate('()=>{bj01SelectedLotCode="DH2509";bj01LotOpen=true;render();}')
    short=cs('.ds24-sheet .v-banner',['minHeight','paddingTop','paddingLeft','columnGap','borderRadius','borderTopWidth'])
    short_copy=cs('.ds24-sheet .v-banner-copy',['width','rowGap'])
    short_icon=cs('.ds24-sheet .v-banner-icon',['width','height','borderRadius','backgroundColor'])
    chk('One-line VBanner hugs content instead of forcing 96px',short['__h']<90 and px(short['minHeight'])==0,str(short))
    chk('VBanner shell geometry matches Figma',close(short['__w'],370) and px(short['paddingTop'])==16 and px(short['paddingLeft'])==16 and px(short['columnGap'])==12 and px(short['borderRadius'])==12 and px(short['borderTopWidth'])==1,str(short))
    chk('VBanner copy width/gap match live master',close(short_copy['__w'],286) and px(short_copy['rowGap'])==4,str(short_copy))
    chk('VBanner semantic icon is direct 20px without decorative circle',close(short_icon['__w'],20) and close(short_icon['__h'],20) and px(short_icon['borderRadius'])==0 and short_icon['backgroundColor']=='rgba(0, 0, 0, 0)',str(short_icon))

    set_screen('SCR-003','STALE')
    multi=cs('.v-banner',['minHeight'])
    chk('Longer VBanner grows from content',multi['__h']>short['__h'] and px(multi['minHeight'])==0,{'short':short['__h'],'long':multi['__h']})

    set_screen('SCR-001','READY')
    search=cs('.ds24-search',['height'])
    sinput=cs('.ds24-search input',['width','flexGrow','minWidth'])
    sicon=cs('.ds24-search > .icon',['width','height'])
    chk('VSearchBar remains exact 370x44 with 20px icon',close(search['__w'],370) and close(search['__h'],44) and close(sicon['__w'],20) and close(sicon['__h'],20),{'search':search,'icon':sicon})
    chk('VSearchBar input fills remaining control width',sinput['__w']>=300 and sinput['flexGrow']=='1' and px(sinput['minWidth'])==0,str(sinput))
    chip=cs('.ds24-chip',['position','height'])
    after=p.eval_on_selector('.ds24-chip','e=>{const s=getComputedStyle(e,"::after");return {top:s.top,bottom:s.bottom,position:s.position}}')
    chk('VChip expanded hit area is anchored to each chip',chip['position']=='relative' and close(chip['__h'],34) and after['position']=='absolute' and after['top']=='-5px' and after['bottom']=='-5px',{'chip':chip,'after':after})

    # Metadata still uses Info Row, but not for aligned stock quantities.
    set_screen('SCR-003','READY'); p.evaluate('()=>{bj01ProvenanceOpen=true;render();}')
    infos=p.locator('.ds24-sheet [data-ds-component="DS v2 / Info Row"]')
    chk('Info Row is retained only for supporting provenance metadata',infos.count()==3)
    info=cs('.ds24-sheet .ds24-info-row',['height','columnGap','justifyContent'])
    chk('Metadata Info Row preserves canonical 44px / 8px-gap anatomy',close(info['__h'],44) and px(info['columnGap'])==8 and info['justifyContent']=='flex-start',str(info))
    chk('Provenance VBottomSheet has no horizontal overflow',p.eval_on_selector('.ds24-sheet','e=>e.scrollWidth<=e.clientWidth+.5'))

    # VBottomSheet remains the live V-component, unchanged by this patch.
    sheet=cs('.ds24-sheet',['paddingTop','paddingLeft','paddingBottom','rowGap','borderTopLeftRadius'])
    chk('VBottomSheet still matches live master geometry',close(sheet['__w'],402) and px(sheet['paddingTop'])==12 and px(sheet['paddingLeft'])==16 and px(sheet['paddingBottom'])==44 and px(sheet['rowGap'])==12 and px(sheet['borderTopLeftRadius'])==20,str(sheet))

    # No custom Theme7 component identities on active BJ01 screens.
    set_screen('SCR-001','READY')
    chk('SCR-001 creates no Theme7 component identity',p.locator('#app-screen [data-theme-component]').count()==0)
    set_screen('SCR-003','READY')
    chk('SCR-003 creates no Theme7 component identity',p.locator('#app-screen [data-theme-component]').count()==0)

    # Main-state overflow regression.
    states=[('SCR-001','READY'),('SCR-001','EMPTY'),('SCR-001','FILTER_EMPTY'),('SCR-001','STALE'),('SCR-003','READY'),('SCR-003','STALE'),('SCR-003','LOADING'),('SCR-003','PERMISSION_DENIED')]
    ov=[]
    for s,st in states:
        set_screen(s,st)
        d=p.eval_on_selector('#app-screen .v-page-scaffold','e=>({sw:e.scrollWidth,cw:e.clientWidth})')
        ov.append((s,st,d))
    chk('BJ01 main states have no horizontal overflow',all(x[2]['sw']<=x[2]['cw']+.5 for x in ov),str(ov))

    cap=OUT/'v245-bj01-captures'; cap.mkdir(exist_ok=True)
    for s,st,name in [('SCR-001','READY','01-list-ready'),('SCR-003','READY','02-detail-ready'),('SCR-003','STALE','03-detail-stale')]:
        set_screen(s,st); p.locator('#app-screen').screenshot(path=str(cap/f'{name}.png'))
    set_screen('SCR-003','READY'); p.evaluate('()=>{bj01SelectedLotCode="DH2509";bj01LotOpen=true;render();}'); p.locator('#app-screen').screenshot(path=str(cap/'04-lot-short-banner.png'))
    set_screen('SCR-003','READY'); p.evaluate('()=>{bj01ProvenanceOpen=true;render();}'); p.locator('#app-screen').screenshot(path=str(cap/'05-provenance-vbottomsheet.png'))
    b.close()

chk('No browser page errors',not errors,'; '.join(errors))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'BJ01-KEY-VALUE-ALIGNMENT-QA-v2.4.5.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ01 Key-value Alignment QA — v2.4.5','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','',
       'Scope: Key-value Row alignment hardening with exact component-owned typography preserved; prior BJ01 DS fidelity and overflow gates remain protected.','']
for x in checks:
    lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] and not x['pass'] else ''))
(OUT/'BJ01-KEY-VALUE-ALIGNMENT-QA-v2.4.5.md').write_text('\n'.join(lines)+'\n')
print(status,res['passed'],res['total'])
for x in checks:
    if not x['pass']: print('FAIL',x['name'],x['note'])
if status!='PASS': raise SystemExit(1)
