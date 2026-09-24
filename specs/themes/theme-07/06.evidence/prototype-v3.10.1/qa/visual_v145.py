from pathlib import Path
from PIL import Image,ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.4.5'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[];shots=[];errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page): page.goto('about:blank');page.set_content(html,wait_until='load');page.wait_for_timeout(20);page.evaluate('activeFlowId="UIF-13";activeScreenId="SCR-085";stateByScreen["SCR-085"]="READY";render();')
def snap(page,name,label):
 path=SHOTS/f'{name}.png';page.locator('#device-preview').screenshot(path=str(path));im=Image.open(path);ck(f'{name}: 402x874',im.size==(402,874));g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})');ck(f'{name}: no horizontal overflow',g['sw']<=g['cw']+1);shots.append((path,label))
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);page=b.new_page(viewport={'width':1400,'height':1100});page.on('pageerror',lambda e:errors.append(str(e)))
 fresh(page);snap(page,'BJ13-SCR085-queue','Queue · source component + waiting ownership')
 page.click('[data-val13-task="LC13-001"]');snap(page,'BJ13-SCR086-scope','Source + 1..N receipt-line scope')
 page.click('[data-val13-action="scope-to-allocation"]');snap(page,'BJ13-SCR087-method-required','Allocation · explicit method choice')
 page.select_option('[data-val13-method]','FIXTURE_VALUE');snap(page,'BJ13-SCR087-allocation','Allocation preview · closed original period')
 page.select_option('[data-val13-method]','FIXTURE_QTY');snap(page,'BJ13-SCR087-method','Alternative allowed method fixture')
 page.click('[data-val13-action="open-review"]');snap(page,'BJ13-SCR088-review','Final review · value-only effects')
 page.evaluate('val13ApplySourceUpdate()');snap(page,'BJ13-SCR088-stale','Stale source blocks commit')
 page.click('[data-val13-action="back-allocation"]');page.click('[data-val13-action="open-review"]');page.click('[data-val13-action="confirm-late-cost"]');snap(page,'BJ13-SCR089-completed','Completed · dirty scope for BJ14')
 fresh(page);page.click('[data-val13-task="LC13-002"]');page.click('[data-val13-action="scope-to-allocation"]');snap(page,'BJ13-SCR087-fx','Foreign currency + accounting FX')
 fresh(page);page.click('[data-val13-task="LC13-004"]');page.click('[data-val13-action="scope-to-allocation"]');snap(page,'BJ13-SCR087-negative','Negative purchase discount component')
 page.evaluate('activeScreenId="SCR-089";stateByScreen["SCR-089"]="UNKNOWN";render();');snap(page,'BJ13-SCR089-unknown','UNKNOWN · no blind retry')
 ck('No page JS errors',not errors);b.close()
thumb_w,thumb_h=201,437;label_h=32;cols=3;rows=(len(shots)+cols-1)//cols;sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white');d=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
 im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h));x=(i%cols)*thumb_w;y=(i//cols)*(thumb_h+label_h);sheet.paste(im,(x,y));d.text((x+4,y+thumb_h+5),label,fill='black')
contact=SHOTS/'BJ13-LATE-COST-CONTACT-SHEET-v1.4.5.png';sheet.save(contact)
failed=[n for n,v in checks if not v];passed=sum(v for _,v in checks)
lines=['# Visual QA v1.4.5 — BJ13','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',f'- {len(shots)} specimens at canonical 402×874.','- Focus: source-component queue, exact scope, allocation preview, period/FX/negative component, final review, stale-source block and result finality.','', '## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]
(OUT/'VISUAL-QA-v1.4.5.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'screens',len(shots))
if failed: print('\n'.join(failed)); raise SystemExit(1)
