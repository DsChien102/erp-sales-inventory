from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'v255-bj02-review-captures'; SHOTS.mkdir(exist_ok=True)
checks=[]; errors=[]
def check(name, ok, detail=''): checks.append((name,bool(ok),detail))
def build():
    idx=(ROOT/'index.html').read_text()
    for line in list(idx.splitlines()):
        if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: idx=idx.replace(line+'\n','').replace(line,'')
    cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css']
    css='\n'.join((ROOT/x).read_text() for x in cssfiles)
    for x in cssfiles: idx=idx.replace(f'<link rel="stylesheet" href="{x}" />','')
    idx=idx.replace('</head>',f'<style>{css}</style></head>')
    for s in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
        idx=idx.replace(f'<script src="{s}"></script>',f'<script>{(ROOT/s).read_text()}</script>')
    return idx

def no_overflow(p): return p.locator('.figma-calibrated-shell').evaluate('e=>e.scrollWidth<=e.clientWidth+1')
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1200}); p.set_default_timeout(6000); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(build(),wait_until='load')
    # Build a deliberately dense quick receipt with 8 lines to exercise mobile review density.
    p.evaluate('''()=>{
      activeFlowId='UIF-02'; flowMode='quick'; resetBj02Receipt('quick');
      bj02Header={supplierId:'SUP-001',supplier:'An Nam Trading',businessDate:localDateIso(),evidence:'bien-ban-giao-nhan.pdf',note:''};
      const defs=[
        ['P-NOB-DHPP','UOM-BOX','hộp',12,0,0,0],['P-NOB-DHPP','UOM-VIAL','lọ',8,1,0,0],
        ['P-AMX-LA','UOM-BOTTLE','chai',24,0,0,0],['P-GLOVE-N','UOM-BOX','hộp',34,0,0,0],
        ['P-AMX-LA','UOM-BOX','hộp',10,0,2,0],['P-GLOVE-N','UOM-PAIR','đôi',20,0,0,1],
        ['P-NOB-DHPP','UOM-BOX','hộp',6,0,0,0],['P-AMX-LA','UOM-BOTTLE','chai',5,0,0,0]
      ];
      bj02Lines=defs.map((d,i)=>{const pr=productById(d[0]);return hydrateReceiptLine({id:'QA-'+i,productId:d[0],uomId:d[1],uom:d[2],trackingPolicy:pr.trackingPolicy,expiryRequired:pr.expiryRequired,priceBasisVnd:pr.priceBasisVnd,status:'COMPLETED',accepted:d[3],quarantine:d[4],damaged:d[5],rejected:d[6],lots:pr.trackingPolicy==='LOT'?[{id:'LOT-'+i,code:'LOT'+(100+i),expiry:'2027-12-31',accepted:d[3],quarantine:d[4],damaged:d[5],rejected:d[6]}]:[]})});
      activeScreenId='SCR-010'; stateByScreen['SCR-010']='READY'; render();
    }''')
    rows=p.locator('.bj02-review-summary-row')
    check('Eight receipt lines render as compact summary rows', rows.count()==8, str(rows.count()))
    geom=rows.first.evaluate('e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,h:r.height,g:s.gap,px:s.paddingLeft,rad:s.borderRadius}}')
    check('Compact List Row geometry matches Figma 370x52 / gap8 / px12 / radius8', round(geom['w'])==370 and round(geom['h'])==52 and geom['g']=='8px' and geom['px']=='12px' and geom['rad']=='8px', str(geom))
    check('Review list avoids old expanded product blocks', p.locator('.bj02-review-product').count()==0)
    check('Product summary count is visible', 'sản phẩm' in p.locator('.bj02-section-heading').nth(1).inner_text().lower())
    check('Review screen has no horizontal overflow', no_overflow(p))
    # Density target: 8 lines should stay below 8*60 + gaps and substantially below old dump layout.
    list_h=p.locator('.bj02-review-summary-list').evaluate('e=>e.getBoundingClientRect().height')
    check('Eight-line review list stays compact', list_h <= 8*52+7*8+1, str(list_h))
    p.locator('#device-preview').screenshot(path=str(SHOTS/'01-review-8-lines.png'))
    # Exception is surfaced at parent row without opening detail.
    badges=[x.strip() for x in rows.locator('.status-badge').all_inner_texts()]
    check('Exceptions surfaced in summary list', 'Có cách ly' in badges and 'Có hàng hỏng' in badges and 'Có từ chối' in badges, str(badges))
    # Progressive disclosure.
    rows.nth(1).click()
    check('Tapping row opens VBottomSheet detail', p.locator('.bj02-review-detail-sheet[data-ds-component="VBottomSheet"]').count()==1)
    sheet=p.locator('.bj02-review-detail-sheet')
    sg=sheet.evaluate('e=>{const r=e.getBoundingClientRect(),s=getComputedStyle(e);return {w:r.width,rtl:s.borderTopLeftRadius,rtr:s.borderTopRightRadius,p:s.paddingTop,g:s.gap}}')
    check('Detail uses live VBottomSheet geometry', round(sg['w'])==402 and sg['rtl']=='20px' and sg['rtr']=='20px' and sg['p']=='12px' and sg['g']=='12px', str(sg))
    text=sheet.inner_text()
    check('Detail shows relevant non-zero classification facts', 'Đạt' in text and 'Cách ly' in text)
    check('Detail does not dump zero-value Hỏng/Từ chối', 'Hỏng\n0' not in text and 'Từ chối\n0' not in text, text[:400])
    check('LOT detail remains accessible on demand', 'Lô và hạn dùng' in text and 'HSD' in text)
    check('Detail sheet no horizontal overflow', sheet.evaluate('e=>e.scrollWidth<=e.clientWidth+1'))
    p.locator('#device-preview').screenshot(path=str(SHOTS/'02-review-detail-sheet.png'))
    p.locator('[data-bj02-review-close]').last.click()
    check('Detail sheet closes without leaving review', p.locator('.bj02-review-detail-sheet').count()==0 and p.evaluate('activeScreenId')=='SCR-010')
    # Approval screen uses same compact review composition.
    p.evaluate("activeScreenId='SCR-011'; stateByScreen['SCR-011']='READY'; render();")
    check('Approval reuses compact product summaries', p.locator('.bj02-review-summary-row').count()==8)
    check('Approval screen no horizontal overflow', no_overflow(p))
    p.locator('#device-preview').screenshot(path=str(SHOTS/'03-approval-8-lines.png'))
    # DS ownership: no new feature component identity.
    src=(ROOT/'app.js').read_text()
    block=src[src.index('function bj02ReviewIssue'):src.index('function bj02NumericValue')]
    check('Review uses existing DS assets only', 'data-theme-component=' not in block and 'DS v2 / List Row' in block and 'VBottomSheet' in block and 'VSection' in block)
    check('Browser errors zero', not errors, str(errors))
    b.close()
passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]; status='PASS' if not failed and not errors else 'FAIL'
res={'status':status,'passed':passed,'total':len(checks),'failed':[{'name':n,'detail':d} for n,d in failed],'browserErrors':errors,'captures':[str(x.name) for x in sorted(SHOTS.glob('*.png'))]}
(OUT/'BJ02-REVIEW-DENSITY-QA-v2.5.5.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
md=['# BJ02 Review Density QA — v2.5.5','',f'**Result: {status} · {passed}/{len(checks)} checks**','', '- SCR-010 review changed from expanded data dump to progressive disclosure.', '- Default product/line summary uses existing DS v2 / List Row, Type=Status, Density=Compact.', '- Exceptions are surfaced at list level; detailed classification and LOT/HSD remain available through VBottomSheet.', '- SCR-011 approval reuses the same dense review anatomy.','','## Checks','']
for n,ok,d in checks: md.append(f'- [{"x" if ok else " "}] {n}'+(f' — `{d}`' if d else ''))
(OUT/'BJ02-REVIEW-DENSITY-QA-v2.5.5.md').write_text('\n'.join(md)+'\n')
print(status,passed,'/',len(checks)); [print('FAIL',n,d) for n,d in failed]
raise SystemExit(0 if status=='PASS' else 1)
