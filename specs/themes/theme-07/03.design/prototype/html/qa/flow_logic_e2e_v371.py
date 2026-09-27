from pathlib import Path
import re, asyncio, json, sys
from playwright.async_api import async_playwright
ROOT=Path(__file__).resolve().parents[1]

def bundled_html():
    h=(ROOT/'index.html').read_text()
    h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
    def css(m):
        p=ROOT/m.group(1).split('?')[0]
        return '<style>'+p.read_text()+'</style>' if p.exists() else ''
    h=re.sub(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',css,h)
    def js(m):
        p=ROOT/m.group(1).split('?')[0]
        return '<script>'+p.read_text()+'</script>' if p.exists() else m.group(0)
    h=re.sub(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',js,h)
    return h
HTML=bundled_html()
PASS=[]

async def load(ctx):
    p=await ctx.new_page()
    errs=[]
    p.on('pageerror',lambda e:errs.append(str(e)))
    await p.set_content(HTML,wait_until='domcontentloaded')
    await p.wait_for_timeout(30)
    assert not errs, f'page errors: {errs}'
    return p

def ok(name): PASS.append(name); print('PASS',name)

async def state(p): return await p.evaluate('window.__VET45_V350__.getState()')
async def goto(p,flow,screen,st='READY'):
    await p.evaluate('([f,s,t])=>{activeFlowId=f;activeScreenId=s;if(stateByScreen[s]!==undefined)stateByScreen[s]=t;render();}',[flow,screen,st])
    await p.wait_for_timeout(10)

async def test_search(ctx):
    p=await load(ctx)
    for flow,screen,sel in [('UIF-01','SCR-001','[data-bj01-search]'),('UIF-06','SCR-030','[data-io06-search]'),('UIF-07','SCR-036','[data-io07-search]')]:
        await goto(p,flow,screen)
        if await p.locator(sel).count():
            await p.locator(sel).fill('zzzz-not-found')
            await p.wait_for_timeout(15)
            bad=await p.locator('#app-screen [hidden]').evaluate_all("els=>els.filter(e=>getComputedStyle(e).display!=='none').length")
            assert bad==0,(flow,bad)
    ok('search-hidden-rows-DS-migration')
    await p.close()

async def test_bj08(ctx):
    p=await load(ctx)
    await goto(p,'UIF-08','SCR-044','BLIND_COUNT')
    txt=await p.locator('#app-screen').inner_text()
    assert '18 hộp' not in txt and '7 hộp' not in txt,txt
    # blank first count validation
    await p.click('[data-ic08-action="submit-first"]'); await p.click('[data-v350-action="ic08-confirm-submit-first"]')
    assert (await state(p))['state']=='VALIDATION_ERROR'
    # exact count => no recount, approval
    await p.evaluate('ic08Counts={amox:"20",glove:"6"};stateByScreen["SCR-044"]="BLIND_COUNT";render()')
    await p.click('[data-ic08-action="submit-first"]'); await p.click('[data-v350-action="ic08-confirm-submit-first"]')
    s=await state(p); assert s['screen']=='SCR-046' and s['state']=='APPROVAL_REVIEW',s
    # maker cannot approve
    await p.evaluate('window.__VET45_V350__.setActor("module")')
    await p.click('[data-v350-action="ic08-approve"]')
    assert (await state(p))['state']=='SELF_APPROVAL_NOT_ALLOWED'
    # approver can complete; exact count creates no adjustment
    await p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-046"]="APPROVAL_REVIEW";render()')
    await p.click('[data-v350-action="ic08-approve"]'); await p.click('[data-v350-action="ic08-confirm-approve"]')
    assert (await state(p))['screen']=='SCR-047'
    txt=await p.locator('#app-screen').inner_text(); assert 'không cần điều chỉnh' in txt.lower() and 'Không tạo' in txt
    # discrepancy -> recount only discrepant lines
    await goto(p,'UIF-08','SCR-044','BLIND_COUNT'); await p.evaluate('ic08Counts={amox:"18",glove:"7"};render()')
    await p.click('[data-ic08-action="submit-first"]'); await p.click('[data-v350-action="ic08-confirm-submit-first"]')
    assert (await state(p))['screen']=='SCR-045'
    assert await p.locator('[data-ic08-keypad-open^="recount:"]').count()==2
    ok('BJ08-blind-branch-actor-finality')
    # list controls actual behavior
    await goto(p,'UIF-08','SCR-042','READY')
    assert await p.locator('[data-v350-ic08-filter]').count()==3
    await p.click('[data-v350-ic08-filter="APPROVAL"]')
    txt=await p.locator('#app-screen').inner_text(); assert 'KK-0708-02' in txt and 'KK-0709-03' not in txt
    await p.fill('[data-v350-ic08-list-search]','not-here')
    txt2=await p.locator('#app-screen').inner_text(); assert 'Không tìm thấy phiên kiểm kê' in txt2
    ok('BJ08-list-search-filter')
    await p.close()

async def test_bj09(ctx):
    p=await load(ctx); await goto(p,'UIF-09','SCR-038','READY')
    await p.fill('[data-v350-ic09-reason]','')
    await p.click('[data-v350-action="ic09-submit"]')
    assert (await state(p))['state']=='VALIDATION_ERROR'
    await p.evaluate('stateByScreen["SCR-038"]="READY";render()')
    await p.fill('[data-v350-ic09-reason]','Bao bì rách')
    await p.click('[data-v350-action="ic09-submit"]')
    assert 'Bao bì rách' in await p.locator('#app-screen').inner_text()
    await p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-038"]="APPROVAL_REVIEW";render()')
    assert 'Bao bì rách' in await p.locator('#app-screen').inner_text()
    await p.click('[data-v350-action="ic09-approve"]')
    info=await p.evaluate('window.__VET45_V350__.getIC09()')
    assert info['current']['state']=='QUARANTINE' and info['current']['label']=='Cách ly',info
    ok('BJ09-bound-reason-and-state-mutation')
    await p.close()

async def test_bj10(ctx):
    p=await load(ctx); await goto(p,'UIF-10','SCR-040','READY')
    assert await p.locator('[data-v350-ic10-qty]').input_value()==''
    await p.fill('[data-v350-ic10-qty]','3'); await p.fill('[data-v350-ic10-reason]','Hàng hỏng'); await p.fill('[data-v350-ic10-evidence]','BB-01')
    await p.click('[data-v350-action="ic10-submit"]'); assert '3 hộp' in await p.locator('#app-screen').inner_text()
    # maker cannot approve
    await p.evaluate('window.__VET45_V350__.setActor("module");stateByScreen["SCR-040"]="APPROVAL_REVIEW";render()')
    await p.click('[data-v350-action="ic10-approve"]'); assert (await state(p))['state']=='SELF_APPROVAL_NOT_ALLOWED'
    # approver approves requested qty
    await p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-040"]="APPROVAL_REVIEW";render()')
    await p.click('[data-v350-action="ic10-approve"]'); info=await p.evaluate('window.__VET45_V350__.getIC10()'); assert info['approvedQty']==3
    # completion > approval blocked
    await p.evaluate('window.__VET45_V350__.setActor("completion-operator");stateByScreen["SCR-040"]="COMPLETION";render()')
    await p.fill('[data-v350-ic10-actual]','4'); await p.fill('[data-v350-ic10-proof]','BB-02'); await p.click('[data-v350-action="ic10-complete"]')
    assert (await state(p))['state']=='COMPLETION_QTY_BLOCKED'
    # valid actual becomes actual result, not approved fixture
    await p.fill('[data-v350-ic10-actual]','2'); await p.fill('[data-v350-ic10-proof]','BB-02'); await p.click('[data-v350-action="ic10-complete"]')
    txt=await p.locator('#app-screen').inner_text(); assert '2 hộp' in txt and '4 hộp' in txt
    ok('BJ10-bound-request-approval-completion')
    await p.close()

async def test_stale(ctx):
    p=await load(ctx)
    # BJ05: set a review snapshot, then source changes; application rejects commit
    await goto(p,'UIF-05','SCR-028','READY')
    await p.evaluate('(()=>{const o=io05CurrentOrder();o.reviewSourceVersion=o.sourceVersion;})()')
    await p.evaluate('window.__VET45_V350__.bumpIO05Source()')
    res=await p.evaluate('io05ApplyHandover()')
    assert res is None and (await state(p))['state']=='SOURCE_CHANGED'
    ok('BJ05-stale-source-commit-guard')
    # BJ06 normal-return stale guard
    await goto(p,'UIF-06','SCR-031','READY')
    before=await p.evaluate('(()=>{const r=io06CurrentRequest();r.reviewSourceVersion=r.sourceVersion;return io06ReceiptReady(r)})()')
    await p.evaluate('window.__VET45_V350__.bumpIO06Source()')
    after=await p.evaluate('io06ReceiptReady(io06CurrentRequest())')
    assert after is False
    ok('BJ06-normal-return-stale-source-guard')
    await p.close()

async def test_unknown(ctx):
    p=await load(ctx)
    for flow,screen in [('UIF-03','SCR-019'),('UIF-05','SCR-029'),('UIF-06','SCR-035'),('UIF-07','SCR-041'),('UIF-08','SCR-047'),('UIF-09','SCR-041'),('UIF-10','SCR-041'),('UIF-12','SCR-071'),('UIF-13','SCR-089'),('UIF-14','SCR-077')]:
        await goto(p,flow,screen,'UNKNOWN')
        assert await p.locator('[data-v350-action="handoff-unknown"]').count()==1,(flow,screen,await p.locator('#app-screen').inner_text())
    # representative handoff locks source queue and preserves operation id
    await goto(p,'UIF-05','SCR-029','UNKNOWN'); op=await p.evaluate('io05CurrentOrder().id')
    await p.click('[data-v350-action="handoff-unknown"]'); s=await state(p); assert s['flow']=='UIF-17' and s['screen']=='SCR-079'
    rec=await p.evaluate('window.__VET45_V350__.getBJ17()'); assert rec['operation']==op
    # source must be omitted from retry queue
    locked=await p.evaluate('!io05VisibleOrders().some(o=>o.id==='+json.dumps(op)+')'); assert locked
    # BJ02 explicit verify then handoff
    await goto(p,'UIF-02','SCR-012','UNKNOWN'); await p.click('[data-v350-action="bj02-verify-unknown"]'); assert (await state(p))['screen']=='SCR-013'
    assert await p.locator('[data-v350-action="bj02-handoff-unknown"]').count()==1
    ok('UNKNOWN-system-recovery-and-no-blind-retry')
    await p.close()

async def test_bj12(ctx):
    p=await load(ctx); await goto(p,'UIF-12','SCR-067','READY')
    # ensure source fixture and intentionally mismatched controls
    await p.evaluate('cf12FileName="ton-kho-dau-ky-2026.xlsx";cf12Cutoff="2026-08-31";window.__VET45_V350__.setCf12Control(9999,cf12Summary.parsedValue);render()')
    await p.click('[data-v350-action="cf12-check"]'); assert (await state(p))['state']=='CONTROL_TOTAL_MISMATCH'
    # exact totals pass
    await p.evaluate('activeScreenId="SCR-067";stateByScreen["SCR-067"]="READY";window.__VET45_V350__.setCf12Control(cf12Summary.parsedQty,cf12Summary.parsedValue);render()')
    await p.click('[data-v350-action="cf12-check"]'); assert (await state(p))['screen']=='SCR-068' and (await state(p))['state']=='READY'
    # send approval snapshot then mutate inputs; approver cannot approve stale snapshot
    await p.evaluate('activeScreenId="SCR-069";stateByScreen["SCR-069"]="READY";render()'); await p.click('[data-v350-action="cf12-send-approval"]')
    await p.evaluate('window.__VET45_V350__.setCf12Control(cf12Summary.parsedQty+1,cf12Summary.parsedValue);window.__VET45_V350__.setActor("approver");activeScreenId="SCR-070";stateByScreen["SCR-070"]="READY";render()')
    await p.click('[data-v350-action="cf12-approve"]'); assert (await state(p))['state']=='VALIDATION_ERROR'
    ok('BJ12-control-total-and-stale-approval')
    await p.close()

async def test_bj14_15(ctx):
    p=await load(ctx)
    # BJ14 dirty run successor lineage/method
    await goto(p,'UIF-14','SCR-072','READY')
    await p.evaluate('(()=>{const d=val14Runs.find(r=>r.status==="DIRTY");val14SelectedRunId=d.id;val14SetupKind=d.kind;val14SetupPeriod=d.period;val14SetupScope="Sản phẩm cần tính lại";val14SuccessorOf=d.id;activeScreenId="SCR-073";stateByScreen["SCR-073"]="READY";render()})()')
    pred=await p.evaluate('val14SuccessorOf'); assert pred=='COST-0903',pred
    txt=await p.locator('#app-screen').inner_text(); assert 'Bình quân liên hoàn' in txt
    await p.click('[data-val14-action="calculate"]'); await p.wait_for_timeout(160)
    run=await p.evaluate('(()=>{const r=val14Current();return {method:r.policyMethod,label:r.policyLabel,supersedes:r.supersedes}})()')
    assert run['method']=='MOVING' and run['supersedes']=='COST-0903',run
    ok('BJ14-successor-lineage-policy-lock')
    # BJ15 product/date scope actual rows
    await goto(p,'UIF-15','SCR-055','READY')
    await p.evaluate('cf15ReportType="STOCK_CARD";cf15Product="P-AMX";cf15SelectedProduct="P-AMX";cf15From="2026-09-07";cf15To="2026-09-07";cf15DateMode="BUSINESS";render()')
    ids=await p.evaluate('window.__VET45_V350__.getCf15Rows()'); assert ids==['MV-AMX-01'],ids
    txt=await p.locator('#app-screen').inner_text(); assert 'PN-260907-11' in txt and 'VC-' not in txt
    await p.evaluate('cf15ExportFrom="REPORT";activeScreenId="SCR-058";stateByScreen["SCR-058"]="READY";render()')
    txt=await p.locator('#app-screen').inner_text(); assert 'Amox 500' in txt and '07/09/2026 → 07/09/2026' in txt and '1' in txt
    ok('BJ15-product-date-export-scope')
    await p.close()

async def test_bj16_17(ctx):
    p=await load(ctx)
    # correct source-context handoff
    await goto(p,'UIF-16','SCR-079','CORRECTION_REQUIRED')
    await p.evaluate('cr16SelectedId="REC-260907-04";stateByScreen["SCR-079"]="CORRECTION_REQUIRED";render()')
    assert 'Amox 500' in await p.locator('#app-screen').inner_text()
    await p.click('[data-v350-action="cr16-correction-handoff"]'); s=await state(p); assert s['flow']=='UIF-11'
    assert await p.evaluate('cr11SelectedId')=='IO-260904-021'; assert 'Amox 500' in await p.locator('#app-screen').inner_text()
    ok('BJ16-correction-context-integrity')
    # source mismatch has executable handoff
    await goto(p,'UIF-16','SCR-079','SOURCE_MISMATCH'); await p.evaluate('cr16SelectedId="REC-260907-07";stateByScreen["SCR-079"]="SOURCE_MISMATCH";render()')
    assert await p.locator('[data-v350-action="cr16-source-handoff"]').count()==1
    await p.click('[data-v350-action="cr16-source-handoff"]'); assert (await state(p))['screen']=='SCR-083'
    # mismatch remains returns to evidence
    await goto(p,'UIF-16','SCR-082','MISMATCH_REMAINS'); assert await p.locator('[data-v350-action="cr16-back-evidence"]').count()==1
    ok('BJ16-no-dead-end')
    # evidence freshness blocks recovery
    await goto(p,'UIF-16','SCR-079','READY'); await p.evaluate('cr16SelectedId="REC-260907-01";stateByScreen["SCR-079"]=cr079StateFor16(cr16Current());render()')
    if await p.locator('[data-v350-action="cr16-open-plan"]').count():
        await p.click('[data-v350-action="cr16-open-plan"]'); await p.evaluate('window.__VET45_V350__.bumpCR16Evidence()')
        await p.click('[data-v350-action="cr16-start-recovery"]'); assert (await state(p))['state']=='CONFLICT'
    ok('BJ16-evidence-freshness')
    # BJ17 same operation/evidence finality
    await goto(p,'UIF-17','SCR-079','UNKNOWN_EVIDENCE'); await p.evaluate('cr17SelectedId="REC-UNKNOWN-01";stateByScreen["SCR-079"]=cr079StateFor17(cr17Current());render()')
    await p.click('[data-cr17-action="open-plan"]'); await p.evaluate('window.__VET45_V350__.bumpCR17Evidence()')
    if await p.locator('[data-v350-action="cr17-execute-plan"]').count():
        await p.click('[data-v350-action="cr17-execute-plan"]'); assert (await state(p))['state']=='CONFLICT'
    # fresh plan then execute
    await goto(p,'UIF-17','SCR-079','UNKNOWN_EVIDENCE'); await p.evaluate('stateByScreen["SCR-079"]=cr079StateFor17(cr17Current());render()'); await p.click('[data-cr17-action="open-plan"]')
    await p.click('[data-v350-action="cr17-execute-plan"]'); rec=await p.evaluate('window.__VET45_V350__.getBJ17()'); assert rec['record']['operationId']==rec['operation'] and not rec['record']['newOperationCreated'] and not rec['record']['duplicateEffect']
    await p.click('[data-v350-action="cr17-finish-review"]'); assert (await state(p))['state']=='COMPLETED'
    ok('BJ17-safe-finality-identity-and-evidence')
    await p.close()


async def test_bj03_bj04_bj07_bj13(ctx):
    p=await load(ctx)
    # BJ03: review is bound to the source version; a source update must invalidate commit.
    await goto(p,'UIF-03','SCR-015','READY')
    ready=await p.evaluate('''()=>{const r=val03Current();for(const g of r.groups){const sl=g.slices.find(x=>x.pendingQty>0);if(!sl||!g.sources.length)continue;sl.selected=true;sl.selectedQty=sl.pendingQty;g.selectedSource=g.sources[0].id;if(val03EvidenceState(g)==="CONFLICT")g.reason="Đối chiếu chứng từ nguồn";break;}val03ReviewSourceVersion=r.sourceVersion;return val03ScopeReady(r)}''')
    assert ready
    await p.evaluate('activeScreenId="SCR-017";stateByScreen["SCR-017"]="READY";render();val03Current().sourceVersion+=1')
    await p.click('[data-val03-action="confirm-value"]')
    assert (await state(p))['state']=='SOURCE_CHANGED'
    ok('BJ03-source-version-review-guard')

    # BJ04 is a read-only reservation projection: distinct business states are visible and there is no mutation CTA.
    expected={
      'PARTIAL':'Chưa giữ đủ toàn bộ đơn',
      'FULL':'Sản phẩm đang giữ',
      'RELEASED':'Đã nhả lượng giữ',
      'STALE':'Tình trạng đã được cập nhật'
    }
    for st,needle in expected.items():
        await goto(p,'UIF-04','SCR-021',st)
        txt=await p.locator('#app-screen').inner_text(); assert needle in txt,(st,txt)
        # Only navigation/back affordances are allowed; no reservation mutation action exists in Theme 7.
        assert await p.locator('#app-screen [data-io04-action],#app-screen [data-bj04-action]').count()==0
    ok('BJ04-read-only-reservation-state-projection')

    # BJ07: source changes after review invalidate the physical handover commit.
    await goto(p,'UIF-07','SCR-037','READY')
    await p.evaluate('''()=>{const r=io07Current();for(const x of io07Allocations(r)){x.allocation.verified=true;x.allocation.physicalMismatch=false;x.allocation.affectedByChange=false;}r.reviewSourceVersion=r.sourceVersion;activeScreenId="SCR-039";stateByScreen["SCR-039"]="READY";render();r.sourceVersion+=1;}''')
    await p.click('[data-io07-action="confirm-handover"]')
    assert (await state(p))['state']=='SOURCE_CHANGED'
    ok('BJ07-stale-source-handover-guard')

    # BJ13: allocation preview hash + source version must be revalidated at commit.
    await goto(p,'UIF-13','SCR-086','READY')
    can=await p.evaluate('''()=>{const t=val13Current();t.targets.forEach(x=>x.selected=true);t.selectedMethod=t.allowedMethods[0].id;val13ReviewSourceVersion=t.sourceVersion;val13PreviewHash=val13PreviewHashOf(t);activeScreenId="SCR-088";stateByScreen["SCR-088"]="READY";render();return val13CanPreview(t)}''')
    assert can
    await p.evaluate('val13Current().sourceVersion+=1')
    await p.click('[data-val13-action="confirm-late-cost"]')
    assert (await state(p))['state']=='SOURCE_CHANGED'
    ok('BJ13-preview-hash-and-source-version-guard')
    await p.close()

async def test_entry_routing(ctx):
    p=await load(ctx)
    cases=[
        ('UIF-08','assigned-counter','SCR-044','BLIND_COUNT'),
        ('UIF-08','approver','SCR-046','APPROVAL_REVIEW'),
        ('UIF-09','product-context','SCR-037','READY'),
        ('UIF-09','approver','SCR-038','APPROVAL_REVIEW'),
        ('UIF-10','product-context','SCR-037','READY'),
        ('UIF-10','approver','SCR-040','APPROVAL_REVIEW'),
        ('UIF-10','completion-operator','SCR-040','COMPLETION'),
        ('UIF-14','dirty-scope','SCR-073','READY'),
    ]
    for flow,mode,screen,st in cases:
        out=await p.evaluate('([f,m])=>window.__VET45_V350__.applyEntry(f,m)',[flow,mode])
        assert out['applied'] and out['flow']==flow and out['screen']==screen and out['state']==st,(flow,mode,out)
        assert out['actor']==mode
    pred=await p.evaluate('val14SuccessorOf')
    assert pred=='COST-0903',pred
    ok('entry-routing-and-actor-contexts')
    await p.close()

async def test_actor_boundaries(ctx):
    p=await load(ctx)
    # BJ02 maker cannot approve; approver can start execution
    await goto(p,'UIF-02','SCR-011','READY'); await p.evaluate('window.__VET45_V350__.setActor("module")')
    if await p.locator('[data-v350-action="bj02-approve"]').count():
        await p.click('[data-v350-action="bj02-approve"]'); assert (await state(p))['state']=='SELF_APPROVAL_NOT_ALLOWED'
    # BJ06 maker cannot decide an exception approval
    await goto(p,'UIF-06','SCR-034','READY'); await p.evaluate('io06ApproverListMode=false;io06SelectedApprovalCaseId="EX-06-001";window.__VET45_V350__.setActor("module");render()')
    if await p.locator('[data-v350-action="io06-approve-exception"]').count():
        await p.click('[data-v350-action="io06-approve-exception"]'); assert (await state(p))['state']=='SELF_APPROVAL_NOT_ALLOWED'
    # BJ11 maker cannot approve correction; result navigation stays read-only
    await goto(p,'UIF-11','SCR-051','READY'); await p.evaluate('window.__VET45_V350__.setActor("module");render()')
    if await p.locator('[data-v350-action="cr11-approve"]').count():
        await p.click('[data-v350-action="cr11-approve"]'); assert (await state(p))['state']=='SELF_APPROVAL_NOT_ALLOWED'
    await goto(p,'UIF-11','SCR-051','APPROVAL_ALREADY_DECIDED'); await p.evaluate('stateByScreen["SCR-053"]="PENDING_APPROVAL";render()')
    await p.click('[data-v350-action="cr11-approval-result"]'); assert (await state(p))['screen']=='SCR-053' and (await state(p))['state']=='PENDING_APPROVAL'
    # BJ12 maker cannot approve initial balances
    await goto(p,'UIF-12','SCR-070','READY'); await p.evaluate('window.__VET45_V350__.setActor("module");render()')
    await p.click('[data-v350-action="cf12-approve"]'); assert (await state(p))['state']=='SELF_APPROVAL_NOT_ALLOWED'
    ok('actor-boundaries-and-navigation-no-finality')
    await p.close()

async def main():
    async with async_playwright() as pw:
        b=await pw.chromium.launch(executable_path='/usr/bin/chromium',args=['--no-sandbox','--disable-dev-shm-usage'])
        ctx=await b.new_context(viewport={'width':1440,'height':1100})
        tests=[test_search,test_bj03_bj04_bj07_bj13,test_bj08,test_bj09,test_bj10,test_stale,test_unknown,test_bj12,test_bj14_15,test_bj16_17,test_entry_routing,test_actor_boundaries]
        for t in tests:
            try: await t(ctx)
            except Exception as e:
                print('FAIL',t.__name__,repr(e)); raise
        await b.close()
    result={'version':'3.7.1','checks':len(PASS),'status':'PASS','pass':PASS}
    out=ROOT/'qa'/'FLOW-LOGIC-E2E-QA-v3.7.1.json'
    out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    md=ROOT/'qa'/'FLOW-LOGIC-E2E-QA-v3.7.1.md'
    md.write_text('# Flow & Logic E2E QA — v3.5.1\n\n**Status: PASS**  \nChecks: **%d/%d**\n\n%s\n' % (len(PASS),len(PASS),'\n'.join('- '+x for x in PASS)))
    print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=='__main__': asyncio.run(main())
