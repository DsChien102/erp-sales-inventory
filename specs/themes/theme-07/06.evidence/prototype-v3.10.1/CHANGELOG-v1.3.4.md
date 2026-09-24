# CHANGELOG v1.3.4

Parent: `v0.3.4`. This is a cumulative release.

## BJ-02
- `SCR-084`: removed separate `Số lượng thực nhận` input.
- `Đạt / Cách ly / Hỏng / Từ chối` are four authoritative quantity inputs.
- `Tổng thực nhận` derives from the four values.
- LOT lines apply the same rule per LOT.

## BJ-04
- Reframed reservation lifecycle as source/system-driven.
- Active Inventory UI reduced to read-only `SCR-021` projection; manual hold/release/reallocation screens retired from active UIF04.

## BJ-05
- Designed queue → pick overview → one-item pick → handover review → result.
- Normal pick/handover no approval.
- LOT override requires permission, eligible same-warehouse LOT, mandatory reason and audit.
- Physical stock changes only at actual handover.

## BJ-06
- Designed return queue → receipt overview → line/LOT receipt → receipt milestone → classification.
- Wrong LOT uses separate maker-checker approver surface; approval itself does not post stock.
- Receipt posts once to `RETURN_PENDING`; classification has `Bán được / Cách ly / Hỏng / Hết hạn` and no second value posting.
- Cumulative return cap and expired→sellable are hard guards.

## BJ-07
- Designed source-authorized supplier-return queue/detail/handover/result.
- Removed generic `SCR-038` from active UIF07 while preserving it for UIF09.
- No second commercial approval in Inventory.
- `RTV_PENDING` removes availability; physical/value decrease only on actual handover.

## Cross-cutting
- Flutter Design System remains UI authority.
- Search/no-result, inline validation, UNKNOWN recovery and 402×874 mobile behavior were runtime/visual QA targets.
- Out-of-scope UIFs remain protected by isolation checks.
