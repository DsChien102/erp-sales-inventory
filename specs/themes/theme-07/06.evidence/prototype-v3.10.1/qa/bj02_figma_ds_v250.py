from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'v250-bj02-captures'; SHOTS.mkdir(exist_ok=True)
checks=[]
def check(n,c,d=''): checks.append((n,bool(c),d))
def build():
    idx=(ROOT/'index.html').read_text()
    for line in list(idx.splitlines()):
        if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: idx=idx.replace(line+'\n','').replace(line,'')
    cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css']
    css='\n'.join((ROOT/x).read_text() for x in cssfiles)
    for x in cssfiles: idx=idx.replace(f'<link rel="stylesheet" href="{x}" />','')
    idx=idx.replace('</head>',f'<style>{css}</style></head>')
    idx=idx.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
    idx=idx.replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
    idx=idx.replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>')
    return idx
def set_screen(p,sid,state='READY',mode='document'):
    p.evaluate(f'''()=>{{activeFlowId="UIF-02";flowMode="{mode}";resetBj02Receipt("{mode}");activeScreenId="{sid}";stateByScreen["{sid}"]="{state}";render();}}''')
def geom(p,sel):
    return p.locator(sel).first.evaluate('(e)=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:Math.round(r.width),h:Math.round(r.height),pad:s.padding,gap:s.gap,r:s.borderRadius,ff:s.fontFamily,fs:s.fontSize,lh:s.lineHeight,fw:s.fontWeight}}')
