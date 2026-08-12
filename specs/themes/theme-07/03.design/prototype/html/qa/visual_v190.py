from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.9.0'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text(); html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; shots=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(p,u,s,st,setup=''):
 p.goto('about:blank');p.set_content(html,wait_until='load');p.wait_for_timeout(10)
 base='''(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;
 if(x.u==="UIF-02"){if(x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");stateByScreen[x.s]=x.st;}}
 if(x.u==="UIF-03"){val03SelectedReceiptId="VAL03-R1";val03ReviewSourceVersion=val03Current().sourceVersion;}
 if(x.u==="UIF-13"){val13SelectedTaskId="LC13-001";if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
 if(x.u==="UIF-14"){val14SelectedRunId="COST-0826";val14PublishReviewVersion=val14Current().inputVersion;}
 render();}'''
 p.evaluate(base,{'u':u,'s':s,'st':st})
 if setup: p.evaluate(setup);p.evaluate('render()')
 p.wait_for_timeout(10)
def snap(p,u,s,st,i):
 name=f'{i:02d}-{u}-{s}-{st}'.replace('_','-'); path=SHOTS/f'{name}.png'; p.locator('#device-preview').screenshot(path=str(path)); im=Image.open(path); ck(name+' 402x874',im.size==(402,874)); g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(name+' no overflow',g['sw']<=g['cw']+1); ck(name+' has content',bool(p.locator('#app-screen').inner_text().strip())); shots.append((path,f'{u} · {s} · {st}'))
cases=[
('UIF-01','SCR-001','READY',''),('UIF-01','SCR-003','READY',''),
('UIF-02','SCR-008','READY',''),('UIF-02','SCR-009','READY',''),('UIF-02','SCR-012','COMPLETED',''),
('UIF-03','SCR-015','READY',''),('UIF-03','SCR-019','COMPLETED',''),
('UIF-04','SCR-021','READY',''),
('UIF-05','SCR-025','READY',''),('UIF-05','SCR-028','READY',''),
('UIF-06','SCR-030','READY',''),('UIF-06','SCR-035','READY',''),
('UIF-07','SCR-036','READY',''),('UIF-07','SCR-041','COMPLETED',''),
('UIF-08','SCR-044','BLIND_COUNT',''),('UIF-08','SCR-046','APPROVAL_REQUIRED',''),('UIF-08','SCR-047','COMPLETED',''),
('UIF-09','SCR-038','READY',''),('UIF-09','SCR-041','COMPLETED',''),
('UIF-10','SCR-040','READY',''),('UIF-10','SCR-041','UNKNOWN',''),
('UIF-11','SCR-050','CONFLICT',''),('UIF-11','SCR-051','READY',''),('UIF-11','SCR-053','COMPLETED',''),
('UIF-12','SCR-067','READY',''),('UIF-12','SCR-070','READY',''),('UIF-12','SCR-071','COMPLETED',''),
('UIF-13','SCR-085','READY',''),('UIF-13','SCR-088','READY',''),('UIF-13','SCR-089','COMPLETED',''),
('UIF-14','SCR-072','READY',''),('UIF-14','SCR-076','READY',''),('UIF-14','SCR-077','COMPLETED',''),
('UIF-15','SCR-054','READY','()=>{cf15ReportType="INVENTORY";cf15Product="ALL";cf15DateMode="BUSINESS";}'),('UIF-15','SCR-055','READY','()=>{cf15ReportType="INVENTORY";cf15Product="ALL";}'),('UIF-15','SCR-059','COMPLETED',''),
('UIF-16','SCR-078','READY',''),('UIF-16','SCR-080','LOCKED',''),('UIF-16','SCR-082','MISMATCH_REMAINS',''),
('UIF-17','SCR-078','READY',''),('UIF-17','SCR-080','READY',''),('UIF-17','SCR-083','COMPLETED','')]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1400,'height':1100});p.on('pageerror',lambda e:errors.append(str(e)))
 for i,(u,s,st,setup) in enumerate(cases,1): fresh(p,u,s,st,setup);snap(p,u,s,st,i)
 ck('No page JS errors',not errors);b.close()
thumb_w,thumb_h=201,437;label_h=42;cols=4;rows=(len(shots)+cols-1)//cols;sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white');d=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
 im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h));x=(i%cols)*thumb_w;y=(i//cols)*(thumb_h+label_h);sheet.paste(im,(x,y));d.text((x+3,y+thumb_h+3),label,fill='black')
contact=SHOTS/'HOLISTIC-CONTACT-SHEET-v1.9.0.png';sheet.save(contact)
failed=[n for n,v in checks if not v];passed=sum(v for _,v in checks);lines=['# Visual QA v1.9.0 — Theme 7 Holistic Hardening','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks · {len(shots)} specimens**','','- Canonical Product viewport: 402×874.','- Workbench/Inspect UI excluded from screenshots.','- Representative coverage spans all 17 UIFs and the v1.9.0 hardening targets.','','## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]
if errors:lines+=['','## Page errors']+[f'- {e}' for e in errors]
if failed:lines+=['','## Failed checks']+[f'- {x}' for x in failed]
(OUT/'VISUAL-QA-v1.9.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8');print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'screens',len(shots));
if failed: raise SystemExit(1)
