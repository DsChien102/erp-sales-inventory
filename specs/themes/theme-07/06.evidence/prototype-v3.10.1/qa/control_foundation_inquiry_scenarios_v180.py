from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text(); html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
M={'UIF-12':{'SCR-066':['READY','LOADING','PERMISSION_DENIED','PREPARING','PENDING_APPROVAL','REJECTED','UNKNOWN','ACTIVE_RECONCILED'],'SCR-067':['READY','VALIDATION_ERROR','CONFLICT','LOCKED','PERMISSION_DENIED'],'SCR-068':['READY','LOADING','CONFLICT','PERMISSION_DENIED','VALIDATION_FAILED','CONTROL_TOTAL_MISMATCH'],'SCR-069':['READY','VALIDATION_ERROR','CONFLICT','PERMISSION_DENIED','PENDING_APPROVAL'],'SCR-070':['READY','VALIDATION_ERROR','PERMISSION_DENIED','SELF_APPROVAL_NOT_ALLOWED','APPROVAL_ALREADY_DECIDED'],'SCR-071':['PROCESSING','COMPLETED','UNKNOWN','REJECTED_EXECUTION','PERMISSION_DENIED','COMMIT_UNKNOWN','ACTIVE_RECONCILED']},'UIF-15':{'SCR-054':['READY','VALIDATION_ERROR','CONFLICT','LOCKED','PERMISSION_DENIED'],'SCR-055':['READY','LOADING','EMPTY','FILTER_EMPTY','PERMISSION_DENIED','RECORDED_DATE_VIEW','BUSINESS_DATE_VIEW','ARCHIVED_DATA','STALE','FINANCIAL_RESTRICTED'],'SCR-056':['READY','LOADING','CONFLICT','LOCKED','PERMISSION_DENIED','FINANCIAL_RESTRICTED'],'SCR-057':['READY','LOADING','EMPTY','STALE','PERMISSION_DENIED'],'SCR-058':['READY','VALIDATION_ERROR','PERMISSION_DENIED','EXPORT_RUNNING','STALE'],'SCR-059':['PROCESSING','COMPLETED','REJECTED_EXECUTION','SOURCE_STALE','PERMISSION_DENIED']}}
fail=[]; total=0; errors=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':402,'height':874}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load')
 for u,sm in M.items():
  for s,states in sm.items():
   for st in states:
    total+=1
    try:
     p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;if(x.u==="UIF-15"){cf15ReportType="INVENTORY";cf15Product="ALL";cf15ProductSheetOpen=false;}render();}',{'u':u,'s':s,'st':st})
     text=p.locator('#app-screen').inner_text().strip(); g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
     if not text: fail.append(f'{u}/{s}/{st}: empty')
     if 'undefined' in text.lower(): fail.append(f'{u}/{s}/{st}: undefined leak')
     if g['sw']>g['cw']+1: fail.append(f'{u}/{s}/{st}: horizontal overflow {g}')
    except Exception as e: fail.append(f'{u}/{s}/{st}: {e}')
 # extra UIF15 stock-card mode render surfaces
 for s,st in [('SCR-055','READY'),('SCR-055','FINANCIAL_RESTRICTED'),('SCR-056','READY'),('SCR-057','READY'),('SCR-058','READY'),('SCR-059','COMPLETED')]:
  total+=1; p.evaluate('(x)=>{activeFlowId="UIF-15";cf15ReportType="STOCK_CARD";cf15Product="P-NOB";cf15SelectedProduct="P-NOB";activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'s':s,'st':st}); t=p.locator('#app-screen').inner_text(); g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})');
  if not t.strip() or g['sw']>g['cw']+1: fail.append(f'UIF-15/{s}/{st}/STOCK_CARD invalid')
 fail += ['pageerror: '+e for e in errors]; b.close()
lines=['# Control Foundation & Inquiry Scenario QA v1.8.0','',f'**Result: {"PASS" if not fail else "FAIL"} · {total} state/mode renders**','','## Failures','']+(['- None.'] if not fail else [f'- {x}' for x in fail])
(OUT/'CONTROL-FOUNDATION-INQUIRY-SCENARIO-QA-v1.8.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8'); print(('PASS' if not fail else 'FAIL'),total,'renders')
if fail: print('\n'.join(fail[:80])); raise SystemExit(1)
