from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
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
checks=[];errors=[]
def ck(name,ok,note=''): checks.append({'name':name,'pass':bool(ok),'note':note})
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1050})
    p.set_default_timeout(5000)
    p.on('pageerror',lambda e:errors.append(str(e)))
    p.set_content(html,wait_until='load',timeout=30000)
    p.click('[data-workbench-mode="theme"]')
    p.click('[data-theme-sidebar-route="inventory"]')
    ck('Default persona is warehouse operator',p.locator('[data-t390-persona]').input_value()=='operator')
    ck('Operator Home projects exactly three relevant work items',p.locator('.t390-work-item').count()==3,p.locator('.t390-work-item').all_inner_texts())
    ck('Work-item subtitle does not duplicate status badge',all('Cần nhận' not in x and 'Đang lấy' not in x for x in p.locator('.t390-work-item .ds24-list-row__copy small').all_inner_texts()))
    inv=p.locator('.t380-utility-section .ds24-list-row').filter(has_text='Tồn kho')
    ck('Inventory utility does not promise an unbound attention filter',inv.locator('.ds24-badge').count()==0)

    # Controller projection and exact deep links.
    p.select_option('[data-t390-persona]','controller')
    labels=p.locator('.t390-work-item .ds24-list-row__copy strong').all_inner_texts()
    ck('Controller sees controller work rather than operator queue',labels==['PN-260901-03','Amox 500 · L2407-A'],labels)
    p.locator('[data-t390-task-id="VAL-PN26090103"]').click()
    ctx=p.evaluate('()=>({flow:activeFlowId,screen:activeScreenId,receipt:val03SelectedReceiptId})')
    ck('Valuation task deep-links to exact receipt scope',ctx=={'flow':'UIF-03','screen':'SCR-015','receipt':'VAL03-R3'},ctx)
    p.click('[data-theme-sidebar-route="inventory"]')
    p.locator('[data-t390-task-id="REC-AMOX-L2407A"]').click()
    ctx=p.evaluate('()=>({flow:activeFlowId,screen:activeScreenId,caseId:cr16SelectedId,state:stateByScreen[activeScreenId]})')
    ck('Reconciliation task deep-links to exact Amox case',ctx['flow']=='UIF-16' and ctx['screen']=='SCR-079' and ctx['caseId']=='REC-260907-04' and ctx['state']=='CORRECTION_REQUIRED',ctx)

    # Manual actions select the object before editing it.
    p.click('[data-theme-sidebar-route="inventory"]')
    p.select_option('[data-t390-persona]','operator')
    p.locator('[data-t383-start-new]').click()
    p.locator('.t380-manual-sheet [data-theme-entry-flow="UIF-09"]').click()
    ctx=p.evaluate('()=>({flow:activeFlowId,screen:activeScreenId})')
    ck('State-change manual entry starts at item-selection list',ctx=={'flow':'UIF-09','screen':'SCR-036'},ctx)
    p.click('[data-theme-sidebar-route="inventory"]')
    p.locator('[data-t383-start-new]').click()
    p.locator('.t380-manual-sheet [data-theme-entry-flow="UIF-10"]').click()
    ctx=p.evaluate('()=>({flow:activeFlowId,screen:activeScreenId})')
    ck('Disposal manual entry starts at eligible-item list',ctx=={'flow':'UIF-10','screen':'SCR-036'},ctx)

    # Handoff lock + context-aware return + queue mutation.
    p.click('[data-theme-sidebar-route="inventory"]')
    p.locator('[data-t390-task-id="RCV-PN26081604"]').click()
    p.evaluate("()=>{activeScreenId='SCR-010';stateByScreen['SCR-010']='PENDING_APPROVAL';render();}")
    ck('Submitted approval handoff cannot backtrack into editable receipt',p.locator('#app-screen .app-back-button').count()==0)
    ck('Integrated handoff gets an explicit return to Warehouse Home',p.locator('[data-t390-return-home]').count()==1 and 'Về Kho' in p.locator('[data-t390-return-home]').inner_text())
    p.locator('[data-t390-return-home]').click()
    ids=p.locator('.t390-work-item').evaluate_all("els=>els.map(e=>e.getAttribute('data-t390-task-id'))")
    ck('Resolved originating task leaves the operator queue', 'RCV-PN26081604' not in ids,ids)

    # Permission-aware searchable long-tail catalog.
    p.locator('[data-t381-catalog-open]').click()
    ck('Catalog includes function search',p.locator('[data-t390-catalog-search]').count()==1)
    vis=p.locator('.t381-catalog-row:visible .ds24-list-row__copy strong').all_inner_texts()
    ck('Operator catalog omits finance/admin-only capabilities','Giá vốn' not in vis and 'Chính sách tồn & cận hạn' not in vis,vis)
    p.fill('[data-t390-catalog-search]','kiểm kê')
    filtered=p.locator('.t381-catalog-row:visible .ds24-list-row__copy strong').all_inner_texts()
    ck('Catalog search narrows long-tail functions',filtered==['Kiểm kê kho'],filtered)
    p.fill('[data-t390-catalog-search]','')
    p.select_option('[data-t390-persona]','manager')
    vis=p.locator('.t381-catalog-row:visible .ds24-list-row__copy strong').all_inner_texts()
    ck('Manager persona exposes financial and policy capabilities','Giá vốn' in vis and 'Chính sách tồn & cận hạn' in vis,vis)

    # Copy semantics.
    p.click('[data-t381-catalog-back]')
    p.select_option('[data-t390-persona]','operator')
    p.locator('[data-t383-start-new]').click();p.locator('.t380-manual-sheet [data-theme-entry-flow="UIF-09"]').click()
    p.locator('[data-ic09-item="amox"]').click();p.locator('[data-ic09-action="change"]').click()
    ck('BJ09 CTA names the actual approval handoff','Gửi chờ duyệt'==p.locator('[data-ic09-action="submit"],[data-v350-action="ic09-submit"]').inner_text().strip())

    # A successfully approved over-receipt must not still read like an unresolved warning.
    p.evaluate("()=>{activeFlowId='UIF-02';activeScreenId='SCR-012';flowMode='document';selectedDocumentId='PN-260816-04';resetBj02Receipt('document');bj02Lines[0].status='COMPLETED';bj02Lines[0].lots=[{id:'QA-L1',code:'QA-OVER',expiry:'31/12/2027',manufactureDate:'',accepted:121,quarantine:0,damaged:0,rejected:0}];bj02Lines[1].status='COMPLETED';bj02Lines[1].lots=[{id:'QA-L2',code:'QA-OK',expiry:'',manufactureDate:'',accepted:24,quarantine:0,damaged:0,rejected:0}];stateByScreen['SCR-012']='COMPLETED';render();}")
    badges=p.locator('#app-screen .status-badge').all_inner_texts()
    ck('Completed approved over-receipt uses resolved status semantics','Vượt chứng từ' not in badges and 'Đã duyệt vượt' in badges,badges)
    ck('No browser errors',not errors,errors)
    b.close()
status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
res={'status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errors}
(OUT/'FULL-THEME-END-USER-HARDENING-QA-v3.9.4.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(OUT/'FULL-THEME-END-USER-HARDENING-QA-v3.9.4.md').write_text('\n'.join(['# Full Theme End-user Hardening QA — v3.9.4','',f'**Result: {status} · {res["passed"]}/{res["total"]}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}: {x["note"]}' for x in checks])+'\n',encoding='utf-8')
print(status,res['passed'],res['total'],'errors',len(errors))
if status!='PASS':
    for x in checks:
        if not x['pass']: print('FAIL',x['name'],x['note'])
    raise SystemExit(1)
