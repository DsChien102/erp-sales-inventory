from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text()
for line in list(idx.splitlines()):
    if 'fonts.googleapis.com' in line or 'fonts.gstatic.com' in line:
        idx=idx.replace(line+'\n','').replace(line,'')
cssfiles=['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css','bj01-ds-fidelity.css','bj02-ds-fidelity.css','v251-ui-ds-corrections.css','v252-bj02-quick-flow-ui.css','v252-figma-live-sync.css','v253-info-row-live-sync.css','v254-bj02-input-ux-correction.css','v255-bj02-review-density.css','v260-bj04-ds-fidelity.css','v270-bj05-ds-fidelity.css','v271-figma-ds-corrections.css','v272-detail-composition-fidelity.css','v273-ui-hardening.css','v274-figma-ds-hard-gate.css']
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
bj05css=(ROOT/'v270-bj05-ds-fidelity.css').read_text()
flow=(ROOT.parent/'flows/UIF-05-BJ-05.md').read_text()
usage=(ROOT.parent/'contracts/component-usage/UIF-05-COMPONENT-USAGE.md').read_text()
contract026=(ROOT.parent/'contracts/screens/SCR-026.md').read_text()
wb=json.loads((ROOT/'workbench-data.json').read_text())
status=json.loads((ROOT.parent/'contracts/figma-ds/UIF-MIGRATION-STATUS.json').read_text())
uif05=next(f for f in wb['flows'] if f['id']=='UIF-05')
chunk=app[app.find('function bj05DsTone'):app.find('function render030IO06')]

chk('BJ05 CSS contains no raw hex colors', not re.search(r'#[0-9a-fA-F]{3,8}',bj05css))
chk('BJ05 CSS contains no raw rgb/rgba colors', not re.search(r'rgba?\(',bj05css))
clean=re.sub(r'/\*.*?\*/','',bj05css,flags=re.S)
selectors=[]
for block in clean.split('}'):
    if '{' not in block: continue
    sel=block.split('{',1)[0].strip()
    if not sel or sel.startswith('@'): continue
    selectors.extend(x.strip() for x in sel.split(',') if x.strip())
chk('BJ05 fidelity selectors are UIF-05 scoped', all(x.startswith('body[data-active-uif="UIF-05"]') for x in selectors), str([x for x in selectors if not x.startswith('body[data-active-uif="UIF-05"]')]) )
chk('Active BJ05 renderer has no generic VCard/read-card wrappers', 'ioReadCard(' not in chunk and 'data-ds-component="VCard"' not in chunk)
chk('Active BJ05 renderer removes non-canonical VQuantitySelector', 'VQuantitySelector' not in chunk)
chk('Active BJ05 renderer removes legacy VTextFormField reason input', 'VTextFormField' not in chunk and 'data-ds-component="VTextarea"' in chunk)
chk('LOT override uses exact Form Sheet pattern node', 'data-ds-pattern="DS v2 / Form Sheet"' in chunk and 'data-figma-node="1353:6355"' in chunk)
chk('LOT override uses List Row Selection + VRadio', 'data-ds-prop-type="Selection"' in chunk and 'data-ds-component="VRadio"' in chunk)
chk('LOT change is contextual Link, not repeated full secondary CTA', 'data-ds-component="DS v2 / Link"' in chunk and 'button--secondary button--full' not in chunk)
chk('Result uses ds24Result and not legacy ioResult', 'ds24Result(' in chunk and 'ioResult(' not in chunk)
chk('Current component contract declares Figma DS authority', 'Live Figma Design System is the UI authority' in usage and 'Flutter Design System remains UI authority' not in usage)
chk('UIF-05 migration status is review-ready', status['release']=='2.7.4' and 'UIF-05' in status['productWiringScope'] and next(x for x in status['uifs'] if x['uif']=='UIF-05')['productApproval']=='REVIEW_READY')
chk('UIF-05 active flow remains exactly SCR-025..029', uif05.get('screens')==['SCR-025','SCR-026','SCR-027','SCR-028','SCR-029'], str(uif05.get('screens')))
chk('Locked physical stock rule remains documented', 'Pick chưa giảm physical' in contract026 and 'actual handover quantity' in flow)
chk('Locked stale correction rule remains documented', 'reset phần pick đó về 0' in flow and 'physical-correction' in flow)
chk('Locked UNKNOWN no-blind-retry rule remains documented', 'UNKNOWN không blind retry' in flow)

