from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageDraw
import re
ROOT=Path(__file__).resolve().parents[1];OUT=Path(__file__).resolve().parent/'v293-migrated-all';OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for line in list(idx.splitlines()):
 if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:idx=idx.replace(line+'\n','').replace(line,'')
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
 p=ROOT/fn
 if p.exists():styles.append(p.read_text(encoding='utf-8'));idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in ['workbench-data.js','figma-ds-runtime-map.js','app.js']:html=html.replace(f'<script src="{fn}"></script>',f'<script>{(ROOT/fn).read_text(encoding="utf-8")}</script>')
flows=['UIF-01','UIF-02','UIF-04','UIF-05','UIF-06','UIF-07','UIF-08']; captures=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1600,'height':1000});p.set_content(html,wait_until='load',timeout=30000)
 for fid in flows:
  ids=p.evaluate('fid=>flowCatalog.find(f=>f.id===fid).screens',fid)
  for sid in ids:
   setup=''
   if fid=='UIF-01':setup="if(typeof bj01SelectedProductId!=='undefined')bj01SelectedProductId='P-001';"
   elif fid=='UIF-05':setup="io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';io05PickEditorOpen=false;io05OverrideOpen=false;"
   elif fid=='UIF-06':setup="io06SelectedRequestId=(['SCR-031','SCR-032'].includes('"+sid+"'))?'RET-260827-03':'RET-260827-05';io06ClassificationOpen=false;if('"+sid+"'==='SCR-032')io06ActiveLineId='RET-L1A';if('"+sid+"'==='SCR-035')io06CurrentRequest().classified=true;"
   elif fid=='UIF-07':setup="io07Selected='RTV-260827-02';io07VerifySheetOpen=false;if('"+sid+"'==='SCR-037'){const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=false;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});}if('"+sid+"'==='SCR-039'){const r=io07Current();io07Allocations(r).forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false});r.reviewSourceVersion=r.sourceVersion;}"
   state='READY'
   if fid=='UIF-08' and sid=='SCR-044':state='BLIND_COUNT'
   if fid=='UIF-08' and sid=='SCR-045':state='RECOUNT_REQUIRED'
   if fid=='UIF-08' and sid=='SCR-046':state='APPROVAL_REQUIRED'
   if fid=='UIF-06' and sid=='SCR-034':state='TASK_LIST'
   if fid=='UIF-06' and sid=='SCR-035':state='COMPLETED'
   if fid=='UIF-07' and sid=='SCR-041':state='COMPLETED'
   p.evaluate("([fid,sid,state,setup])=>{activeFlowId=fid;eval(setup);activeScreenId=sid;stateByScreen[sid]=state;render();}",[fid,sid,state,setup]);p.wait_for_timeout(10)
   name=f'{fid}-{sid}.png';p.locator('#app-screen').screenshot(path=str(OUT/name));captures.append(OUT/name)
 b.close()
# contact sheet
thumb_w,thumb_h=190,440; label_h=20;cols=5
thumbs=[]
for f in captures:
 im=Image.open(f).convert('RGB');im.thumbnail((thumb_w-10,thumb_h-30));c=Image.new('RGB',(thumb_w,thumb_h),(255,255,255));c.paste(im,((thumb_w-im.width)//2,4));ImageDraw.Draw(c).text((5,thumb_h-label_h),f.stem,fill='black');thumbs.append(c)
rows=(len(thumbs)+cols-1)//cols;sheet=Image.new('RGB',(cols*thumb_w,rows*thumb_h),(235,238,240))
for i,t in enumerate(thumbs):sheet.paste(t,((i%cols)*thumb_w,(i//cols)*thumb_h))
sheet.save(OUT/'CONTACT-SHEET.jpg',quality=86)
print('captured',len(captures),'migrated canonical screens')
