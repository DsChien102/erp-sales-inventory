# TH-08: Hóa đơn điện tử

**Trạng thái deliver:** `planned`

## Mục tiêu

Lập, phát hành, theo dõi trạng thái và tải hóa đơn điện tử (HĐĐT) cho từng tenant — tích hợp vendor **MISA meInvoice** (đầu ra) qua blackbox `vet45_misa`, gọi HTTP **chỉ từ messaging worker**.

## Module / package tham gia (dự kiến)

| Thành phần | Vai trò |
| ---------- | ------- |
| Module HĐĐT (TBD khi SRS) | Owner — commands, ports, persist trạng thái HĐ |
| [`packages/vet45_misa`](../../../packages/vet45_misa/) | Vendor adapter blackbox (`e_invoice.dart`) |
| [`apps/messaging_worker`](../../../apps/messaging_worker/) | Runtime caller MISA (on-behalf-of tenant) |
| IAM / tenant legal profile | Supporting — `tenantId`, MST pháp lý |
| sales / partner | Supporting — nguồn dữ liệu phát hành (sau) |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| Overview | [OVERVIEWS.md](OVERVIEWS.md) |
| Kiến trúc tích hợp MISA (agent) | [harness/03-architecture-and-flows.md](harness/03-architecture-and-flows.md) |
| Platform architecture | [docs/architecture/](../../architecture/README.md) |

Epic/US/FR và đầy đủ harness `00..07` sẽ bổ sung khi theme chuyển `in_progress`.

## Quy ước ID

```text
TH-08 / EP-{nn} / US-{nn} / FR-{nn}
```
