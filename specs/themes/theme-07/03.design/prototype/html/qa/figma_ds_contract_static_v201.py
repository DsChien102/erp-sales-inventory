from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[2]
CON=ROOT/'contracts'; CU=CON/'component-usage'; FD=CON/'figma-ds'; HTML=ROOT/'html'
checks=[]
def ck(n,c): checks.append((n,bool(c)))
mp=json.loads((FD/'html-figma-ds-mapping.json').read_text(encoding='utf-8'))
ck('Mapping registry has four mapping layers',all(k in mp for k in ['componentMappings','profileMappings','themeComponentMappings','internalMappings']))
ck('VButton maps to live Figma node 521:529',mp['componentMappings']['VButton']['nodeId']=='521:529')
ck('VConfirmDialog maps to Confirmation Sheet',mp['componentMappings']['VConfirmDialog']['nodeId']=='550:1058')
ck('OperationEvidenceTimeline maps to Timeline Item',mp['themeComponentMappings']['OperationEvidenceTimeline']['nodeId']=='525:587')
ck('VQuantitySelector remains explicit OPEN_DS_GAP',mp['componentMappings']['VQuantitySelector']['status']=='OPEN_DS_GAP')
ck('Generic VCard remains contextual migration debt',mp['componentMappings']['VCard']['status']=='CONTEXTUAL_CARD')
mds=sorted(CU.glob('UIF-*-COMPONENT-USAGE.md')); ymls=sorted(CU.glob('UIF-*-COMPONENT-USAGE.yaml'))
ck('17 component-usage Markdown files carry Figma migration notice',len(mds)==17 and all('Figma DS migration v2.0.1' in p.read_text(encoding='utf-8') for p in mds))
ck('17 component-usage YAML files carry Figma authority metadata',len(ymls)==17 and all('uiAuthority: Figma Design System v2.0.2' in p.read_text(encoding='utf-8') and 'figmaMappingRegistry:' in p.read_text(encoding='utf-8') for p in ymls))
combined='\n'.join(p.read_text(encoding='utf-8') for p in mds+ymls)
for bad in ['Flutter DS is UI authority.','Flutter DS là single source of truth.','authority: Flutter Design System','authority: FLUTTER-DS-LOCK.json']:
    ck(f'No current authority contradiction: {bad}',bad not in combined)
active_docs=[ROOT/'README.md']+sorted((ROOT/'flows').glob('*.md'))+sorted((CON/'screens').glob('*.md'))
active_text='\n'.join(x.read_text(encoding='utf-8') for x in active_docs if x.exists())
ck('Current flow/screen/prototype docs no longer assert Flutter DS as current UI authority', 'Flutter DS là UI authority' not in active_text and 'UI authority: Flutter Design System locked' not in active_text)
sr=json.loads((CON/'screen-registry.json').read_text(encoding='utf-8'))
ck('Screen registry declares Figma DS migration authority',sr.get('figma_ds_migration',{}).get('authority')=='Figma Design System v2.0.2')
ck('Screen registry marks legacy component fields as mapping input only',sr.get('figma_ds_migration',{}).get('legacy_component_fields_status')=='MAPPING_INPUT_ONLY')
app=(HTML/'app.js').read_text(encoding='utf-8'); idx=(HTML/'index.html').read_text(encoding='utf-8')
ck('Workbench loads runtime Figma map before app renderer','figma-ds-runtime-map.js' in idx and idx.index('figma-ds-runtime-map.js')<idx.index('app.js'))
ck('Inspect authority copy is Figma-native','Figma DS v2.0.2' in app and '<span>Flutter DS</span>' not in app)
ck('Legacy timeline Flutter gap annotation removed','TIMELINE_PATTERN_NOT_PUBLIC_IN_FLUTTER_DS' not in app)
failed=[n for n,c in checks if not c]
out=Path(__file__).resolve().parent/'FIGMA-DS-CONTRACT-STATIC-v2.0.1.md'
out.write_text('\n'.join(['# Phase 2 — Figma DS Contract Static QA v2.0.1','',f'**Result: {"PASS" if not failed else "FAIL"} · {sum(c for _,c in checks)}/{len(checks)} checks**','','## Checks','']+[f'- {"PASS" if c else "FAIL"} — {n}' for n,c in checks])+'\n',encoding='utf-8')
print(('PASS' if not failed else 'FAIL'),sum(c for _,c in checks),'/',len(checks))
if failed:
 print('\n'.join(failed)); raise SystemExit(1)
