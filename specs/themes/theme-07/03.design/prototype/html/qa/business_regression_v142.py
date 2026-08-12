from pathlib import Path
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
idx=(ROOT/'index.html').read_text(); css=(ROOT/'tokens.generated.css').read_text()+'\n'+(ROOT/'styles.css').read_text(); data=(ROOT/'workbench-data.js').read_text(); app=(ROOT/'app.js').read_text()
html=idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','').replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>').replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>').replace('<script src="app.js"></script>',f'<script>{app}</script>')
checks=[]
def ck(n,c): checks.append((n,bool(c)))
def fresh(page): page.goto('about:blank'); page.set_content(html); page.wait_for_timeout(30)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox']); page=b.new_page(viewport={'width':1400,'height':1050}); errs=[]; page.on('pageerror',lambda e:errs.append(str(e))); page.set_content(html); page.wait_for_timeout(40)
 # BJ03: selected quantity changes valuation scope only.
 page.evaluate('val03SelectedReceiptId="VAL03-R1";var r=val03Current();r.groups.forEach(g=>g.slices.forEach(s=>s.selected=false));r.groups[0].slices[0].selected=true;r.groups[0].slices[0].selectedQty=10;')
 ck('BJ03 selected quantity participates in valuation scope',page.evaluate('val03GroupSelectedQty(val03Current().groups[0])')==10)
 ck('BJ03 pending received quantity is not mutated before commit',page.evaluate('val03Current().groups[0].slices[0].pendingQty')==96)
 # source conflict needs explicit source + reason
 page.evaluate('var g=val03Current().groups[1];g.slices[0].selected=true;g.slices[0].selectedQty=5;g.selectedSource="";g.reason="";')
 ck('BJ03 source conflict blocks readiness without explicit resolution',not page.evaluate('val03ScopeReady()'))
 page.evaluate('var g=val03Current().groups[1];g.selectedSource=g.sources[0].id;g.reason="Đối chiếu theo đơn mua hiện hành";')
 ck('BJ03 conflict becomes ready after source + reason',page.evaluate('val03ScopeReady()'))
 # BJ05 partial source policy remains behavior, not UI invention.
 fresh(page); ck('BJ05 partial-enabled order can review after some valid pick',page.evaluate('io05SelectedOrderId="SO-260827-21";io05CanReview()'))
 ck('BJ05 waiting order cannot review',not page.evaluate('io05SelectedOrderId="SO-260827-24";io05CanReview()'))
 # BJ06 wrong lot requires approval state before atomic receipt ready.
 fresh(page); page.evaluate('io06SelectedRequestId="RET-260827-03"; var l=io06CurrentLines()[0]; l.qty=2;l.actualLot="DH2509";l.actualLotMode="OTHER";l.verified=true;l.reasonCode="ACTUAL_DIFF";l.evidenceFile="lot.jpg";l.evidenceData=io06EvidenceSvg("DH2509");io06RefreshRequestState(io06CurrentRequest());')
 ck('BJ06 wrong-LOT creates non-normal approval state',page.evaluate('io06LineApprovalState(io06CurrentLines()[0])') in ['DRAFT','PENDING','APPROVED','REJECTED'])
 ck('BJ06 receipt not ready while request lines/approvals incomplete',not page.evaluate('io06ReceiptReady(io06CurrentRequest())'))
 # BJ07 granular source update invalidates only affected allocation.
 fresh(page); page.evaluate('io07Selected="RTV-260827-02";io07Allocations().forEach(x=>{x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false;});')
 before=page.evaluate('io07VerifiedCount()'); ck('BJ07 fixture starts with all current allocations verified',before==4)
 page.evaluate('io07ApplySourceUpdate("RTV-260827-02",[{type:"QTY",allocationId:"RTV-A2",newQty:1,note:"test"}]);')
 ck('BJ07 source delta invalidates only one affected allocation',page.evaluate('io07VerifiedCount()')==3)
 ck('BJ07 unaffected allocations retain evidence',page.evaluate('io07Allocations().filter(x=>x.allocation.id!=="RTV-A2").every(x=>x.allocation.verified)'))
 ck('BJ07 affected allocation is marked for recheck',page.evaluate('io07FindAllocation("RTV-A2").allocation.affectedByChange'))
 ck('BJ07 final review is blocked until all current allocations verified',not page.evaluate('io07AllVerified()'))
 # mismatch hard guard
 page.evaluate('var a=io07FindAllocation("RTV-A1").allocation;a.physicalMismatch=true;a.verified=false;')
 ck('BJ07 physical mismatch hard-blocks handover readiness',page.evaluate('io07HasMismatch()') and not page.evaluate('io07AllVerified()'))
 # mixed UOM groups remain separate in exact source model.
 ck('BJ07 same Product different UOM remains separate groups',page.evaluate('io07Current().groups.filter(g=>g.code==="SP-00142").length')==2)
 # finality: UNKNOWN has no commit button
 page.evaluate('activeFlowId="UIF-07";activeScreenId="SCR-041";stateByScreen["SCR-041"]="UNKNOWN";render();'); page.wait_for_timeout(20)
 ck('BJ07 UNKNOWN has no blind handover retry',page.locator('[data-io07-action="confirm-handover"]').count()==0)
 ck('No JavaScript errors in regression',not errs)
 b.close()
passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Business Invariant Regression v1.4.2','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Purpose: prove the semantic-hierarchy correction did not change core BJ03/BJ05/BJ06/BJ07 business behavior.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'BUSINESS-INVARIANT-REGRESSION-v1.4.2.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
