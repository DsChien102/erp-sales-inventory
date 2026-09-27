from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]  # .../prototype
THEME=Path(__file__).resolve().parents[3]
SRS=THEME/'srs'; OUT=ROOT/'html/qa'
checks=[]
def ck(n,c): checks.append((n,bool(c)))
def read(rel): return (THEME/rel).read_text(encoding='utf8')
data=read('srs/04-data-entities.md'); domain=read('srs/03-domain-foundation.md'); bc=read('srs/06-shared-behavioral-contracts.md'); tech=read('srs/07-technical-contracts.md'); bj=read('srs/02-business-journeys/03-BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan.md')
uc1=read('srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-01-chon-pham-vi-can-dinh-gia.md'); uc2=read('srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-02-xac-dinh-gia-nhap-thuc-te.md'); uc3=read('srs/05-use-cases/BJ-03-xac-nhan-gia-tri-ban-dau-cua-hang-nhan/UC-03-03-xac-nhan-gia-tri.md')
flow=read('prototype/flows/UIF-03-BJ-03.md'); app=read('prototype/html/app.js')
ck('TransactionalBalance materializes valuation_state','| `valuation_state` |' in data)
ck('Balance unique key includes valuation_state','stock_state, valuation_state, lot_key' in data)
ck('ReceiptValuation has stable scope key','`valuation_scope_key`' in data)
ck('ReceiptValuation has scope version','`scope_version_before`' in data)
ck('ReceiptValuation has confirmed quantity','`confirmed_quantity`' in data)
ck('Partial direct confirmations explicitly allowed','nhiều direct-price confirmation khi xác nhận từng phần' in data)
ck('Old one-direct-confirmation-per-line rule removed','Một receipt line chỉ có một direct-price confirmation chính thức' not in data)
ck('Domain uses two independent axes','hai trục độc lập' in domain and 'Physical axis' in domain and 'Valuation axis' in domain)
ck('Old RECEIVED->VALUATION_PENDING->SELLABLE lifecycle removed','RECEIVED → VALUATION_PENDING → SELLABLE' not in domain)
ck('BC-IV-01 preserves physical state','giữ nguyên physical state' in bc)
ck('Expired/blocked no longer blocks valuation','không chặn valuation' in bc)
ck('BC-IV-01 has exact-scope stale/quantity guards','VALUATION_SCOPE_STALE' in bc and 'VALUATION_QUANTITY_EXCEEDS_PENDING' in bc)
ck('Non-mutating preview contract exists','BC-IV-05 — Build direct receipt valuation preview' in bc)
ck('Preview API-Q-11 exists','API-Q-11' in tech and 'POST /v1/receipt-valuations/preview' in tech)
ck('UC03-01 maps to preview not confirm','BC-IV-05' in uc1 and 'API-Q-11' in uc1 and 'API-C-20' not in uc1)
ck('UC03-02 maps to preview not confirm','BC-IV-05' in uc2 and 'API-Q-11' in uc2 and 'API-C-20' not in uc2)
ck('UC03-03 remains final confirm command','BC-IV-01' in uc3 and 'API-C-20' in uc3)
ck('BJ03 start boundary excludes post-valuation late cost','chưa từng được xác nhận giá trị ban đầu' in bj)
ck('BJ03 explicitly routes post-initial late cost to BJ13','thuộc BJ-13' in bj)
ck('UI flow happy path bypasses SCR016','S015 -->|Scope ready| S017' in flow)
ck('UI flow keeps SCR016 for conflict','S015 -->|Có source conflict| S016' in flow)
ck('UI result distinguishes waiting remainder','WAITING_EVIDENCE' in flow and 'S019' in flow)
# End-user copy: target renderer should not leak high-risk technical English vocabulary.
segment=app[app.index('// UIF-03 / BJ-03 v1.4.4'):app.index('function cloneBj02')]
for term in ['identified scope','exact scope','authoritative','value movement','task này']:
    ck(f'No end-user technical leakage: {term}',term not in segment)
failed=[n for n,v in checks if not v]; passed=sum(v for _,v in checks)
lines=['# BJ03 Static / Contract Conformance v1.4.4','',f'**Result: {"PASS" if not failed else "FAIL"} · {passed}/{len(checks)} checks**','', '- Covers data model, domain lifecycle, BC preview/commit split, UC trace, BJ03/BJ13 boundary, flow topology and Product-copy leakage.','', '## Checks','']+[f'- {"PASS" if v else "FAIL"} — {n}' for n,v in checks]
(OUT/'BJ03-STATIC-CONFORMANCE-v1.4.4.md').write_text('\n'.join(lines)+'\n',encoding='utf8')
print(('PASS' if not failed else 'FAIL'),passed,'/',len(checks))
if failed: print('\n'.join(failed)); raise SystemExit(1)
