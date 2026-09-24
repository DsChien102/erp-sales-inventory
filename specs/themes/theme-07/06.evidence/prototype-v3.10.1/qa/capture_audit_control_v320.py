from pathlib import Path
import re
from PIL import Image,ImageOps,ImageDraw
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v320-audit-control-captures'
OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"\s*/?>',idx):
    p=ROOT/fn
    if p.exists(): styles.append(p.read_text(encoding='utf8'))
    idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
idx=idx.replace('</head>','<style>\n'+'\n'.join(styles)+'\n</style></head>')
for fn in re.findall(r'<script src="([^"]+\.js)"></script>',idx):
    p=ROOT/fn
    if p.exists(): idx=idx.replace(f'<script src="{fn}"></script>',f'<script>\n{p.read_text(encoding="utf8")}\n</script>')
SAMPLES=[
('UIF-08','SCR-042','READY','BJ08-SCR042-LIST'),('UIF-08','SCR-044','BLIND_COUNT','BJ08-SCR044-COUNT'),
('UIF-09','SCR-036','READY','BJ09-SCR036-LIST'),('UIF-09','SCR-056','READY','BJ09-SCR056-HISTORY'),
('UIF-10','SCR-036','READY','BJ10-SCR036-LIST'),('UIF-11','SCR-048','READY','BJ11-SCR048-LIST'),
('UIF-12','SCR-068','READY','BJ12-SCR068-VALIDATION'),('UIF-15','SCR-055','READY','BJ15-SCR055-REPORT'),
('UIF-16','SCR-078','READY','BJ16-SCR078-LIST'),('UIF-17','SCR-078','READY','BJ17-SCR078-LIST')]
shots=[]
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=browser.new_page(viewport={'width':1200,'height':1000})
    page.set_content(idx,wait_until='load')
    for u,s,st,name in SAMPLES:
        page.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st})
        loc=page.locator('#app-screen')
        path=OUT/f'{name}.png'
        loc.screenshot(path=str(path))
        shots.append((name,path))
    browser.close()
# contact sheet: 5 columns x 2 rows with labels
thumb_w,thumb_h=201,437
cell_w,cell_h=225,485
sheet=Image.new('RGB',(cell_w*5,cell_h*2),(246,248,249))
d=ImageDraw.Draw(sheet)
for i,(name,path) in enumerate(shots):
    im=Image.open(path).convert('RGB')
    im.thumbnail((thumb_w,thumb_h),Image.Resampling.LANCZOS)
    col,row=i%5,i//5
    x=col*cell_w+(cell_w-im.width)//2; y=row*cell_h+30
    sheet.paste(im,(x,y))
    d.text((col*cell_w+8,row*cell_h+8),name,fill=(14,17,22))
sheet.save(OUT/'AUDIT-CONTROL-CONTACT-SHEET-v3.2.0.png')
print(OUT/'AUDIT-CONTROL-CONTACT-SHEET-v3.2.0.png')
