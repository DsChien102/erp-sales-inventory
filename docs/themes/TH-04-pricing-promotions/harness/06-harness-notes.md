# TH-04 EP02 — Harness notes

## Guards

| Guard | Script |
| ----- | ------ |
| Theme structure | `scripts/ci/guard_theme_structure.sh` |
| Theme traceability | `scripts/ci/guard_theme_traceability.sh` |
| Documentation links | `scripts/ci/guard_docs_reference.sh` |
| Layer imports | `scripts/ci/guard_layer_imports.sh` |
| Infrastructure Dart-only | `scripts/ci/guard_infra_dart_only.sh` |
| Presentation size/dialogs | `scripts/ci/guard_presentation_size.sh`, `scripts/ci/guard_presentation_dialogs.sh` |

Umbrella: `scripts/ci/verify_harness.sh`.

## Verify chain per implementation slice

```bash
melos bootstrap
melos run analyze
melos run test
melos run codegen
./scripts/ci/verify_harness.sh
cd apps/erp && flutter test test/features/pricing/
```

## Decisions captured on 2026-07-14

- Recreated TH-04 after `dev` fetch removed earlier local work.
- `Theme-3-partner.md` is the formatting/canonical-document standard.
- Six epic folders are retained; only EP02 is active.
- Future owner is `pricing`; `catalog`, `partner`, `sales`, `iam` are supporting contexts.
- RPC-first CQRS replaces legacy REST endpoint notation from the source document.
- Money uses integer minor units in Dart/contracts.
- `expired` is derived; activity is append-only; memory request is idempotent.
- S9 Pricing lanes are actionable, but E2E is blocked by Sales.

## S1 decisions captured on 2026-07-16

- Below-floor system default là `block_with_override`; tenant-specific policy deferred.
- Dưới floor chỉ commit khi request đã acknowledge và actor có `pricing.customer_price_rule.override_floor_price`; cả hai failure dùng `BELOW_FLOOR_BLOCKED` với `details.reason` khác nhau.
- Precheck chỉ hỗ trợ UX. Mutation RPC lấy actor từ `auth.uid()` và recheck tenant/create permission, provider references, closed-interval overlap và floor policy. **Target docs:** overlap → `OVERWRITE_REQUIRED` rồi soft-delete khi acknowledge (legacy auto-disable/`DUPLICATE_ACTIVE_RULE` = drift).
- Floor snapshot bị redact với actor không có override permission; server vẫn trả `isBelowFloor` để enforce acknowledgement mà không lộ amount.
- Không có floor trả outcome `notChecked`; currency mismatch hoặc Catalog numeric không tương thích integer minor units trả `REFERENCE_INVALID`, không round qua `double`.
- S1 idempotency dùng unique tenant + key + normalized payload hash; same payload trả original result, different payload trả `IDEMPOTENCY_CONFLICT`.
- `CustomerPriceRuleCreatedDomainEvent` chỉ nội bộ. S1 không tạo integration event/outbox; RPC ghi activity cùng transaction.
- Partner/Catalog IDs là opaque references, không có physical cross-context FK. Ba SQL file vẫn là draft và chưa được apply.

## S2 decisions captured on 2026-07-16

- Search/list là read projection; không thay đổi aggregate/domain event/activity/outbox.
- Pricing-owned customer/product snapshots phục vụ search. Product reference/SKU được snapshot lúc commit; customer code deferred.
- Derived status precedence cố định: disabled → needs review → expired → not yet effective → applying; deleted không vào working list và date boundaries inclusive.
- Pagination dùng opaque cursor `updated_at DESC, id DESC`, query `limit + 1`; V1 không có custom effectivity/updated-date range.
- Quick below-floor dùng validation snapshot gần nhất, không phải Catalog-live; list không lộ floor amount.
- Query access guard bind tenant từ execution context và dùng generated access metadata trước RPC; RPC vẫn recheck view/tenant, không nhận actor ID.
- SQL vẫn chỉ là draft dưới `_drafts/`; không apply/promote và không chạy live DB E2E trong S2.

