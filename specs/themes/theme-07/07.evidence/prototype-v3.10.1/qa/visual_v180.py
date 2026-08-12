from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent; SHOTS=OUT/'screenshots-v1.8.0'; SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text(); html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; shots=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page,u,s,st,setup=None):
 page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(20)
 if setup: page.evaluate(setup)
 page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st}); page.wait_for_timeout(20)
def snap(page,name,label):
 path=SHOTS/f'{name}.png'; page.locator('#device-preview').screenshot(path=str(path)); im=Image.open(path); ck(name+' 402x874',im.size==(402,874)); g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})'); ck(name+' no horizontal overflow',g['sw']<=g['cw']+1); ck(name+' has Product UI',bool(page.locator('#app-screen').inner_text().strip())); shots.append((path,label))
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':1400,'height':1100}); p.on('pageerror',lambda e:errors.append(str(e)))
 cases=[
 ('UIF-12','SCR-066','READY',None,'BJ12-SCR066-entry','BJ12 · single initialization status'),
 ('UIF-12','SCR-067','READY',None,'BJ12-SCR067-data','BJ12 · file + date + independent control totals'),
 ('UIF-12','SCR-068','READY',None,'BJ12-SCR068-pass','BJ12 · validation passed'),
 ('UIF-12','SCR-068','VALIDATION_FAILED',None,'BJ12-SCR068-errors','BJ12 · business-readable row errors'),
 ('UIF-12','SCR-069','READY',None,'BJ12-SCR069-review','BJ12 · maker business review'),
 ('UIF-12','SCR-066','PENDING_APPROVAL',None,'BJ12-SCR066-pending','BJ12 · maker boundary · pending approval'),
 ('UIF-12','SCR-070','READY',None,'BJ12-SCR070-approval','BJ12 · independent approver evidence'),
 ('UIF-12','SCR-070','READY','()=>{cf12RejectOpen=true;cf12RejectReason="";}','BJ12-SCR070-reject','BJ12 · rejection reason sheet'),
 ('UIF-12','SCR-071','COMPLETED',None,'BJ12-SCR071-completed','BJ12 · authoritative activation result'),
 ('UIF-12','SCR-071','UNKNOWN',None,'BJ12-SCR071-unknown','BJ12 · UNKNOWN · no blind retry'),
 ('UIF-15','SCR-054','READY','()=>{cf15ReportType="INVENTORY";cf15Product="ALL";cf15DateMode="BUSINESS";}','BJ15-SCR054-inventory','BJ15 · inventory report scope'),
 ('UIF-15','SCR-054','READY','()=>{cf15ReportType="STOCK_CARD";cf15Product="P-NOB";cf15DateMode="RECORDED";}','BJ15-SCR054-stock-card','BJ15 · stock card + explicit recorded date'),
 ('UIF-15','SCR-055','READY','()=>{cf15ReportType="INVENTORY";cf15Product="ALL";cf15ProductSheetOpen=false;}','BJ15-SCR055-report','BJ15 · inventory report by Product/UOM'),
 ('UIF-15','SCR-055','READY','()=>{cf15ReportType="INVENTORY";cf15Product="ALL";cf15SelectedProduct="P-NOB";cf15ProductSheetOpen=true;}','BJ15-SCR055-lot-sheet','BJ15 · LOT breakdown contextual sheet'),
 ('UIF-15','SCR-055','READY','()=>{cf15ReportType="INVENTORY";cf15Product="ALL";cf15SelectedProduct="P-GLV";cf15ProductSheetOpen=true;}','BJ15-SCR055-none-sheet','BJ15 · NONE product · no fake lot'),
 ('UIF-15','SCR-055','FINANCIAL_RESTRICTED','()=>{cf15ReportType="INVENTORY";cf15Product="ALL";cf15ProductSheetOpen=false;}','BJ15-SCR055-finance-restricted','BJ15 · quantity allowed · finance omitted'),
 ('UIF-15','SCR-055','READY','()=>{cf15ReportType="STOCK_CARD";cf15Product="P-NOB";cf15SelectedProduct="P-NOB";cf15DateMode="BUSINESS";}','BJ15-SCR055-stock-card-business','BJ15 · stock card · business date'),
 ('UIF-15','SCR-055','RECORDED_DATE_VIEW','()=>{cf15ReportType="STOCK_CARD";cf15Product="P-NOB";cf15SelectedProduct="P-NOB";}','BJ15-SCR055-stock-card-recorded','BJ15 · stock card · recorded date'),
 ('UIF-15','SCR-056','READY','()=>{cf15ReportType="STOCK_CARD";cf15Product="P-NOB";cf15SelectedMovement="M-RECEIPT";}','BJ15-SCR056-movement','BJ15 · movement business detail'),
 ('UIF-15','SCR-057','READY','()=>{cf15ReportType="STOCK_CARD";cf15Product="P-NOB";cf15SelectedMovement="M-RECEIPT";}','BJ15-SCR057-source','BJ15 · business source timeline'),
 ('UIF-15','SCR-058','READY','()=>{cf15ReportType="INVENTORY";cf15ExportFrom="REPORT";cf15FinanceIncluded=false;}','BJ15-SCR058-export','BJ15 · export review preserves permission/as-of'),
 ('UIF-15','SCR-059','COMPLETED','()=>{cf15ReportType="INVENTORY";cf15ExportFrom="REPORT";cf15FinanceIncluded=false;}','BJ15-SCR059-completed','BJ15 · export result')]
 for u,s,st,setup,name,label in cases: fresh(p,u,s,st,setup); snap(p,name,label)
 ck('No page JS errors',not errors); b.close()
thumb_w,thumb_h=201,437; label_h=54; cols=3; rows=(len(shots)+cols-1)//cols; sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white'); d=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
 im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h)); x=(i%cols)*thumb_w; y=(i//cols)*(thumb_h+label_h); sheet.paste(im,(x,y)); d.text((x+4,y+thumb_h+4),label,fill='black')
contact=SHOTS/'CONTROL-FOUNDATION-INQUIRY-CONTACT-SHEET-v1.8.0.png'; sheet.save(contact)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Visual QA v1.8.0 — Control Foundation & Inquiry','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',f'- {len(shots)} specimens at canonical 402×874.','- Screenshots are Product viewport only; workbench/Inspect is excluded.','','## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]
if errors: lines+=['','## Page errors']+[f'- {e}' for e in errors]
if failed: lines+=['','## Failed checks']+[f'- {x}' for x in failed]
(OUT/'VISUAL-QA-v1.8.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8'); print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'screens',len(shots))
if failed: print('\n'.join(failed)); raise SystemExit(1)
