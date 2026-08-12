from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image, ImageDraw, ImageFont
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'screenshots-v2.1.1'
OUT.mkdir(parents=True,exist_ok=True)

def inline_html(root):
    idx=(root/'index.html').read_text(encoding='utf-8')
    css=(root/'tokens.generated.css').read_text(encoding='utf-8')+'\n'+(root/'styles.css').read_text(encoding='utf-8')
    data=(root/'workbench-data.js').read_text(encoding='utf-8')
    fmap=(root/'figma-ds-runtime-map.js').read_text(encoding='utf-8')
    app=(root/'app.js').read_text(encoding='utf-8')
    return (idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','')
      .replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>')
      .replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
      .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
      .replace('<script src="app.js"></script>',f'<script>{app}</script>'))

CASES=[
 ('UIF-01','SCR-001','READY'),('UIF-01','SCR-003','READY'),
 ('UIF-02','SCR-006','READY'),('UIF-02','SCR-006','PERMISSION_DENIED'),('UIF-02','SCR-009','READY'),('UIF-02','SCR-012','COMPLETED'),
 ('UIF-03','SCR-014','READY'),('UIF-03','SCR-015','READY'),('UIF-03','SCR-017','READY'),('UIF-03','SCR-019','COMPLETED'),
 ('UIF-04','SCR-021','PARTIAL'),
 ('UIF-05','SCR-025','READY'),('UIF-05','SCR-027','READY'),('UIF-05','SCR-029','COMPLETED'),
 ('UIF-06','SCR-030','READY'),('UIF-06','SCR-032','READY'),('UIF-06','SCR-034','READY'),('UIF-06','SCR-035','COMPLETED'),
 ('UIF-07','SCR-036','READY'),('UIF-07','SCR-039','READY'),('UIF-07','SCR-041','COMPLETED'),
 ('UIF-08','SCR-042','READY'),('UIF-08','SCR-044','BLIND_COUNT'),('UIF-08','SCR-046','APPROVAL_REQUIRED'),('UIF-08','SCR-047','COMPLETED'),
 ('UIF-09','SCR-036','READY'),('UIF-09','SCR-038','READY'),('UIF-09','SCR-038','APPROVAL_REVIEW'),('UIF-09','SCR-041','COMPLETED'),
 ('UIF-10','SCR-036','READY'),('UIF-10','SCR-040','READY'),('UIF-10','SCR-040','COMPLETION'),('UIF-10','SCR-041','COMPLETED'),
 ('UIF-11','SCR-048','READY'),('UIF-11','SCR-052','CORRECTION_ROUTE'),('UIF-11','SCR-051','READY'),('UIF-11','SCR-053','COMPLETED'),
 ('UIF-12','SCR-066','READY'),('UIF-12','SCR-066','PERMISSION_DENIED'),('UIF-12','SCR-067','READY'),('UIF-12','SCR-068','VALIDATION_FAILED'),('UIF-12','SCR-069','READY'),('UIF-12','SCR-070','READY'),('UIF-12','SCR-071','COMPLETED'),
 ('UIF-13','SCR-085','READY'),('UIF-13','SCR-086','READY'),('UIF-13','SCR-088','READY'),('UIF-13','SCR-089','COMPLETED'),
 ('UIF-14','SCR-072','READY'),('UIF-14','SCR-073','READY'),('UIF-14','SCR-074','READY_FOR_REVIEW'),('UIF-14','SCR-076','READY'),('UIF-14','SCR-077','COMPLETED'),
 ('UIF-15','SCR-054','READY'),('UIF-15','SCR-055','READY'),('UIF-15','SCR-057','READY'),('UIF-15','SCR-059','COMPLETED'),
 ('UIF-16','SCR-078','READY'),('UIF-16','SCR-079','PROJECTION_MISMATCH'),('UIF-16','SCR-080','READY'),('UIF-16','SCR-081','READY'),('UIF-16','SCR-083','RESOLVED'),
 ('UIF-17','SCR-078','READY'),('UIF-17','SCR-079','UNKNOWN_EVIDENCE'),('UIF-17','SCR-080','READY'),('UIF-17','SCR-082','READY'),('UIF-17','SCR-083','RESOLVED'),
]

