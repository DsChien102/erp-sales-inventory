#!/usr/bin/env python3
"""Current design-readiness gate for the v3.6.0 HTML Theme 7 baseline.

Historical DR1 inventories are intentionally retained as evidence, but are no
longer used as current screen-count authority.
"""
import json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
errors=[]
def fail(x): errors.append(x)
reg=json.loads((root/'prototype/contracts/screen-registry.json').read_text(encoding='utf-8'))
if reg.get('version')!='3.6.0': fail('screen_registry_version')
if len(reg.get('screens',[]))!=89: fail(f"screen_registry_count:{len(reg.get('screens',[]))}")
required=['status','structural_disposition','primary_object','entry_transition_ids','exit_transition_ids','visible_action_ids','trace_only_action_ids','flutter_ds_component_candidates','module_presentation_pattern_candidates']
for s in reg.get('screens',[]):
    dr=s.get('design_readiness',{})
    for key in required:
        if key not in dr: fail(f"{s.get('id')}:missing:{key}")
    p=root/'prototype/contracts/screens'/f"{s['id']}.md"
    if not p.is_file(): fail(f"{s['id']}:missing_contract")
# Current HTML/DS conformance status must cover all 17 UIF + CAP-01.
status=json.loads((root/'prototype/contracts/figma-ds/UIF-MIGRATION-STATUS.json').read_text(encoding='utf-8'))
if status.get('release')!='3.6.0': fail('ds_status_version')
if len(status.get('uifs',[]))!=18: fail('ds_status_scope')
if any(x.get('productApproval') not in {'QA_PASS','QA_PASS_WITH_BG_006_INTEGRATION_BOUNDARY'} for x in status.get('uifs',[])): fail('ds_status_pending')
# Historical inventory remains explicitly historical; its old 83-screen baseline is not current authority.
inv=json.loads((root/'design-readiness/screen-inventory.json').read_text(encoding='utf-8'))
legacy_count=inv.get('baseline_screen_count')
result={'status':'PASS' if not errors else 'FAIL','errors':errors,'screens':89,'checkpoint':'3.6.0-html-full-theme','historical_dr1_screen_inventory':legacy_count,'authority':'HTML Theme 7 design + Figma DS/reference only'}
print(json.dumps(result,ensure_ascii=False,indent=2));sys.exit(1 if errors else 0)