errors=[]
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    def page():
        p=b.new_page(viewport={'width':1440,'height':1100})
        p.set_default_timeout(5000)
        p.on('pageerror',lambda e:errors.append(str(e)))
        p.set_content(html,wait_until='load',timeout=30000)
        return p
    def set_screen(p,sid,st='READY',setup=''):
        p.evaluate(f'''()=>{{activeFlowId='UIF-05';{setup}activeScreenId='{sid}';stateByScreen['{sid}']='{st}';render();}}''')
    def geometry(p,name):
        g=p.locator('#app-screen .v-page-scaffold').evaluate('(e)=>({w:e.getBoundingClientRect().width,h:e.getBoundingClientRect().height,overflow:e.scrollWidth-e.clientWidth})')
        chk(name,abs(g['w']-402)<=.5 and abs(g['h']-874)<=.5 and g['overflow']<=.5,str(g))

    # Queue
    p=page(); set_screen(p,'SCR-025','READY')
    txt=p.locator('#app-screen').inner_text()
    chk('SCR-025 defaults to Tất cả filter', p.locator('[data-io05-filter].is-selected').inner_text()=='Tất cả')
    chk('SCR-025 peer orders use Navigation rows with Default/Disabled state', p.locator('[data-io05-order][data-ds-prop-type="Navigation"][data-ds-prop-state="Default"]').count()==1 and p.locator('[data-io05-order][data-ds-prop-type="Navigation"][data-ds-prop-state="Disabled"]').count()==1)
    chk('Waiting row is not a button and has no navigation affordance', p.locator('button.bj05-readonly-row').count()==0 and p.locator('.bj05-readonly-row .nav-action-chevron').count()==0)
    chk('Queue uses current Search/Chip/List Row DS assets', p.locator('[data-figma-node="522:7245"]').count()==1 and p.locator('[data-figma-node="522:7449"]').count()==3 and p.locator('[data-figma-node="525:519"]').count()==2)
    p.locator('[data-io05-search]').fill('Minh Tâm')
    chk('Live search keeps only matching order visible', p.locator('[data-io05-search-text]:visible').count()==1 and 'SO-260827-24' in p.locator('[data-io05-search-text]:visible').inner_text())
    p.locator('[data-io05-search]').fill('không có')
    chk('Live search exposes no-result state without losing search', p.locator('[data-io05-filter-empty]:visible').count()==1 and p.locator('[data-io05-search]').input_value()=='không có')
    geometry(p,'SCR-025 canonical 402x874 without horizontal overflow')
    p.close()

    # Pick overview normal and shortage
    p=page(); set_screen(p,'SCR-026','READY',"io05SelectedOrderId='SO-260827-21';")
    txt=p.locator('#app-screen').inner_text()
    chk('SCR-026 context is exactly three Info Rows', p.locator('[data-ds-component="DS v2 / Info Row"]').count()==3)
    chk('SCR-026 Product+UOM rows are independent navigation List Rows', p.locator('[data-io05-line][data-ds-prop-type="Navigation"]').count()==2)
    chk('SCR-026 normal progress is numeric with no progress badges', '12/20 hộp' in txt and '0/6 hộp' in txt and p.locator('.bj05-section .ds24-badge').count()==0)
    chk('SCR-026 partial allowance is quiet text, not banner', 'Có thể bàn giao phần đã lấy.' in txt and p.locator('.v-banner').count()==0)
    chk('SCR-026 review CTA is enabled when partial handover is allowed and picked > 0', not p.locator('[data-io05-action="review-handover"]').is_disabled())
    geometry(p,'SCR-026 canonical 402x874 without horizontal overflow')
    p.close()

    p=page(); set_screen(p,'SCR-026','SHORTAGE',"io05SelectedOrderId='SO-260827-24';")
    txt=p.locator('#app-screen').inner_text()
    chk('SCR-026 SHORTAGE has one semantic warning banner', p.locator('.v-banner--warning').count()==1 and 'Kho không tự đổi kho hoặc giảm lượng của đơn.' in txt)
    chk('SCR-026 SHORTAGE item rows are Disabled Navigation peers', p.locator('[data-io05-line][data-ds-prop-type="Navigation"][data-ds-prop-state="Disabled"]:disabled').count()==p.locator('[data-io05-line]').count() and p.locator('[data-io05-line]').count()>0)
    chk('SCR-026 SHORTAGE exposes no handover footer', p.locator('[data-io05-action="review-handover"]').count()==0)
    p.close()

    # Stale recovery and repick
    p=page(); set_screen(p,'SCR-026','STALE_RECOVERED',"io05SelectedOrderId='SO-260827-21';")
    txt=p.locator('#app-screen').inner_text()
    chk('STALE recovery invalidates old picked evidence', '8/20 hộp' in txt and p.evaluate("()=>io05CurrentOrder().lines[0].allocations[0].picked") == 0)
    chk('STALE recovery gives physical return/take instruction', 'Trả 4 hộp lô DH2507' in txt and 'lấy 4 hộp lô DH2511' in txt)
    chk('STALE recovery blocks review until repick', p.locator('[data-io05-action="review-handover"]').is_disabled())
    p.locator('[data-io05-line="PK-21-01"]').click()
    chk('SCR-027 surfaces unresolved physical correction', 'Cần điều chỉnh hàng đang cầm' in p.locator('#app-screen').inner_text() and p.locator('[data-io05-picked-allocation="AL-21-01"]').input_value()=='0')
    p.locator('[data-io05-picked-allocation="AL-21-01"]').fill('4')
    p.locator('[data-io05-action="save-pick"]').click()
    chk('Repick clears physical correction and returns to overview', p.evaluate("()=>activeScreenId")=='SCR-026' and p.evaluate("()=>io05CurrentOrder().lines[0].allocations[0].physicalCorrection") is None)
    p.close()

    # LOT override: real pointer/focus/type path
    p=page(); set_screen(p,'SCR-027','READY',"io05SelectedOrderId='SO-260827-21';io05ActiveLineId='PK-21-01';io05ActiveAllocationId='AL-21-01';")
    chk('SCR-027 uses one numeric VTextField per allocation', p.locator('[data-io05-picked-allocation][data-ds-component="VTextField"]').count()==0 and p.locator('[data-ds-component="VTextField"] [data-io05-picked-allocation]').count()==2)
    p.locator('[data-io05-open-override="AL-21-01"]').click()
    chk('Override opens canonical Form Sheet pattern', p.locator('[data-ds-pattern="DS v2 / Form Sheet"][data-figma-node="1353:6355"]').count()==1)
    chk('Alternative LOT is not preselected', p.locator('[data-io05-select-lot][aria-pressed="true"]').count()==0 and p.locator('[data-io05-select-lot]').count()==2)
    chk('Alternative rows show LOT + HSD + available quantity', 'HSD 31/12/2027 · Có thể lấy 22 hộp' in p.locator('#app-screen').inner_text())
    chk('Override reason uses VTextarea', p.locator('[data-ds-component="VTextarea"] [data-io05-override-reason]').count()==1)
    p.locator('[data-io05-select-lot="DH2511"]').click()
    ta=p.locator('[data-io05-override-reason]'); ta.click(); ta.fill('Lô cũ không còn đủ điều kiện')
    chk('Form Sheet remains open during actual focus/type interaction', p.locator('[data-ds-pattern="DS v2 / Form Sheet"]').count()==1 and ta.input_value()=='Lô cũ không còn đủ điều kiện')
    chk('Confirm stays disabled until both lot and reason exist', not p.locator('[data-io05-action="confirm-lot-override"]').is_disabled())
    p.locator('[data-io05-action="confirm-lot-override"]').click()
    data=p.evaluate("()=>{const a=io05CurrentOrder().lines[0].allocations[0];return {lot:a.lot,picked:a.picked,c:a.physicalCorrection};}")
    chk('Changing a picked LOT resets picked to zero', data['lot']=='DH2511' and data['picked']==0)
    chk('Changing a picked LOT creates exact physical correction', data['c']['returnLot']=='DH2507' and data['c']['returnQty']==4 and data['c']['takeLot']=='DH2511' and data['c']['takeQty']==4,str(data))
    chk('SCR-027 shows correction as warning and not as normal helper', p.locator('.v-banner--warning').count()==1 and 'Trả 4 hộp lô DH2507; lấy lại 4 hộp lô DH2511.' in p.locator('#app-screen').inner_text())
    geometry(p,'SCR-027 canonical 402x874 without horizontal overflow')
    p.close()

    # Handover review
    p=page(); set_screen(p,'SCR-028','PARTIAL_ALLOWED',"io05SelectedOrderId='SO-260827-21';io05ResetHandover();")
    txt=p.locator('#app-screen').inner_text()
    chk('SCR-028 renders only picked allocations', p.locator('[data-io05-handover-allocation]').count()==2 and 'Găng tay khám Nitrile' not in txt)
    chk('SCR-028 keeps actual quantity per allocation and never shows a cross-UOM total', 'Lô DH2507' in txt and 'Lô DH2509' in txt and '12 hộp' not in txt)
    chk('SCR-028 summary uses semantic Key-value Rows', p.locator('[data-io05-handover-summary] [data-ds-component="DS v2 / Key-value Row"]').count()==2 and '1 dòng hàng' in txt and '2 dòng hàng' in txt)
    chk('SCR-028 normal execution has no banner', p.locator('.v-banner').count()==0)
    chk('SCR-028 quiet helper states physical commit boundary', 'Chỉ xác nhận sau khi hàng đã giao thực tế.' in txt)
    bottom=p.evaluate("""()=>{const sc=document.querySelector('#app-screen .app-content');const note=document.querySelector('#app-screen .bj05-business-note');const footer=document.querySelector('#app-screen .figma-sticky-footer');sc.scrollTop=sc.scrollHeight;const nr=note.getBoundingClientRect(),fr=footer.getBoundingClientRect();return {scrollTop:sc.scrollTop,noteBottom:nr.bottom,footerTop:fr.top,ok:nr.bottom<=fr.top};}""")
    chk('SCR-028 bottom helper remains fully reachable above sticky footer', bottom['ok'], str(bottom))
    p.locator('[data-io05-handover-allocation="AL-21-01"]').fill('0')
    p.locator('[data-io05-handover-allocation="AL-21-02"]').fill('0')
    chk('Zero actual handover disables commit', p.locator('[data-io05-action="confirm-handover"]').is_disabled())
    geometry(p,'SCR-028 canonical 402x874 without horizontal overflow')
    p.close()

    p=page(); set_screen(p,'SCR-028','SOURCE_CHANGED',"io05SelectedOrderId='SO-260827-21';")
    chk('SOURCE_CHANGED blocks commit and offers only recovery CTA', p.locator('.v-banner--warning').count()==1 and p.locator('[data-io05-action="confirm-handover"]').count()==0 and p.locator('[data-io05-action="back-to-pick"]').count()==1)
    p.close()

    # Partial commit/result
    p=page(); p.evaluate("""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';io05ResetHandover();const r=io05ApplyHandover();activeScreenId='SCR-029';stateByScreen['SCR-029']='PARTIAL_COMPLETED';render();}""")
    txt=p.locator('#app-screen').inner_text()
    chk('PARTIAL result shows authoritative actual handover by LOT', 'Lô DH2507' in txt and '4 hộp' in txt and 'Lô DH2509' in txt and '8 hộp' in txt)
    chk('PARTIAL result shows remaining per Product/UOM without mixed-UOM sum', 'Còn lại' in txt and '8 hộp' in txt and '6 hộp' in txt and '14 ' not in txt)
    chk('PARTIAL result has no Back to pre-commit screen', p.locator('.app-back-button').count()==0)
    chk('PARTIAL commit keeps order active', p.evaluate("()=>io05CurrentOrder().closed") is False)
    p.locator('[data-io05-action="continue-remaining"]').click()
    chk('PARTIAL result continues same order task', p.evaluate("()=>activeScreenId")=='SCR-026' and p.evaluate("()=>io05SelectedOrderId")=='SO-260827-21')
    p.close()

    # Full commit and queue lifecycle
    p=page(); p.evaluate("""()=>{activeFlowId='UIF-05';io05SelectedOrderId='SO-260827-21';const o=io05CurrentOrder();for(const l of o.lines){for(const a of l.allocations)a.picked=a.qty;}io05ResetHandover(o);io05ApplyHandover();activeScreenId='SCR-029';stateByScreen['SCR-029']='COMPLETED';render();}""")
    txt=p.locator('#app-screen').inner_text()
    chk('COMPLETED result has no zero-remaining noise', 'Còn lại' not in txt and 'Đã bàn giao toàn bộ' in txt)
    chk('COMPLETED commit closes task', p.evaluate("()=>io05CurrentOrder().closed") is True)
    p.locator('[data-io05-action="result-to-queue"]').click()
    qtxt=p.locator('#app-screen').inner_text()
    chk('COMPLETED task is removed from active queue', 'SO-260827-21' not in qtxt and 'SO-260827-24' in qtxt)
    p.close()

    # UNKNOWN / permission terminal semantics + inspector
    p=page(); set_screen(p,'SCR-029','UNKNOWN',"io05SelectedOrderId='SO-260827-21';")
    txt=p.locator('#app-screen').inner_text()
    chk('UNKNOWN does not claim success/failure and has no blind retry', 'Đang xác minh kết quả' in txt and 'Thử lại' not in txt and p.locator('[data-io05-action="result-to-queue"]').count()==1)
    chk('UNKNOWN has no Back to commit screen', p.locator('.app-back-button').count()==0)
    geometry(p,'SCR-029 UNKNOWN canonical 402x874 without horizontal overflow')
    inspector=p.locator('#traceability').inner_text()
    chk('Inspect reports BJ05 v2.7.4 Figma DS hardening', 'v2.7.4 · BJ05 migrated + DS hard-gated' in inspector)
    p.close()

    p=page(); set_screen(p,'SCR-029','PERMISSION_DENIED',"io05SelectedOrderId='SO-260827-21';")
    chk('PERMISSION_DENIED is distinct and states no stock change', 'Không có quyền bàn giao' in p.locator('#app-screen').inner_text() and 'Không thay đổi' in p.locator('#app-screen').inner_text())
    p.close()
    b.close()

chk('No browser page errors during BJ05 QA', not errors, '; '.join(errors))
status_name='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status_name,'checks':checks,'passed':sum(x['pass'] for x in checks),'total':len(checks),'browserErrors':errors}
(OUT/'BJ05-FIGMA-DS-QA-v2.7.4.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n')
lines=['# BJ05 Figma DS / Product QA — v2.7.1','',f'**Result: {status_name} · {res["passed"]}/{res["total"]} checks**','']
for x in checks: lines.append(f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f' — {x["note"]}' if x['note'] else ''))
(OUT/'BJ05-FIGMA-DS-QA-v2.7.4.md').write_text('\n'.join(lines)+'\n')
print(status_name,res['passed'],res['total'])
if status_name!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL:',x['name'],x['note'])
    raise SystemExit(1)