html=inline_html(ROOT); errors=[]; files=[]; geometry=[]; template_rows=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100},device_scale_factor=1); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(html,wait_until='load'); p.add_style_tag(content='*{animation:none!important;transition:none!important;caret-color:transparent!important}')
    for i,(f,s,st) in enumerate(CASES,1):
        p.evaluate('''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
          if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
          if(x.f==='UIF-03'&&x.s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}
          if(x.f==='UIF-06'&&x.s==='SCR-035'&&x.st==='COMPLETED'){
            io06SelectedRequestId='RET-260827-05';const req=io06CurrentRequest();req.receiptCommitted=true;req.phase='CLASSIFICATION';req.classified=true;req.closed=true;
            const ls=io06CurrentLines(); if(ls[0])ls[0].classification={sellable:2,quarantine:0,damaged:0,expired:2}; if(ls[1])ls[1].classification={sellable:5,quarantine:0,damaged:0,expired:0};
          }
          if(x.f==='UIF-13'&&x.s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
          if(x.f==='UIF-14'&&x.s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}
          render();}''',{'f':f,'s':s,'st':st})
        p.wait_for_timeout(20)
        loc=p.locator('#app-screen'); box=loc.bounding_box() or {}; geometry.append((f,s,st,round(box.get('width',0)),round(box.get('height',0))))
        template_rows.append((f,s,st,p.locator('#app-screen .v-page-scaffold').get_attribute('data-figma-template')))
        png=loc.screenshot(); fn=OUT/f'{i:02d}-{f}-{s}-{st}.png'; fn.write_bytes(png); files.append(fn)
    b.close()
# full contact sheet
thumb_w,thumb_h=201,437; label_h=34; cols=5; gap=12; pad=16; rows=(len(files)+cols-1)//cols
sheet=Image.new('RGB',(pad*2+cols*thumb_w+(cols-1)*gap,pad*2+rows*(thumb_h+label_h)+(rows-1)*gap),'white'); d=ImageDraw.Draw(sheet); font=ImageFont.load_default()
for i,fn in enumerate(files):
    im=Image.open(fn).convert('RGB').resize((thumb_w,thumb_h),Image.Resampling.LANCZOS); r,c=divmod(i,cols); x=pad+c*(thumb_w+gap); y=pad+r*(thumb_h+label_h+gap); label=fn.stem.split('-',1)[1]; d.text((x,y),label,fill='black',font=font); sheet.paste(im,(x,y+label_h))
contact=OUT/'PHASE-5-HOLISTIC-CONTACT-SHEET-v2.1.1.png'; sheet.save(contact)
# split review sheets of max 10 specimens for manual inspection
for g,start in enumerate(range(0,len(files),10),1):
    subset=files[start:start+10]; cols2=5; rows2=(len(subset)+4)//5
    sh=Image.new('RGB',(pad*2+cols2*thumb_w+(cols2-1)*gap,pad*2+rows2*(thumb_h+label_h)+(rows2-1)*gap),'white'); dr=ImageDraw.Draw(sh)
    for j,fn in enumerate(subset):
        im=Image.open(fn).convert('RGB').resize((thumb_w,thumb_h),Image.Resampling.LANCZOS); rr,cc=divmod(j,cols2); x=pad+cc*(thumb_w+gap); y=pad+rr*(thumb_h+label_h+gap); dr.text((x,y),fn.stem.split('-',1)[1],fill='black',font=font); sh.paste(im,(x,y+label_h))
    sh.save(OUT/f'PHASE-5-REVIEW-GROUP-{g}.png')
all_402=all(w==402 and h==874 for _,_,_,w,h in geometry)
report=Path(__file__).resolve().parent/'VISUAL-QA-v2.1.1.md'
report.write_text('\n'.join(['# Theme 7 Phase 5 — Visual QA v2.1.1','',f'- Specimens: **{len(files)}**',f'- UIF coverage: **{len(set(f for f,_,_ in CASES))}/17**',f'- Device geometry 402x874: **{"PASS" if all_402 else "FAIL"}**',f'- Browser page errors: **{len(errors)}**','- Review status: **PENDING_MANUAL_INSPECTION**','',f'- `Mobile / State` targeted specimens: **{sum(1 for *_,t in template_rows if t=="Mobile / State")}**','- Success/result specimens are expected to use `Mobile / Detail`; true full-content permission/empty cases may use `Mobile / State`.','', 'Contact sheet: `screenshots-v2.1.1/PHASE-5-HOLISTIC-CONTACT-SHEET-v2.1.1.png`','', 'The screenshots are Product-only 402x874 renders. Labels in the contact sheet are QA metadata outside Product UI.'])+'\n',encoding='utf-8')
print(json.dumps({'specimens':len(files),'uifs':len(set(f for f,_,_ in CASES)),'geometry402x874':all_402,'errors':errors,'stateSpecimens':sum(1 for *_,t in template_rows if t=='Mobile / State'),'contact':str(contact)},ensure_ascii=False))
