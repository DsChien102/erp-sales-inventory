#!/usr/bin/env python3
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re

ROOT=Path(__file__).resolve().parents[1]
QA=Path(__file__).resolve().parent
PKG=Path(__file__).resolve().parents[6]
CAP=QA/'v391-bj01-captures'
CAP.mkdir(exist_ok=True)

idx=(ROOT/'index.html').read_text(encoding='utf-8')
styles=[]
for fn in re.findall(r'<link rel="stylesheet" href="([^"]+\.css)"',idx):
    p=ROOT/fn
    if p.exists():
        styles.append(p.read_text(encoding='utf-8'))
        idx=re.sub(rf'\s*<link rel="stylesheet" href="{re.escape(fn)}"\s*/?>','',idx)
html=idx.replace('</head>','<style>'+"\n".join(styles)+'</style></head>')
for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',html):
    p=ROOT/fn.split('?')[0]
    html=html.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')

app=(ROOT/'app.js').read_text(encoding='utf-8')
data_entities=(PKG/'specs/themes/theme-07/srs/04-data-entities.md').read_text(encoding='utf-8')
uc_dir=PKG/'specs/themes/theme-07/srs/05-use-cases/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh'
ucs='\n'.join(x.read_text(encoding='utf-8') for x in sorted(uc_dir.glob('*.md')))
flow=(PKG/'specs/themes/theme-07/prototype/flows/UIF-01-BJ-01.md').read_text(encoding='utf-8')
scr003=(PKG/'specs/themes/theme-07/prototype/contracts/screens/SCR-003.md').read_text(encoding='utf-8')

checks=[]; errors=[]; shots=[]
def ck(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})
def shot(page,name,label):
    fp=CAP/name
    page.locator('#device-preview').screenshot(path=str(fp))
    shots.append({'file':name,'label':label,'flow':page.evaluate('()=>activeFlowId'),'screen':page.evaluate('()=>activeScreenId')})

