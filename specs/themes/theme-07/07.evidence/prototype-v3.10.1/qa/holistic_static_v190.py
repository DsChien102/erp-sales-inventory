#!/usr/bin/env python3
import json
from pathlib import Path

HERE = Path(__file__).resolve()
HTML = HERE.parents[1]
PROTO = HERE.parents[2]
CONTRACTS = PROTO / 'contracts'
FLOWS_DIR = PROTO / 'flows'
QA = HTML / 'qa'

screen_registry = json.loads((CONTRACTS/'screen-registry.json').read_text(encoding='utf-8'))
flow_registry = json.loads((FLOWS_DIR/'ui-flow-registry.json').read_text(encoding='utf-8'))
action_registry = json.loads((CONTRACTS/'action-registry.json').read_text(encoding='utf-8'))
workbench = json.loads((HTML/'workbench-data.json').read_text(encoding='utf-8'))
index_text = (HTML/'index.html').read_text(encoding='utf-8')
screen_map = (PROTO/'screen-map.md').read_text(encoding='utf-8')

checks = []
def check(name, ok, detail=''):
    checks.append((name, bool(ok), detail))

flows = flow_registry.get('flows', [])
flow_ids = [f['id'] for f in flows]
flow_screens = {f['id']: f.get('screen_ids', []) for f in flows}
active_screen_ids = sorted({sid for f in flows for sid in f.get('screen_ids', [])})
screen_by_id = {s['id']: s for s in screen_registry.get('screens', [])}
wb_screen_by_id = {s['id']: s for s in workbench.get('screens', [])}
action_by_id = {a['id']: a for a in action_registry.get('actions', [])}

check('Screen registry version is 1.9.0', screen_registry.get('version') == '1.9.0', str(screen_registry.get('version')))
check('Screen registry is holistic-hardened', screen_registry.get('prototype_status') == 'CUMULATIVE_HOLISTIC_HARDENED_v1.9.0', str(screen_registry.get('prototype_status')))
check('UI flow registry patch version is 1.9.0', flow_registry.get('patch_version') == '1.9.0', str(flow_registry.get('patch_version')))
check('UI flow registry is holistic-hardened', flow_registry.get('prototype_status') == 'CUMULATIVE_HOLISTIC_HARDENED_v1.9.0', str(flow_registry.get('prototype_status')))
check('Action registry version is 1.9.0', action_registry.get('version') == '1.9.0', str(action_registry.get('version')))
check('Workbench version is 1.9.0', workbench.get('version') == '1.9.0', str(workbench.get('version')))
check('Workbench index badge identifies v1.9.0 holistic hardening', 'v1.9.0' in index_text and 'Holistic Hardening' in index_text)
check('Exactly 17 UIFs are registered', len(flows) == 17 and len(set(flow_ids)) == 17, f'{len(flows)} UIF')
check('Exactly 73 canonical active screens participate in UIFs', len(active_screen_ids) == 73, f'{len(active_screen_ids)} active screens')
check('All active screen IDs resolve in screen registry', all(sid in screen_by_id for sid in active_screen_ids))
check('All active screen IDs resolve in workbench', all(sid in wb_screen_by_id for sid in active_screen_ids))
check('All active screen Markdown contracts exist', all((CONTRACTS/'screens'/f'{sid}.md').is_file() for sid in active_screen_ids))
check('All 17 UIF flow Markdown files exist', all((FLOWS_DIR/f.get('file','')).is_file() for f in flows))
md_usage = list((CONTRACTS/'component-usage').glob('UIF-*-COMPONENT-USAGE.md'))
yaml_usage = list((CONTRACTS/'component-usage').glob('UIF-*-COMPONENT-USAGE.yaml'))
check('17 component-usage Markdown contracts exist', len(md_usage) == 17, str(len(md_usage)))
check('17 component-usage YAML contracts exist', len(yaml_usage) == 17, str(len(yaml_usage)))
check('Current screen-map declares v1.9.0 and 17/73/497 topology', all(x in screen_map for x in ['v1.9.0','17 UIF','73 canonical active screens','497 active flow/state render combinations']))
check('Historical v4.1.0 screen-map is preserved under legacy/', (PROTO/'legacy/screen-map-v4.1.0.md').is_file())

# Topology equivalence between registry and workbench.
wb_flows = {f['id']: f for f in workbench.get('flows', [])}
check('All flow IDs resolve in workbench', set(flow_ids) == set(wb_flows))
check('Each UIF preserves the same active screen order in workbench', all(wb_flows[fid].get('screens', []) == flow_screens[fid] for fid in flow_ids))
check('Workbench run order covers each UIF exactly once', len(workbench.get('runOrder', [])) == 17 and set(workbench.get('runOrder', [])) == set(flow_ids))
check('All active workbench screens expose at least one registered state', all(bool(wb_screen_by_id[sid].get('states')) for sid in active_screen_ids))

# Action registry integrity.
flow_action_refs = []
for f in flows:
    flow_action_refs += f.get('action_ids', []) + f.get('system_action_ids', [])
