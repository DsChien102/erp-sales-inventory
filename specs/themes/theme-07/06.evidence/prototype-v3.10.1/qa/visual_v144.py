from pathlib import Path
from PIL import Image,ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.4.4'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; shots=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page): page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(30); page.evaluate('activeFlowId="UIF-03";activeScreenId="SCR-014";render();')
def snap(page,name,label):
    path=SHOTS/f'{name}.png'; page.locator('#device-preview').screenshot(path=str(path)); im=Image.open(path); ck(f'{name}: 402x874',im.size==(402,874)); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(f'{name}: no horizontal overflow',g['sw']<=g['cw']+1); shots.append((path,label))
with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1400,'height':1100}); page.on('pageerror',lambda e:errors.append(str(e)))
    fresh(page); snap(page,'BJ03-SCR014-queue','Queue · actionable vs waiting')
    page.click('[data-val03-receipt="VAL03-R1"]'); snap(page,'BJ03-SCR015-scope','Scope · Product → LOT/state')
    page.click('[data-val03-slice="VAL03-S1"]'); page.click('[data-val03-partial="VAL03-S1"]'); page.locator('[data-val03-qty="VAL03-S1"]').fill('20'); snap(page,'BJ03-SCR015-partial','Partial · progressive disclosure')
    page.click('[data-val03-action="open-review"]'); snap(page,'BJ03-SCR017-review','Final review · unit cost/value/effect')
    # blocker slice example only
    fresh(page); page.click('[data-val03-receipt="VAL03-R1"]'); page.click('[data-val03-slice="VAL03-S2"]'); page.click('[data-val03-action="open-review"]'); snap(page,'BJ03-SCR017-blocker','Sellable but availability blocker')
    # conflict resolution
    fresh(page); page.click('[data-val03-receipt="VAL03-R1"]'); page.click('[data-val03-slice="VAL03-S4"]'); page.click('[data-val03-action="open-calculation"]'); snap(page,'BJ03-SCR016-conflict','Exception · source conflict')
    page.click('[data-val03-source="VAL03-G2"][data-val03-source-id="SUP"]'); page.locator('[data-val03-reason="VAL03-G2"]').fill('Xác nhận NCC mới nhất'); page.click('[data-val03-action="open-review"]'); snap(page,'BJ03-SCR017-new-cost','Review · first official cost')
    page.click('[data-val03-action="confirm-value"]'); snap(page,'BJ03-SCR019-completed','Result · exact committed scope')
    # waiting-only result
    fresh(page); page.click('[data-val03-receipt="VAL03-R4"]'); page.click('[data-val03-slice="VAL03-S7"]'); page.click('[data-val03-action="open-review"]'); page.click('[data-val03-action="confirm-value"]'); snap(page,'BJ03-SCR019-waiting','Result · remaining waiting evidence')
    # unknown
    page.evaluate('stateByScreen["SCR-019"]="UNKNOWN";activeScreenId="SCR-019";render();'); snap(page,'BJ03-SCR019-unknown','UNKNOWN · reconciliation-safe')
    ck('No page JS errors',not errors); b.close()
# contact sheet
thumb_w,thumb_h=201,437; label_h=32; cols=3; rows=(len(shots)+cols-1)//cols
sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white'); d=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
    im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h)); x=(i%cols)*thumb_w; y=(i//cols)*(thumb_h+label_h); sheet.paste(im,(x,y)); d.text((x+4,y+thumb_h+5),label,fill='black')
contact=SHOTS/'BJ03-VALUATION-CONTACT-SHEET-v1.4.4.png'; sheet.save(contact)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Visual QA v1.4.4 — BJ03','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',f'- {len(shots)} screenshots at canonical 402×874.','- Focus: task ownership, Product→LOT/state scope, partial disclosure, conflict exception, final-review completeness, availability blocker, result/finality.','- Visual QA supports Product review; it does not equal Product approval.','', '## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]
(OUT/'VISUAL-QA-v1.4.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'screens',len(shots))
if failed: print('\n'.join(failed)); raise SystemExit(1)
