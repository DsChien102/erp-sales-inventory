# Theme template — Hướng dẫn sử dụng

Bộ template theo cấu trúc đã chốt: Domain là vùng chung BA/SA; kiến trúc dùng chung nằm trong Domain hoặc Technical Contract; thiết kế cục bộ nằm trong Work Slice (theo role).

## Cấu trúc Theme đích

```text
theme-xx/
    README.md
    VERSION.md
    01.knowledge/
        know-how/
        decisions/
        glossary/
    02.specification/
        overview/
        behavior/
            journeys/
            use-cases/
            behavioral-contracts/
        domain/
            domain-foundation/
            entities/
            aggregates/
            read-models/
            integrations/
        technical-contracts/
    03.design/
        screens/
        patterns/
        design-system/
        prototype/
    04.harness/
        BJ-<id>-harness/
            CATALOG.md
            SL-*.md
    05.procedures/
    06.evidence/
    09.generated/
```

Khi tạo Theme, dùng [README.template.md](README.template.md) và [VERSION.template.md](VERSION.template.md) để tạo README.md/VERSION.md. Sample harness chỉ minh họa; không sao chép thành yêu cầu chính thức.

## Nơi sở hữu nội dung

- **Knowledge:** tri thức, quyết định và thuật ngữ.
- **Behavior:** BJ, UC và BC; luồng giao diện cấp hành trình tiếp tục nằm trong BJ. Giữ quy ước BJ/UC V5.
- **Domain:** Foundation mô tả trách nhiệm/bất biến; Entity mô tả đối tượng; Aggregate sở hữu ranh giới nhất quán; Read Model sở hữu mô hình đọc; Integration sở hữu nghĩa và ranh giới trao đổi giữa các Domain/Theme.
- **Technical Contract:** quy tắc kỹ thuật dùng chung nhiều Slice hoặc toàn Theme. NFR đo được dùng mẫu NFR trong cùng thư mục. Không tạo tài liệu chỉ để lấp đủ chủ đề.
- **Design:** Screen, Pattern, Design System và prototype. Prototype không quyết định quy tắc nghiệp vụ; HTML chạy được đặt trong 03.design/prototype/html/ khi Theme có runtime.
- **Work Slice:** file flat theo role (`full` | `be-contract` | `be-impl` | `fe` | `e2e`) trong `BJ-<id>-harness/`; nhóm bằng `family`; `CATALOG.md` là SSOT `design_status`. Templates: `.agents/skills/to-work-slices/`.
- **Procedures/Evidence/Generated:** quy trình vận hành, bằng chứng và dữ liệu sinh tự động. Generated không phải nguồn biên tập tay.

Xem [Doctrine và Directory Contract](../README.md) để đối chiếu trách nhiệm từng vùng.

## Điểm bắt đầu

- [BJ template](02.specification/behavior/journeys/BJ.template.md) và [UC template](02.specification/behavior/use-cases/UC.template.md).
- [Aggregate](02.specification/domain/aggregates/AGGREGATE.template.md), [Read Model](02.specification/domain/read-models/READ-MODEL.template.md), [Integration](02.specification/domain/integrations/INTEGRATION.template.md).
- [Technical Contract](02.specification/technical-contracts/TECHNICAL-CONTRACT.template.md) và [NFR](02.specification/technical-contracts/NFR.template.md).
- [Harness README](04.harness/README.md), [sample BJ-xx-harness](04.harness/BJ-xx-harness/CATALOG.md) (`full` + family `quick-receipt` đủ 4 role).
- Skills: `/to-work-slices` → `/review-work-slices` → `/implement-work-slice` (templates + SSOT: `.agents/skills/to-work-slices/`).

`CATALOG.md`: `depends_on` = Slice ID; `sources` = artifact ID; coverage = phạm vi dự kiến, không phải bằng chứng hoàn thành. Không còn `theme.manifest.yml`.

## Mapping chuyển đổi bộ template

Bảng này ghi đường dẫn lịch sử → đường dẫn hiện hành; không giữ bản sao ở đường dẫn cũ.

| Đường dẫn cũ | Đường dẫn mới / Xử lý |
|---|---|
| 04.architecture/aggregates/ | 02.specification/domain/aggregates/ |
| 04.architecture/read-models/ | 02.specification/domain/read-models/ |
| 04.architecture/integrations/ | 02.specification/domain/integrations/ |
| 04.architecture/foundations/FOUNDATION.template.md | 02.specification/technical-contracts/TECHNICAL-CONTRACT.template.md |
| 04.architecture/foundations/FND-01-Idempotency.sample.md | 02.specification/technical-contracts/FND-01-Idempotency.sample.md; giữ ID FND-01 |
| 04.architecture/nfr/NFR.template.md | 02.specification/technical-contracts/NFR.template.md |
| 05. harness/*-slices/ | 04.harness/BJ-<id>-harness/ flat + role suffix; templates trong `.agents/skills/to-work-slices/` |
| 04.harness/slices/SLICE.template.md | `.agents/skills/to-work-slices/template.work-slice*.md` |
| 04.harness/slices/SL-001-*.sample.md | 04.harness/BJ-xx-harness/SL-001-inventory-operation-boundary.md (`full`) |
| 04.harness/slices/SL-002-*.sample.md | Family `quick-receipt`: SL-002…SL-005 role files |
| 04.harness/manifests/ | **Xóa** — thay bằng `BJ-<id>-harness/CATALOG.md` |
| 06.procedures/ | 05.procedures/ |
| 07.evidence/ | 06.evidence/ |
| 09.generated/ | Giữ nguyên |

ID nguồn nghiệp vụ/Domain/Screen giữ nguyên. Sample harness không áp máy móc cho Theme thật. Có UI → đủ 4 role; không UI → `full`.

Khi migrate Theme thật: xác định cumulative parent, giữ ID, cập nhật link/`CATALOG.md`, kiểm tra orphan. Chuyển cấu trúc không nghĩa đã phê duyệt sample hoặc đã ship.
