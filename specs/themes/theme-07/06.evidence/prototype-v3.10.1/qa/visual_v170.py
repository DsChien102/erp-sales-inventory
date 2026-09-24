from pathlib import Path
from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v1.7.0'
SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8')
css=(ROOT/'tokens.generated.css').read_text(encoding='utf-8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf-8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf-8')
app=(ROOT/'app.js').read_text(encoding='utf-8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; shots=[]; errors=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page,u,s,st,setup=None):
    page.goto('about:blank')
    page.set_content(html,wait_until='load')
    page.wait_for_timeout(20)
    if setup:
        page.evaluate(setup)
    page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st})
    page.wait_for_timeout(20)
def snap(page,name,label):
    path=SHOTS/f'{name}.png'
    page.locator('#device-preview').screenshot(path=str(path))
    im=Image.open(path)
    ck(name+' 402x874',im.size==(402,874))
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth,sh:e.scrollHeight,ch:e.clientHeight})')
    ck(name+' no horizontal overflow',g['sw']<=g['cw']+1)
    ck(name+' has Product UI',bool(page.locator('#app-screen').inner_text().strip()))
    shots.append((path,label))
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1400,'height':1100})
    p.on('pageerror',lambda e:errors.append(str(e)))
    cases=[
      ('UIF-11','SCR-048','READY',None,'BJ11-SCR048-worklist','BJ11 · worklist theo business state'),
      ('UIF-11','SCR-049','CORRECTABLE','()=>{cr11SelectedId="IO-260901-014"}','BJ11-SCR049-correctable','BJ11 · completed operation · correction eligible'),
      ('UIF-11','SCR-052','CORRECTION_ROUTE','()=>{cr11SelectedId="IO-260901-014"}','BJ11-SCR052-route','BJ11 · chọn cách sửa sai'),
      ('UIF-11','SCR-050','READY','()=>{cr11SelectedId="IO-260901-014";cr11CorrectQty=118;cr11CorrectionReason="Ghi nhận thừa 2 hộp khi nhận hàng"}','BJ11-SCR050-editor','BJ11 · một nguồn nhập authoritative · delta derive'),
      ('UIF-11','SCR-053','PENDING_APPROVAL','()=>{cr11SelectedId="IO-260901-014"}','BJ11-SCR053-pending','BJ11 · maker result · chờ actor khác duyệt'),
      ('UIF-11','SCR-051','READY','()=>{cr11SelectedId="IO-260901-014"}','BJ11-SCR051-approver','BJ11 · independent approver task'),
      ('UIF-11','SCR-053','COMPLETED','()=>{cr11SelectedId="IO-260901-014"}','BJ11-SCR053-completed','BJ11 · authoritative correction result'),
      ('UIF-11','SCR-049','UNKNOWN','()=>{cr11SelectedId="IO-260906-031"}','BJ11-SCR049-unknown','BJ11 · UNKNOWN handoff · no blind retry'),
      ('UIF-11','SCR-049','BLOCKED_PHYSICAL_HANDOVER','()=>{cr11SelectedId="IO-260902-005"}','BJ11-SCR049-handover-boundary','BJ11 · physical handover boundary · return belongs BJ06'),
      ('UIF-16','SCR-078','READY',None,'BJ16-SCR078-worklist','BJ16 · reconciliation case worklist'),
      ('UIF-16','SCR-079','PROJECTION_MISMATCH','()=>{cr16SelectedId="REC-260907-03"}','BJ16-SCR079-projection','BJ16 · source / ledger / display evidence'),
      ('UIF-16','SCR-080','READY','()=>{cr16SelectedId="REC-260907-03"}','BJ16-SCR080-plan','BJ16 · business-level display recovery plan'),
      ('UIF-16','SCR-081','REBUILDING','()=>{cr16SelectedId="REC-260907-03"}','BJ16-SCR081-processing','BJ16 · system recovery progress'),
      ('UIF-16','SCR-082','READY','()=>{cr16SelectedId="REC-260907-03"}','BJ16-SCR082-review','BJ16 · evidence review before close/unlock'),
      ('UIF-16','SCR-083','RESOLVED','()=>{cr16SelectedId="REC-260907-03"}','BJ16-SCR083-resolved','BJ16 · reconciliation result'),
      ('UIF-16','SCR-079','LEDGER_INTEGRITY_RISK','()=>{cr16SelectedId="REC-260907-06"}','BJ16-SCR079-ledger-risk','BJ16 · ledger integrity suspicion · escalation only'),
      ('UIF-17','SCR-078','READY',None,'BJ17-SCR078-worklist','BJ17 · operations requiring finality'),
      ('UIF-17','SCR-079','UNKNOWN_EVIDENCE','()=>{cr17SelectedId="REC-UNKNOWN-01"}','BJ17-SCR079-committed-evidence','BJ17 · evidence proves existing commit'),
      ('UIF-17','SCR-080','READY','()=>{cr17SelectedId="REC-UNKNOWN-01"}','BJ17-SCR080-committed-plan','BJ17 · finalize existing effect · same identity'),
      ('UIF-17','SCR-079','INSUFFICIENT_EVIDENCE','()=>{cr17SelectedId="REC-UNKNOWN-03"}','BJ17-SCR079-insufficient','BJ17 · insufficient evidence · keep protected'),
      ('UIF-17','SCR-083','ESCALATED','()=>{cr17SelectedId="REC-UNKNOWN-03"}','BJ17-SCR083-escalated','BJ17 · unresolved escalated result')
    ]
    for u,s,st,setup,name,label in cases:
        fresh(p,u,s,st,setup)
        snap(p,name,label)
    ck('No page JS errors',not errors)
    b.close()
thumb_w,thumb_h=201,437; label_h=54; cols=3; rows=(len(shots)+cols-1)//cols
sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white'); d=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
    im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h))
    x=(i%cols)*thumb_w; y=(i//cols)*(thumb_h+label_h)
    sheet.paste(im,(x,y)); d.text((x+4,y+thumb_h+4),label,fill='black')
contact=SHOTS/'CORRECTION-RECOVERY-CONTACT-SHEET-v1.7.0.png'; sheet.save(contact)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Visual QA v1.7.0 — Correction & Recovery','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',f'- {len(shots)} specimens at canonical 402×874.','- Screenshots are Product viewport only; workbench/Inspect is excluded.','','## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]
if errors: lines+=['','## Page errors']+[f'- {e}' for e in errors]
if failed: lines+=['','## Failed checks']+[f'- {x}' for x in failed]
(OUT/'VISUAL-QA-v1.7.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'screens',len(shots))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
