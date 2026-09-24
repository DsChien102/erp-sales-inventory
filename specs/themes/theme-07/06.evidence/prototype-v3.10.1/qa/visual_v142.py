from pathlib import Path
from PIL import Image, ImageDraw
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
SHOTS=OUT/'screenshots-v1.4.2'
SHOTS.mkdir(exist_ok=True)
idx=(ROOT/'index.html').read_text(encoding='utf8')
css=(ROOT/'tokens.generated.css').read_text(encoding='utf8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf8')
app=(ROOT/'app.js').read_text(encoding='utf8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]; shots=[]
def check(n,c): checks.append((n,bool(c)))
def fresh(page):
    page.goto('about:blank'); page.set_content(html,wait_until='load'); page.wait_for_timeout(35)
def show(page,flow,screen,state='READY',setup=''):
    page.evaluate('''(x)=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;if(x.setup){eval(x.setup);}render();}''',{'f':flow,'s':screen,'st':state,'setup':setup}); page.wait_for_timeout(25)
def snap(page,name,label):
    path=SHOTS/f'{name}.png'; page.locator('#device-preview').screenshot(path=str(path)); im=Image.open(path)
    check(f'{name}: canonical 402x874',im.size==(402,874))
    g=page.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
    check(f'{name}: no horizontal overflow',g['sw']<=g['cw']+1)
    shots.append((path,label))

with sync_playwright() as p:
    b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    page=b.new_page(viewport={'width':1400,'height':1100}); errors=[]; page.on('pageerror',lambda e: errors.append(str(e)))

    # BJ01 benchmark
    fresh(page); show(page,'UIF-01','SCR-003'); snap(page,'BJ01-SCR003-benchmark','BJ01 · Product / LOT benchmark')

    # BJ02 selection affordance + LOT semantics
    fresh(page); show(page,'UIF-02','SCR-009',setup='flowMode="quick"; resetBj02Receipt("quick"); quickOverviewProductMenuOpen=true;'); snap(page,'BJ02-SCR009-product-search','BJ02 · Chọn sản phẩm')
    fresh(page); show(page,'UIF-02','SCR-010',setup='flowMode="document"; resetBj02Receipt("document"); var l=bj02Lines[0]; l.status="COMPLETED"; l.lots=[{id:1,code:"ND2408",expiry:"30/11/2026",accepted:120,quarantine:0,damaged:0,rejected:0}]; render();'); snap(page,'BJ02-SCR010-review','BJ02 · Lô có nhãn')

    # BJ03 semantic scope / calculation / review / result
    fresh(page); show(page,'UIF-03','SCR-014'); snap(page,'BJ03-SCR014-queue','BJ03 · Danh sách chờ giá')
    page.click('[data-val03-receipt="VAL03-R1"]'); page.click('[data-val03-slice="VAL03-S1"]'); page.locator('[data-val03-qty="VAL03-S1"]').fill('50'); page.click('[data-val03-slice="VAL03-S2"]'); snap(page,'BJ03-SCR015-scope','BJ03 · Phạm vi xác nhận giá')
    page.click('[data-val03-action="open-calculation"]'); snap(page,'BJ03-SCR016-calculation','BJ03 · Căn cứ / phạm vi')
    # resolve conflict if present, then review
    if page.locator('[data-val03-source="VAL03-G2"][data-val03-source-id="SUP"]').count():
        page.click('[data-val03-source="VAL03-G2"][data-val03-source-id="SUP"]')
        page.locator('[data-val03-reason="VAL03-G2"]').fill('Căn cứ mới nhất')
    page.click('[data-val03-action="open-review"]'); snap(page,'BJ03-SCR017-review','BJ03 · Giá trị sẽ ghi')
    page.click('[data-val03-action="confirm-value"]'); snap(page,'BJ03-SCR019-completed','BJ03 · Kết quả theo Product')

    # BJ04 benchmark
    fresh(page); show(page,'UIF-04','SCR-021','PARTIAL'); snap(page,'BJ04-SCR021-benchmark','BJ04 · Role số lượng benchmark')

    # BJ05 queue / partial / review
    fresh(page); show(page,'UIF-05','SCR-025'); snap(page,'BJ05-SCR025-queue','BJ05 · Queue gọn')
    fresh(page); show(page,'UIF-05','SCR-026',setup='io05SelectedOrderId="SO-260827-21";'); snap(page,'BJ05-SCR026-partial','BJ05 · Partial handover cue')
    fresh(page); show(page,'UIF-05','SCR-028',setup='io05SelectedOrderId="SO-260827-21"; io05ResetHandover();'); snap(page,'BJ05-SCR028-review','BJ05 · Product / LOT review')

    # BJ06 physical evidence and grouped result
    fresh(page); show(page,'UIF-06','SCR-031',setup='io06SelectedRequestId="RET-260827-03"; io06RefreshRequestState(io06CurrentRequest());'); snap(page,'BJ06-SCR031-source-lot','BJ06 · Lô giao / lô thực nhận')
    fresh(page); show(page,'UIF-06','SCR-031',setup='io06SelectedRequestId="RET-260827-03"; var l=io06CurrentLines()[0]; l.qty=2;l.actualLot="DH2509";l.actualLotMode="OTHER";l.verified=true;l.reasonCode="ACTUAL_DIFF";l.evidenceFile="lot.jpg";l.evidenceData=io06EvidenceSvg("DH2509"); io06RefreshRequestState(io06CurrentRequest());'); snap(page,'BJ06-SCR031-wrong-lot','BJ06 · Lô thực nhận khác')
    fresh(page); show(page,'UIF-06','SCR-034','TASK_LIST',setup='io06SelectedRequestId="RET-260827-07"; io06SelectedApprovalCaseId="EX-06-001"; io06ApproverListMode=false; io06ActiveLineId="RET-L6";'); snap(page,'BJ06-SCR034-evidence','BJ06 · Vai trò ảnh bằng chứng')
    fresh(page); show(page,'UIF-06','SCR-035','COMPLETED',setup='io06SelectedRequestId="RET-260827-05"; var ls=io06CurrentLines(); ls[0].classification={sellable:1,quarantine:1,damaged:0,expired:2}; ls[1].classification={sellable:4,quarantine:1,damaged:0,expired:0}; io06CurrentRequest().classified=true;'); snap(page,'BJ06-SCR035-result','BJ06 · Kết quả Product → LOT')

    # BJ07 source queue, Product→LOT task hierarchy, verify sheet, review, result
    fresh(page); show(page,'UIF-07','SCR-036'); snap(page,'BJ07-SCR036-queue','BJ07 · Hàng chờ trả NCC')
    fresh(page); show(page,'UIF-07','SCR-037',setup='io07Selected="RTV-260827-02";'); snap(page,'BJ07-SCR037-prepare','BJ07 · Product → lô cần kiểm')
    page.click('[data-io07-allocation="RTV-A1"]'); page.wait_for_timeout(250); snap(page,'BJ07-SCR037-verify-sheet','BJ07 · Đối chiếu LOT')
    fresh(page); show(page,'UIF-07','SCR-039',setup='io07Selected="RTV-260827-02"; io07Allocations().forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;}); io07Current().reviewSourceVersion=io07Current().sourceVersion;'); snap(page,'BJ07-SCR039-review','BJ07 · Bàn giao Product → LOT')
    # completed fixture
    fresh(page); show(page,'UIF-07','SCR-041','COMPLETED',setup='io07Selected="RTV-260827-02"; io07Allocations().forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;});'); snap(page,'BJ07-SCR041-completed','BJ07 · Kết quả Product → LOT')

    check('No page JavaScript errors',not errors)
    b.close()

# contact sheet at half scale
thumb_w,thumb_h=201,437; label_h=34; cols=4; rows=(len(shots)+cols-1)//cols
sheet=Image.new('RGB',(cols*thumb_w,rows*(thumb_h+label_h)),'white'); draw=ImageDraw.Draw(sheet)
for i,(path,label) in enumerate(shots):
    im=Image.open(path).convert('RGB').resize((thumb_w,thumb_h)); x=(i%cols)*thumb_w; y=(i//cols)*(thumb_h+label_h)
    sheet.paste(im,(x,y)); draw.text((x+5,y+thumb_h+6),label,fill='black')
contact=SHOTS/'SEMANTIC-HIERARCHY-CONTACT-SHEET-v1.4.2.png'; sheet.save(contact)
passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Semantic Hierarchy Visual QA v1.4.2','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       f'- {len(shots)} representative screenshots captured at canonical 402×874.',
       '- Focus: 2-second semantic scan, Product/UOM parent vs LOT/allocation child, read-only fact vs task/action affordance, and stable vocabulary.',
       '- BJ01/BJ04 are retained as visual benchmarks; BJ02/BJ03/BJ05/BJ06/BJ07 cover the corrected surfaces.',
       '- Visual QA is evidence for Product review; it does not replace Product approval.','', '## Specimens','']+[f'- `{p.name}` — {l}' for p,l in shots]+['','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if errors: lines += ['','## Page errors']+[f'- {e}' for e in errors]
(OUT/'VISUAL-QA-v1.4.2.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'checks;',len(shots),'screenshots')
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
