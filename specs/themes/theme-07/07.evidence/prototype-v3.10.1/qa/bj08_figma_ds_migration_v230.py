from pathlib import Path
from playwright.sync_api import sync_playwright
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent

def inline_html(root):
    idx=(root/'index.html').read_text()
    css='\n'.join((root/x).read_text() for x in ['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css'])
    data=(root/'workbench-data.js').read_text(); fmap=(root/'figma-ds-runtime-map.js').read_text(); app=(root/'app.js').read_text()
    return (idx
      .replace('<link rel="stylesheet" href="figma-ds.exact.css" />','')
      .replace('<link rel="stylesheet" href="figma-ds.styles.exact.css" />','')
      .replace('<link rel="stylesheet" href="tokens.generated.css" />','')
      .replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>')
      .replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
      .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
      .replace('<script src="app.js"></script>',f'<script>{app}</script>'))

checks=[]; errors=[]
def ck(name,cond,detail=''): checks.append((name,bool(cond),detail))

def main():
  with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: errors.append(str(e)))
    p.set_content(inline_html(ROOT),wait_until='load'); p.add_style_tag(content='*{animation:none!important;transition:none!important}')
    def render(screen,state):
      p.evaluate('x=>{activeFlowId="UIF-08";activeScreenId=x.s;stateByScreen[x.s]=x.st;ic08ConfirmKind=null;ic08KeypadTarget=null;ic08ScopeSheetOpen=false;ic08ProductSheetOpen=false;render();}',{'s':screen,'st':state})
    expected={'SCR-042':'Mobile / Nested List','SCR-043':'Mobile / Form','SCR-044':'Mobile / Form','SCR-045':'Mobile / Form','SCR-046':'Mobile / Detail','SCR-047':'Mobile / Detail'}
    for s,t in expected.items():
      st={'SCR-042':'READY','SCR-043':'READY','SCR-044':'BLIND_COUNT','SCR-045':'RECOUNT_REQUIRED','SCR-046':'APPROVAL_REQUIRED','SCR-047':'COMPLETED'}[s]
      render(s,st)
      shell=p.locator('#app-screen .v-page-scaffold')
      ck(f'{s} maps to {t}',shell.get_attribute('data-figma-template')==t,shell.get_attribute('data-figma-template') or '')
      size=p.evaluate('''()=>{const e=document.querySelector('#app-screen .app-screen')||document.querySelector('#app-screen');const s=document.querySelector('#app-screen .v-page-scaffold');const r=s?.getBoundingClientRect();return {w:r?.width,h:r?.height,scroll:s?.scrollWidth,client:s?.clientWidth}}''')
      ck(f'{s} has no horizontal overflow',(size.get('scroll') or 0)-(size.get('client') or 0)<=0.5,json.dumps(size))
    render('SCR-043','READY')
    device=p.evaluate('''()=>{const e=document.querySelector('.device-preview:not(.is-wide) > .app-screen');const r=e?.getBoundingClientRect();return {w:r?.width,h:r?.height}}''')
    ck('canonical Product canvas is 402x874',abs((device.get('w') or 0)-402)<.5 and abs((device.get('h') or 0)-874)<.5,json.dumps(device))
    widths=p.evaluate('''()=>[...document.querySelectorAll('#app-screen .form-field')].map(e=>({w:e.getBoundingClientRect().width,name:e.dataset.dsComponent||e.dataset.themeComponent||''}))''')
    ck('BJ08 form fields fit 370px content boundary',bool(widths) and all(x['w']<=370.5 for x in widths),json.dumps(widths,ensure_ascii=False))
    ck('SCR-043 exposes VTimePicker gap explicitly',p.locator('#app-screen [data-ds-gap="VTimePicker"]').count()==1)
    p.locator('[data-ic08-action="open-session"]').click()
    ck('SCR-043 open uses canonical Confirmation Sheet',p.locator('#app-screen [data-ds-component="DS v2 / Confirmation Sheet"]').count()==1)
    radius=p.evaluate('''()=>{const e=document.querySelector('#app-screen .ic08-confirmation-sheet');return e?getComputedStyle(e).borderTopLeftRadius:''}''')
    ck('Confirmation Sheet shell radius is 16px',radius=='16px',radius)

    render('SCR-044','BLIND_COUNT')
    blind_html=p.locator('#app-screen').inner_html().lower(); blind_text=p.locator('#app-screen').inner_text().lower()
    forbidden=['book_quantity','data-book','variance_quantity','data-variance','số hệ thống','sổ 20','sổ 6']
    ck('blind-count DOM contains no book/variance payload',all(x not in blind_html and x not in blind_text for x in forbidden),','.join(x for x in forbidden if x in blind_html or x in blind_text))
    ck('blind-count Product DOM does not use legacy VNumberField',p.locator('#app-screen [data-ds-component="VNumberField"]').count()==0)
    ck('blind-count Product DOM does not use VQuantitySelector',p.locator('#app-screen [data-ds-component="VQuantitySelector"]').count()==0)
    ck('blind-count Product DOM does not depend on generic VCard',p.locator('#app-screen [data-ds-component="VCard"]').count()==0)
    p.locator('[data-ic08-keypad-open="count:amox"]').click()
    ck('quantity trigger opens VNumericKeypadSheet',p.locator('#app-screen [data-ds-component="VNumericKeypadSheet"]').count()==1)
    keypad=p.evaluate('''()=>{const e=document.querySelector('#app-screen .ic08-numeric-sheet');const r=e?.getBoundingClientRect();return {w:r?.width,h:r?.height,radius:e?getComputedStyle(e).borderTopLeftRadius:''}}''')
    ck('VNumericKeypadSheet geometry is 402x512 / radius16',abs((keypad.get('w') or 0)-402)<.5 and abs((keypad.get('h') or 0)-512)<.5 and keypad.get('radius')=='16px',json.dumps(keypad))
    p.locator('[data-ic08-action="keypad-cancel"]').last.click()
    p.locator('[data-ic08-action="add-actual-open"]').click()
    ck('add actual item uses Select Sheet rather than Product quick-create',p.locator('#app-screen [data-ds-component="DS v2 / Select Sheet"]').count()==1 and 'tạo sản phẩm' not in p.locator('#app-screen').inner_text().lower())
    p.locator('[data-ic08-product="vitc"]').click()
    ck('unexpected physical line is explicitly marked',p.locator('#app-screen [data-product-flag="is_unexpected_key"]').count()==1)

    render('SCR-045','PRICE_BASIS_REQUIRED')
    text=p.locator('#app-screen').inner_text()
    ck('recount reveals book/first/variance only after first submit','Sổ' in text and 'Lần đếm đầu' in text and 'Chênh lệch' in text)
    ck('price-basis gap blocks submit without invented price input',p.locator('[data-ic08-action="submit-recount"]').is_disabled() and p.locator('#app-screen input[type="number"]').count()==0)
    ck('blocked recount exposes contextual cancellation',p.locator('[data-ic08-action="cancel-open"]').count()==1)
    p.locator('[data-ic08-action="cancel-open"]').click()
    ck('cancellation uses danger Confirmation Sheet with reason',p.locator('#app-screen [data-ds-component="DS v2 / Confirmation Sheet"] [data-ic08-cancel-reason]').count()==1)

    render('SCR-046','APPROVAL_REQUIRED')
    ck('approval surface has approve + request-review',p.locator('[data-ic08-action="approve"]').count()==1 and p.locator('[data-ic08-action="request-review"]').count()==1)
    ck('approval surface does not mix session cancellation',p.locator('[data-ic08-action="cancel-open"]').count()==0 and 'Hủy phiên' not in p.locator('#app-screen').inner_text())
    ck('both approval affordances trace to same stable decision action',p.locator('[data-action-contract="ACT-09-APPROVE"]').count()==2)
    p.locator('[data-ic08-action="request-review"]').click()
    ck('request-review returns to SCR-045',p.locator('#current-screen-id').inner_text().startswith('SCR-045'))

    render('SCR-046','APPROVAL_REQUIRED')
    p.locator('[data-ic08-action="approve"]').click()
    ck('approve requires Confirmation Sheet',p.locator('#app-screen [data-ds-component="DS v2 / Confirmation Sheet"]').count()==1)
    p.locator('[data-ic08-action="confirm-approve"]').click()
    ck('approved decision lands on terminal SCR-047',p.locator('#current-screen-id').inner_text().startswith('SCR-047'))
    ck('SCR-047 has no mutation action-contract',p.locator('#app-screen [data-action-contract="ACT-09-APPROVE"]').count()==0)

    render('SCR-046','PERMISSION_DENIED')
    denied=p.locator('#app-screen').inner_text().lower()
    ck('permission-denied approval DOM contains no financial risk value','giá trị rủi ro' not in denied and 'adj-' not in denied,denied[:220])
    b.close()
  ck('no browser page errors',not errors,str(errors))
  passed=sum(ok for _,ok,_ in checks); result='PASS' if passed==len(checks) else 'FAIL'
  details=[{'name':n,'pass':ok,'detail':d} for n,ok,d in checks]
  (OUT/'BJ08-FIGMA-DS-MIGRATION-QA-v2.3.0.json').write_text(json.dumps({'result':result,'passed':passed,'checks':len(checks),'browserErrors':errors,'details':details},ensure_ascii=False,indent=2)+'\n')
  lines=['# BJ08 Figma DS Migration QA — v2.3.0','',f'**{result} {passed}/{len(checks)}**','']+[f'- [{"x" if ok else " "}] {n}'+(f' — {d}' if d else '') for n,ok,d in checks]
  (OUT/'BJ08-FIGMA-DS-MIGRATION-QA-v2.3.0.md').write_text('\n'.join(lines)+'\n')
  print(result,passed,'/',len(checks))
  if result!='PASS':
    for n,ok,d in checks:
      if not ok: print('FAIL:',n,d)
    raise SystemExit(1)

if __name__=='__main__': main()