## S3 decisions captured on 2026-07-16

- Detail là read projection với live Partner/Catalog provider enrichment; không mutate aggregate/status/list projection/activity.
- Provider missing/inactive reference → health issue codes + stored snapshot fallback; provider technical failure → `SYSTEM_ERROR`.
- Below-floor luôn expose `below_floor_price`; floor amount chỉ hiện với override permission.
- Source-trace identifiers chỉ với `view_history`; không embed activity rows — `history` điều hướng S10.
- Action matrix theo persisted status + update/disable/reenable/view_history permissions; derived expired/not_yet_effective không đổi actions.
- Create helper `_customer_price_rule_result` được mở rộng health/trace/lifecycle actions để S1 create result decode chung với S3 detail mapper.
- SQL vẫn chỉ là draft (`pricing_customer_price_rule_detail_s3.sql`); không apply/promote.

## S5 decisions captured on 2026-07-16

- Update chỉ nhận mutable fields (`rulePriceMinor`, `effectiveFrom`, `effectiveTo`, `note`, `acknowledgeFloorWarning`) + `ruleId`/`expectedVersion`; không có `currencyCode`/identity/source input — currency lấy từ rule hiện hành và không thể đổi qua command này (`RuleCurrencyMustNotChangeRule`).
- `CustomerPriceRule.reconstitute` không raise `CustomerPriceRuleCreatedDomainEvent`; `updateMutableFields` no-op (giá/kỳ hạn/note không đổi sau normalize) không tăng version, không raise event, không ghi activity. Meaningful update tăng version đúng một lần và raise đúng một `CustomerPriceRuleUpdatedDomainEvent`.
- Advisory RPC (`get_customer_price_rule_update_context`) chỉ hỗ trợ UX/precheck; không authorize commit. Authoritative RPC (`update_customer_price_rule`) luôn tự lock row, tự recheck version/status/reference/duplicate/floor trước khi ghi — không tin kết quả advisory.
- Handler luôn gọi authoritative gateway kể cả khi no-op ở local (advisory `expectedVersion` gửi luôn là giá trị gốc từ command, RPC là nguồn quyết định version thật).
- `disabled` giữ nguyên `disabled` khi update; mọi status khác (kể cả `needs_review` do bị block) normalize thành `active` sau khi validation/review snapshot được refresh lại.
- Hai stable code mới: `STATE_CHANGED` (version lệch) và `INVALID_STATUS` (persisted status ngoài `active`/`needs_review`/`disabled`).
- SQL vẫn chỉ là draft (`pricing_customer_price_rule_update_s5.sql`); không apply/promote. `activity_type` check constraint được nới để chấp nhận `updated` bên cạnh `created` (chỉ trong file S5, không đụng S1/S3).

## S6 decisions captured on 2026-07-16

- Disable dùng **một** authoritative RPC (`pricing.disable_customer_price_rule`): không có precheck/advisory port, không gọi Partner/Catalog provider, không floor/duplicate check — lifecycle tắt rule không cần revalidate reference/overlap.
- Nhánh already-disabled chạy **trước** expected-version check để retry an toàn với `expectedVersion` gốc: trả current detail, không ghi đè actor/time/reason, không tăng version, không thêm activity.
- Real disable: `active`/`needs_review` → `disabled`, `version + 1`, một `CustomerPriceRuleDisabledDomainEvent` (domain mirror) + một activity `disabled`; audit `disabled_at`/`disabled_by`/`disabled_reason` do RPC ghi cùng transaction (`auth.uid()`).
- Derived `expired` / below-floor không chặn disable; deleted/cross-tenant → `NOT_FOUND`.
- SQL vẫn chỉ là draft (`pricing_customer_price_rule_disable_s6.sql`); không apply/promote. `activity_type` check constraint nới thêm `'disabled'` trong file S6.

## S7 decisions captured on 2026-07-16

