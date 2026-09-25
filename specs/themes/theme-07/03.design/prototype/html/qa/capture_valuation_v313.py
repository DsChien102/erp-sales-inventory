from pathlib import Path
from playwright.sync_api import sync_playwright
from PIL import Image,ImageOps,ImageDraw
import re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent/'v313-valuation-captures';OUT.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf-8');styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    q=ROOT/fn
    if q.exists():styles.append(q.read_text(encoding='utf-8'));idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    q=ROOT/fn.split('?')[0];html=html.replace(f'<script src="{fn}"></script>',f'<script>{q.read_text(encoding="utf-8")}</script>' if q.exists() else '')
shots=[]
def snap(p,name):
    path=OUT/f'{len(shots)+1:02d}-{name}.png';p.locator('#device-preview').screenshot(path=str(path));shots.append(path)
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100});p.set_content(html,wait_until='load');p.set_default_timeout(5000)
    p.evaluate("activeFlowId='UIF-03';activeScreenId='SCR-014';stateByScreen['SCR-014']='READY';render()");snap(p,'BJ03-worklist')
    p.locator('[data-v313-val03-receipt="VAL03-R2"]').click();snap(p,'BJ03-quick-missing-basis');p.locator('[data-v313-val03-add-basis]').click();snap(p,'BJ03-direct-basis-sheet')
    p.evaluate("v313Val03Sheet=null;activeScreenId='SCR-014';render()");p.locator('[data-v313-val03-receipt="VAL03-R1"]').click();snap(p,'BJ03-document-conflict')
    # select ready group then review
    p.locator('[data-v313-val03-select]').first.click();p.locator('[data-v313-val03-review]').click();snap(p,'BJ03-review')
    p.evaluate("activeFlowId='UIF-13';activeScreenId='SCR-085';stateByScreen['SCR-085']='READY';render()");snap(p,'BJ13-worklist')
    p.locator('[data-v313-val13-task="LC13-004"]').click();snap(p,'BJ13-scope-allocation-negative');p.locator('[data-v313-val13-review]').click();snap(p,'BJ13-review-negative')
    p.evaluate("activeFlowId='UIF-14';activeScreenId='SCR-072';stateByScreen['SCR-072']='READY';render()");snap(p,'BJ14-worklist')
    p.locator('[data-v313-val14-run="COST-0903"]').click();snap(p,'BJ14-dirty-setup')
    p.evaluate("activeScreenId='SCR-072';render()");p.locator('[data-v313-val14-run="COST-0826"]').click();snap(p,'BJ14-ready-review');p.locator('[data-v313-val14-open-publish]').click();snap(p,'BJ14-publish-sheet')
    b.close()
# contact sheet 4 cols
ims=[Image.open(x).convert('RGB') for x in shots]
cellw=max(i.width for i in ims)+20;cellh=max(i.height for i in ims)+50;cols=4;rows=(len(ims)+cols-1)//cols
sheet=Image.new('RGB',(cellw*cols,cellh*rows),'white');d=ImageDraw.Draw(sheet)
for j,(im,path) in enumerate(zip(ims,shots)):
    x=(j%cols)*cellw+10;y=(j//cols)*cellh+28;sheet.paste(im,(x,y));d.text((x,8+(j//cols)*cellh),path.stem,fill='black')
sheet.save(OUT/'VALUATION-CONTACT-SHEET-v3.13.0.png')
print(OUT/'VALUATION-CONTACT-SHEET-v3.13.0.png')
