from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(encoding='utf-8')
css=(ROOT/'tokens.generated.css').read_text(encoding='utf-8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf-8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf-8'); app=(ROOT/'app.js').read_text(encoding='utf-8')
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
forbidden=[
 'operation identity','authoritative','correction','mutation','finality','movement','outbox','polling','idempotency','checksum','REC-UNKNOWN-'
]
forbidden_re=re.compile('|'.join(re.escape(x) for x in forbidden),re.I)
arch_re=re.compile(r'\b(?:UIF|SCR|ACT|UC|BJ)-\d',re.I)
save_re=re.compile(r'\b(?:Lưu nháp|Lưu bản nháp|Tự lưu bản nháp)\b',re.I)
raw_state_re=re.compile(r'\b(?:UNKNOWN|READY|PROCESSING|COMPLETED|PENDING_APPROVAL|SOURCE_VERSION_STALE|PERMISSION_DENIED)\b')
checks=[]; issues=[]; page_errors=[]; total=0

def add_issue(kind,f,s,st,detail): issues.append({'kind':kind,'flow':f,'screen':s,'state':st,'detail':detail})
def ck(name,cond): checks.append((name,bool(cond)))

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e: page_errors.append(str(e)))
    p.set_content(html,wait_until='load'); p.wait_for_timeout(30)
    flow_count=p.evaluate('flowCatalog.length'); screen_count=p.evaluate('screens.length'); version=p.evaluate('VET45_HARNESS_DATA.version')
    ck('17 active flows',flow_count==17); ck('Workbench version 1.9.0',version=='1.9.0'); ck('Active screen registry present',screen_count>=85)
    flows=p.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))')
    states=p.evaluate('Object.fromEntries(screens.map(s=>[s.id,s.states||["READY"]]))')
    seen=set()
    for f in flows:
      for sid in f['screens']:
        key=(f['id'],sid)
        if key in seen: continue
        seen.add(key)
        for st in states.get(sid,['READY']):
          total+=1
          try:
            p.evaluate('''(x)=>{
              activeFlowId=x.f; activeScreenId=x.s; stateByScreen[x.s]=x.st;
              if(x.f==="UIF-02"&&x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");stateByScreen[x.s]=x.st;}
              if(x.f==="UIF-03"&&x.s==="SCR-017"){val03SelectedReceiptId="VAL03-R1";val03ReviewSourceVersion=val03Current().sourceVersion;}
              if(x.f==="UIF-13"&&x.s==="SCR-088"){val13SelectedTaskId="LC13-001";if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
              if(x.f==="UIF-14"&&x.s==="SCR-076"){val14SelectedRunId="COST-0826";val14PublishReviewVersion=val14Current().inputVersion;}
              render();
            }''',{'f':f['id'],'s':sid,'st':st}); p.wait_for_timeout(2)
            txt=p.locator('#app-screen').inner_text().strip()
            if not txt: add_issue('EMPTY_PRODUCT_UI',f['id'],sid,st,'No visible Product UI text')
            if 'undefined' in txt.lower(): add_issue('UNDEFINED_LEAK',f['id'],sid,st,'undefined')
            m=arch_re.search(txt)
            if m: add_issue('ARCHITECTURE_ID_LEAK',f['id'],sid,st,m.group(0))
            m=forbidden_re.search(txt)
            if m: add_issue('TECHNICAL_JARGON_LEAK',f['id'],sid,st,m.group(0))
            m=save_re.search(txt)
            if m: add_issue('FAKE_SAVE_DRAFT_TASK',f['id'],sid,st,m.group(0))
            m=raw_state_re.search(txt)
            if m: add_issue('RAW_STATE_LEAK',f['id'],sid,st,m.group(0))
            geom=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
            if geom['sw']>geom['cw']+1: add_issue('HORIZONTAL_OVERFLOW',f['id'],sid,st,str(geom))
            primary=p.locator('#app-screen .button--primary:visible').count()
            if primary>1: add_issue('MULTIPLE_PRIMARY_ACTIONS',f['id'],sid,st,str(primary))
          except Exception as e:
            add_issue('RENDER_ERROR',f['id'],sid,st,str(e))
    b.close()
ck('No browser page errors',not page_errors); ck('All active states rendered',total>=400); ck('No Product UI semantic/runtime issues',not issues)
passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
report=['# Holistic Hardening QA v1.9.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} gates · {total} active state renders**','',
'## Scope','',
'- All 17 active UIFs and every registered state reachable by the cumulative workbench.','- Product viewport text only; Inspect/workbench metadata is intentionally excluded from the jargon gate.','- Checks: runtime render, horizontal overflow, one-primary-action rule, architecture-ID leakage, raw-state leakage, fake Save Draft task, and technical implementation jargon.','',
'## Gates','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
if page_errors: report+=['','## Browser errors']+[f'- {x}' for x in page_errors]
if issues: report+=['','## Issues']+[f'- `{x["flow"]}/{x["screen"]}/{x["state"]}` · {x["kind"]}: {x["detail"]}' for x in issues[:300]]
(OUT/'HOLISTIC-HARDENING-QA-v1.9.0.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
(OUT/'HOLISTIC-HARDENING-QA-v1.9.0.json').write_text(json.dumps({'result':'PASS' if not failed else 'FAIL','gates':checks,'renders':total,'issues':issues,'pageErrors':page_errors},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks),'gates',total,'renders','issues',len(issues))
if issues:
  for x in issues[:50]: print(x)
if failed: raise SystemExit(1)
