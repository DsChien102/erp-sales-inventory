# TH-08 — APPENDICES

Index nhanh từ canonical [Theme-8-e-invoice.md](Theme-8-e-invoice.md). Chi tiết UI/ERD nằm ở SSOT — không nhân bản full ch.4 / ch.6.

## A. Customer journeys (CJ)

Canonical §2.3.

| ID | Tên | Epic chính |
| -- | --- | ---------- |
| CJ-01 | Thiết lập và duy trì khả năng phát hành hóa đơn điện tử | EP-01 |
| CJ-02 | Kiểm tra điều kiện và xem trước hóa đơn từ đơn hàng | EP-02 |
| CJ-03 | Phát hành thủ công hóa đơn từ đơn hàng Hoàn tất | EP-02 |
| CJ-04 | Tự động phát hành hóa đơn khi đơn hàng đủ điều kiện | EP-02 |
| CJ-05 | Kiểm tra và xác lập kết quả phát hành bất thường | EP-02 |
| CJ-06 | Xem hồ sơ và tài liệu hóa đơn đã phát hành | EP-03 |
| CJ-07 | Gửi, gửi lại và theo dõi kết quả gửi hóa đơn qua email | EP-04 |

## B. User flows (UF)

Canonical §6.3.

| UF | CJ | Tên | Entry → SG |
| -- | -- | --- | ---------- |
| UF-01 | CJ-01 | Thiết lập khả năng phát hành | → SG-01 |
| UF-02 | CJ-02 | Kiểm tra và xem trước | Theme 05 source → SG-02 → viewer |
| UF-03 | CJ-03 | Phát hành thủ công | Theme 05 → SG-02 → SG-03 |
| UF-04 | CJ-04 | Theo dõi phát hành tự động | Theme 05 → SG-03 contextual |
| UF-05 | CJ-05 | Chờ hệ thống xác lập kết quả | Theme 05 ↔ server-side (không UI recovery) |
| UF-06 | CJ-06 | Xem hóa đơn hoặc lấy tài liệu | post-issued Sheet → viewer / SG-06 |
| UF-07 | CJ-07 | Gửi, gửi lại hoặc xem lịch sử | post-issued Sheet → SG-07 |

## C. Screen groups (SG)

Canonical §6.5.

| SG | Tên | Epic | UI MVP |
| -- | --- | ---- | ------ |
| SG-01 | Thiết lập và mức sẵn sàng HĐĐT | EP-01 | Có |
| SG-02 | HĐĐT trên đơn hàng và xem trước | EP-02, EP-03 | Có |
| SG-03 | Xác nhận và theo dõi phát hành | EP-02 | Có |
| SG-04 | Reconciliation | EP-02 | **Loại khỏi UI MVP** (server-side) |
| SG-05 | Hồ sơ HĐ độc lập | EP-03 | **Loại khỏi UI MVP** |
| SG-06 | Tài liệu hóa đơn (XML/PDF) | EP-03 | Có (Action Sheet) |
| SG-07 | Gửi và gửi lại hóa đơn | EP-04 | Có |

## D. Data / ERD

Canonical §4:

- §4.1 Relationship model
- §4.2 ERDs
- §4.3 Entity catalog
- §4.4 Entity fields

Domain harness tóm tắt: [harness/01-domain-model.md](harness/01-domain-model.md).

## E. Domain foundation

Canonical §3 — domains: Invoice Configuration · Invoice Issuance · Electronic Invoice · Invoice Delivery (+ cross-cutting: Provider Integration, Duplicate Prevention, Result Reconciliation, …).

## F. Anomalies khi đọc SRS

Ghi trong [harness/06-harness-notes.md](harness/06-harness-notes.md) (heading 2.2.1 lệch số, duplicate 5.4.2, SC vs SCN, SG-04/05 no UI).
