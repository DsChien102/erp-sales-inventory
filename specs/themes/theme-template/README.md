# Theme template — Hướng dẫn sử dụng

Bộ template theo cấu trúc đã chốt: Domain là vùng chung BA/SA; kiến trúc dùng chung nằm trong Domain hoặc Technical Contract; thiết kế cục bộ nằm trong Slice.

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
        slices/
        manifests/
    05.procedures/
    06.evidence/
    09.generated/
```

Khi tạo Theme, dùng [README.template.md](README.template.md) và [VERSION.template.md](VERSION.template.md) để tạo README.md/VERSION.md. Các file *.sample.md và manifest sample chỉ minh họa; không sao chép chúng thành yêu cầu chính thức. Các thư mục con Evidence/Generated có thể thêm khi có đầu ra thực tế.

## Nơi sở hữu nội dung

- **Knowledge:** tri thức, quyết định và thuật ngữ.
- **Behavior:** BJ, UC và BC; luồng giao diện cấp hành trình tiếp tục nằm trong BJ. Giữ quy ước BJ/UC V5.
- **Domain:** Foundation mô tả trách nhiệm/bất biến; Entity mô tả đối tượng; Aggregate sở hữu ranh giới nhất quán; Read Model sở hữu mô hình đọc; Integration sở hữu nghĩa và ranh giới trao đổi giữa các Domain/Theme.
- **Technical Contract:** quy tắc kỹ thuật dùng chung nhiều Slice hoặc toàn Theme. NFR đo được dùng mẫu NFR trong cùng thư mục. Không tạo tài liệu chỉ để lấp đủ chủ đề.
- **Design:** Screen, Pattern, Design System và prototype. Prototype không quyết định quy tắc nghiệp vụ; HTML chạy được đặt trong 03.design/prototype/html/ khi Theme có runtime.
- **Slice:** một đơn vị thay đổi, có thể bao gồm Domain, Application, backend, frontend và kiểm chứng. Phân theo kết quả/phạm vi, không theo vai trò. Dẫn nguồn; không sao chép toàn bộ UC/Domain vào Slice.
- **Procedures/Evidence/Generated:** quy trình vận hành, bằng chứng và dữ liệu sinh tự động. Generated không chứa nguồn biên tập tay.

Xem [Doctrine và Directory Contract](../README.md) để đối chiếu trách nhiệm từng vùng.

## Điểm bắt đầu

- [BJ template](02.specification/behavior/journeys/BJ.template.md) và [UC template](02.specification/behavior/use-cases/UC.template.md).
- [Aggregate](02.specification/domain/aggregates/AGGREGATE.template.md), [Read Model](02.specification/domain/read-models/READ-MODEL.template.md), [Integration](02.specification/domain/integrations/INTEGRATION.template.md).
- [Technical Contract](02.specification/technical-contracts/TECHNICAL-CONTRACT.template.md) và [NFR](02.specification/technical-contracts/NFR.template.md).
- [Slice chung](04.harness/slices/SLICE.template.md), [sample Aggregate](04.harness/slices/SL-001-InventoryOperation.sample.md), [sample nhận hàng nhanh](04.harness/slices/SL-002-QuickReceipt.sample.md).
- [Manifest template](04.harness/manifests/theme.manifest.template.yml) và [manifest sample](04.harness/manifests/theme.manifest.sample.yml).

Manifest dùng path tính từ root Theme. sources dẫn artifact ID; depends_on dẫn Slice ID; coverage ghi cả UC ID và các mã Flow/Scenario nội bộ. Coverage là phạm vi dự kiến, không phải bằng chứng hoàn thành.

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
| 05. harness/sa-slices/SA-SLICE.template.md | 04.harness/slices/SLICE.template.md; mẫu chung 7 phần |
| 05. harness/be-slices/BE-SLICE.template.md | Thay bằng cùng SLICE.template.md |
| 05. harness/fe-slices/FE-SLICE.template.md | Thay bằng cùng SLICE.template.md |
| 05. harness/sa-slices/SA-IO-01-InventoryOperation.sample.md | 04.harness/slices/SL-001-InventoryOperation.sample.md |
| 05. harness/be-slices/BE-02-02-QuickReceipt.sample.md | 04.harness/slices/SL-002-QuickReceipt.sample.md |
| 05. harness/fe-slices/FE-SCR-009-QuickReceipt.sample.md | Tích hợp phạm vi giao diện vào SL-002-QuickReceipt.sample.md |
| 05. harness/manifests/ | 04.harness/manifests/; schema_version 2 |
| 06.procedures/ | 05.procedures/ |
| 07.evidence/ | 06.evidence/ |
| 09.generated/ | Giữ nguyên |

ID các nguồn nghiệp vụ/Domain/Screen được giữ nguyên. Đổi ID Slice sample được ghi ở migration_aliases của manifest; không áp dụng máy móc cho Slice của Theme thật. SL-001 vẫn riêng vì cung cấp mô hình dùng chung; SL-002 gom phần lập/gửi hồ sơ và giao diện của cùng mục tiêu.

Khi migrate Theme thật: xác định cumulative parent được chấp nhận, phân loại từng Foundation/NFR theo phạm vi dùng chung hay cục bộ, giữ ID, cập nhật link và kiểm tra orphan. Không mặc định phiên bản cũ là baseline mới nhất. Chuyển cấu trúc không có nghĩa đã phê duyệt các sample hoặc đã triển khai sản phẩm.
