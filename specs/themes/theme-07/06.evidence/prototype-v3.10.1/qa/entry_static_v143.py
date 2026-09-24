from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]; HTML=ROOT/'html'; OUT=HTML/'qa'; C=ROOT/'contracts'; F=ROOT/'flows'
checks=[]
def ck(n,v): checks.append((n,bool(v)))
def read(p): return Path(p).read_text(encoding='utf8')
entry=read(C/'entry-architecture.md'); nav=read(C/'navigation-areas.md'); bjmap=read(C/'bj-ui-flow-map.md'); app=read(HTML/'app.js'); wb=json.loads(read(HTML/'workbench-data.json')); reg=json.loads(read(F/'ui-flow-registry.json')); screens=json.loads(read(C/'screen-registry.json'))
flow={x['id']:x for x in reg['flows']}; scr={x['id']:x for x in screens['screens']}
target_ids=sorted(set(sum([flow[x]['screen_ids'] for x in ['UIF-01','UIF-02','UIF-03','UIF-04','UIF-05','UIF-06','UIF-07']],[])))
ck('All active target surfaces have entry continuity metadata',all(scr.get(sid,{}).get('entry_architecture',{}).get('class') in {'MODULE_ENTRY','CONTEXTUAL_DEEP_LINK','CONTEXTUAL_ONLY','ACTOR_HANDOFF_TASK','IN_FLOW_SURFACE','SYSTEM_RECOVERY','RESULT'} and scr.get(sid,{}).get('entry_architecture',{}).get('canonical_parent') for sid in target_ids))
ck('No active target surface is classified RETIRED',all(scr.get(sid,{}).get('entry_architecture',{}).get('class')!='RETIRED' for sid in target_ids))
ck('Canonical entry architecture contract exists',all(x in entry for x in ['MODULE_ENTRY','CONTEXTUAL_DEEP_LINK','CONTEXTUAL_ONLY','ACTOR_HANDOFF_TASK','IN_FLOW_SURFACE','SYSTEM_RECOVERY','RESULT']))
ck('Current README entry taxonomy includes IN_FLOW_SURFACE','IN_FLOW_SURFACE' in read(ROOT/'README.md') and 'IN_FLOW_SURFACE' in nav)
ck('Workbench UIF04 has only active SCR021',next(x for x in wb['flows'] if x['id']=='UIF-04')['screens']==['SCR-021'])
ck('Flow registry UIF04 has only active SCR021',flow['UIF-04']['screen_ids']==['SCR-021'] and flow['UIF-04']['entry_screen_ids']==['SCR-021'])
ck('Flow registry current totals are 87 screen refs / 189 transitions',sum(len(x['screen_ids']) for x in reg['flows'])==87 and sum(x.get('transition_count',0) for x in reg['flows'])==189)
status=read(ROOT/'HARNESS-STATUS.yaml')
ck('Current candidate overlay includes SCR084 and one-screen UIF04','activeScreens: [SCR-006, SCR-007, SCR-008, SCR-009, SCR-084, SCR-010, SCR-011, SCR-012, SCR-013]' in status and 'activeScreens: [SCR-021]' in status)
ck('Navigation explicitly retires old UIF04 surfaces',all(x in nav for x in ['SCR-020','SCR-022','SCR-023','SCR-024','migration/historical']))
ck('BJ map canonical UIF04 is contextual SCR021','Order detail → Tình trạng giữ hàng' in bjmap and '1 active Product surface' in bjmap)
ck('SCR021 is contextual only',scr['SCR-021']['entry_architecture']['class']=='CONTEXTUAL_ONLY')
ck('SCR011 is actor handoff',scr['SCR-011']['entry_architecture']['class']=='ACTOR_HANDOFF_TASK')
ck('SCR034 is actor handoff',scr['SCR-034']['entry_architecture']['class']=='ACTOR_HANDOFF_TASK')
ck('SCR013 is system recovery',scr['SCR-013']['entry_architecture']['class']=='SYSTEM_RECOVERY')
ck('BJ03 module entry is SCR014',scr['SCR-014']['entry_architecture']['class']=='MODULE_ENTRY')
ck('BJ01 product detail supports contextual entry',scr['SCR-003']['entry_architecture']['class']=='CONTEXTUAL_DEEP_LINK')
ck('BJ03 receipt task supports contextual entry',scr['SCR-015']['entry_architecture']['class']=='CONTEXTUAL_DEEP_LINK')
ck('BJ06 maker request supports contextual entry',scr['SCR-031']['entry_architecture']['class']=='CONTEXTUAL_DEEP_LINK')
ck('BJ07 supplier task supports contextual entry',scr['SCR-037']['entry_architecture']['class']=='CONTEXTUAL_DEEP_LINK')
for sid in ['SCR-020','SCR-022','SCR-023','SCR-024']:
    ck(sid+' registered retired',scr[sid]['entry_architecture']['class']=='RETIRED')
