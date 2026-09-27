from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re
ROOT=Path(__file__).resolve().parents[1]; OUT=Path(__file__).resolve().parent
PKG=ROOT.parents[5]
idx=(ROOT/'index.html').read_text(encoding='utf-8')
css=(ROOT/'tokens.generated.css').read_text(encoding='utf-8')+'\n'+(ROOT/'styles.css').read_text(encoding='utf-8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf-8')
mpjs=(ROOT/'figma-ds-runtime-map.js').read_text(encoding='utf-8')
app=(ROOT/'app.js').read_text(encoding='utf-8')
html=(idx.replace('<link rel="stylesheet" href="tokens.generated.css" />','')
         .replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>')
         .replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
         .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{mpjs}</script>')
         .replace('<script src="app.js"></script>',f'<script>{app}</script>'))
map_json=json.loads((PKG/'prototype/contracts/figma-ds/html-figma-ds-mapping.json').read_text(encoding='utf-8')) if False else json.loads((ROOT.parent/'contracts/figma-ds/html-figma-ds-mapping.json').read_text(encoding='utf-8'))
var_manifest=json.loads((ROOT.parent/'contracts/figma-ds/figma-variable-manifest.json').read_text(encoding='utf-8'))
comp_registry=json.loads((ROOT.parent/'contracts/figma-ds/figma-component-registry.json').read_text(encoding='utf-8'))
pat_registry=json.loads((ROOT.parent/'contracts/figma-ds/figma-pattern-template-registry.json').read_text(encoding='utf-8'))
checks=[]; issues=[]; page_errors=[]; total=0; annotated=0; combo={}
def ck(name,cond,detail=''):
    checks.append((name,bool(cond),detail))

def add(kind,f,s,st,detail): issues.append({'kind':kind,'flow':f,'screen':s,'state':st,'detail':detail})

# Static mapping integrity
assets=map_json.get('assetIndex',{})
for group in ['componentMappings','profileMappings','themeComponentMappings','internalMappings']:
    for key,m in map_json.get(group,{}).items():
        if m.get('nodeId'):
            a=assets.get(m.get('name'))
            if not a or a.get('nodeId')!=m.get('nodeId'):
                issues.append({'kind':'NODE_ID_MISMATCH','flow':'—','screen':'—','state':'—','detail':f'{group}:{key} -> {m.get("name")} {m.get("nodeId")}'})
ck('Mapping registry release is v2.1.0',map_json.get('release')=='2.1.0')
ck('Figma DS authority locked to v2.0.2',map_json.get('source',{}).get('designSystemVersion')=='2.0.2')
ck('Variable manifest retains 119 live variables',sum(len(c.get('variables',[])) for c in var_manifest.get('collections',[]))==119)
ck('Component registry retains 49 sets + 15 standalone',comp_registry.get('counts')=={'componentSets':49,'standaloneComponents':15})
ck('Pattern/template registry retains 22 assets',len(pat_registry.get('assets',[]))==22)
ck('No mapping node-id mismatches',not [x for x in issues if x['kind']=='NODE_ID_MISMATCH'])

