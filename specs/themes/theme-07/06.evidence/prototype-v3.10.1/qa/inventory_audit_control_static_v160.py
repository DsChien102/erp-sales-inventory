from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]; PRO=ROOT.parent; OUT=Path(__file__).resolve().parent
checks=[]
def ck(n,c): checks.append((n,bool(c)))
wb=json.loads((ROOT/'workbench-data.json').read_text())
ck('Workbench version 1.6.0',wb.get('version')=='1.6.0')
fm={f['id']:f for f in wb['flows']}
ck('UIF08 topology preserved',fm['UIF-08']['screens']==['SCR-042','SCR-043','SCR-044','SCR-045','SCR-046','SCR-047'])
ck('UIF09 topology preserved',fm['UIF-09']['screens']==['SCR-036','SCR-037','SCR-038','SCR-041','SCR-056'])
ck('UIF10 topology preserved',fm['UIF-10']['screens']==['SCR-036','SCR-037','SCR-040','SCR-041'])
sm={s['id']:s for s in wb['screens']}
ck('SCR038 has no visible Save Draft',all(a['id']!='ACT-COMMON-SAVE-DRAFT' for a in sm['SCR-038']['actions']))
ck('SCR040 has no visible Save Draft',all(a['id']!='ACT-COMMON-SAVE-DRAFT' for a in sm['SCR-040']['actions']))
ck('SCR042 owns cancellation',any(a['id']=='ACT-09-CANCEL' for a in sm['SCR-042']['actions']))
ck('SCR046 approval excludes cancellation',[a['id'] for a in sm['SCR-046']['actions']]==['ACT-09-APPROVE'])
app=(ROOT/'app.js').read_text()
for fn in ['render042IC08','render043IC08','render044IC08','render045IC08','render046IC08','render047IC08','render036IC09','render037IC09','render038IC09','render041IC09','render056IC09','render036IC10','render037IC10','render040IC10','render041IC10']:
 ck(fn+' exists',f'function {fn}' in app)
blind=re.search(r'function render044IC08\(state\)\{(.*?)\n\}',app,re.S)
ck('Blind renderer avoids system/book/discrepancy terms',blind is not None and all(x not in blind.group(1).lower() for x in ['số hệ thống','số sổ','chênh lệch','book quantity']))
ck('No mark-expired user action','Đánh dấu hết hạn' not in app)
for technical in ['VALUATION_PENDING','RETURN_PENDING','RTV_PENDING']:
 block=re.search(r'function render038IC09\(state\)\{(.*?)function render041IC09',app,re.S)
 ck('State form does not offer '+technical,block is not None and technical not in block.group(1))
ck('Disposal approval explicitly no decrement','Phê duyệt chưa phải tiêu hủy' in app and 'Tồn vật lý chưa giảm' in app)
ck('Disposal completion is distinct state','APPROVED_PENDING_DISPOSAL' in app and 'COMPLETION' in sm['SCR-040']['states'])
ck('Unknown stock count no blind retry','Không tạo hoặc gửi lại điều chỉnh' in app)
ck('Unknown disposal no second operation','Không tạo lần tiêu hủy mới' in app)
ck('Canonical viewport 402x874','Mobile · 402 × 874' in (ROOT/'index.html').read_text())
reg=json.loads((PRO/'flows/ui-flow-registry.json').read_text())
rm={f['id']:f for f in reg['flows']}
for id in ['UIF-08','UIF-09','UIF-10']:
 ck(id+' registry product corrected',rm[id]['prototype_status']=='GROUP_PRODUCT_CORRECTED_v1.6.0')
 ck(id+' registry evidence level',rm[id]['evidence_level']=='STATIC_RUNTIME_VISUAL_VALIDATED')
for sid in ['038','040']:
 txt=(PRO/'contracts/screens'/f'SCR-{sid}.md').read_text()
 ck('SCR-'+sid+' no Save Draft contract','Lưu nháp yêu cầu' not in txt and 'ACT-COMMON-SAVE-DRAFT' not in txt)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Inventory Audit & Control Static QA v1.6.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'INVENTORY-AUDIT-CONTROL-STATIC-QA-v1.6.0.md').write_text('\n'.join(lines)+'\n')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed)); raise SystemExit(1)
