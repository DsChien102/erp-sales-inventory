from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=Path(__file__).resolve().parent
PRO=ROOT.parent
app=(ROOT/'app.js').read_text(encoding='utf8')
styles=(ROOT/'styles.css').read_text(encoding='utf8')
data=(ROOT/'workbench-data.js').read_text(encoding='utf8')
checks=[]
def ck(n,c): checks.append((n,bool(c)))

# Release metadata
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
ck('HTML manifest declares v1.4.2',manifest.get('version')=='1.4.2')
ck('Root README declares v1.4.2','v1.4.2' in (ROOT.parents[4]/'README.md').read_text(encoding='utf8'))

# Stable display ontology / old ambiguous UI wording removed from renderer.
for old in ['Xác nhận lần này','Chi phí mua đến sau không sửa lần xác nhận này','Mã LOT <small>(không bắt buộc)','mục đã kiểm','Mục hàng','mục hàng','3 mặt hàng · 4 phần']:
    ck(f'Old ambiguous renderer copy absent: {old}',old not in app)
ck('BJ05 progress uses dòng vocabulary','dòng đã lấy đủ' in app)
ck('BJ06 progress uses dòng vocabulary','dòng đã kiểm' in app)
ck('BJ03 scope input uses explicit valuation meaning','Số lượng xác nhận giá' in app)
ck('BJ07 uses explicit child task role','Lô cần kiểm' in app and 'Phần hàng cần kiểm' in app)
ck('BJ07 verify sheet distinguishes source target','Lô cần khớp' in app and 'Quét hoặc nhập LOT để đối chiếu' in app)
ck('BJ07 verify sheet denies source mutation','không thay đổi LOT của yêu cầu' in app)
ck('BJ03 financial values are labeled','Giá trị sẽ ghi' in app and 'Giá trị đã ghi' in app)
ck('BJ06 approval evidence role is labeled','Ảnh nhãn lô thực nhận' in app)

# Semantic composition classes exist without ad-hoc color literals in the v1.4.2 tail.
for klass in ['io-object-kicker','io-action-hint','val03-effect-group','io06-result-group','io07-product-group','io07-allocation-row','io07-verify-target','io07-review-group','io07-result-group']:
    ck(f'Composition style exists: {klass}',f'.{klass}' in styles)
# v1.4.2 style section should consume tokens, not add new hex colors.
marker='v1.4.2'
tail=styles[styles.rfind(marker):] if marker in styles else styles[-12000:]
ck('v1.4.2 semantic styles introduce no hex color literal',re.search(r'#[0-9a-fA-F]{3,8}',tail) is None)

# Contracts and UIF component usage are synchronized.
for scr in ['009','010','011','012','015','016','017','019','025','026','027','028','031','034','035','037','039','041']:
    p=PRO/'contracts/screens'/f'SCR-{scr}.md'
    ck(f'SCR-{scr} contract exists',p.exists())
for uif in ['02','03','05','06','07']:
    p=PRO/'contracts/component-usage'/f'UIF-{uif}-COMPONENT-USAGE.yaml'
    txt=p.read_text(encoding='utf8')
    ck(f'UIF-{uif} component contract carries v1.4.2 hierarchy block','semanticHierarchy_v1_4_2:' in txt)

scr37=(PRO/'contracts/screens/SCR-037.md').read_text(encoding='utf8')
ck('SCR-037 contract explicitly defines UIF07 physical verification','physical' in scr37.lower() and 'UIF-07' in scr37)
ck('SCR-037 contract no longer globally forbids UIF07 mutation','không dùng generic rule này để biến uif-07 thành read-only' in scr37.lower())

# Active UIF07 flow still excludes SCR-038; shared workbench may retain it for UIF09.
uif07=(PRO/'flows/UIF-07-BJ-07.md').read_text(encoding='utf8')
ck('UIF07 explicitly excludes SCR-038','SCR-038' in uif07 and 'không thuộc UIF-07' in uif07)
# Active path remains canonical.
for token in ['SCR-036','SCR-037','SCR-039','SCR-041']:
    ck(f'UIF07 flow retains {token}',token in uif07)

# Workbench vocabulary aligns with renderer for line-level business objects.
ck('Workbench data no longer calls Product+UOM line mục hàng','mục hàng' not in data.lower())
flow02=(PRO/'flows/UIF-02-BJ-02.md').read_text(encoding='utf8')
ck('UIF02 flow vocabulary uses dòng hàng','dòng hàng' in flow02 and 'mục hàng' not in flow02.lower())

passed=sum(v for _,v in checks); failed=[n for n,v in checks if not v]
lines=['# Static Conformance v1.4.2','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','',
       'Coverage: release metadata; stable display ontology; BJ03/BJ05/BJ06/BJ07 semantic hierarchy copy; component-composition styles; synchronized screen/component contracts; UIF07 active-flow guard; workbench vocabulary.','',
       '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'STATIC-CONFORMANCE-v1.4.2.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed:
    print('\n'.join(failed)); raise SystemExit(1)
