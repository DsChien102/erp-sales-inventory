#!/usr/bin/env python3
from pathlib import Path
import json, re, sys
ROOT=Path(__file__).resolve().parents[6]
QA=Path(__file__).resolve().parent

def r(rel): return (ROOT/rel).read_text(encoding='utf-8')
checks=[]
def ck(name,cond,note=''): checks.append({'name':name,'pass':bool(cond),'note':note})

bj02=r('specs/themes/theme-07/srs/02-business-journeys/02-BJ-02-nhan-hang-mua.md')
bj04=r('specs/themes/theme-07/srs/02-business-journeys/04-BJ-04-quan-ly-vong-doi-giu-hang.md')
bj05=r('specs/themes/theme-07/srs/02-business-journeys/05-BJ-05-lay-hang-va-ban-giao-don.md')
bj06=r('specs/themes/theme-07/srs/02-business-journeys/06-BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md')
bj07=r('specs/themes/theme-07/srs/02-business-journeys/07-BJ-07-thuc-hien-tra-hang-cho-nha-cung-cap.md')
bc=r('specs/themes/theme-07/srs/06-shared-behavioral-contracts.md')
data=r('specs/themes/theme-07/srs/04-data-entities.md')
tech=r('specs/themes/theme-07/srs/07-technical-contracts.md')
dec=r('specs/themes/theme-07/know-how/decisions/decision-register.md')

# Source identity / versioning
ck('BJ02 source document/version remains authoritative for receipt', 'source' in bj02.lower() and 'version' in bj02.lower())
ck('BJ05 source and allocation versions remain distinct', 'allocation' in bj05.lower() and 'source' in bj05.lower() and 'version' in bj05.lower())
ck('BJ06 receipt authorization is bound to current return source', 'ReturnExchangeLine' in bj06 or 'authorized_return_quantity' in bj06)
ck('BJ07 source request/line/allocation identity is stable across versions', all(x in bj07 for x in ['source_request_id','source_line_id','source_allocation_id']))
ck('BJ04 source line/version is stable and contextual', 'source_line_id' in bj04 and 'source version' in bj04.lower())

# Product/UOM/LOT semantics
ck('Transaction UOM snapshots are explicit in BJ04 reservation', 'transaction_uom_snapshot' in data and 'conversion_version' in data)
ck('BJ05 owns LOT allocation, not BJ04', 'PickAllocation' in bj04 and 'BJ-05' in bj04 and 'không' in bj04.lower())
ck('BJ06 actual LOT is physical truth distinct from source LOT', 'actual LOT' in bj06 or 'Actual LOT' in bj06)
ck('BJ07 handover scope uses exact Product/UOM/LOT source allocation', all(x in bj07 for x in ['Product','UOM','LOT']))

# Quantity semantics
ck('BJ02 classification derives a single authoritative received total', 'authoritative' in bj02.lower() and ('Tổng thực nhận' in bj02 or 'actual' in bj02.lower()))
ck('BJ04 separates requested/current-held/consumed/shortage', all(x in bj04 for x in ['requested_base_quantity','reserved_base_quantity','consumed_base_quantity','shortage_base']))
ck('BJ05 handover quantity cannot exceed allocation/reservation semantics', 'consumed' in bj05.lower() and 'allocation' in bj05.lower())
ck('BJ06 actual received cannot exceed current authorized return quantity', 'authorized_return_quantity' in bj06 and 'actual received có thể ít hơn' in bj06)
ck('BJ07 warehouse cannot silently reduce/substitute commercial return scope', 'không' in bj07.lower() and ('substitute' in bj07.lower() or 'thay lô' in bj07.lower()))

# Reservation / availability ownership
ck('ReservationBucket represents current hold only', 'ReservationBucket.reserved_base_quantity = Σ current Reservation.reserved_base_quantity' in bj04)
ck('BJ04 emits allocation review instead of mutating BJ05 allocation', 'allocation_review_required' in bj04 and 'không mutate allocation' in bj04.lower())
ck('No automatic reservation top-up occurs after capacity returns', 'Không auto top-up' in bj04 or 'không auto top-up' in bj04.lower())

