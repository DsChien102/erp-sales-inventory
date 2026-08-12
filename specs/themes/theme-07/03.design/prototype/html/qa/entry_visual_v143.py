from pathlib import Path
import json
from PIL import Image,ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.4.3'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8'); css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8'); data=(ROOT/'workbench-data.js').read_text(encoding='utf8'); app0=(ROOT/'app.js').read_text(encoding='utf8')
checks=[]; shots=[]
def ck(n,v): checks.append((n,bool(v)))
def html_for(q):
 app=app0.replace('window.location.search',json.dumps(q)); return idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
def load(page,q,setup=''):
 page.goto('about:blank'); page.set_content(html_for(q),wait_until='load'); page.wait_for_timeout(40)
 if setup: page.evaluate(setup); page.wait_for_timeout(25)
def snap(page,name,label):
 path=SHOTS/f'{name}.png'; page.locator('#device-preview').screenshot(path=str(path)); im=Image.open(path); ck(name+' 402x874',im.size==(402,874)); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(name+' no horizontal overflow',g['sw']<=g['cw']+1); shots.append((path,label))
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); page=b.new_page(viewport={'width':1400,'height':1100}); errors=[]; page.on('pageerror',lambda e:errors.append(str(e)))
 cases=[
  ('?uif=UIF-01&entry=product-context','BJ01-product-context','BJ01 · Product contextual entry'),
  ('?uif=UIF-02','BJ02-module','BJ02 · Module entry'),
  ('?uif=UIF-02&entry=document-context','BJ02-document-context','BJ02 · Purchase contextual entry'),
  ('?uif=UIF-02&entry=approver','BJ02-approver','BJ02 · Approver task'),
  ('?uif=UIF-02&screen=SCR-013&state=EMPTY','BJ02-recovery','BJ02 · System recovery'),
  ('?uif=UIF-03','BJ03-module','BJ03 · Valuation module entry'),
  ('?uif=UIF-03&entry=receipt-task','BJ03-receipt-task','BJ03 · Receipt task deep link'),
  ('?uif=UIF-04&entry=order-context','BJ04-order-context','BJ04 · Contextual-only reservation'),
  ('?uif=UIF-05','BJ05-module','BJ05 · Picking module entry'),
  ('?uif=UIF-05&entry=order-task','BJ05-order-task','BJ05 · Assigned picking task'),
  ('?uif=UIF-06','BJ06-maker','BJ06 · Maker queue'),
  ('?uif=UIF-06&entry=return-task','BJ06-return-task','BJ06 · Assigned maker return task'),
  ('?uif=UIF-06&entry=approver','BJ06-approver','BJ06 · Approver worklist'),
  ('?uif=UIF-07','BJ07-module','BJ07 · Supplier return queue'),
  ('?uif=UIF-07&entry=return-task','BJ07-return-task','BJ07 · Assigned supplier-return task'),
 ]
 for q,n,l in cases: load(page,q); snap(page,n,l)
 load(page,'?uif=UIF-06&screen=SCR-035','io06SelectedRequestId="RET-260827-05"; stateByScreen["SCR-035"]="RECEIVED_PENDING_CLASSIFICATION"; render();'); snap(page,'BJ06-received-milestone','BJ06 · Receipt milestone')
 load(page,'?uif=UIF-06&screen=SCR-035','io06SelectedRequestId="RET-260827-05"; var ls=io06CurrentLines(); ls[0].classification={sellable:1,quarantine:1,damaged:0,expired:2}; ls[1].classification={sellable:4,quarantine:1,damaged:0,expired:0}; stateByScreen["SCR-035"]="COMPLETED"; io06CurrentRequest().classified=true; render();'); snap(page,'BJ06-final-result','BJ06 · Final classification result')
 load(page,'?uif=UIF-07&entry=return-task','var a=io07Allocations(io07Current())[0].allocation; a.physicalMismatch=true; render();'); snap(page,'BJ07-purchase-handoff','BJ07 · Waiting Purchase amendment')
 ck('No page JavaScript errors',not errors); b.close()
thumb_w,thumb_h=201,437; label_h=34; cols=4; rows=(len(shots)+cols-1)//cols
sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white'); draw=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
 im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h)); x=(i%cols)*thumb_w; y=(i//cols)*(thumb_h+label_h); sheet.paste(im,(x,y)); draw.text((x+5,y+thumb_h+6),label,fill='black')
contact=SHOTS/'ENTRY-JOURNEY-CONTACT-SHEET-v1.4.3.png'; sheet.save(contact)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Entry & Journey Continuity Visual QA v1.4.3','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',f'- {len(shots)} representative specimens at canonical 402×874.','- Focus: why-here context, actor ownership, contextual-only entry, recovery-only entry and intermediate-vs-terminal milestone comprehension.','- QA PASS is evidence for Product review, not Product approval.','','## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]+['','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'VISUAL-QA-v1.4.3.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'checks;',len(shots),'screenshots')
if failed: print('\n'.join(failed)); raise SystemExit(1)