- Precheck query + reenable command frozen với 16 fake scenarios; `precheckToken` optional, 64-char lowercase hex khi có; `businessDate` UTC calendar date bắt buộc ở cả query và command.
- Private helper `pricing._customer_price_rule_reenable_context` derive live Partner/Catalog snapshots, duplicate, floor, permission, outcome, và HMAC-SHA-256 fingerprint (`pricing-reenable-s7-v1`) dùng chung cho precheck và commit. HMAC key lấy từ Vault secret `pricing_reenable_fingerprint_hmac_v1`; commit lấy cùng rule-key advisory lock như S1/S5 trước khi recompute context.
- Stale supplied token → `STATE_CHANGED` trước business-validation errors mới; omitted token vẫn chạy full authoritative validation.
- Commit ordering: `FOR UPDATE` → version → disabled status → context → token compare → reference/duplicate/floor/expired errors → active update + một activity `reenabled`.
- Mutation không gọi `get_customer_price_rule_detail` (không yêu cầu `view` permission ngầm); response build qua `_customer_price_rule_result`.
- SQL vẫn chỉ là draft (`pricing_customer_price_rule_reenable_s7.sql`); không apply/promote. `activity_type` check constraint nới thêm `'reenabled'` trong file S7.

## Pitfalls

- Không nhầm TH-02 product/base price với TH-04 customer-specific policy.
- Không đặt final-price calculation vào `CustomerPriceRule` aggregate.
- Không dùng customer/product/unit display label làm identity.
- Không bỏ `product_unit_id` vì Excel V1 thiếu cột unit; phải resolve hoặc row error.
- Không tin precheck/cache tại commit time.
- Overlap active → yêu cầu **overwrite-confirm** rồi soft-delete; không coi `DUPLICATE_ACTIVE_RULE` blocked là product SSOT nữa (legacy code vẫn có thể trả code cũ — `DOC_AHEAD_OF_CODE`).
- Không phân biệt nguồn rule cũ khi nhớ giá từ Sales (bỏ pitfall “không overwrite manual”).
- Không lưu tiền bằng `double`.
- Không ghi activity sau transaction như best-effort side effect; activity phải cùng commit.
- Không coi RPC draft là migration đã apply.
- Docs-only PR không được “sửa cho khớp” Dart/SQL khi Theme-4 đã đổi policy — ghi drift và mở catch-up slice.

## Flywheel log

| Date | Observation | Harness response |
| ---- | ----------- | ---------------- |
| 2026-07-14 | TH-04 cũ mất sau fetch; catalog còn stale Sales link | Recreate canonical TH-04 folder and reconcile catalog/cross-links. |
| 2026-07-14 | Source spec dùng REST references | Normalize to CQRS symbols + `pricing.*` RPC targets. |
| 2026-07-14 | Sales dependency có thể block toàn S9 | Block only E2E lane; use fake/public contract for CONTRACT/BE/FE. |
| 2026-08-04 | Theme-4 đổi duplicate → overwrite-confirm; harness/US/contracts lệch code | Sync docs-only (`DOC_AHEAD_OF_CODE`); note known drift: code still blocks/`MANUAL_RULE_PROTECTED`/auto-disable. |

## Known drift (implementation still blocks duplicates)

Đến khi catch-up slice chạy, Dart/SQL/Fake có thể vẫn:

- Trả `DUPLICATE_ACTIVE_RULE` blocked trên create/import
- Auto-disable overlapping (`AUTO_REPLACED_BY_RULE`) trên update/reenable
- Sales memory: `MANUAL_RULE_PROTECTED`

Product + harness docs là SSOT mới; test ids cũ vẫn cover behavior legacy.

## Open follow-ups

- **EP02 overwrite-confirm catch-up** (Contract/BE/FE): `acknowledgeOverwrite`, soft-delete overlapping, deprecate `DUPLICATE_ACTIVE_RULE` / `MANUAL_RULE_PROTECTED`, Fake scenarios `*_overwrite_*`, FE confirm dialog — xem [04-slice-roadmap.md](04-slice-roadmap.md).
- Chốt memory upsert interval semantics trước S9 FE/E2E sign-off (đã supersede Q-02 trong US-09 docs).
- Promote/apply SQL drafts khi môi trường sẵn sàng.