screen_action_refs = []
for s in screen_registry.get('screens', []):
    dr = s.get('design_readiness') or {}
    screen_action_refs += dr.get('visible_action_ids', []) + dr.get('trace_only_action_ids', [])
wb_action_refs = []
for s in workbench.get('screens', []):
    for a in s.get('actions', []):
        wb_action_refs.append(a['id'] if isinstance(a, dict) else a)
    wb_action_refs += s.get('traceActions', [])
all_action_refs = {a for a in (flow_action_refs + screen_action_refs + wb_action_refs) if isinstance(a, str) and a.startswith('ACT-')}
missing_actions = sorted(a for a in all_action_refs if a not in action_by_id)
check('All flow/screen/workbench Action IDs resolve in action registry', not missing_actions, ', '.join(missing_actions[:10]))

# Save draft ownership lock.
for aid in ['ACT-02-SAVE-DRAFT','ACT-COMMON-SAVE-DRAFT']:
    a = action_by_id.get(aid, {})
    check(f'{aid} is system trace-only, not a user task', a.get('ui_visibility') == 'TRACE_ONLY_SYSTEM' and a.get('user_task') is False, str(a))

save_cases = {
    'SCR-008': 'ACT-02-SAVE-DRAFT',
    'SCR-009': 'ACT-02-SAVE-DRAFT',
    'SCR-084': 'ACT-02-SAVE-DRAFT',
    'SCR-038': 'ACT-COMMON-SAVE-DRAFT',
    'SCR-040': 'ACT-COMMON-SAVE-DRAFT',
}
for sid, aid in save_cases.items():
    s = screen_by_id[sid]
    dr = s.get('design_readiness') or {}
    visible = dr.get('visible_action_ids', [])
    trace = dr.get('trace_only_action_ids', [])
    wb = wb_screen_by_id[sid]
    wb_visible = [x['id'] if isinstance(x,dict) else x for x in wb.get('actions', [])]
    wb_trace = wb.get('traceActions', [])
    ok = aid not in visible and aid in trace and aid not in wb_visible and aid in wb_trace
    check(f'{sid} keeps {aid} background-only in contract and renderer', ok, f'contract visible={visible}; trace={trace}; wb visible={wb_visible}; trace={wb_trace}')

uif_by_id = {f['id']: f for f in flows}
check('UIF-02 declares save-draft as system-owned', 'ACT-02-SAVE-DRAFT' in uif_by_id['UIF-02'].get('system_action_ids', []))
check('UIF-09 declares common save-draft as system-owned', 'ACT-COMMON-SAVE-DRAFT' in uif_by_id['UIF-09'].get('system_action_ids', []))
check('UIF-10 declares common save-draft as system-owned', 'ACT-COMMON-SAVE-DRAFT' in uif_by_id['UIF-10'].get('system_action_ids', []))

# Holistic provenance on all current flow and active screen records.
check('All 17 UIFs carry v1.9.0 holistic-review provenance', all((f.get('holistic_review') or {}).get('version') == '1.9.0' and (f.get('holistic_review') or {}).get('status') == 'PASS' for f in flows))
check('All 73 active screen records carry v1.9.0 holistic-review provenance', all((screen_by_id[sid].get('holistic_review') or {}).get('version') == '1.9.0' and (screen_by_id[sid].get('holistic_review') or {}).get('status') == 'PASS' for sid in active_screen_ids))

passed = sum(1 for _,ok,_ in checks if ok)
failed = len(checks)-passed
status = 'PASS' if failed == 0 else 'FAIL'

lines = [
    '# Theme 7 — Holistic static / contract QA v1.9.0',
    '',
    f'**Result: {status} · {passed}/{len(checks)} checks PASS**',
    '',
    'Scope: cumulative all-17-BJ registry/contract/workbench topology, action ownership, component-usage coverage, screen-map governance and v1.9.0 holistic provenance.',
    '',
    '| # | Check | Result | Evidence |',
    '|---:|---|---|---|',
]
for i,(name,ok,detail) in enumerate(checks,1):
    detail = (detail or '').replace('|','\\|').replace('\n',' ')
    lines.append(f'| {i} | {name} | {"PASS" if ok else "FAIL"} | {detail} |')
lines += [
    '',
    '## Notes',
    '',
    '- This validator is release-aware for the cumulative v1.9.0 Harness; it does not substitute the frozen historical v4.x package validator.',
    '- Product approval is a separate gate from engineering/static QA.',
]
(QA/'HOLISTIC-STATIC-QA-v1.9.0.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')
(QA/'HOLISTIC-STATIC-QA-v1.9.0.json').write_text(json.dumps({
    'version':'1.9.0','status':status,'passed':passed,'total':len(checks),'failed':failed,
    'checks':[{'name':n,'status':'PASS' if ok else 'FAIL','detail':d} for n,ok,d in checks]
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'{status} {passed}/{len(checks)}')
if failed:
    for n,ok,d in checks:
        if not ok: print('FAIL:',n,'--',d)
raise SystemExit(1 if failed else 0)
