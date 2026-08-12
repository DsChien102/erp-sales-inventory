from pathlib import Path
import json, re, sys
ROOT=Path(__file__).resolve().parents[1]
PROTO=ROOT.parent
CONTRACTS=PROTO/'contracts'
FLOWS=PROTO/'flows'
checks=[]

def check(name, cond, detail=''):
    checks.append((name,bool(cond),detail))

manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
app=(ROOT/'app.js').read_text(encoding='utf8')
css=(ROOT/'styles.css').read_text(encoding='utf8')
wb=json.loads((ROOT/'workbench-data.json').read_text(encoding='utf8'))
reg=json.loads((CONTRACTS/'screen-registry.json').read_text(encoding='utf8'))
flowreg=json.loads((FLOWS/'ui-flow-registry.json').read_text(encoding='utf8'))
flowmd=(FLOWS/'UIF-01-BJ-01.md').read_text(encoding='utf8')
scr001=(CONTRACTS/'screens/SCR-001.md').read_text(encoding='utf8')
scr003=(CONTRACTS/'screens/SCR-003.md').read_text(encoding='utf8')
usage=(CONTRACTS/'component-usage/UIF-01-COMPONENT-USAGE.md').read_text(encoding='utf8')

check('manifest version is 0.3.2', manifest.get('version')=='0.3.2', str(manifest.get('version')))
flows=flowreg.get('flows',[])
uif1=next((x for x in flows if x.get('id')=='UIF-01'),{})
check('UIF-01 active full screens exactly SCR-001/SCR-003', uif1.get('screen_ids')==['SCR-001','SCR-003'], str(uif1.get('screen_ids')))
check('UIF-01 entry is SCR-001', uif1.get('entry_screen_ids')==['SCR-001'])
check('UIF-01 terminal is SCR-003', uif1.get('terminal_screen_ids')==['SCR-003'])
check('flow contract declares two full screens + contextual overlays', 'Canonical full-screen surfaces' in flowmd and 'Contextual overlays' in flowmd)
check('SCR-001 explicitly has no Tra cứu/Cần chú ý tabs', 'Không có tab/segmented control `Tra cứu / Cần chú ý`' in scr001)
check('filtered rows do not repeat chip indicator', 'row không lặp lại chính indicator đó' in scr001)
check('SCR-003 explicitly avoids duplicate available metric', 'không lặp lại `Khả dụng`' in scr003 or 'Không lặp `Khả dụng`' in scr003)
check('component usage removes VSegmentedControl', 'VSegmentedControl' not in usage)
check('app has no BJ01 mode tabs', 'data-bj01-mode' not in app)
check('search placeholder uses mã vạch', 'Tên, mã sản phẩm hoặc mã vạch' in app)
# Visible BJ01 renderer slice only
start=app.index('function bj01ProductById')
end=app.index('const renderers =', start)
bj=app[start:end]
check('BJ01 UI has no visible tracking labels', 'Theo lô' not in bj and 'Không theo lô' not in bj)
check('BJ01 UI has no barcode wording', 'barcode' not in bj.lower())
check('BJ01 UI has LOT and provenance bottom sheets', 'data-bj01-close-lot' in bj and 'data-bj01-close-provenance' in bj)
check('filtered row helper suppresses repeated status', 'if(bj01Filter!=="ALL") return "";' in bj)
required_breakdown=["bj01QuantityRow('Tồn vật lý'", "bj01QuantityRow('Đủ điều kiện bán'", "bj01QuantityRow('Đã giữ'"]
check('SCR-003 breakdown has exactly physical/sellable/reserved source calls', all(x in bj for x in required_breakdown) and "bj01QuantityRow('Khả dụng'" not in bj)
check('technical provenance labels absent from BJ01 UI', all(x not in bj.lower() for x in ['snapshot','inventory projection','cut-off']))
check('legacy card-heavy BJ01 classes absent', all(x not in bj for x in ['bj01-metrics','bj01-info-card','bj01-hero','bj01-segment']))
# Ensure every bj01 selector is scoped. Ignore textual class names in comments by looking at selector lines.
selector_lines=[ln.strip() for ln in css.splitlines() if '.bj01-' in ln and '{' in ln]
unscoped=[ln for ln in selector_lines if not ln.startswith('body[data-active-uif="UIF-01"]')]
check('BJ01 CSS selectors scoped to UIF-01', not unscoped, '; '.join(unscoped[:3]))
# registry state/surface checks
screens=reg.get('screens', reg if isinstance(reg,list) else [])
if isinstance(screens,dict): screens=list(screens.values())
def getscr(sid):
    if isinstance(screens,list): return next((x for x in screens if x.get('screen_id')==sid or x.get('id')==sid),{})
    return {}
s1,s3,s4,s5=(getscr(x) for x in ['SCR-001','SCR-003','SCR-004','SCR-005'])
check('SCR-001 registry states include FILTER_EMPTY', 'FILTER_EMPTY' in s1.get('states',[]), str(s1.get('states')))
check('SCR-003 registry uses only READY/LOADING/STALE/PERMISSION_DENIED', s3.get('states')==['READY','LOADING','STALE','PERMISSION_DENIED'], str(s3.get('states')))
check('SCR-004 is overlay', s4.get('surface_type')=='overlay', str(s4.get('surface_type')))
check('SCR-005 is overlay', s5.get('surface_type')=='overlay', str(s5.get('surface_type')))
# workbench flow screen list
wflows=wb.get('flows',[])
wuif1=next((x for x in wflows if x.get('id')=='UIF-01'),{})
check('workbench UIF-01 nav has only SCR-001/SCR-003', wuif1.get('screens')==['SCR-001','SCR-003'], str(wuif1.get('screens')))

passed=sum(ok for _,ok,_ in checks)
failed=[(n,d) for n,ok,d in checks if not ok]
lines=['# BJ-01 Static Contract QA v0.3.2','',f'**Result: {passed}/{len(checks)} PASS**' if not failed else f'**Result: {passed}/{len(checks)} PASS · {len(failed)} FAIL**','', '## Checks','']
for n,ok,d in checks: lines.append(f'- [{"x" if ok else " "}] {n}' + (f' — {d}' if d else ''))
lines += ['', '## Boundary','', '- Validates BJ-01 v0.3.2 information architecture, registry alignment, copy hygiene and UIF-01 CSS scoping.', '- Does not replace runtime/browser visual QA or BJ-02 regression QA.']
(OUT:=Path(__file__).resolve().parent/'BJ01-STATIC-QA-v0.3.2.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(f'{passed}/{len(checks)} passed')
for n,d in failed: print('FAIL',n,d)
sys.exit(1 if failed else 0)