with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100}); p.on('pageerror',lambda e:page_errors.append(str(e)))
    p.set_content(html,wait_until='load'); p.wait_for_timeout(20)
    ck('Workbench runtime version is v2.1.0',p.evaluate('VET45_HARNESS_DATA.version')=='2.1.0')
    flows=p.evaluate('flowCatalog.map(f=>({id:f.id,screens:f.screens}))')
    states=p.evaluate('Object.fromEntries(screens.map(s=>[s.id,s.states||["READY"]]))')
    seen=set()
    for f in flows:
      for sid in f['screens']:
        if (f['id'],sid) in seen: continue
        seen.add((f['id'],sid))
        for st in states.get(sid,['READY']):
          total+=1
          try:
            p.evaluate('''(x)=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
              if(x.f==="UIF-02"&&x.s==="SCR-009"){flowMode="document";resetBj02Receipt("document");stateByScreen[x.s]=x.st;}
              if(x.f==="UIF-03"&&x.s==="SCR-017"){val03SelectedReceiptId="VAL03-R1";val03ReviewSourceVersion=val03Current().sourceVersion;}
              if(x.f==="UIF-13"&&x.s==="SCR-088"){val13SelectedTaskId="LC13-001";if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
              if(x.f==="UIF-14"&&x.s==="SCR-076"){val14SelectedRunId="COST-0826";val14PublishReviewVersion=val14Current().inputVersion;}
              render();}''',{'f':f['id'],'s':sid,'st':st})
            p.wait_for_timeout(1)
            rows=p.locator('#app-screen [data-ds-component],#app-screen [data-theme-component],#app-screen [data-ds-internal]').evaluate_all('''els=>els.map(e=>{const m=resolveFigmaMapping(e);return {ds:e.dataset.dsComponent||'',theme:e.dataset.themeComponent||'',internal:e.dataset.dsInternal||'',profile:e.dataset.dsProfile||'',target:m.name,status:m.status,nodeId:m.nodeId,layer:m.layer};})''')
            annotated+=len(rows)
            for r in rows:
              k=json.dumps(r,sort_keys=True,ensure_ascii=False); combo[k]=combo.get(k,0)+1
              if r['status']=='UNMAPPED' or r['layer']=='UNMAPPED': add('UNMAPPED_RUNTIME_ANNOTATION',f['id'],sid,st,k)
            txt=p.locator('#app-screen').inner_text().strip()
            if not txt: add('EMPTY_PRODUCT_UI',f['id'],sid,st,'empty')
            if 'undefined' in txt.lower(): add('UNDEFINED_LEAK',f['id'],sid,st,'undefined')
            g=p.locator('#app-screen').evaluate('(e)=>({sw:e.scrollWidth,cw:e.clientWidth})')
            if g['sw']>g['cw']+1: add('HORIZONTAL_OVERFLOW',f['id'],sid,st,str(g))
          except Exception as e: add('RENDER_ERROR',f['id'],sid,st,str(e))
    ck('All 497 active state renders executed',total==497,f'{total}')
    ck('Every runtime DS/theme/internal annotation resolves',not [x for x in issues if x['kind']=='UNMAPPED_RUNTIME_ANNOTATION'],f'{annotated} annotations / {len(combo)} unique combos')
    ck('No Product runtime/overflow regressions in mapping pass',not [x for x in issues if x['kind'] in {'EMPTY_PRODUCT_UI','UNDEFINED_LEAK','HORIZONTAL_OVERFLOW','RENDER_ERROR'}])
    # Inspect exact common mappings
    p.evaluate('''()=>{activeFlowId="UIF-02";activeScreenId="SCR-008";stateByScreen["SCR-008"]="READY";render();toggleInspect(true);}''')
    btn=p.locator('#app-screen [data-ds-profile="button.primaryFooter"]')
    if btn.count():
      btn.evaluate('(e)=>showInspectOverlay(e)')
      panel=p.locator('#inspect-details').inner_text()
      ck('Inspect resolves footer to Figma VButton node 521:529','521:529' in panel and 'VButton' in panel)
      ck('Inspect normalizes medium legacy size to Figma Default','Size' in panel and 'Default' in panel)
      ck('Inspect is Figma-native and does not present Flutter as authority','Figma DS v2.0.2' in panel and 'Flutter DS' not in panel)
    else:
      ck('Inspect resolves footer to Figma VButton node 521:529',False,'button not found')
      ck('Inspect normalizes medium legacy size to Figma Default',False,'button not found')
      ck('Inspect is Figma-native and does not present Flutter as authority',False,'button not found')
    p.evaluate('''()=>{activeFlowId="UIF-02";activeScreenId="SCR-006";stateByScreen["SCR-006"]="PERMISSION_DENIED";render();}''')
    emp=p.locator('#app-screen [data-theme-component="PermissionDeniedState"]')
    ep=emp.evaluate('(e)=>({m:resolveFigmaMapping(e),p:canonicalFigmaProps(e,resolveFigmaMapping(e))})')
    ck('Permission state maps to VEmptyState node 526:4352',ep['m']['nodeId']=='526:4352')
    ck('Permission state canonical Type is No Permission',any(x==['Type','No Permission'] for x in ep['p']))
    p.evaluate('''()=>{activeFlowId="UIF-02";activeScreenId="SCR-013";stateByScreen["SCR-013"]="READY";render();}''')
    tl=p.locator('#app-screen [data-ds-component="DS v2 / Timeline Item"]')
    tm=tl.first.evaluate('(e)=>resolveFigmaMapping(e)') if tl.count() else {}
    ck('Evidence timeline now targets live Figma Timeline Item',tm.get('nodeId')=='525:587')
    ck('Obsolete Flutter timeline gap annotation removed',p.locator('#app-screen [data-ds-gap="TIMELINE_PATTERN_NOT_PUBLIC_IN_FLUTTER_DS"]').count()==0)
    b.close()
ck('No browser page errors',not page_errors,'; '.join(page_errors[:3]))
failed=[x for x in checks if not x[1]]
report=['# Phase 2 — Figma DS Mapping QA v2.1.0','',f'**Result: {"PASS" if not failed else "FAIL"} · {sum(1 for x in checks if x[1])}/{len(checks)} gates · {total} active state renders · {annotated} mapped annotations · {len(combo)} unique runtime mapping combinations**','','## Gates','']+[f'- {"PASS" if ok else "FAIL"} — {name}'+(f' · {detail}' if detail else '') for name,ok,detail in checks]
if issues: report+=['','## Issues']+[f'- `{x["flow"]}/{x["screen"]}/{x["state"]}` · {x["kind"]}: {x["detail"]}' for x in issues[:200]]
if page_errors: report+=['','## Browser errors']+[f'- {x}' for x in page_errors]
(OUT/'FIGMA-DS-MAPPING-QA-v2.1.0.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
(OUT/'FIGMA-DS-MAPPING-QA-v2.1.0.json').write_text(json.dumps({'result':'PASS' if not failed else 'FAIL','gates':checks,'renders':total,'annotations':annotated,'uniqueCombos':len(combo),'issues':issues,'pageErrors':page_errors},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(('PASS' if not failed else 'FAIL'),sum(1 for x in checks if x[1]),'/',len(checks),'gates',total,'renders',annotated,'annotations',len(combo),'combos','issues',len(issues))
if failed:
  for x in failed: print('FAIL',x)
  raise SystemExit(1)
