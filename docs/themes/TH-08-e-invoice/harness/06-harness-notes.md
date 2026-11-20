# TH-08 — Harness notes

## Flywheel

Khi agent fail cùng lỗi docs/ID → cập nhật file này + guard/doc, không chỉ retry prompt.

### Flywheel log

| Date | Error / symptom | Fix (file + rule) |
| ---- | --------------- | ----------------- |
| — | — | — |

## Naming decisions (harness — không có trong canonical)

| Decision | Value | Ghi chú |
| -------- | ----- | ------- |
| Module / bounded context | `einvoice` | `modules/einvoice/` |
| Postgres schema | `einvoice` | RPC prefix `einvoice.*` |
| Error taxonomy | 07-api-contracts Error envelope | Canonical không định nghĩa mã lỗi — harness derive từ EC/BR |
| Permission constants | `EInvoicePermissions.*` | Xem [02-module-map.md](02-module-map.md) |
| Test id pattern | `scn_e0x_u0y_*`, `wgt_*`, `e2e_*` | SC trong US giữ `SC-*`; map khi implement |
| Fake module | `FakeEInvoiceModule` | Scenario ids khớp 07-api-contracts |
| Q-02 `GetProviderConnectionStatusQuery` | **Removed** — merged into Q-01 `GetProviderConnectionScreenQuery` in 07 §S1a |
| E2E vendor | `FakeMeInvoiceClient` | Không gọi MISA live trong CI |
| Status feedback | Poll projection qua RPC | Realtime deferred — [03 §11](03-architecture-and-flows.md) |

## Platform gap (phát hiện khi thiết kế S2)

| Gap | Ảnh hưởng | Hướng xử lý |
| --- | --------- | ----------- |
| `c45_async_query` thiếu `refetchInterval` | Không poll được trạng thái async bằng cơ chế chung | Bổ sung vào `QueryOptions`/`QueryObserver` trong S2 FE lane — không dựng `Timer.periodic` từng màn |
| `IMessagingFlushPort.flushAfterMutation()` chưa có implementation | Không kick worker sau enqueue; latency phụ thuộc tick 3–30s | Deferred — xem [03 §11](03-architecture-and-flows.md) |
| Supabase Realtime chưa dùng ở đâu trong repo | Push signal sẽ là mechanism hoàn toàn mới (gateway + RLS + test) | Deferred, không thuộc S2 |

## Anomalies trong canonical SRS

| Issue | Ghi chú |
| ----- | ------- |
| Heading `### 2.2.1` dưới §2.1 | Lệch số (nên 2.1.x) — đọc theo nội dung |
| Duplicate `### 5.4.2 Business context` | Hai heading liền nhau quanh EP-03 overview |
| Scenario IDs `SC-*` | Template harness thường `SCN-*` — giữ SC trong US; map test id khi implement |
| SG-04 / SG-05 | **Loại khỏi UI MVP** — reconciliation / hồ sơ độc lập không có màn user |
| FR IDs local theo US | Luôn qualify `EP-0n/US-0m/FR-0k` |
| Google Docs escapes | Canonical còn `FR\-01`, `5\.2` — bản Epic/US đã normalize |

## Scope locks (MVP)

- Một HĐ gốc / SalesOrder; không điều chỉnh / thay thế / hủy trong Mosaic Retail.
- Một ProviderConnection hoạt động; Phase 1 = MISA meInvoice.
- Không danh sách HĐĐT độc lập; entry từ Theme 05.
- Worker-only HTTP tới MISA ([03-architecture-and-flows.md](03-architecture-and-flows.md)).

## Guards liên quan

- `./scripts/ci/guard_theme_structure.sh` — khi chuyển `in_progress` cần harness 00–07 + Epic README.
- `./scripts/ci/guard_theme_traceability.sh` — Role column + scn_* khi có SCN reference.
- Migration: chỉ `_drafts/` cho đến khi user promote.

## Package đã có (blackbox)

`packages/c45_misa` — Phase A: `listInvoiceTemplates`, `previewUnpublished`, `publish`, `getStatus`, `download`, `previewPublished`, `sendEmail`. Map vào worker jobs — xem [03-architecture-and-flows.md §8](03-architecture-and-flows.md).

## Presentation example catalog

Audit scaffold (38 SRS §6.5 specimens, SG tabs placeholder): [modules/einvoice/presentation/example/README.md](../../../modules/einvoice/presentation/example/README.md) — chạy `c45 run einvoice_presentation debug:web`.

## Harness maturity (2026-08-17)

- S0 docs ingest: **done**
- Harness 00–07 exemplar-complete (symbol + RPC drafted + traceability): **done**
- Slice code S1+: **Contract lane done** (toàn S1–S5, 2026-08-17) — **BE S1 done**; FE/E2E S1 todo
