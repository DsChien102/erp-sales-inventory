# TH-08 — Slice roadmap

Lane columns: **Contract** | **BE** (sub-lane **Worker**) | **FE** | **E2E**. Prerequisite chỉ bind **E2E**. Status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

Dependency epic: EP-01 → EP-02 → (EP-03 ∥ EP-04).

Contracts: [07-api-contracts.md](07-api-contracts.md) · Traceability: [05-traceability.md](05-traceability.md).


| #   | Slice                                                                                                                                                                                                                                                                             | Type     | Contract | BE   | FE   | E2E  | Parallel group | E2E blocked by      |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- | ---- | ---- | ---- | -------------- | ------------------- |
| S0  | Docs ingest (canonical → Epic/US + harness)                                                                                                                                                                                                                                       | docs     | done     | n/a  | n/a  | n/a  | —              | —                   |
| S1  | EP-01 — [US-01](../Epic-01-provider-connection-config/US-01.md) connection + [US-02](../Epic-01-provider-connection-config/US-02.md) profile + [US-03](../Epic-01-provider-connection-config/US-03.md) policy + [US-04](../Epic-01-provider-connection-config/US-04.md) readiness | vertical | todo     | todo | todo | todo | A              | —                   |
| S2  | EP-02 — [US-01](../Epic-02-issue-from-sales-order/US-01.md) preview + [US-02](../Epic-02-issue-from-sales-order/US-02.md) manual issue                                                                                                                                            | vertical | todo     | todo | todo | todo | B              | S1 Contract+BE      |
| S3  | EP-02 — [US-03](../Epic-02-issue-from-sales-order/US-03.md) auto issue + [US-04](../Epic-02-issue-from-sales-order/US-04.md) result + [US-05](../Epic-02-issue-from-sales-order/US-05.md) retry                                                                                   | vertical | todo     | todo | todo | todo | B              | S2                  |
| S4  | EP-03 — [US-01](../Epic-03-issued-invoice-documents/US-01.md) official view + [US-02](../Epic-03-issued-invoice-documents/US-02.md) documents + [US-03](../Epic-03-issued-invoice-documents/US-03.md) observation                                                                 | vertical | todo     | todo | todo | todo | C              | S2 (issued invoice) |
| S5  | EP-04 — [US-01](../Epic-04-send-resend-einvoice/US-01.md) auto send + [US-02](../Epic-04-send-resend-einvoice/US-02.md) manual send + [US-03](../Epic-04-send-resend-einvoice/US-03.md) delivery result                                                                           | vertical | todo     | todo | todo | todo | C              | S2 (issued invoice) |




## Lane semantics


| Lane            | Phạm vi                                                          | Done khi                                      |
| --------------- | ---------------------------------------------------------------- | --------------------------------------------- |
| **Contract**    | Symbol + DTO + error codes trong 07; fake scenario ids           | §S{n} frozen; FE có thể bắt đầu fake          |
| **BE**          | Domain, application handlers, draft RPC `_drafts/einvoice_*.sql` | Handler tests pass; RPC name khớp 07          |
| **BE → Worker** | Job types, idempotency keys, `IMeInvoiceClient` mapping          | Worker job tests + soft-fail thiếu credential |
| **FE**          | Presentation + Theme 05 embed (SG-02/03)                         | Widget tests + fake module scenarios          |
| **E2E**         | Mediator/integration qua `FakeMeInvoiceClient`                   | Không gọi MISA thật; scenario ids trong 05    |




## Parallel groups


| Group | Slices | Ghi chú                                                |
| ----- | ------ | ------------------------------------------------------ |
| A     | S1     | Foundation — unblock S2                                |
| B     | S2, S3 | Issuance vertical — S3 sau S2                          |
| C     | S4, S5 | Sau ElectronicInvoice từ S2/S3 — **parallel** với nhau |


- FE fake: cho phép theo [07-api-contracts.md](07-api-contracts.md) sau Contract lane `done`.
- S4 và S5 parallel sau khi có ElectronicInvoice từ S2/S3.
- UI entry Theme 05 (SG-02/03): coordinate với sales presentation — không block BE handler tests.

## Status feedback (thuộc S2 FE lane)

ERP quan sát trạng thái async bằng **poll projection qua RPC**, không dùng realtime — quyết định và lý do: [03-architecture-and-flows.md §11](03-architecture-and-flows.md).

Việc cụ thể trong S2:

- [ ] `IssueInvoiceCommand` trả `PROCESSING` → UI hiện `Đang xử lý` ngay, không chờ vòng poll đầu
- [ ] Poll `GetOrderInvoiceProjectionQuery` 3–5s khi chưa terminal; dừng hẳn khi terminal
- [ ] Thêm `refetchInterval` vào `packages/vet45_async_query` (`QueryOptions` + `QueryObserver`) — mechanism dùng chung, không dựng `Timer.periodic` từng màn

Deferred (chưa lên slice, đã ghi rationale trong §11): realtime broadcast signal → invalidate; kick worker tick server-side sau enqueue.



## Definition of Done



### Contract lane

- [ ] §S sections trong 07 có symbol Dart, input summary, success DTO, error codes
- [ ] RPC names `einvoice.*` liệt kê status `drafted`
- [ ] Worker mapping + fake scenarios ≥ happy + error path
- [ ] Row CONTRACT trong 05-traceability cập nhật



### BE lane

- [ ] Handlers registered via codegen (`modules/einvoice/`)
- [ ] Validators trong pipeline — không inline trong handler
- [ ] Draft SQL trong `_drafts/` — không file timestamp migration
- [ ] Domain invariants covered by unit tests
- [ ] 05 traceability BE rows có `scn_*` test id



### BE → Worker sub-lane

- [ ] Job type + payload documented trong [03-architecture-and-flows.md §8](03-architecture-and-flows.md)
- [ ] Idempotency key stable per operation
- [ ] Per-tenant credential load + token cache keyed by `tenantId`
- [ ] Soft-fail khi thiếu credential tenant (không crash worker tick)
- [ ] `FakeMeInvoiceClient` trong worker/integration tests



### FE lane

- [ ] Pages/widgets tách file — không God Widget
- [ ] `IModuleMediator` wiring — không direct PostgREST
- [ ] Fake scenarios khớp 07 `scenario_id`
- [ ] SG-04/05: không implement UI



### E2E lane

- [ ] Integration test qua mediator + fake RPC/worker
- [ ] `FakeMeInvoiceClient` — **không** live MISA
- [ ] Theme 05 projection consume verified (khi sales slice sẵn sàng)
- [ ] `e2e_*` ids trong 05



### Chung

- [ ] `melos run analyze && melos run test`
- [ ] `./scripts/ci/verify_harness.sh`



## Slice done

Contract + BE (+ Worker) + FE + E2E đều `done` (hoặc `n/a`).

Khi bắt đầu S1: cập nhật [README.md](../README.md) **Trạng thái deliver** sang đang giao.

## Epic → module mapping


| Epic  | Primary package folders               |
| ----- | ------------------------------------- |
| EP-01 | `application/.../configuration/`      |
| EP-02 | `application/.../issuance/`           |
| EP-03 | `application/.../electronic_invoice/` |
| EP-04 | `application/.../delivery/`           |


Golden reference CQRS: `modules/iam/` — không copy `modules/sales/` scaffold.