def set_bj01(page,screen='SCR-001',state='READY',product='INV-NOB'):
    page.evaluate("""([screen,state,product])=>{
      activeFlowId='UIF-01'; activeScreenId=screen; stateByScreen[screen]=state;
      bj01Filter='ALL'; bj01Query=''; bj01SelectedProductId=product;
      bj01LotOpen=false; bj01ProvenanceOpen=false; render();
    }""",[screen,state,product])

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1050})
    p.set_default_timeout(5000)
    p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)

    # SCR-001 canonical list
    set_bj01(p,'SCR-001','READY')
    ck('Runtime package identifies v3.9.1','v3.9.1' in idx)
    body=p.locator('#app-screen').inner_text()
    ck('List freshness is server snapshot wording', 'Dữ liệu đến 09:42, 27/08/2026' in body and 'Cập nhật 09:42' not in body, body[:300])
    oxy=p.locator('[data-bj01-product="INV-OXY"]')
    ck('NOT_CONFIGURED is explicit instead of silently NORMAL','Chưa có ngưỡng tồn' in oxy.inner_text(),oxy.inner_text())
    ty=p.locator('[data-bj01-product="INV-TYLO"]')
    ck('Product-level expiry copy is scoped to LOT','Có lô hết hạn' in ty.inner_text(),ty.inner_text())
    row_overflow=p.locator('[data-bj01-product] .ds24-list-row__copy small').evaluate_all("els=>els.filter(e=>e.scrollWidth>e.clientWidth+1).map(e=>({text:e.innerText,sw:e.scrollWidth,cw:e.clientWidth}))")
    ck('All-list decision phrases fit without subtitle ellipsis',not row_overflow,row_overflow)
    shot(p,'01-SCR001-ALL-SEMANTIC.png','SCR-001 with scoped indicators, query_as_of and NOT_CONFIGURED')

    p.locator('[data-bj01-filter="LOW"]').click()
    ty=p.locator('[data-bj01-product="INV-TYLO"]')
    ck('Selected LOW filter controls row attention phrase',ty.count()==1 and 'Tồn thấp' in ty.inner_text() and 'Có lô hết hạn' not in ty.inner_text(),ty.inner_text() if ty.count() else 'missing')
    shot(p,'02-SCR001-LOW-MULTI-INDICATOR.png','Multi-indicator product under LOW filter uses LOW phrase')

    p.locator('[data-bj01-filter="EXPIRED"]').click()
    ty=p.locator('[data-bj01-product="INV-TYLO"]')
    ck('Selected EXPIRED filter controls row attention phrase',ty.count()==1 and 'Có lô hết hạn' in ty.inner_text(),ty.inner_text() if ty.count() else 'missing')

    # Nobivac detail
    set_bj01(p,'SCR-003','READY','INV-NOB')
    summary=p.locator('[data-ds-role="inventory-product-summary"]')
    ck('Product identity does not use a metric badge',summary.locator('.ds24-badge').count()==0,summary.inner_text())
    emph=p.locator('.ds24-key-value-row--emphasis')
    ck('Availability is an Emphasis Key-value Row','Khả dụng' in emph.inner_text() and '106 hộp' in emph.inner_text(),emph.inner_text())
    detail=p.locator('#app-screen').inner_text()
    ck('Product supporting facts remain authoritative product-grain quantities',all(x in detail for x in ['Tồn vật lý\n120 hộp','Đủ điều kiện bán\n118 hộp','Đã giữ\n12 hộp']),detail[:800])
    ck('Physical-to-eligible difference is explained','Không đủ điều kiện bán' in detail and 'Cách ly\n2 hộp' in detail,detail[:900])
    ck('LOT list preserves source expiry precision and physical quantity','Lô DH2509' in detail and 'HSD 15/09/2026 · Tồn 50 hộp · Cận hạn' in detail,detail[-900:])
    shot(p,'03-SCR003-NOBIVAC-DETAIL.png','Availability as metric with eligibility breakdown and LOT list')

    p.locator('[data-bj01-lot="DH2509"]').click()
    sheet=p.locator('.ds24-sheet')
    st=sheet.inner_text()
    ck('LOT sheet does not invent reserved or available quantity','Tồn vật lý\n50 hộp' in st and 'Đủ điều kiện bán\n48 hộp' in st and 'Đã giữ' not in st and 'Khả dụng' not in st,st)
    ck('Near-expiry WARN explains sellability','Cận hạn' in st and 'vẫn đủ điều kiện bán theo chính sách hiện tại' in st,st)
    shot(p,'04-LOT-WARN-NO-RESERVATION.png','LOT detail has physical/eligible/expiry only')

    # Month precision fixture
    set_bj01(p,'SCR-003','READY','INV-TYLO')
    p.locator('[data-bj01-lot="TY2511"]').click()
    st=p.locator('.ds24-sheet').inner_text()
    ck('MONTH expiry precision is preserved on UI','HSD 11/2027' in st and '30/11/2027' not in st,st)
    p.click('[data-bj01-close-lot]')
    p.locator('[data-bj01-lot="TY2408"]').click()
    st=p.locator('.ds24-sheet').inner_text()
    ck('Expired LOT explains ineligibility','Hết hạn' in st and 'không đủ điều kiện bán' in st,st)

    # Provenance
    set_bj01(p,'SCR-003','READY','INV-NOB')
    p.locator('[data-bj01-provenance]').click()
    st=p.locator('.ds24-sheet').inner_text()
    ck('Provenance uses concrete snapshot, movement and reservation source',all(x in st for x in ['Dữ liệu đến\n09:42 · 27/08/2026','PN-260816-04 · +118 hộp','12 hộp · SO-260817-08']),st)
    ck('Generic VET45 source copy and vague scope copy are removed','Tồn kho VET45' not in st and 'Phạm vi số liệu' not in st,st)
    ck('Deep history remains a BJ15 handoff','Xem thẻ kho và lịch sử' in st,st)
    shot(p,'05-PROVENANCE-CONCRETE.png','Concrete provenance summary with BJ15 handoff')

    # STALE refresh semantics
    p.evaluate("()=>{bj01ProvenanceOpen=false; bj01QueryAsOf='09:42 · 27/08/2026'; bj01RefreshIndex=0; activeScreenId='SCR-003'; stateByScreen['SCR-003']='STALE'; render();}")
    before=p.locator('#app-screen').inner_text()
    p.locator('[data-bj01-refresh]').click()
    after=p.locator('#app-screen').inner_text()
    ck('Refresh advances only to response query_as_of fixture','Dữ liệu hiện tại đến 09:42 · 27/08/2026' in before and 'Dữ liệu đến 09:47, 27/08/2026' in after,after[:350])
    event_chunk=re.search(r'if \(event\.target\.closest\("\[data-bj01-refresh\]"\)\).*?\n',app)
    ck('BJ01 refresh handler does not use client Date()',event_chunk is not None and 'new Date' not in event_chunk.group(0),event_chunk.group(0).strip() if event_chunk else 'handler missing')

    # LOW copy / suggestion
    set_bj01(p,'SCR-003','READY','INV-AMX')
    txt=p.locator('#app-screen').inner_text()
    ck('LOW banner frames replenishment as a suggestion','Gợi ý bổ sung: 38 hộp' in txt and 'mức mục tiêu 80 hộp' in txt,txt[-600:])

    # Empty state
    set_bj01(p,'SCR-001','EMPTY')
    txt=p.locator('#app-screen').inner_text()
    ck('EMPTY means inventory data, not absence of product master','Chưa có dữ liệu tồn kho' in txt and 'Chưa có sản phẩm' not in txt,txt)

    # Visual frame / overflow on representative detail.
    set_bj01(p,'SCR-003','READY','INV-NOB')
    overflow=p.evaluate("""()=>{const el=document.querySelector('.phone-screen')||document.querySelector('#app-screen');return {sw:el.scrollWidth,cw:el.clientWidth};}""")
    ck('Representative BJ01 screen has no horizontal overflow',overflow['sw']<=overflow['cw']+1,overflow)
    b.close()