def no_over(p): return p.locator('.v-page-scaffold').evaluate('(e)=>e.scrollWidth<=e.clientWidth+1')
errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(build(),wait_until='load')
    # SCR006 exact List Row
    set_screen(p,'SCR-006'); g=geom(p,'.bj02-ds-list-row'); check('SCR006 List Row 370x76',g['w']==370 and g['h']==76,str(g)); check('SCR006 List Row canonical radius 12',g['r']=='12px',str(g)); check('SCR006 no false VCardIcon',p.locator('[data-ds-component="VCardIcon"]').count()==0); check('SCR006 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-006.png'))
    # SCR007 Record Card + Search
    set_screen(p,'SCR-007'); sg=geom(p,'.bj02-search'); rg=geom(p,'.bj02-record-card'); check('SCR007 VSearchBar 370x44',sg['w']==370 and sg['h']==44,str(sg)); check('SCR007 Record Card 370x116',rg['w']==370 and rg['h']==116,str(rg)); check('SCR007 partial is status not extra copy line','Đã nhận một phần' in p.locator('#app-screen').inner_text()); check('SCR007 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-007.png'))
    # SCR008 canonical fields + file zone
    set_screen(p,'SCR-008',mode='quick'); p.evaluate('bj02Header.supplierId="SUP-MINH-DUNG";bj02Header.supplier="Minh Dũng";bj02Header.businessDate=localDateIso();bj02Header.evidence="PG-01.pdf";renderAppScreen()'); ig=geom(p,'.input-shell'); fg=geom(p,'.file-drop-zone'); check('SCR008 canonical field height 44',ig['h']==44,str(ig)); check('SCR008 VFileDropZone 310x116',fg['w']==310 and fg['h']==116,str(fg)); check('SCR008 no create Supplier action','Tạo nhà cung cấp' not in p.locator('#app-screen').inner_text()); check('SCR008 no Save Draft action','Lưu nháp' not in p.locator('#app-screen').inner_text()); check('SCR008 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-008.png'))
    # SCR009 overview uses Record Card, no fake list anatomy; quick search direct
    set_screen(p,'SCR-009',mode='document'); check('SCR009 document items use Record Card',p.locator('.receipt-line-card[data-ds-component="DS v2 / Record Card"]').count()>=1); check('SCR009 no cross-UOM aggregate','Tổng số lượng' not in p.locator('#app-screen').inner_text()); check('SCR009 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-009-document.png'))
    set_screen(p,'SCR-009',mode='quick'); check('SCR009 Quick search is direct',p.locator('[data-bj02-overview-product-search]').count()==1); check('SCR009 no Theme7Quick component',p.locator('[data-theme-component="Theme7QuickReceiptProductSearch"]').count()==0); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-009-quick.png'))
    # SCR084 four authoritative fields, correct template and width
    set_screen(p,'SCR-009',mode='document'); p.locator('[data-bj02-line-id]').first.click(); labs=p.locator('.classification-quantities .quantity-label strong').all_inner_texts(); check('SCR084 Form template',p.locator('.v-page-scaffold').get_attribute('data-figma-template')=='Mobile / Form'); check('SCR084 four classifications always visible',labs==['Đạt','Cách ly','Hỏng','Từ chối'],str(labs)); qg=geom(p,'.quantity-control'); check('SCR084 quantity field 370x44',qg['w']==370 and qg['h']==44,str(qg)); check('SCR084 no editable total input',p.locator('[data-bj02-line-total],[data-bj02-lot-total]').count()==0); check('SCR084 no Theme7 custom component identity',p.locator('[data-theme-component]').count()==0); check('SCR084 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-084.png'))
    # Review / approval / result / recovery business invariants
    set_screen(p,'SCR-010',mode='quick'); check('SCR010 Quick approval is info normal flow','Cần phê duyệt trước khi ghi nhận' in p.locator('#app-screen').inner_text()); check('SCR010 no technical IDs','approval-ID' not in p.locator('#app-screen').inner_text()); check('SCR010 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-010.png'))
    set_screen(p,'SCR-011',mode='quick'); check('SCR011 only approve/reject decisions',p.locator('[data-action="approve"]').count()==1 and p.locator('[data-action="open-reject"]').count()==1); check('SCR011 actor handoff stated','Việc dành cho người phê duyệt' in p.locator('#app-screen').inner_text()); check('SCR011 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-011.png'))
    set_screen(p,'SCR-012','COMPLETED',mode='document'); check('SCR012 result has no receive mutation CTA','Ghi nhận hàng' not in p.locator('#app-screen').inner_text()); check('SCR012 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-012.png'))
    set_screen(p,'SCR-013','PROCESSING_OR_UNKNOWN',mode='quick'); txt=p.locator('#app-screen').inner_text(); check('SCR013 UNKNOWN no blind retry','Thử lại' not in txt); check('SCR013 same-operation guidance','Chưa cần thực hiện lại lần nhận' in txt or 'Không cần tạo lần nhận mới' in txt); check('SCR013 no overflow',no_over(p)); p.locator('#device-preview').screenshot(path=str(SHOTS/'SCR-013.png'))
    # static DS identity gate on UIF02 source render area
    source=(ROOT/'app.js').read_text(); a=source.index('function bj02ListRow'); z=source.index('function esc(v)'); bj=source[a:z]
    check('BJ02 no VCombobox identity','data-ds-component="VCombobox"' not in bj); check('BJ02 no VTextFormField identity','data-ds-component="VTextFormField"' not in bj); check('BJ02 no feature Theme7 component identity','data-theme-component=' not in bj); check('BJ02 V-first primitives present',all(x in bj for x in ['VSearchBar','VTextField','VDatePicker','VFileDropZone','VBanner','VButton']));
    b.close()
passed=sum(x[1] for x in checks); failed=[x for x in checks if not x[1]]; status='PASS' if not failed and not errors else 'FAIL'
res={'status':status,'passed':passed,'total':len(checks),'failed':[{'name':n,'detail':d} for n,ok,d in failed],'browserErrors':errors}
(OUT/'BJ02-FIGMA-DS-QA-v2.5.0.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ02 Figma DS / Business QA — v2.5.0','',f'**Result: {status} · {passed}/{len(checks)} checks**','',f'- Browser errors: **{len(errors)}**','- Viewport: **402 × 874 Product canvas**','- Gates: business ownership + interaction + DS component anatomy + computed geometry + overflow.','','## Checks','']
for n,ok,d in checks: lines.append(f'- [{"x" if ok else " "}] {n}'+(f' — `{d}`' if d else ''))
(OUT/'BJ02-FIGMA-DS-QA-v2.5.0.md').write_text('\n'.join(lines)+'\n')
print(status,passed,'/',len(checks));
for n,ok,d in failed: print('FAIL',n,d)
if status!='PASS': raise SystemExit(1)