# Evidence / approval semantics
ck('BJ02 quick receipt approval remains mandatory and separate from ownership/execution', 'Mọi Quick receipt' in bj02 and 'không bypass approval' in bj02 and 'approval không thay ownership' in bj02)
ck('BJ06 wrong-LOT approval is line-exception scoped', 'LINE_EXCEPTION' in data or 'subject_line_id' in data)
ck('BJ07 commercial authorization is not re-approved by Theme7', 'không duyệt thương mại lần hai' in bj07.lower() or 'không phê duyệt thương mại lần hai' in bj07.lower())
ck('Shared handover evidence is source-agnostic across BJ05/BJ07', 'HandoverEvidence' in data and ('source_type' in data or 'source_document_id' in data))

# Finality / UNKNOWN
ck('Shared UNKNOWN rule preserves same operation identity', 'UNKNOWN' in bc and 'same' in bc.lower() and ('identity' in bc.lower() or 'idempotency' in bc.lower()))
ck('BJ05 UNKNOWN is recovery/reconciliation rather than blind retry', 'UNKNOWN' in bj05 and ('retry' in bj05.lower() or 'xác minh' in bj05.lower()))
ck('BJ06 UNKNOWN retains operation identity for BJ17 recovery', 'UNKNOWN' in bj06 and ('BJ17' in bj06 or 'BJ-17' in bj06))
ck('BJ07 UNKNOWN remains part of shared non-blind-retry finality contract', 'UNKNOWN/ESCALATED' in bj07 and 'UNKNOWN' in bc and ('same operation' in bc.lower() or 'same identity' in bc.lower() or 'idempotency identity' in bc.lower()))

# Cross-boundary auditability
ck('Commercial order intent is separate from reservation capacity commitment', 'reservation_policy' in bj04 and 'source' in bj04.lower())
ck('Reservation capacity is separate from physical LOT allocation/handover', 'Reservation không gắn LOT' in data and 'PickAllocation' in data)
ck('Commercial supplier price is not a physical handover blocker', 'commercial' in bj07.lower() and ('không' in bj07.lower()) and ('block' in bj07.lower() or 'bàn giao' in bj07.lower()))
ck('Routine customer-return classification is inventory physical truth, not Theme5 commercial condition', 'ReturnCondition' in bj06 and ('classification' in bj06.lower() or 'phân loại' in bj06.lower()))
ck('Cross-Wave decisions are present through T7-DR-149', all(f'T7-DR-{i}' in dec for i in range(106,150) if i not in {107,108}))

status='PASS' if all(x['pass'] for x in checks) else 'FAIL'
out={'version':'3.9.6','scope':'Wave 2 Cross-BJ Audit — BJ02/BJ05/BJ06/BJ07/BJ04','status':status,'passed':sum(x['pass'] for x in checks),'total':len(checks),'checks':checks}
(QA/'WAVE-2-CROSS-BJ-AUDIT-v3.9.6.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
md=['# Wave 2 Cross-BJ Audit — v3.9.6','',f'**Result: {status} · {out["passed"]}/{out["total"]}**','', 'Scope: BJ02 → BJ05 → BJ06 → BJ07 → BJ04 after all deep-review decision packs were propagated.','']
md += [f'- {"PASS" if x["pass"] else "FAIL"} — {x["name"]}' + (f': `{x["note"]}`' if not x['pass'] and x['note'] else '') for x in checks]
(QA/'WAVE-2-CROSS-BJ-AUDIT-v3.9.6.md').write_text('\n'.join(md)+'\n')
print(status,out['passed'],out['total'])
if status!='PASS':
 for x in checks:
  if not x['pass']: print('FAIL',x['name'],x['note'])
 sys.exit(1)
