from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
APP=(ROOT/'app.js').read_text(); CSS=(ROOT/'v272-detail-composition-fidelity.css').read_text(); IDX=(ROOT/'index.html').read_text()
checks=[]; errors=[]
def ck(n,v,d=''): checks.append({'name':n,'pass':bool(v),'detail':str(d)})
ck('Summary Card maps to live Figma 525:552','data-figma-node="525:552"' in APP)
ck('No legacy BJ01 naked product head','<section class="ds24-product-head"' not in APP)
ck('No legacy BJ05 naked product head','<section class="bj05-product-head"' not in APP)
ck('BJ01 detail uses canonical Summary Card','inventory-product-summary' in APP)
ck('BJ02 summary composition uses Summary Card + Info Row','bj02-product-summary-composition' in APP and 'DS v2 / Summary Card,DS v2 / Info Row,VButton' in APP)
ck('BJ05 detail uses Summary Card + Info Row','bj05-product-summary' in APP and 'Detail summary + supporting metadata' in APP)
ck('BJ05 handover declares grouped-surface composition','bj05-handover-product' in APP and 'data-layout-pattern="Grouped surface"' in APP)
ck('Correction CSS has no raw hex', not re.search(r'#[0-9a-fA-F]{3,8}\b',CSS))
ck('Correction CSS has no rgb colors', 'rgb(' not in CSS and 'rgba(' not in CSS)
ck('Summary Card locks 370x112','.ds24-summary-card' in CSS and 'width:370px' in CSS.replace(' ','') and 'height:112px' in CSS.replace(' ',''))
# build standalone using all current style files in index order
html=IDX
for line in list(html.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: html=html.replace(line+'\n','').replace(line,'')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',html):
    p=ROOT/fn
    if p.exists(): styles.append(p.read_text()); html=html.replace(f'<link rel="stylesheet" href="{fn}" />','')
html=html.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text()}</script>')
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1200,'height':1000}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load')
    def set_scr(u,s,setup=''):
        p.evaluate(f"()=>{{activeFlowId='{u}';activeScreenId='{s}';stateByScreen['{s}']='READY';{setup}render();}}")
    set_scr('UIF-01','SCR-003',"bj01SelectedProductId='P-001';")
    ck('BJ01 runtime has one canonical Summary Card',p.locator('[data-ds-role="inventory-product-summary"]').count()==1)
    set_scr('UIF-05','SCR-027',"io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';")
    sc=p.locator('[data-ds-role="picking-product-summary"]'); ir=p.locator('.bj05-product-summary > [data-ds-component="DS v2 / Info Row"]')
    ck('SCR027 has one Summary Card and one supporting Info Row',sc.count()==1 and ir.count()==1,f'{sc.count()}/{ir.count()}')
    if sc.count():
        g=sc.evaluate('e=>{const r=e.getBoundingClientRect();return [Math.round(r.width),Math.round(r.height)]}')
        ck('SCR027 Summary Card is 370x112',g==[370,112],g)
    ck('SCR027 summary wrapper is surface-free',p.locator('.bj05-product-summary').evaluate("e=>['rgba(0, 0, 0, 0)','transparent'].includes(getComputedStyle(e).backgroundColor)"))
    ck('SCR027 has no horizontal overflow',p.locator('.v-page-scaffold').evaluate('e=>e.scrollWidth<=e.clientWidth+1'))
    ck('No browser errors',len(errors)==0,errors)
    b.close()
passed=sum(x['pass'] for x in checks)
out={'release':'2.7.2','passed':passed,'total':len(checks),'checks':checks,'browserErrors':errors}
(Path(__file__).parent/'DETAIL-COMPOSITION-QA-v2.7.2.json').write_text(json.dumps(out,ensure_ascii=False,indent=2))
(Path(__file__).parent/'DETAIL-COMPOSITION-QA-v2.7.2.md').write_text('# Detail Composition QA v2.7.2\n\n'+f'**Result: {"PASS" if passed==len(checks) else "FAIL"} {passed}/{len(checks)}**\n\n'+'\n'.join(f'- [{"x" if c["pass"] else " "}] {c["name"]}' for c in checks)+'\n')
print('PASS' if passed==len(checks) else 'FAIL',passed,len(checks))
