# EVD-STRUCTURE-MIGRATION-v3.11.0

## Mục tiêu

Chuyển nguyên baseline Theme 07 v3.10.1 sang cấu trúc `V45-Theme skeleton` hiện hành mà không thay đổi semantic nghiệp vụ.

## Parent và candidate

- Parent: `v3.10.1` từ `theme-07.zip` do Product cung cấp.
- Candidate: `v3.11.0`.
- Semantic delta: `NONE`.
- Số file nguồn trước khi thêm evidence migration mới: **7025**.

## Mapping cấu trúc

| Nguồn cũ | Đích mới |
|---|---|
| `04.architecture/aggregates` | `02.specification/domain/aggregates` |
| `04.architecture/read-models` | `02.specification/domain/read-models` |
| `04.architecture/integrations` | `02.specification/domain/integrations` |
| `04.architecture/foundations + nfr` | `02.specification/technical-contracts` |
| `05. harness/{sa-slices,be-slices,fe-slices}` | `04.harness/slices` |
| `05. harness/manifests` | `04.harness/manifests` |
| `06.procedures` | `05.procedures` |
| `07.evidence` | `06.evidence` |

## Quy tắc bảo toàn

- Không sửa nghiệp vụ, Decision, BJ/UC, Domain/Entity hoặc hành vi prototype.
- Nội dung IO đã có trong parent được giữ nguyên; chỉ đường dẫn cấu trúc được phép thay đổi khi cần để tránh link gãy.
- Ba nhóm SA/BE/FE Slice được đặt chung dưới `04.harness/slices/`; version này chưa đổi semantic của Slice.
- Evidence lịch sử giữ nguyên nội dung lịch sử; chỉ liên kết tương đối có đích canonical được phép cập nhật khi cần.
- Generated registry/checksum được tái sinh sau migration.
