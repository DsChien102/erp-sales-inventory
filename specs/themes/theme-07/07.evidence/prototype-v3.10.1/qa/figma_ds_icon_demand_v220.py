from pathlib import Path
from playwright.sync_api import sync_playwright
import json,re,collections
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent

def inline_html(root):
    idx=(root/'index.html').read_text(encoding='utf-8')
    css='\n'.join((root/x).read_text(encoding='utf-8') for x in ['figma-ds.exact.css','figma-ds.styles.exact.css','tokens.generated.css','styles.css'])
    data=(root/'workbench-data.js').read_text(encoding='utf-8')
    fmap=(root/'figma-ds-runtime-map.js').read_text(encoding='utf-8')
    app=(root/'app.js').read_text(encoding='utf-8')
    return (idx.replace('<link rel="stylesheet" href="figma-ds.exact.css" />','')
      .replace('<link rel="stylesheet" href="figma-ds.styles.exact.css" />','')
      .replace('<link rel="stylesheet" href="tokens.generated.css" />','')
      .replace('<link rel="stylesheet" href="styles.css" />',f'<style>{css}</style>')
      .replace('<script src="workbench-data.js"></script>',f'<script>{data}</script>')
      .replace('<script src="figma-ds-runtime-map.js"></script>',f'<script>{fmap}</script>')
      .replace('<script src="app.js"></script>',f'<script>{app}</script>'))

def data(root):
    s=(root/'workbench-data.js').read_text(encoding='utf-8')
    return json.loads(re.sub(r'^window\.VET45_HARNESS_DATA\s*=\s*','',s).rstrip().rstrip(';'))

def prep():
    return '''x=>{activeFlowId=x.f;activeScreenId=x.s;stateByScreen[x.s]=x.st;
      if(x.f==='UIF-02'&&x.s==='SCR-009'){flowMode='document';resetBj02Receipt('document');stateByScreen[x.s]=x.st;}
      if(x.f==='UIF-03'&&x.s==='SCR-017'){val03SelectedReceiptId='VAL03-R1';val03ReviewSourceVersion=val03Current().sourceVersion;}
      if(x.f==='UIF-13'&&x.s==='SCR-088'){val13SelectedTaskId='LC13-001';if(!val13Current().selectedMethod)val13Current().selectedMethod=val13Current().allowedMethods[0].id;val13ReviewSourceVersion=val13Current().sourceVersion;val13PreviewHash=val13PreviewHashOf();}
      if(x.f==='UIF-14'&&x.s==='SCR-076'){val14SelectedRunId='COST-0826';val14PublishReviewVersion=val14Current().inputVersion;}
      render();}'''

approved={
 'VIcons.chevronLeft':'li:chevron-left',
 'VIcons.chevronRight':'li:chevron-right',
 'VIcons.arrowDropDown':'li:chevron-down',
 'VIcons.search':'li:search',
 'VIcons.tune':'li:sliders-horizontal',
 'VIcons.edit':'li:pencil',
 'VIcons.close':'li:x',
 'VIcons.success':'li:circle-check',
 'VIcons.warning':'li:triangle-alert',
 'VIcons.error':'li:circle-x',
 'VIcons.info':'li:info',
 'VIcons.person':'li:user',
 'VIcons.warehouse':'li:warehouse',
 'VIcons.shield':'li:shield-check',
 'VIcons.history':'li:history',
 'VIcons.moreHoriz':'li:ellipsis',
 'VIcons.refresh':'li:refresh-cw',
}
source_gap={
 'VIcons.arrowLeft':'li:arrow-left',
 'VIcons.arrowRight':'li:arrow-right',
 'VIcons.description':'li:file-text',
 'VIcons.bolt':'li:zap',
 'VIcons.calendar':'li:calendar',
 'VIcons.save':'li:save',
 'VIcons.inventory':'contextual: li:package / li:layers',
 'VIcons.check':'li:check',
 'VIcons.clock':'li:clock',
 'VIcons.lock':'li:lock',
 'VIcons.inbox':'li:inbox',
 'VIcons.checkList':'li:list-check',
}

