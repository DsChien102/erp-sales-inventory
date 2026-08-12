from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text(); html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
M={'UIF-08':{'SCR-042':['READY','EMPTY','PENDING_APPROVAL','PERMISSION_DENIED'],'SCR-043':['READY','PARTIAL_SCOPE','VALIDATION_ERROR','CONFLICT'],'SCR-044':['BLIND_COUNT','NO_RESULT','VALIDATION_ERROR','LOCK_LOST'],'SCR-045':['RECOUNT_REQUIRED','EVIDENCE_REQUIRED','PRICE_BASIS_REQUIRED','LOCKED'],'SCR-046':['APPROVAL_REQUIRED','SELF_APPROVAL_NOT_ALLOWED','APPROVAL_ALREADY_DECIDED'],'SCR-047':['COMPLETED','CANCELLED','REJECTED_EXECUTION','UNKNOWN']},'UIF-09':{'SCR-036':['READY','EMPTY','FILTER_EMPTY'],'SCR-037':['READY','EXPIRED','LOCKED'],'SCR-038':['READY','PENDING_APPROVAL','APPROVAL_REVIEW','LOCKED','SELF_APPROVAL_NOT_ALLOWED'],'SCR-041':['COMPLETED','REJECTED_EXECUTION','UNKNOWN','EXPIRED'],'SCR-056':['READY']},'UIF-10':{'SCR-036':['READY','EMPTY'],'SCR-037':['READY','LOCKED'],'SCR-040':['READY','PRICE_BASIS_REQUIRED','PENDING_APPROVAL','APPROVAL_REVIEW','APPROVED_PENDING_DISPOSAL','COMPLETION','COMPLETION_QTY_BLOCKED'],'SCR-041':['COMPLETED','REJECTED_EXECUTION','UNKNOWN']}}
fail=[]; total=0
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']); p=b.new_page(viewport={'width':402,'height':874}); errors=[]; p.on('pageerror',lambda e:errors.append(str(e))); p.set_content(html,wait_until='load')
 for u,screens in M.items():
  for s,states in screens.items():
   for st in states:
    total+=1
    try:
     p.evaluate('(x)=>{activeFlowId=x.u;activeScreenId=x.s;stateByScreen[x.s]=x.st;render();}',{'u':u,'s':s,'st':st}); text=p.locator('#app-screen').inner_text().strip(); g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
     if not text: fail.append(f'{u}/{s}/{st}: empty')
     if g['sw']>g['cw']+1: fail.append(f'{u}/{s}/{st}: horizontal overflow')
    except Exception as e: fail.append(f'{u}/{s}/{st}: {e}')
 fail += ['pageerror: '+e for e in errors]; b.close()
lines=['# Inventory Audit & Control Scenario QA v1.6.0','',f'**Result: {"PASS" if not fail else "FAIL"} · {total} state renders**','','## Failures','']+(['- None.'] if not fail else [f'- {x}' for x in fail])
(OUT/'INVENTORY-AUDIT-CONTROL-SCENARIO-QA-v1.6.0.md').write_text('\n'.join(lines)+'\n'); print(('PASS' if not fail else 'FAIL'),total,'renders')
if fail: print('\n'.join(fail[:40])); raise SystemExit(1)
