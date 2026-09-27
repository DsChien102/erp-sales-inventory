from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
M={
 'UIF-11':{
  'SCR-048':['READY','LOADING','EMPTY','FILTER_EMPTY','PERMISSION_DENIED'],
  'SCR-049':['READY','LOADING','PERMISSION_DENIED','UNKNOWN','CANCELABLE','CORRECTABLE','BLOCKED_PHYSICAL_HANDOVER','TERMINAL'],
  'SCR-052':['CANCEL_UNEXECUTED','CORRECTION_ROUTE','VALIDATION_ERROR','DEPENDENCY_BLOCKED','PERIOD_POLICY_VIOLATION','PERMISSION_DENIED'],
  'SCR-050':['READY','VALIDATION_ERROR','CONFLICT','PERMISSION_DENIED','SOURCE_VERSION_STALE'],
  'SCR-053':['PROCESSING','PENDING_APPROVAL','CANCELLED','COMPLETED','REJECTED','UNKNOWN','BLOCKED','PERMISSION_DENIED'],
  'SCR-051':['READY','VALIDATION_ERROR','PERMISSION_DENIED','SELF_APPROVAL_NOT_ALLOWED','APPROVAL_ALREADY_DECIDED']},
 'UIF-16':{
  'SCR-078':['READY','LOADING','EMPTY','FILTER_EMPTY','PERMISSION_DENIED','INVESTIGATING','ESCALATED'],
  'SCR-079':['READY','LOADING','PERMISSION_DENIED','INSUFFICIENT_EVIDENCE','SOURCE_MISMATCH','PROJECTION_MISMATCH','CORRECTION_REQUIRED','LEDGER_INTEGRITY_RISK','NO_REAL_DIFFERENCE'],
  'SCR-080':['READY','LOCKED','PERMISSION_DENIED','CONFLICT'],
  'SCR-081':['REBUILDING','READY','PERMISSION_DENIED','CONFLICT','VALIDATION_FAILED'],
  'SCR-082':['READY','MISMATCH_REMAINS','PERMISSION_DENIED'],
  'SCR-083':['PROCESSING','RESOLVED','UNKNOWN','ESCALATED','PERMISSION_DENIED']},
 'UIF-17':{
  'SCR-078':['READY','LOADING','EMPTY','FILTER_EMPTY','PERMISSION_DENIED','INVESTIGATING','ESCALATED'],
  'SCR-079':['READY','LOADING','PERMISSION_DENIED','INSUFFICIENT_EVIDENCE','UNKNOWN_EVIDENCE'],
  'SCR-080':['READY','LOCKED','PERMISSION_DENIED','CONFLICT','INSUFFICIENT_EVIDENCE'],
  'SCR-082':['READY','MISMATCH_REMAINS','PERMISSION_DENIED'],
  'SCR-083':['PROCESSING','COMPLETED','UNKNOWN','ESCALATED','PERMISSION_DENIED']}}
fail=[]; total=0; errors=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':402,'height':874}); p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load')
 for u,sm in M.items():
  for s,states in sm.items():
   for st in states:
    total+=1
    try:
     p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st})
     text=p.locator('#app-screen').inner_text().strip(); g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
     if not text: fail.append(f'{u}/{s}/{st}: empty')
     if 'undefined' in text.lower(): fail.append(f'{u}/{s}/{st}: undefined leak')
     if g['sw']>g['cw']+1: fail.append(f'{u}/{s}/{st}: horizontal overflow {g}')
    except Exception as e: fail.append(f'{u}/{s}/{st}: {e}')
 fail += ['pageerror: '+e for e in errors]; b.close()
lines=['# Correction & Recovery Scenario QA v1.7.0','',f'**Result: {"PASS" if not fail else "FAIL"} · {total} state renders**','','Covers target journey state surfaces at canonical mobile width.','','## Failures','']+(['- None.'] if not fail else [f'- {x}' for x in fail])
(OUT/'CORRECTION-RECOVERY-SCENARIO-QA-v1.7.0.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(('PASS' if not fail else 'FAIL'),total,'renders')
if fail:
 print('\n'.join(fail[:80])); raise SystemExit(1)
