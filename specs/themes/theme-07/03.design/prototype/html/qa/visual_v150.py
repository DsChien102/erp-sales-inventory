from pathlib import Path
from PIL import Image,ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.5.0'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[];shots=[];errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page,uif,sid): page.goto('about:blank');page.set_content(html,wait_until='load');page.wait_for_timeout(20);page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]="READY";render();}',{'u':uif,'s':sid})
def snap(page,name,label):
 path=SHOTS/f'{name}.png';page.locator('#device-preview').screenshot(path=str(path));im=Image.open(path);ck(f'{name}: 402x874',im.size==(402,874));g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})');ck(f'{name}: no horizontal overflow',g['sw']<=g['cw']+1);shots.append((path,label))
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);page=b.new_page(viewport={'width':1400,'height':1100});page.on('pageerror',lambda e:errors.append(str(e)))
 # BJ03
 fresh(page,'UIF-03','SCR-014'); snap(page,'BJ03-SCR014-queue','BJ03 · queue without architecture card')
 page.click('[data-val03-receipt="VAL03-R1"]'); snap(page,'BJ03-SCR015-scope','BJ03 · identified Product/UOM/LOT scope')
 page.click('[data-val03-slice="VAL03-S4"]'); page.click('[data-val03-action="open-evidence-sheet"]'); snap(page,'BJ03-SCR015-conflict-sheet','BJ03 · contextual source conflict')
 fresh(page,'UIF-03','SCR-015'); page.evaluate('val03SelectedReceiptId="VAL03-R1";render();'); page.click('[data-val03-slice="VAL03-S1"]'); page.click('[data-val03-action="open-review"]'); snap(page,'BJ03-SCR017-review','BJ03 · final valuation review')
 page.click('[data-val03-action="confirm-value"]'); snap(page,'BJ03-SCR019-result','BJ03 · terminal result')
 # BJ13
 fresh(page,'UIF-13','SCR-085'); snap(page,'BJ13-SCR085-queue','BJ13 · late-cost queue')
 page.click('[data-val13-task="LC13-001"]'); snap(page,'BJ13-SCR086-scope','BJ13 · source and exact target scope')
 page.click('[data-val13-action="scope-to-allocation"]'); snap(page,'BJ13-SCR087-allocation','BJ13 · allocation work surface')
 page.select_option('[data-val13-method]','FIXTURE_VALUE'); page.click('[data-val13-action="open-review"]'); snap(page,'BJ13-SCR088-review','BJ13 · value-only final review')
 page.click('[data-val13-action="confirm-late-cost"]'); snap(page,'BJ13-SCR089-result','BJ13 · dirty-scope result')
 # BJ14
 fresh(page,'UIF-14','SCR-072'); snap(page,'BJ14-SCR072-runs','BJ14 · cost-run worklist')
 page.click('[data-val14-action="new-run"]'); snap(page,'BJ14-SCR073-setup','BJ14 · run setup, policy method read-only')
 fresh(page,'UIF-14','SCR-072'); page.click('[data-val14-run="COST-0826"]'); snap(page,'BJ14-SCR074-ready','BJ14 · two-method result, ready')
 fresh(page,'UIF-14','SCR-072'); page.click('[data-val14-run="COST-0901-B"]'); snap(page,'BJ14-SCR074-blocked','BJ14 · blocker as run state')
 fresh(page,'UIF-14','SCR-072'); page.click('[data-val14-run="COST-0826"]'); page.click('[data-val14-action="review-publish"]'); snap(page,'BJ14-SCR076-review','BJ14 · final publish review')
 page.click('[data-val14-action="publish"]'); snap(page,'BJ14-SCR077-result','BJ14 · publication result')
 page.evaluate('stateByScreen["SCR-077"]="UNKNOWN";render();'); snap(page,'BJ14-SCR077-unknown','BJ14 · UNKNOWN without retry')
 ck('No page JS errors',not errors);b.close()
thumb_w,thumb_h=201,437;label_h=36;cols=3;rows=(len(shots)+cols-1)//cols;sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white');d=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
 im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h));x=(i%cols)*thumb_w;y=(i//cols)*(thumb_h+label_h);sheet.paste(im,(x,y));d.text((x+4,y+thumb_h+5),label,fill='black')
contact=SHOTS/'INVENTORY-VALUATION-CONTACT-SHEET-v1.5.0.png';sheet.save(contact)
failed=[n for n,v in checks if not v];passed=sum(v for _,v in checks)
lines=['# Visual QA v1.5.0 — Inventory Valuation','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',f'- {len(shots)} specimens at canonical 402×874.','- Covers BJ03 linear/contextual flow, BJ13 scope/allocation/review/result, BJ14 worklist/setup/ready/blocker/review/result/UNKNOWN.','', '## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]
(OUT/'VISUAL-QA-v1.5.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'screens',len(shots))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