d=data(ROOT); screens={s['id']:s for s in d['screens']}; flows=d['flows']; html=inline_html(ROOT)
counts=collections.Counter(); by_uif={}; renders=0; missing_wrapper=0
with sync_playwright() as pw:
    b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--disable-dev-shm-usage'])
    p=b.new_page(viewport={'width':1440,'height':1100});p.set_content(html,wait_until='load')
    for f in flows:
        uc=collections.Counter()
        for sid in f['screens']:
            for st in screens[sid].get('states') or ['READY']:
                renders+=1;p.evaluate(prep(),{'f':f['id'],'s':sid,'st':st})
                vals=p.locator('#app-screen [data-ds-icon]').evaluate_all("els=>els.map(e=>e.dataset.dsIcon)")
                counts.update(vals);uc.update(vals)
                missing_wrapper += p.locator('#app-screen svg:not([data-ds-icon])').count()
        by_uif[f['id']]=dict(uc.most_common())
    b.close()
rows=[]
for name,count in counts.most_common():
    if name in approved: status='APPROVED_ICON_LIBRARY'; target=approved[name]
    elif name in source_gap: status='DS_SOURCE_GAP_NOT_IN_APPROVED_LIBRARY'; target=source_gap[name]
    else: status='UNMAPPED_LEGACY_ICON_SEMANTIC'; target=None
    rows.append({'legacySemantic':name,'renderOccurrences':count,'status':status,'canonicalTarget':target})
result={
 'release':'2.2.0-candidate',
 'sourceFileKey':'QVJolM5tAdFKkhP7RIwe3y',
 'figmaDsVersion':'2.0.2',
 'renders':renders,
 'approvedIconLibraryCount':28,
 'rule':'Product migration may use only approved Icon Library instances wrapped by DS v2 / Icon. Raw Lucide vendor masters are source material, not Product-ready assets.',
 'global':rows,
 'byUif':by_uif,
 'legacySvgWithoutDataDsIconOccurrencesAcrossRenders':missing_wrapper,
}
(OUT/'FIGMA-DS-ICON-DEMAND-v2.2.0.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
blocking=[x for x in rows if x['status']!='APPROVED_ICON_LIBRARY']
lines=['# Figma DS Icon Demand Audit — v2.2.0 candidate','',f'**{renders} declared state renders across {len(flows)} UIFs audited.**','',
'> This is migration demand from the legacy Product renderer. It does not authorize raw Lucide usage. Canonical Product icon use must resolve through the approved VET45 Icon Library and `DS v2 / Icon` wrapper.','',
'## Global icon demand','']
for r in rows:
    lines.append(f'- `{r["legacySemantic"]}` — {r["renderOccurrences"]} render occurrences — **{r["status"]}**'+(f' → `{r["canonicalTarget"]}`' if r['canonicalTarget'] else ''))
lines += ['','## Freeze blockers','']
if blocking:
    for r in blocking: lines.append(f'- `{r["legacySemantic"]}` requires `{r["canonicalTarget"] or "unresolved"}` but is not currently available as an approved Icon Library Product source.')
else: lines.append('- None.')
lines += ['','## Rule','', '- Do not reuse the current hand-authored SVG registry during migration.', '- Do not pull a glyph directly from the raw `Lucide Icons` vendor section.', '- If a demanded glyph is absent from the approved Icon Library, add/approve it in Figma DS first, then materialize the exact asset and migrate Product usage.']
(OUT/'FIGMA-DS-ICON-DEMAND-v2.2.0.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({'renders':renders,'icons':rows,'blocking':len(blocking),'missingWrapperOccurrences':missing_wrapper},ensure_ascii=False,indent=2))
