from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css']
css='\n'.join((ROOT/x).read_text() for x in cssfiles)
html=idx
for x in cssfiles: html=html.replace(f'<link rel="stylesheet" href="{x}" />','')
html=html.replace('</head>',f'<style>{css}</style></head>')
html=(html.replace('<script src="workbench-data.js"></script>',f'<script>{(ROOT/"workbench-data.js").read_text()}</script>')
          .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{(ROOT/"figma-ds-runtime-map.js").read_text()}</script>')
          .replace('<script src="app.js"></script>',f'<script>{(ROOT/"app.js").read_text()}</script>'))
checks=[]
def chk(name,ok,note=''):
    checks.append({'name':name,'pass':bool(ok),'note':note})

app=(ROOT/'app.js').read_text()
bj04css=(ROOT/'v260-bj04-ds-fidelity.css').read_text()
flow=(ROOT.parent/'flows/UIF-04-BJ-04.md').read_text()
contract=(ROOT.parent/'contracts/screens/SCR-021.md').read_text()
usage=(ROOT.parent/'contracts/component-usage/UIF-04-COMPONENT-USAGE.md').read_text()
wb=json.loads((ROOT/'workbench-data.json').read_text())
uif04=next(f for f in wb['flows'] if f['id']=='UIF-04')

chk('BJ04 CSS contains no raw hex colors', not re.search(r'#[0-9a-fA-F]{3,8}',bj04css))
chk('BJ04 CSS contains no raw rgb/rgba colors', not re.search(r'rgba?\(',bj04css))
selectors=[line.strip() for line in bj04css.splitlines() if line.strip().startswith(('.', 'body[')) and '{' in line]
chk('BJ04 fidelity selectors are UIF-04 scoped', all(line.startswith('body[data-active-uif="UIF-04"]') for line in selectors), str([x for x in selectors if not x.startswith('body[data-active-uif="UIF-04"]')]) )
chunk=app[app.find('function bj04ReservationRow'):app.find('function render025IO05')]
chk('Active BJ04 renderer uses List Row', 'data-ds-component="DS v2 / List Row"' in chunk and 'data-figma-node="525:519"' in chunk)
chk('Active BJ04 renderer uses Info Row composition', 'ds24InfoRow("Kho"' in chunk and 'ds24InfoRow("Trạng thái đơn"' in chunk)
chk('Active BJ04 renderer does not use legacy read-card/card grouping', 'ioReadCard(' not in chunk and 'data-ds-component="VCard"' not in chunk)
chk('Active BJ04 renderer has no mutation footer/button helper', 'primaryFooter(' not in chunk and 'ioSecondary(' not in chunk)
chk('BJ04 source/system-driven rule is retained in contracts', 'source/system-driven' in usage and 'không' in contract.lower() and 'No `VButton`' in usage)
chk('BJ04 contract explicitly forbids cross-UOM shortage aggregation', 'không cộng số lượng giữa các uom khác nhau' in contract.lower())
chk('UIF-04 active flow exposes only SCR-021', uif04.get('screens')==['SCR-021'], str(uif04.get('screens')))
chk('order-context deep link resolves directly to SCR-021', 'activeFlowId === "UIF-04" && entryMode === "order-context"' in app and 'activeScreenId = "SCR-021"' in app)

errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100})
    p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    def set_state(st):
        p.evaluate('''(st)=>{activeFlowId='UIF-04';activeScreenId='SCR-021';stateByScreen['SCR-021']=st;render();}''',st)
    set_state('PARTIAL')
    txt=p.locator('#app-screen').inner_text()
    chk('AppBar keeps canonical screen name and order context', 'Giữ hàng theo đơn' in txt and 'Đơn SO-260827-18' in txt)
    chk('Visible Product UI removes redundant Chỉ xem label', 'Chỉ xem' not in txt)
    chk('Context is two canonical Info Rows', p.locator('#app-screen [data-ds-component="DS v2 / Info Row"]').count()==2)
    info_sizes=p.locator('#app-screen [data-ds-component="DS v2 / Info Row"]').evaluate_all('(els)=>els.map(e=>({w:e.getBoundingClientRect().width,h:e.getBoundingClientRect().height}))')
    chk('Info Row geometry is 338x44', all(abs(x['w']-338)<=.5 and abs(x['h']-44)<=.5 for x in info_sizes), str(info_sizes))
    chk('Reservation projection uses two non-interactive Status List Rows', p.locator('#app-screen .bj04-reservation-row[data-ds-prop-type="Status"]').count()==2 and p.locator('#app-screen button.bj04-reservation-row').count()==0)
    chk('PARTIAL has exactly one Warning banner', p.locator('#app-screen .v-banner--warning').count()==1 and p.locator('#app-screen .v-banner').count()==1)
    chk('PARTIAL surfaces shortage only on affected row', p.locator('#app-screen .bj04-reservation-row .ds24-badge--warning').count()==1 and 'Thiếu 8 hộp' in txt)
    chk('PARTIAL does not aggregate shortage into a cross-UOM quantity banner', 'Còn thiếu 8' not in txt and '1 sản phẩm thiếu' in txt)
    banner_h=p.locator('#app-screen .v-banner').evaluate('(e)=>e.getBoundingClientRect().height')
    chk('PARTIAL compact VBanner stays within 72px', banner_h<=72.5, str(banner_h))
    chk('Read-only surface exposes only Back button', p.locator('#app-screen button').count()==1 and p.locator('#app-screen .app-actions').count()==0)
    chk('Back is wired to source-order context exit', p.locator('#app-screen [data-action="exit-reservation-context"]').count()==1)
    shell=p.locator('#app-screen .v-page-scaffold').evaluate('(e)=>({w:e.getBoundingClientRect().width,h:e.getBoundingClientRect().height,overflow:e.scrollWidth-e.clientWidth})')
    chk('Canonical mobile canvas is 402x874 without horizontal overflow', abs(shell['w']-402)<=.5 and abs(shell['h']-874)<=.5 and shell['overflow']<=.5, str(shell))

    set_state('FULL')
    txt=p.locator('#app-screen').inner_text()
    chk('FULL has no semantic banner or status badge noise', p.locator('#app-screen .v-banner').count()==0 and p.locator('#app-screen .ds24-badge').count()==0 and 'Đủ' not in txt)
    chk('FULL shows authoritative need/held facts', 'Cần 50 hộp · Đã giữ 50 hộp' in txt)

    set_state('RELEASED')
    txt=p.locator('#app-screen').inner_text()
    chk('RELEASED uses one Info banner and no shortage badge', p.locator('#app-screen .v-banner--info').count()==1 and p.locator('#app-screen .ds24-badge--warning').count()==0 and 'Thiếu' not in txt)
    chk('RELEASED does not masquerade as shortage', 'Sản phẩm đã nhả' in txt and 'Cần trước đó 50 hộp · Đã giữ 0 hộp' in txt)
    banner_h=p.locator('#app-screen .v-banner').evaluate('(e)=>e.getBoundingClientRect().height')
    chk('RELEASED compact VBanner stays within 72px', banner_h<=72.5, str(banner_h))

    set_state('STALE')
    txt=p.locator('#app-screen').inner_text()
    chk('STALE presents reconciled latest projection, no technical retry', 'Tình trạng đã được cập nhật' in txt and 'Thử lại' not in txt and 'Làm mới' not in txt)
    banner_h=p.locator('#app-screen .v-banner').evaluate('(e)=>e.getBoundingClientRect().height')
    chk('STALE compact VBanner stays within 72px', banner_h<=72.5, str(banner_h))

    set_state('LOADING')
    chk('LOADING uses VSkeleton', p.locator('#app-screen [data-ds-component="VSkeleton"]').count()==1)
    set_state('PERMISSION_DENIED')
    chk('PERMISSION_DENIED uses VEmptyState', p.locator('#app-screen [data-ds-component="VEmptyState"]').count()==1)

    set_state('PARTIAL')
    inspector=p.locator('#traceability').inner_text()
    chk('Inspect reports BJ04 current migrated/reviewed status', ('v2.6.0 · BJ04 Figma DS migrated' in inspector) or ('v2.7.3 · BJ04 migrated + reviewed' in inspector))
    b.close()

chk('No browser page errors during BJ04 QA', not errors, '; '.join(errors))
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'checks':checks,'passed':sum(x['pass'] for x in checks),'total':len(checks),'browserErrors':errors}
(OUT/'BJ04-FIGMA-DS-QA-v2.6.0.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ04 Figma DS / Product QA — v2.6.0','',f'**Result: {status} · {res["passed"]}/{res["total"]} checks**','']
for x in checks: lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else ''))
(OUT/'BJ04-FIGMA-DS-QA-v2.6.0.md').write_text('\n'.join(lines)+'\n')
print(status,res['passed'],res['total'])
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL:',x['name'],x['note'])
    raise SystemExit(1)