s41=read(C/'screens/SCR-041.md')
ck('SCR041 UIF07 result enters through T06','UIF-07-T06' in s41)
ck('SCR041 UIF07 safe exits T07/T08','UIF-07-T07' in s41 and 'UIF-07-T08' in s41)
ck('SCR041 narrative marks T09/T10/T11 as retired refs','reference cũ' in s41 and 'UIF-07-T09/T10/T11' in s41)
# Machine registry must contain only live UIF07 transition refs. This catches stale trace data even when Markdown is correct.
valid_uif07={f'UIF-07-T{i:02d}' for i in range(1,9)}
reg_uif07=set()
for item in screens['screens']:
    dr=item.get('design_readiness') or {}
    for key in ('entry_transition_ids','exit_transition_ids','evidence_sources'):
        for x in dr.get(key,[]) or []:
            if isinstance(x,str) and x.startswith('UIF-07-T'): reg_uif07.add(x)
ck('Screen registry contains no stale UIF07 transition refs',reg_uif07 <= valid_uif07)
ck('SCR039 machine trace is current T04/T05/T06',scr['SCR-039']['design_readiness']['entry_transition_ids']==['UIF-07-T04'] and scr['SCR-039']['design_readiness']['exit_transition_ids']==['UIF-07-T05','UIF-07-T06'] and all(x in scr['SCR-039']['design_readiness']['evidence_sources'] for x in ['UIF-07-T04','UIF-07-T05','UIF-07-T06']))
ck('SCR041 machine trace is current T06/T07/T08',scr['SCR-041']['design_readiness']['entry_transition_ids'][0]=='UIF-07-T06' and scr['SCR-041']['design_readiness']['exit_transition_ids'][:2]==['UIF-07-T07','UIF-07-T08'] and all(x in scr['SCR-041']['design_readiness']['evidence_sources'] for x in ['UIF-07-T06','UIF-07-T07','UIF-07-T08']))
f1=read(F/'UIF-01-BJ-01.md'); f2=read(F/'UIF-02-BJ-02.md'); f3=read(F/'UIF-03-BJ-03.md'); f6=read(F/'UIF-06-BJ-06.md'); f7=read(F/'UIF-07-BJ-07.md')
ck('BJ01 Product contextual entry documented','CONTEXTUAL_DEEP_LINK' in f1 and 'SCR-003' in f1 and 'Product context nguồn' in f1)
ck('BJ02 maker submit modeled as waiting + actor handoff','WAITING_APPROVAL' in f2 and 'maker không navigate' in f2.lower())
ck('BJ02 Purchase contextual entry can skip generic choice','CONTEXTUAL_DEEP_LINK' in f2 and 'SCR-009' in f2)
ck('BJ02 Purchase contextual entry has source Back contract','Back về chứng từ nguồn' in f2 and 'exit-receipt-document-context' in app)
ck('BJ03 ownership does not auto-route warehouse','warehouse actor' in f3 and 'không bị auto-route' in f3)
ck('BJ03 vs BJ13 boundary is explicit','Boundary với BJ13' in f3 and 'initial valuation' in f3)
ck('BJ06 maker task supports direct request entry','CONTEXTUAL_DEEP_LINK' in f6 and 'SCR-031' in f6)
ck('BJ06 maker and approver sessions separated','không navigate sang' in f6 and 'SCR-034' in f6 and 'cùng session' in f6)
ck('BJ06 intermediate/final result roles documented','Đã nhận hàng khách trả' in f6 and 'Kết quả phân loại hàng trả' in f6)
ck('BJ07 Purchase ownership explicit','Mua hàng' in f7 and 'CONTEXTUAL_DEEP_LINK' in f7)
ck('Runtime has all direct entry modes',all(x in app for x in ['product-context','document-context','receipt-task','order-context','order-task','entryMode === "approver"','activeFlowId === "UIF-06" && entryMode === "return-task"','activeFlowId === "UIF-07" && entryMode === "return-task"']))
ck('Workbench version is v1.4.3',wb['version']=='1.4.3')
ck('Flow registry patch version is v1.4.3',reg.get('patch_version')=='1.4.3')
ck('Screen registry version is v1.4.3',screens['version']=='1.4.3')
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Entry Architecture Static / Contract QA v1.4.3','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Coverage: canonical entry classes, BJ04 ghost-route removal, actor handoff separation, BJ03 ownership/boundary, BJ07 source ownership, SCR041 transition integrity and registry consistency.','','## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'ENTRY-ARCHITECTURE-STATIC-QA-v1.4.3.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
