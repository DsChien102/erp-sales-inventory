#!/usr/bin/env python3
from pathlib import Path
import re,json,sys,shutil
from playwright.sync_api import sync_playwright
ROOT=Path(__file__).resolve().parents[1];QA=Path(__file__).resolve().parent;CAP=QA/'v3101-bj09-captures'
if CAP.exists(): shutil.rmtree(CAP)
CAP.mkdir(exist_ok=True)
def inline(root):
 h=(root/'index.html').read_text(encoding='utf-8');h=re.sub(r'<link[^>]+href="https://fonts.googleapis.com[^"]*"[^>]*>','',h)
 for fn in re.findall(r'<link[^>]+href="([^"]+\.css(?:\?[^\"]*)?)"[^>]*>',h):
  p=root/fn.split('?')[0];h=re.sub(rf'<link[^>]+href="{re.escape(fn)}"[^>]*>',f'<style>{p.read_text(encoding="utf-8")}</style>' if p.exists() else '',h,count=1)
 for fn in re.findall(r'<script[^>]+src="([^"]+\.js(?:\?[^\"]*)?)"[^>]*>\s*</script>',h):
  p=root/fn.split('?')[0];h=h.replace(f'<script src="{fn}"></script>',f'<script>{p.read_text(encoding="utf-8")}</script>' if p.exists() else '')
 return h
