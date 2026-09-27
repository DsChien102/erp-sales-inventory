from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
CAP=OUT/'v450-grouped-surface-captures'; CAP.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8'); styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists(): styles.append(q.read_text(encoding='utf-8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>','<script>'+q.read_text(encoding='utf-8')+'</script>' if q.exists() else '')
checks=[]; errors=[]
def ck(name,cond,detail=''): checks.append({'name':name,'pass':bool(cond),'detail':detail})
def surface_report(page):
    return page.evaluate("""() => Array.from(document.querySelectorAll('.v430-flat__rows,.v430-key-stack,.v430-details')).filter(el=>{const r=el.getBoundingClientRect();return r.width>0&&r.height>0}).map(el=>{const s=getComputedStyle(el);return {cls:el.className,bg:s.backgroundColor,border:s.borderTopWidth,radius:s.borderTopLeftRadius,overflow:s.overflow,rows:el.querySelectorAll(':scope > .ds24-info-row,:scope > .ds24-key-value-row').length};})""")
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(7000); p.on('pageerror',lambda e: errors.append(str(e))); p.set_content(html,wait_until='load')
    # BJ03: choose document receipt and select a ready line so source + calculation blocks are visible.
    p.evaluate("activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render()")
    p.locator('[data-v430-val03-receipt="VAL03-R1"]').click()
    if p.locator('[data-v430-val03-select]').count(): p.locator('[data-v430-val03-select]').first.click()
    rep03=surface_report(p); p.locator('#device-preview').screenshot(path=str(CAP/'03-grouped-surface.png'))
    ck('BJ03 has grouped surfaces',len(rep03)>=2,str(rep03))
    # BJ13 active edit
    p.evaluate("activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render()")
    if p.locator('[data-v430-val13-task="LC13-004"]').count(): p.locator('[data-v430-val13-task="LC13-004"]').click()
    rep13=surface_report(p); p.locator('#device-preview').screenshot(path=str(CAP/'13-grouped-surface.png'))
    ck('BJ13 has grouped surfaces',len(rep13)>=2,str(rep13))
    # BJ14 ready result, then expand comparison.
    p.evaluate("activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render()")
    p.locator('[data-v430-val14-run="COST-0826"]').click()
    if p.locator('[data-v430-compare] summary').count(): p.locator('[data-v430-compare] summary').click()
    rep14=surface_report(p); p.locator('#device-preview').screenshot(path=str(CAP/'14-grouped-surface.png'))
    ck('BJ14 has grouped surfaces',len(rep14)>=2,str(rep14))
    allrep=rep03+rep13+rep14
    bad_bg=[x for x in allrep if x['bg'] in ('rgba(0, 0, 0, 0)','transparent')]
    bad_border=[x for x in allrep if x['border']=='0px']
    bad_radius=[x for x in allrep if x['radius']=='0px']
    ck('Every grouped information block has a surface background',not bad_bg,json.dumps(bad_bg,ensure_ascii=False))
    ck('Every grouped information block has a boundary',not bad_border,json.dumps(bad_border,ensure_ascii=False))
    ck('Every grouped information block has rounded grouping',not bad_radius,json.dumps(bad_radius,ensure_ascii=False))
    # Key/value groups should be one container; individual normal rows are not cards.
    row_cards=p.evaluate("""() => Array.from(document.querySelectorAll('.v430-key-stack > .ds24-key-value-row:not(.ds24-key-value-row--emphasis),.v430-flat__rows > .ds24-key-value-row:not(.ds24-key-value-row--emphasis),.v430-flat__rows > .ds24-info-row')).filter(el=>{const s=getComputedStyle(el);return s.borderRadius!=='0px' && s.borderRadius!=='0';}).length""")
    ck('Rows stay inside one shared surface, not one card per row',row_cards==0,str(row_cards))
    # Emphasis semantic remains visible.
    emph=p.evaluate("""() => {const el=document.querySelector('.ds24-key-value-row--emphasis'); if(!el)return null; return getComputedStyle(el).backgroundColor;}""")
    ck('Emphasis row keeps semantic background',bool(emph and emph not in ('rgba(0, 0, 0, 0)','transparent')),str(emph))
    b.close()
status='PASS' if all(x['pass'] for x in checks) and not errors else 'FAIL'
payload={'status':status,'version':'4.5.0','checks':checks,'browserErrors':errors,'captures':sorted(x.name for x in CAP.glob('*.png'))}
(OUT/'VALUATION-GROUPED-SURFACE-v4.5.0.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'VALUATION-GROUPED-SURFACE-v4.5.0.md').write_text('\n'.join(['# Valuation Grouped Surface QA v4.5.0','',f'**Result: {status}**','']+[f"- {'PASS' if x['pass'] else 'FAIL'} — {x['name']} {x['detail']}" for x in checks]+['',f'- Browser errors: {len(errors)}'])+'\n',encoding='utf-8')
print(status,'checks',sum(x['pass'] for x in checks),'/',len(checks),'errors',len(errors))
if status!='PASS':
    print([x for x in checks if not x['pass']],errors); raise SystemExit(1)
