---
id: THEME-06
type: theme-readme
theme: theme-06
title: Công nợ — Bộ tài liệu nghiệp vụ
owner: BA
status: IN_REVIEW
---

# Công nợ — Bộ tài liệu nghiệp vụ

> **Phiên bản hiện hành:** 2.1.1

## 1. Mục đích

Giải thích và đặc tả cách VET45 theo dõi nghĩa vụ phải thu/phải trả, thu/chi, phân bổ thanh toán, cấn trừ, đối chiếu công nợ, số dư đầu kỳ và chính sách phê duyệt. Mỗi loại nội dung có một nguồn chịu trách nhiệm chính; tài liệu downstream dẫn chiếu thay vì sao chép quyết định.

## 2. Phạm vi

### 2.1 Trong phạm vi

- Bộ tri thức nghiệp vụ hiện hành: Sổ quyết định, bảng thuật ngữ và chín bài know-how.
- Tổng quan và sáu Business Journey đã được duyệt về mục tiêu/rạch ranh giới.
- **Domain Foundation của Công nợ** với một Domain duy nhất và capability map bên trong.
- **Entity Catalog** và mười entity/child entity nghiệp vụ phục vụ BA/SA alignment.
- **Aggregate Candidate Catalog** và bảy aggregate candidate trong lớp Architecture.
- Các điểm neo Trường hợp sử dụng dùng làm đầu vào cho bước đặc tả tiếp theo.

Xem [Tổng quan và bản đồ hành trình](02.specification/overview/overview.md#ban-do-hanh-trinh), [Domain Công nợ](02.specification/domain/domain-foundation/DOM-ARAP-cong-no.md) và [Aggregate Candidate Catalog](04.architecture/aggregates/AGGREGATE-CATALOG.md).

### 2.2 Ngoài phạm vi

Gói hiện hành chưa có tài liệu Trường hợp sử dụng hoàn chỉnh, Behavioral Contract, Screen Contract, prototype, integration contract canonical, read-model contract chi tiết hoặc delivery slice. Aggregate trong gói là **candidate để review BA/SA**, chưa phải Architecture Freeze. Những capability giai đoạn sau được khóa tại [Sổ quyết định](01.knowledge/decisions/decision-register.md).

## 3. Cấu trúc chính

```text
specs/themes/theme-06/
├── README.md
├── 01.knowledge/
│   ├── decisions/
│   ├── glossary/
│   └── know-how/
├── 02.specification/
│   ├── overview/
│   ├── domain/
│   │   ├── domain-foundation/
│   │   └── entities/
│   └── behavior/journeys/
├── 04.architecture/
│   └── aggregates/
└── 07.evidence/specification/
```

Mọi liên kết nội bộ là đường dẫn tương đối từ tệp đang đọc, không gắn cứng URL GitLab hoặc tên nhánh.

## 4. Điểm bắt đầu theo vai trò

- **BA mới:** đọc [KB-001](01.knowledge/know-how/KB-001-cong-no-can-ban.md), [Sổ quyết định](01.knowledge/decisions/decision-register.md), [Overview](02.specification/overview/overview.md), rồi [Domain Công nợ](02.specification/domain/domain-foundation/DOM-ARAP-cong-no.md).
- **Người duyệt nghiệp vụ:** đọc sáu BJ từ [Business Journey map](02.specification/overview/overview.md#ban-do-hanh-trinh) và entity catalog để kiểm tra semantic ownership.
- **SA:** bắt đầu từ [Domain Công nợ](02.specification/domain/domain-foundation/DOM-ARAP-cong-no.md), [Entity Catalog](02.specification/domain/entities/ENTITY-CATALOG.md) và [Aggregate Candidate Catalog](04.architecture/aggregates/AGGREGATE-CATALOG.md); không coi aggregate candidate là persistence schema đã khóa.
- **SE/QA:** dùng BJ map + Domain/Entity/Aggregate candidate để hiểu phạm vi; chờ Trường hợp sử dụng/BC trước khi coi là contract triển khai.

## 5. Tài liệu chính

- [Tổng quan và bản đồ sáu hành trình](02.specification/overview/overview.md).
- [Domain Foundation — Công nợ](02.specification/domain/domain-foundation/DOM-ARAP-cong-no.md).
- [Entity Catalog — Công nợ](02.specification/domain/entities/ENTITY-CATALOG.md).
- [Aggregate Candidate Catalog — Công nợ](04.architecture/aggregates/AGGREGATE-CATALOG.md).
- [Sổ quyết định nghiệp vụ công nợ](01.knowledge/decisions/decision-register.md).
- [Bảng thuật ngữ công nợ](01.knowledge/glossary/glossary.md).
- [Bài nhập môn và tuyến đọc know-how](01.knowledge/know-how/KB-001-cong-no-can-ban.md).
- [Know-how đối chiếu công nợ](01.knowledge/know-how/KB-009-doi-chieu-cong-no.md).
- [Báo cáo kiểm tra v2.1.1](07.evidence/specification/EVD-001-kiem-tra-tai-lieu.md).

## 6. Trạng thái hiện tại

Sổ quyết định và bảng thuật ngữ ở trạng thái `FROZEN`. Quyết định [T06-DR-040](01.knowledge/decisions/decision-register.md#t06-dr-040) khóa cách nhìn **một Domain Công nợ**, còn các capability không bị nâng thành Domain con.

Chín bài know-how và sáu BJ vẫn `IN_REVIEW` theo chất lượng diễn giải/độ sâu acceptance. Domain Foundation và Entity Catalog đủ để dùng cho vòng BA/SA tiếp theo nhưng vẫn `IN_REVIEW` vì lifecycle/command chi tiết sẽ được kiểm chứng khi đặc tả Trường hợp sử dụng.

Bảy Aggregate là **candidate** ở `IN_REVIEW`. Hai vùng cần review kiến trúc sâu nhất là `DebtObligation` và `Payment + Allocation`, vì phân bổ/cấn trừ tạo invariant và concurrency xuyên aggregate.

Phiên bản **2.1.1** là snapshot hiện hành dùng để tiếp tục.