# Static semantic-contract checks.
start=app.index('const bj01Products = ['); end=app.index('let bj01Filter =',start)
fixture=app[start:end]
lot_objects=re.findall(r'\{\s*code:"[^"]+",\s*expiryDisplay:[^}]+\}',fixture)
ck('BJ01 LOT fixtures contain no reserved/available fields',bool(lot_objects) and all(not re.search(r'\b(reserved|available)\s*:',x) for x in lot_objects), f'{len(lot_objects)} LOT fixtures scanned')
ck('PRJ-01 explicitly forbids LOT reserved/available','**không có ở LOT**' in data_entities and '**không suy ra ở LOT**' in data_entities and 'PickAllocation authoritative' in data_entities)
ck('PRJ-08 separates stock level from expiry attention',all(x in data_entities for x in ['stock_level_status','expiry_attention','monitoring_config_status']))
ck('Active BJ01 use cases no longer reference retired screen routes',not re.search(r'SCR-002|SCR-054|SCR-056|SCR-057|SCR-060|SCR-061',ucs),'UC-01-01..05 scanned')
ck('Current UIF contract states LOT has no pre-allocation reserved/available','LOT chỉ show physical/eligible/expiry, không show reserved/available trước allocation' in flow)
ck('Current SCR-003 contract makes availability a metric, not badge','`Khả dụng` quay về canonical `DS v2 / Key-value Row`' in scr003 and 'Product identity là compact read-only context **không badge**' in scr003)
ck('No browser errors',not errors,errors)

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'version':'3.9.1','scope':'Wave 1 / BJ01 deep review','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors,'captures':shots}
(QA/'BJ01-DEEP-REVIEW-QA-v3.9.1.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
lines=['# BJ01 Deep Review QA — v3.9.1','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','', 'Scope: approved Wave 1 semantic hardening for BJ01 Tồn kho.','']
lines += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if x['note'] not in ('',None) and len(str(x['note']))<180 else '') for x in checks]
lines += ['', '## Captures','']+[f'- `{x["file"]}` — {x["label"]}' for x in shots]
(QA/'BJ01-DEEP-REVIEW-QA-v3.9.1.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(CAP/'manifest.json').write_text(json.dumps(shots,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(status,res['passed'],res['total'],'errors',len(errors),'captures',len(shots))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
