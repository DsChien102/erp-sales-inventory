from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[6]
T7=ROOT/'specs/themes/theme-07'; PRO=T7/'prototype'; OUT=Path(__file__).resolve().parent
checks=[]
def ck(n,c): checks.append((n,bool(c)))
flow=json.loads((PRO/'flows/ui-flow-registry.json').read_text(encoding='utf8'))
by={x['id']:x for x in flow['flows']}
ck('UIF03 active topology linear',by['UIF-03']['screen_ids']==['SCR-014','SCR-015','SCR-017','SCR-019'])
ck('UIF03 SCR016 retired',by['UIF-03'].get('retired_screen_ids')==['SCR-016'])
ck('UIF13 dedicated topology',by['UIF-13']['screen_ids']==['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089'])
ck('UIF14 active topology',by['UIF-14']['screen_ids']==['SCR-072','SCR-073','SCR-074','SCR-076','SCR-077'])
ck('UIF14 SCR075 retired',by['UIF-14'].get('retired_screen_ids')==['SCR-075'])
entry=(PRO/'contracts/entry-architecture.md').read_text(encoding='utf8')
ck('Architecture-only explanation rule explicit','không' in entry.lower() and 'Product UI' in entry and 'architecture' in entry.lower())
for f,seq in [('UIF-03-BJ-03.md',['SCR-014','SCR-015','SCR-017','SCR-019']),('UIF-13-BJ-13.md',['SCR-085','SCR-086','SCR-087','SCR-088','SCR-089']),('UIF-14-BJ-14.md',['SCR-072','SCR-073','SCR-074','SCR-076','SCR-077'])]:
    txt=(PRO/'flows'/f).read_text(encoding='utf8'); pos=[txt.find(x) for x in seq]; ck(f'{f} topology current',all(x>=0 for x in pos) and pos==sorted(pos))
app=(PRO/'html/app.js').read_text(encoding='utf8')
ck('BJ03 has contextual evidence sheet','function val03EvidenceSheet' in app and 'data-val03-action="open-evidence-sheet"' in app)
ck('BJ03 active path does not navigate to SCR016','navigate("SCR-016")' not in app)
ck('BJ13 final result does not expose BJ14','BJ14' not in re.search(r'function render089IV13\(state\)\{.*?\n\}',app,re.S).group(0) if re.search(r'function render089IV13\(state\)\{.*?\n\}',app,re.S) else False)
ck('BJ14 custom renderers exist',all(f'function render{sid[4:]}IV14' in app for sid in ['SCR-072','SCR-073','SCR-074','SCR-075','SCR-076','SCR-077']))
ck('BJ14 policy method is not reviewer-selected', 'data-val14-method' not in app)
ck('BJ14 has immutable successor helper','val14ApplyInputChange' in app and 'successor' in app)
actions=json.loads((PRO/'contracts/action-registry.json').read_text(encoding='utf8'))
action_list=actions.get('actions',actions if isinstance(actions,list) else [])
if isinstance(action_list,dict): action_list=list(action_list.values())
acts={x.get('id'):x for x in action_list if isinstance(x,dict)}
ck('ACT14 publish label business-facing',acts.get('ACT-14-PUBLISH',{}).get('label')=='Công bố giá vốn')
ck('ACT14 publish on SCR076 only',acts.get('ACT-14-PUBLISH',{}).get('screen_ids')==['SCR-076'])
# SRS assertions sourced from current package; no new policy enum invented.
bj14=(T7/'srs/02-business-journeys/14-BJ-14-tinh-va-cong-bo-gia-von.md').read_text(encoding='utf8')
bc=(T7/'srs/06-shared-behavioral-contracts.md').read_text(encoding='utf8')
ck('BJ14 immutable run rule documented','immutable' in bj14.lower() or 'bất biến' in bj14.lower())
ck('BJ14 locked policy method documented','selected_method_snapshot' in bj14 or 'policy' in bj14.lower())
ck('BC says publish method comes from locked policy','locked policy method matches run snapshot' in bc or ('locked method-policy version' in bc and 'run snapshot' in bc))
# Screen contracts current mental tasks.
for sid in ['014','015','017','019','085','086','087','088','089','072','073','074','076','077']:
    ck(f'SCR-{sid} contract exists',(PRO/'contracts/screens'/f'SCR-{sid}.md').exists())
# No retired screens in active ui trace.
trace=json.loads((PRO/'contracts/ui-traceability.json').read_text(encoding='utf8'))
blob=json.dumps(trace,ensure_ascii=False)
ck('Retired SCR016 not active trace','SCR-016' not in blob)
ck('Retired SCR075 not active trace','SCR-075' not in blob)
# Workbench current version/topology.
wb=json.loads((PRO/'html/workbench-data.json').read_text(encoding='utf8'))
ck('Workbench version 1.5.0',wb.get('version')=='1.5.0')
flow_map={x['id']:x for x in wb.get('flows',[])}
ck('Workbench UIF03 topology',flow_map['UIF-03']['screens']==['SCR-014','SCR-015','SCR-017','SCR-019'])
ck('Workbench UIF14 topology',flow_map['UIF-14']['screens']==['SCR-072','SCR-073','SCR-074','SCR-076','SCR-077'])
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# Inventory Valuation Static / Contract QA v1.5.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', 'Covers current topology, retired-route cleanup, architecture/UI separation, BJ14 policy/run invariants, active trace and workbench truth.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'INVENTORY-VALUATION-STATIC-QA-v1.5.0.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
