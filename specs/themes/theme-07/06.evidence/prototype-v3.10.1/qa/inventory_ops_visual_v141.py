from pathlib import Path
from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v1.4.1'
SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8')
css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf8')
app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')

shots=[]
checks=[]
def check(name,cond): checks.append((name,bool(cond)))
def fresh(page):
    page.goto('about:blank')
    page.set_content(html,wait_until='load')
    page.wait_for_timeout(25)
def show(page,flow,screen,state='READY',setup=''):
    page.evaluate('''(x)=>{
      activeFlowId=x.f; activeScreenId=x.s; stateByScreen[x.s]=x.st;
      if(x.f==="UIF-02" && x.s==="SCR-009"){flowMode="document"; resetBj02Receipt("document");}
      if(x.setup){eval(x.setup);}
      render();
    }''',{'f':flow,'s':screen,'st':state,'setup':setup})
    page.wait_for_timeout(20)
def snap(page,name,label):
    path=SHOTS/f'{name}.png'
    page.locator('#device-preview').screenshot(path=str(path))
    im=Image.open(path)
    check(f'{name} screenshot is canonical 402x874',im.size==(402,874))
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
    check(f'{name} no horizontal overflow',g['sw']<=g['cw']+1)
    shots.append((path,label))

with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=b.new_page(viewport={'width':1400,'height':1050})
    errors=[]
    page.on('pageerror',lambda e: errors.append(str(e)))
    page.set_content(html,wait_until='load'); page.wait_for_timeout(25)

    # BJ01
    show(page,'UIF-01','SCR-001'); snap(page,'BJ01-SCR001-list','BJ01 · Tồn kho')
    show(page,'UIF-01','SCR-003'); snap(page,'BJ01-SCR003-detail','BJ01 · Chi tiết tồn kho')

    # BJ02
    fresh(page); show(page,'UIF-02','SCR-008',setup='flowMode="quick";'); snap(page,'BJ02-SCR008-quick','BJ02 · Thông tin lần nhận')
    fresh(page); show(page,'UIF-02','SCR-009',setup='flowMode="quick"; resetBj02Receipt("quick"); quickOverviewProductMenuOpen=true;'); snap(page,'BJ02-SCR009-search','BJ02 · Tìm sản phẩm')
    fresh(page); page.evaluate('flowMode="document"; resetBj02Receipt("document"); beginLineEditor("DOC-04-01");'); page.wait_for_timeout(20); snap(page,'BJ02-SCR084-editor','BJ02 · Chi tiết hàng thực nhận')

    # BJ04
    fresh(page); show(page,'UIF-04','SCR-021','FULL'); snap(page,'BJ04-SCR021-full','BJ04 · Giữ đủ hàng')
    fresh(page); show(page,'UIF-04','SCR-021','PARTIAL'); snap(page,'BJ04-SCR021-partial','BJ04 · Thiếu hàng')

    # BJ05
    fresh(page); show(page,'UIF-05','SCR-025'); snap(page,'BJ05-SCR025-queue','BJ05 · Đơn cần lấy')
    fresh(page); show(page,'UIF-05','SCR-026',setup='io05SelectedOrderId="SO-260827-24";'); snap(page,'BJ05-SCR026-waiting','BJ05 · Đơn đang chờ')
    fresh(page); show(page,'UIF-05','SCR-026',setup='io05SelectedOrderId="SO-260827-21";'); snap(page,'BJ05-SCR026-pick','BJ05 · Hàng cần lấy')
    fresh(page); show(page,'UIF-05','SCR-028',setup='io05SelectedOrderId="SO-260827-21"; io05ResetHandover();'); snap(page,'BJ05-SCR028-review','BJ05 · Rà soát bàn giao')

    # BJ06
    fresh(page); show(page,'UIF-06','SCR-030'); snap(page,'BJ06-SCR030-queue','BJ06 · Hàng khách trả')
    fresh(page); show(page,'UIF-06','SCR-031',setup='io06SelectedRequestId="RET-260827-07"; io06RefreshRequestState(io06CurrentRequest());'); snap(page,'BJ06-SCR031-waiting','BJ06 · Chờ duyệt lô')
    fresh(page); show(page,'UIF-06','SCR-032',setup='io06SelectedRequestId="RET-260827-03"; io06ActiveLineId="RET-L1A"; var l=io06ActiveLine(); l.qty=2; l.actualLot="DH2509"; l.actualLotMode="OTHER"; l.verified=true; l.reasonCode="ACTUAL_DIFF"; l.evidenceFile="lot.jpg"; l.evidenceData=io06EvidenceSvg("DH2509");'); snap(page,'BJ06-SCR032-mismatch','BJ06 · Ngoại lệ lô')
    fresh(page); show(page,'UIF-06','SCR-034','TASK_LIST',setup='io06ApproverListMode=true;'); snap(page,'BJ06-SCR034-approval-list','BJ06 · Ngoại lệ cần duyệt')
    fresh(page); show(page,'UIF-06','SCR-033',setup='io06SelectedRequestId="RET-260827-05";'); snap(page,'BJ06-SCR033-classify','BJ06 · Phân loại hàng trả')

    # BJ07 - include the Product-reported queue and downstream surfaces.
    fresh(page); show(page,'UIF-07','SCR-036'); snap(page,'BJ07-SCR036-queue','BJ07 · Hàng chờ trả NCC')
    fresh(page); show(page,'UIF-07','SCR-037',setup='io07Selected="RTV-260827-02";'); snap(page,'BJ07-SCR037-prepare','BJ07 · Chuẩn bị hàng trả')
    page.click('[data-io07-allocation="RTV-A1"]'); snap(page,'BJ07-SCR037-verify-sheet','BJ07 · Kiểm phần hàng')
    fresh(page); show(page,'UIF-07','SCR-039',setup='io07Selected="RTV-260827-02"; io07Allocations().forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;}); io07Current().reviewSourceVersion=io07Current().sourceVersion;'); snap(page,'BJ07-SCR039-review','BJ07 · Rà soát bàn giao')
    fresh(page); show(page,'UIF-07','SCR-041','UNKNOWN'); snap(page,'BJ07-SCR041-unknown','BJ07 · Đang xác minh')

    check('No page JavaScript errors',not errors)
    b.close()

# Contact sheet at half scale to review all representative screens together.
thumb_w,thumb_h=201,437
label_h=34
cols=4
rows=(len(shots)+cols-1)//cols
sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white')
draw=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
    im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h))
    x=(i%cols)*thumb_w; y=(i//cols)*(thumb_h+label_h)
    sheet.paste(im,(x,y))
    draw.text((x+6,y+thumb_h+7),label,fill='black')
contact=SHOTS/'INVENTORY-OPERATIONS-CONTACT-SHEET-v1.4.1.png'
sheet.save(contact)

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Inventory Operations Visual QA v1.4.1','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       f'- {len(shots)} representative Product screenshots captured at the canonical 402×874 canvas.',
       '- Coverage includes every Inventory Operations BJ/UIF and specifically the BJ07 waiting-card correction.',
       '- Each specimen checks exact viewport capture and horizontal-overflow safety.',
       '- Visual QA is evidence for Product review; it is not Product approval.','',
       '## Specimens','']+[f'- `{path.name}` — {label}' for path,label in shots]+['','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines += ['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'VISUAL-QA-v1.4.1.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'checks;',len(shots),'screenshots')
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
