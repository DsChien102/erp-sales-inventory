from pathlib import Path
from PIL import Image,ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.6.0'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text(); html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; shots=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page,u,s,st): page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20); page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st})
def snap(page,name,label):
 path=SHOTS/f'{name}.png'; page.locator('#device-preview').screenshot(path=str(path)); im=Image.open(path); ck(name+' 402x874',im.size==(402,874)); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(name+' no horizontal overflow',g['sw']<=g['cw']+1); shots.append((path,label))
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1400,'height':1100}); p.on('pageerror',lambda e:errors.append(str(e)))
 cases=[
 ('UIF-08','SCR-042','READY','BJ08-SCR042-list','BJ08 · active count session'),('UIF-08','SCR-043','READY','BJ08-SCR043-create','BJ08 · scope before count'),('UIF-08','SCR-044','BLIND_COUNT','BJ08-SCR044-blind','BJ08 · true blind count'),('UIF-08','SCR-045','RECOUNT_REQUIRED','BJ08-SCR045-recount','BJ08 · discrepancy and recount'),('UIF-08','SCR-046','APPROVAL_REQUIRED','BJ08-SCR046-approval','BJ08 · independent approver task'),('UIF-08','SCR-047','UNKNOWN','BJ08-SCR047-unknown','BJ08 · same-operation recovery'),
 ('UIF-09','SCR-036','READY','BJ09-SCR036-list','BJ09 · product condition list'),('UIF-09','SCR-037','EXPIRED','BJ09-SCR037-expired','BJ09 · derived expiry detail'),('UIF-09','SCR-038','READY','BJ09-SCR038-maker','BJ09 · maker condition change'),('UIF-09','SCR-038','APPROVAL_REVIEW','BJ09-SCR038-approval','BJ09 · independent approver mode'),('UIF-09','SCR-041','COMPLETED','BJ09-SCR041-result','BJ09 · physical/value preserved'),
 ('UIF-10','SCR-036','READY','BJ10-SCR036-list','BJ10 · eligible non-sellable stock'),('UIF-10','SCR-040','READY','BJ10-SCR040-request','BJ10 · disposal request'),('UIF-10','SCR-040','APPROVAL_REVIEW','BJ10-SCR040-approval','BJ10 · approval is not disposal'),('UIF-10','SCR-040','APPROVED_PENDING_DISPOSAL','BJ10-SCR040-waiting','BJ10 · approved, stock unchanged'),('UIF-10','SCR-040','COMPLETION','BJ10-SCR040-completion','BJ10 · physical completion task'),('UIF-10','SCR-041','COMPLETED','BJ10-SCR041-result','BJ10 · authoritative decrement result'),('UIF-10','SCR-041','UNKNOWN','BJ10-SCR041-unknown','BJ10 · same-operation recovery')]
 for c in cases: fresh(p,*c[:3]); snap(p,*c[3:])
 ck('No page JS errors',not errors); b.close()
thumb_w,thumb_h=201,437; label_h=42; cols=3; rows=(len(shots)+cols-1)//cols; sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white'); d=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
 im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h)); x=(i%cols)*thumb_w; y=(i//cols)*(thumb_h+label_h); sheet.paste(im,(x,y)); d.text((x+4,y+thumb_h+4),label,fill='black')
contact=SHOTS/'INVENTORY-AUDIT-CONTROL-CONTACT-SHEET-v1.6.0.png'; sheet.save(contact)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks); lines=['# Visual QA v1.6.0 — Inventory Audit & Control','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',f'- {len(shots)} specimens at canonical 402×874.','','## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]; (OUT/'VISUAL-QA-v1.6.0.md').write_text('\n'.join(lines)+'\n'); print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'screens',len(shots));
if failed: print('\n'.join(failed)); raise SystemExit(1)
