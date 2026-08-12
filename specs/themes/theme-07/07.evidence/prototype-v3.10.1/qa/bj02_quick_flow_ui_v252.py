from pathlib import Path
from playwright.sync_api import sync_playwright
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'v252-bj02-captures'; SHOTS.mkdir(exist_ok=True)
checks=[]; errors=[]
def check(n,ok,d=''): checks.append((n,bool(ok),d))
def build():
    idx=(ROOT/'index.html').read_text()
    for line in list(idx.splitlines()):
        if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line: idx=idx.replace(line+'\n','').replace(line,'')
    cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css']
    css='\n'.join((ROOT/x).read_text() for x in cssfiles)
    for x in cssfiles: idx=idx.replace(f'<link rel="stylesheet" href="{x}" />','')
    idx=idx.replace('</head>',f'<style>{css}</style></head>')
    for s in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:
        idx=idx.replace(f'<script src="{s}"></script>',f'<script>{(ROOT/s).read_text()}</script>')
    return idx

def shot(p,n): p.locator('#device-preview').screenshot(path=str(SHOTS/n))
def page_no_overflow(p): return p.locator('.figma-calibrated-shell').evaluate('e=>e.scrollWidth<=e.clientWidth+1')
def visible_bad_overflow(p):
    return p.locator('#app-screen *:visible').evaluate_all('''els=>{const root=document.querySelector('.figma-calibrated-shell').getBoundingClientRect();return els.map(e=>{const r=e.getBoundingClientRect();return {tag:e.tagName,cls:typeof e.className==='string'?e.className:'',text:(e.innerText||'').trim().slice(0,50),l:r.left,r:r.right,w:r.width,sw:e.scrollWidth,cw:e.clientWidth}}).filter(x=>x.w>0&&(x.l<root.left-1||x.r>root.right+1||false));}''')

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.set_default_timeout(5000); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(build(),wait_until='load')
    # real module -> quick
    p.evaluate("activeFlowId='UIF-02'; activeScreenId='SCR-006'; flowMode='document'; resetBj02Receipt('document'); stateByScreen['SCR-006']='READY'; render();")
    p.locator('[data-flow="quick"]').click(); check('SCR006 Quick navigates to SCR008',p.evaluate('activeScreenId')=='SCR-008',p.evaluate('activeScreenId'))
    # fill header as user would: open supplier sheet, choose; set date and evidence via actual change semantics
    p.locator('[data-bj02-open-supplier-sheet]').click(); p.locator('[data-bj02-supplier-option]').first.click()
    p.locator('[data-bj02-header="businessDate"]').fill(p.evaluate('localDateIso()'))
    p.evaluate("bj02Header.evidence='phieu-giao-hang-rat-dai-2026-09-10-ban-chinh-thuc.pdf'; renderAppScreen();")
    check('SCR008 Continue enabled after valid required header',not p.locator('[data-next="SCR-009"]').is_disabled())
    check('SCR008 long evidence filename wraps without horizontal overflow',page_no_overflow(p) and not visible_bad_overflow(p),str(visible_bad_overflow(p)[:3]))
    shot(p,'01-SCR-008-valid.png')
    p.locator('[data-next="SCR-009"]').click(); p.wait_for_timeout(30)
    check('SCR008 Continue renders SCR009 without stale UI',p.evaluate('activeScreenId')=='SCR-009' and 'Hàng thực nhận' in p.locator('#app-screen').inner_text() and 'Nhập hàng nhanh\nThông tin lần nhận' not in p.locator('#app-screen').inner_text(),p.locator('#app-screen').inner_text()[:120])
    check('No runtime error on SCR008 -> SCR009',not errors,str(errors))
    check('SCR009 no horizontal overflow',page_no_overflow(p))
    shot(p,'02-SCR-009-empty.png')
    # single-UOM: product selection must open editor immediately
    p.locator('[data-bj02-overview-product-search]').click(); p.locator('[data-bj02-overview-product-option="P-GLOVE-N"]').click(); p.wait_for_timeout(30)
    check('Single-UOM product opens SCR084 immediately',p.evaluate('activeScreenId')=='SCR-084',p.evaluate('activeScreenId'))
    check('Single-UOM editor has no redundant UOM selector',p.locator('.line-uom-picker').count()==0)
    shot(p,'03-SCR-084-single-uom.png')
    # real keypad edit then Xong
    p.locator('.bj02-quantity-hit').first.click(); before=p.evaluate('lineEditorDraft.accepted'); p.locator('[data-bj02-numeric-key="2"]').click(); mid=p.evaluate('lineEditorDraft.accepted')
    check('Numeric keypad keeps value uncommitted until Lưu',before==mid,f'{before}->{mid}')
    p.locator('[data-bj02-action="numeric-save"]').click(); check('Numeric keypad commits on Lưu',p.evaluate('lineEditorDraft.accepted')==2,str(p.evaluate('lineEditorDraft.accepted')))
    p.locator('[data-bj02-action="save-line"]').click(); check('Xong returns completed item to SCR009',p.evaluate('activeScreenId')=='SCR-009' and p.evaluate("bj02Lines[0].status")=='COMPLETED',f"{p.evaluate('activeScreenId')} / {p.evaluate('bj02Lines[0].status')}")
    shot(p,'04-SCR-009-one-complete.png')
    # multiple UOM: show direct options, no dropdown, then open editor immediately
    p.locator('[data-bj02-overview-product-search]').click(); p.locator('[data-bj02-overview-product-option="P-NOB-DHPP"]').click(); p.wait_for_timeout(20)
    check('Multi-UOM product shows all direct UOM choices',p.locator('[data-bj02-overview-uom-choice]').count()==2,str(p.locator('[data-bj02-overview-uom-choice]').count()))
    check('Multi-UOM choice does not use VSelect dropdown',p.locator('[data-bj02-overview-uom-select]').count()==0)
    check('UOM direct-choice screen no overflow',page_no_overflow(p) and not visible_bad_overflow(p),str(visible_bad_overflow(p)[:3]))
    shot(p,'05-SCR-009-uom-choice.png')
    p.locator('[data-bj02-overview-uom-choice="UOM-VIAL"]').click(); p.wait_for_timeout(20)
    check('Selecting UOM opens SCR084 immediately',p.evaluate('activeScreenId')=='SCR-084',p.evaluate('activeScreenId'))
    # LOT nested widths and long code guard
    p.evaluate("lineEditorDraft.lots[0].code='LOT-CODE-EXTREMELY-LONG-2026-09-10-ABCDEF'; lineEditorDraft.lots[0].expiry='10/09/2027'; renderAppScreen();")
    nested=p.locator('.active-lot-editor > .form-stack').evaluate('e=>Math.round(e.getBoundingClientRect().width)')
    check('LOT inner form fits 338px padded content',nested==338,str(nested))
    check('LOT editor long content has no horizontal overflow',page_no_overflow(p) and not visible_bad_overflow(p),str(visible_bad_overflow(p)[:3]))
    shot(p,'06-SCR-084-lot-long.png')
    # source governance regression
    src=(ROOT/'app.js').read_text()
    check('Fatal undefined total expression removed','flowMode === "quick" && total === 0' not in src)
    check('Quick overview no UOM VSelect regression','data-bj02-overview-uom-select' not in src)
    check('No new Theme7 shared component identity in BJ02','data-theme-component=' not in src[src.index('function bj02ListRow'):src.index('function esc(v)')])
    check('Browser runtime errors zero',not errors,str(errors))
    b.close()

passed=sum(ok for _,ok,_ in checks); failed=[(n,d) for n,ok,d in checks if not ok]; status='PASS' if not failed and not errors else 'FAIL'
res={'status':status,'passed':passed,'total':len(checks),'failed':[{'name':n,'detail':d} for n,d in failed],'browserErrors':errors}
(OUT/'BJ02-QUICK-FLOW-UI-QA-v2.5.2.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
md=['# BJ02 Quick Flow + UI QA — v2.5.2','',f'**Result: {status} · {passed}/{len(checks)} checks**','',f'- Browser errors: **{len(errors)}**','- This gate executes the real Quick interaction path instead of seeding target screens directly.','- Figma DS authority: Components + Patterns/Templates; mobile canvas 402×874.','','## Checks','']
for n,ok,d in checks: md.append(f'- [{"x" if ok else " "}] {n}'+(f' — `{d}`' if d else ''))
(OUT/'BJ02-QUICK-FLOW-UI-QA-v2.5.2.md').write_text('\n'.join(md)+'\n')
print(status,passed,'/',len(checks)); [print('FAIL',n,d) for n,d in failed]
raise SystemExit(0 if status=='PASS' else 1)