checks=[]
def ck(n,c,note=''):checks.append({'name':n,'pass':bool(c),'note':str(note)[:900]})
errs=[]; capn=0
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage']);p=b.new_page(viewport={'width':1450,'height':1050});p.set_default_timeout(5000);p.on('pageerror',lambda e:errs.append(str(e)));h=inline(ROOT)
 def reset():p.goto('about:blank');p.set_content(h,wait_until='load',timeout=30000);p.wait_for_timeout(20)
 def go(s,st='READY',selected='amox'):
  p.evaluate('([s,t,id])=>{activeFlowId="UIF-09";ic09Selected=id;activeScreenId=s;stateByScreen[s]=t;render()}',[s,st,selected]);p.wait_for_timeout(15);return p.locator('#app-screen').inner_text()
 def snap(name):
  global capn
  p.locator('#app-screen').screenshot(path=str(CAP/f'{name}.png'));capn+=1
 def state():return p.evaluate('()=>({screen:activeScreenId,state:stateByScreen[activeScreenId]})')
 reset();t=go('SCR-036');snap('01-SCR036-LIST')
 ck('list uses user-facing Dùng thử and no technical enum leakage','Dùng thử' in t and 'TRIAL' not in t and 'DEMO' not in t,t)
 ck('list keeps search and five business filters',p.locator('input[placeholder="Tìm sản phẩm hoặc lô"]').count()==1 and p.locator('[data-ic09-filter]').count()==6,t)
 m=p.evaluate('''()=>{const w=document.querySelector('.ac321-chip-wrap');return w?{scroll:w.scrollWidth,client:w.clientWidth,wrap:getComputedStyle(w).flexWrap}:null}''');ck('filter strip stays compact/horizontal without forcing screen overflow',m and m['wrap'] in ['nowrap',''] and p.locator('#app-screen').evaluate('e=>e.scrollWidth-e.clientWidth')<1,m)
 t=go('SCR-037','READY','amox');snap('02-SCR037-SELLABLE')
 ck('sellable detail shows business identity, physical and available facts',all(x in t for x in ['Amox 500','L2407-A','Bán được','Tồn vật lý','Khả dụng bán']),t)
 ck('sellable detail exposes one contextual state-change CTA',p.locator('[data-ic09-action="change"]').count()==1 and 'Thay đổi tình trạng' in t,t)
 t=go('SCR-037','EXPIRED','vitc');snap('03-SCR037-EXPIRED')
 ck('expired detail explains automatic expiry from business date','Lô đã hết hạn' in t and 'Hệ thống tự loại khỏi khả dụng' in t and 'ngày nghiệp vụ' in t,t)
 ck('expired detail has no manual state-change CTA',p.locator('[data-ic09-action="change"]').count()==0 and 'đánh dấu hết hạn' in t,t)
 t=go('SCR-037','LOCKED','amox');ck('stock-count locked detail is true read-only',p.locator('[data-ic09-action="change"]').count()==0 and 'chỉ đọc' in t.lower(),t)
 t=go('SCR-038','READY','amox');p.evaluate('window.__VET45_V3101__.setDraft({destination:"QUARANTINE",quantity:"5",reason:"Bao bì rách",evidence:""});render()');t=p.locator('#app-screen').inner_text();snap('04-SCR038-FORM')
 ck('state-change form presents current state as read-only context','Từ' in t and 'Bán được' in t and p.locator('input[name="current-state"]').count()==0,t)
 vals=p.locator('[data-v3101-destination]').evaluate_all('els=>els.map(e=>e.value)');ck('destinations contain policy-allowed business states only','EXPIRED' not in vals and 'TRIAL' not in vals and all(x not in vals for x in ['VALUATION_PENDING','RETURN_PENDING','RTV_PENDING']) and set(vals)=={'QUARANTINE','DAMAGED','DEMO'},vals)
 ck('partial quantity is explicit user input',p.locator('[data-v3101-qty]').count()==1 and p.locator('[data-v3101-qty]').input_value()=='5',t)
 ck('form does not expose valuation/balance/hash/version controls',p.locator('[name*="valuation" i],[name*="balance" i],[name*="hash" i],[name*="version" i]').count()==0 and not re.search(r'valuation|balance id|basis hash|policy hash',t,re.I),t)
 ck('form copy stays Vietnamese/business-facing',not re.search(r'\b(?:policy|backend|hash|valuation|snapshot|enum|Inspect)\b',t,re.I) and 'lát giá trị' not in t,t)
 p.fill('[data-v3101-reason]','');p.click('[data-v3101-action="submit"]');t=p.locator('#app-screen').inner_text();snap('05-SCR038-VALIDATION')
 ck('validation is persistent inline/banner and keeps entered quantity',state()['state']=='VALIDATION_ERROR' and 'Chưa đủ thông tin' in t and p.locator('[data-v3101-qty]').input_value()=='5',t)
 p.evaluate('stateByScreen["SCR-038"]="READY";window.__VET45_V3101__.setDraft({destination:"QUARANTINE",quantity:"5",reason:"Bao bì rách",evidence:""});render()');p.click('[data-v3101-action="submit"]');t=p.locator('#app-screen').inner_text();snap('06-SCR038-PENDING')
 ck('maker pending surface explicitly says inventory has not changed','Đã gửi chờ duyệt' in t and 'Tồn kho chưa thay đổi' in t,t)
 ck('maker pending surface has no approve/reject/state-write CTA',p.locator('[data-v3101-action="approve"],[data-v3101-action="reject-open"],[data-v3101-action="submit"]').count()==0,t)
 p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-038"]="APPROVAL_REVIEW";render()');t=p.locator('#app-screen').inner_text();snap('07-SCR038-APPROVAL')
 ck('approval focuses on business evidence and impact',all(x in t for x in ['Sản phẩm','Lô','Từ','Sang','Số lượng','Lý do','Tác động khả dụng']),t)
 ck('approval hides basis hashes, policy versions and valuation slices',not re.search(r'\b(?:basis|hash|policy|version|valuation|balance)\b',t,re.I),t)
 ck('approval exposes only decision actions',p.locator('[data-v3101-action="approve"]').count()==1 and p.locator('[data-v3101-action="reject-open"]').count()==1 and p.locator('[data-v3101-action="submit"]').count()==0,t)
 p.click('[data-v3101-action="reject-open"]');snap('08-SCR038-REJECT-SHEET');disabled=p.locator('[data-v3101-action="reject-confirm"]').is_disabled();ck('reject confirmation starts disabled without a reason',disabled)
 p.fill('[data-v3101-reject-reason]','Cần kiểm lại bằng chứng');enabled=not p.locator('[data-v3101-action="reject-confirm"]').is_disabled();ck('reject CTA enables immediately after valid reason',enabled)
 p.click('[data-v3101-action="reject-confirm"]');t=p.locator('#app-screen').inner_text();ck('reject result is final and explicitly zero stock effect',state()['state']=='REJECTED_EXECUTION' and 'Yêu cầu chưa được thực hiện' in t and 'Tác động tồn kho' in t and 'Không có' in t and p.evaluate('window.__VET45_V3101__.getMovement()') is None,t)
 reset();go('SCR-038','READY','amox');p.evaluate('window.__VET45_V3101__.setDraft({destination:"QUARANTINE",quantity:"5",reason:"Bao bì rách",evidence:""});render()');p.click('[data-v3101-action="submit"]');p.evaluate('window.__VET45_V350__.setActor("approver");stateByScreen["SCR-038"]="APPROVAL_REVIEW";render()');p.click('[data-v3101-action="approve"]');t=p.locator('#app-screen').inner_text();ck('approve enters system-processing surface instead of claiming immediate stock write',state()['state']=='PROCESSING' and 'Đang kiểm tra và ghi nhận' in t and p.locator('[data-v3101-action]').count()==0,t)
 p.wait_for_timeout(260);t=p.locator('#app-screen').inner_text();snap('09-SCR041-COMPLETED');ck('completed result states physical quantity is unchanged','Tồn vật lý' in t and 'Không đổi' in t,t)
 ck('completed result states book value is unchanged','Giá trị ghi sổ' in t and 'Không đổi' in t,t)
 ck('completed result exposes actionable reservation impact','Cần phân bổ lại' in t and '3 hộp' in t,t)
 p.click('[data-ic09-action="history"]');t=p.locator('#app-screen').inner_text();ck('history is business-readable without technical identifiers',all(x in t for x in ['Biến động','Số lượng','Ghi nhận lúc']) and not re.search(r'MOV-STATE|basis|hash|valuation|balance|Inspect',t,re.I),t)
 reset();go('SCR-038','READY','amox');p.evaluate('window.__VET45_V3101__.setDraft({destination:"DEMO",quantity:"2",reason:"Dùng thử",evidence:""});window.__VET45_V3101__.buildBasis();window.__VET45_V3101__.setStaleOnExecute(true);activeScreenId="SCR-041";stateByScreen["SCR-041"]="PROCESSING";window.__VET45_V3101__.systemCommit()');t=p.locator('#app-screen').inner_text();snap('10-SCR041-STALE');ck('stale result says no stock change and requires a new request',state()['state']=='STATE_CHANGE_BASIS_STALE' and 'không thay đổi' in t.lower() and 'lập yêu cầu mới' in t.lower(),t)
 t=go('SCR-041','UNKNOWN','amox');ck('UNKNOWN prohibits blind resubmit and routes to verification','Không gửi yêu cầu mới' in t and 'Chuyển sang xác minh' in t,t)
 # Canonical geometry and AppBar target after shared fix.
 bad=[]
 for sid,stt,sel in [('SCR-036','READY','amox'),('SCR-037','READY','amox'),('SCR-037','EXPIRED','vitc'),('SCR-038','READY','amox'),('SCR-041','UNKNOWN','amox')]:
  go(sid,stt,sel);m=p.evaluate('''()=>{const r=document.querySelector('#app-screen'),c=r.querySelector('.app-content'),back=r.querySelector('.app-back-button');return {w:r.offsetWidth,h:r.offsetHeight,ox:r.scrollWidth-r.clientWidth,cx:c?(c.scrollWidth-c.clientWidth):0,bw:back?back.getBoundingClientRect().width:null,bh:back?back.getBoundingClientRect().height:null}}''');
  if m['w']!=402 or m['h']!=874 or m['ox']>.75 or m['cx']>.75 or (m['bw'] is not None and (m['bw']<43.5 or m['bh']<43.5)):bad.append((sid,stt,m))
 ck('focused BJ09 surfaces fit 402x874 and AppBar back target is at least 44x44',not bad,bad)
 ck('fresh-eye run has no browser errors and exactly ten captures',not errs and capn==10,{'errors':errs,'captures':capn})
 b.close()
if len(checks)!=31:
 print('INTERNAL QA DEFINITION ERROR expected 31 got',len(checks));sys.exit(2)
status='PASS' if all(x['pass'] for x in checks) else 'FAIL';out={'version':'3.10.1','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks,'browserErrors':errs,'captures':capn}
(QA/'BJ09-FRESH-EYE-QA-v3.10.1.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');(QA/'BJ09-FRESH-EYE-QA-v3.10.1.md').write_text('\n'.join(['# BJ09 Fresh-eye QA — v3.10.1','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','',f'Captures: **{capn}**','']+[f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}'+(f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks])+'\n',encoding='utf-8');print(status,out['passed'],out['total'],'captures',capn)
if status!='PASS':
 for x in checks:
  if not x['pass']:print('FAIL',x['name'],'::',x['note'])
 sys.exit(1)
