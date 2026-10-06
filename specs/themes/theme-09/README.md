# VET45 Theme 09 — Kế toán

**Phiên bản:** `v0.1.0`  
**Baseline ID:** `T09-BASELINE-v0.1.0`  
**Ngày snapshot:** `2026-09-23`  
**Trạng thái:** `IN_REVIEW` — baseline chính thức đầu tiên để review, **chưa FROZEN**  
**Parent:** `NONE` — greenfield baseline

## 1. Mục đích của gói

Đây là baseline canonical đầu tiên của Theme 09 — Kế toán theo cấu trúc Theme mới đang áp dụng cho Theme 6/7. Gói này cố ý đi đủ sâu để Product/BA có thể nhìn thấy bức tranh đích của Theme 09, nhưng mọi quyết định tự đề xuất trong lượt đầu vẫn được đánh dấu `PROPOSED` và có thể thay đổi trước freeze.

Theme 09 được định hình như **lớp chuyển sự thật vận hành thành dữ liệu kế toán, sổ kế toán và dữ liệu tuân thủ có thể truy vết**, không phải nơi sở hữu lại đơn hàng, công nợ, tồn kho, giá vốn hay hóa đơn điện tử.

## 2. Scope của baseline v0.1.0

Bao gồm:
- `01.knowledge/`: Glossary, Decision Register, Know-how.
- `02.specification/overview/`: mục tiêu, phạm vi, actor, ranh giới Theme, Phase.
- `02.specification/domain/domain-foundation/`: domain map, ownership, lifecycle, invariant, time semantics.
- `02.specification/domain/entities/`: entity catalog và contract dữ liệu nghiệp vụ.
- `04.architecture/aggregates/`: aggregate boundary sơ bộ để BA/SA cùng review.

Chưa bao gồm:
- Business Journey, Use Case, Behavioral Contract chi tiết.
- Screen, UI flow, Design System mapping, prototype.
- API/Event schema, integration protocol, read-model chi tiết, NFR kỹ thuật.
- Harness triển khai và release gate đầy đủ.

## 3. Cây thư mục

```text
VET45-Theme09-Ke-toan-v0.1.0/
├── README.md
├── REVIEW-START-HERE.md
├── VERSION.md
├── CHANGELOG.md
├── manifest.json
├── 00.baseline/
│   ├── source-register.md
│   ├── scope-baseline.md
│   ├── assumption-register.md
│   └── open-question-register.md
├── 01.knowledge/
│   ├── glossary/
│   ├── decisions/
│   └── know-how/
├── 02.specification/
│   ├── overview/
│   ├── behavior/                  # chưa triển khai trong baseline này
│   └── domain/
│       ├── domain-foundation/
│       └── entities/
├── 03.design/                     # chưa triển khai
├── 04.architecture/
│   ├── aggregates/
│   ├── read-models/               # chưa triển khai
│   ├── foundations/               # chưa triển khai
│   ├── integrations/              # chưa triển khai
│   └── nfr/                       # chưa triển khai
├── harness/                       # chưa triển khai
├── evidence/
└── generated/
```

## 4. Cách đọc nhanh

1. `REVIEW-START-HERE.md` — bức tranh đích và các điểm nên phản biện trước.
2. `00.baseline/scope-baseline.md` — Theme 09 làm gì/không làm gì.
3. `01.knowledge/decisions/decision-register.md` — các quyết định hiện tại và trạng thái.
4. `02.specification/overview/overview.md` — sản phẩm Theme 09 dưới góc người dùng và hệ thống.
5. `02.specification/domain/domain-foundation/domain-foundation.md` — domain model.
6. `04.architecture/aggregates/aggregate-catalog.md` — ranh giới write-side để BA/SA review.
7. `02.specification/domain/entities/entity-catalog.md` — dữ liệu bền vững và ownership.

## 5. Nguyên tắc baseline

- `CONFIRMED`: đã có căn cứ từ nguồn hoặc quyết định liên Theme hiện hành; vẫn thuộc baseline chưa freeze.
- `PROPOSED`: quyết định được tự đề xuất trong v0.1.0 để tạo bức tranh đích; cần Product/BA review.
- `DEFERRED`: có định hướng nhưng chưa thuộc Phase 1.
- `OUT_OF_SCOPE`: cố ý loại khỏi phạm vi.
- `OPEN`: chưa đủ dữ kiện để chốt.

Không dùng prototype, UI hay implementation để tự tạo nghiệp vụ ngược lên baseline.
