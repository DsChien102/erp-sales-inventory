# Theme 09 — Overview

## 1. Purpose

Theme 09 giúp đơn vị kinh doanh **ghi nhận đúng, giải thích được và kiểm soát được dữ liệu kế toán hình thành từ hoạt động vận hành trên VET45**, đồng thời tạo nền dữ liệu nhất quán cho sổ kế toán và nghĩa vụ kê khai.

Từ góc nhìn người dùng, mục tiêu không phải “bắt người bán hàng học phần mềm kế toán”, mà là:
- giao dịch đã phát sinh thì biết đã được ghi nhận kế toán chưa;
- số trên sổ truy ngược được về giao dịch/bằng chứng nào;
- kỳ đã khóa không bị lịch sử thay đổi âm thầm;
- điều chỉnh sai sót có dấu vết;
- sổ và dữ liệu khai thuế được hình thành từ cùng một nguồn kiểm soát.

## 2. Product principles

1. **Nguồn nghiệp vụ ở đâu, ownership ở đó.** Theme 09 không tạo bản sao authoritative của đơn hàng, công nợ, tồn kho, giá vốn hay hóa đơn.
2. **Ghi sổ là phép diễn giải có phiên bản.** Một sự thật nguồn được áp chính sách kế toán hiệu lực để tạo bản ghi kế toán.
3. **Đã ghi thì không sửa lịch sử.** Điều chỉnh bằng bản ghi mới có liên kết với bản gốc.
4. **Kỳ kế toán là boundary thật.** Không lén back-date vào kỳ đã khóa.
5. **Chế độ kế toán là cấu hình hiệu lực theo thời gian.** Không hard-code một schema cho mọi loại hình kinh doanh.
6. **Tuân thủ không được tách rời traceability.** Số trên sổ/tờ khai phải truy được nguồn và policy version.

## 3. Users

| Actor | Nhu cầu chính |
|---|---|
| Chủ hộ/chủ cửa hàng | Biết hoạt động đã được ghi sổ đầy đủ; xem sổ/tình hình thuế ở mức dễ hiểu |
| Kế toán | Kiểm tra ca chưa ghi, điều chỉnh, khóa kỳ, xuất sổ, chuẩn bị hồ sơ thuế |
| Người được giao nghiệp vụ tài chính | Xử lý một số công việc theo permission, không mặc nhiên có quyền kế toán toàn phần |
| Auditor/Viewer | Xem lịch sử, nguồn và thay đổi trong phạm vi được cấp |
| System process | Tiếp nhận sự kiện nguồn, áp rule, ghi sổ, cập nhật projection, tạo work item đối chiếu |

Role trong tài liệu là persona; quyền thực tế do Theme 1 cung cấp.

## 4. End-state capability map

```text
Nguồn nghiệp vụ
  ├─ Bán hàng
  ├─ Công nợ / Thu chi
  ├─ Kho & giá vốn
  ├─ Hóa đơn điện tử
  └─ Mua hàng
       ↓
[Tiếp nhận sự thật kế toán]
       ↓
[Chính sách / chế độ kế toán hiệu lực]
       ↓
[Ghi sổ kế toán]
  ├─ Kỳ kế toán
  ├─ Sổ kế toán
  ├─ Điều chỉnh / đối chiếu
  └─ Read model kế toán
       ↓
[Tuân thủ thuế]
  ├─ Kỳ thuế
  ├─ Tính toán
  ├─ Hồ sơ khai
  └─ Submission (tương lai)
```

## 5. Phase model

### Phase 1 — Đề xuất
- HKD/CKD thương mại theo TT152/2025.
- VND.
- Ghi sổ tự động từ các Theme nguồn có contract đủ.
- Worklist chưa ghi/cần xử lý.
- Kỳ kế toán Mở/Đã khóa; mở lại có audit đặc quyền.
- Sổ kế toán áp dụng theo profile.
- Điều chỉnh thủ công có lý do và evidence.
- Tax profile/kỳ thuế; phép tính/snapshot hồ sơ khai theo phạm vi được chốt.
- Chưa nộp điện tử ra cơ quan thuế.

### Evolution
- Doanh nghiệp siêu nhỏ theo TT58/2026.
- Chế độ có hệ thống tài khoản và Nợ/Có đầy đủ.
- Multi-currency.
- Submission/acknowledgement thuế điện tử.
- Advanced close/approval, financial statements mở rộng.

## 6. Cross-theme boundary

| Theme | Source of truth | Theme 09 nhận | Theme 09 trả |
|---|---|---|---|
| T01 Tổ chức & người dùng | Tenant, legal profile, permission | tenant/actor/legal context | trạng thái kế toán/tax theo permission |
| T03 Đối tác | Partner identity/profile | partner reference | không cập nhật ngược master |
| T05 Bán hàng | Sales transaction | giao dịch hoàn tất/điều chỉnh | posting status/reference |
| T06 Công nợ | receivable/payable, collection/payment allocation | nghĩa vụ/thu chi đã xác lập | `POSTED/REJECTED/PERIOD_LOCKED/RECONCILIATION_NEEDED` |
| T07 Kho & giá vốn | movement, valuation, official cost | giá vốn/điều chỉnh authoritative | posting status/reference |
| T08 Hóa đơn điện tử | issued invoice + audit trail | hóa đơn đã phát hành/evidence | accounting/tax consumption status khi cần |
| T10 Mua hàng | purchase/discount entitlement | nghĩa vụ/điều chỉnh thương mại đủ điều kiện | posting status/reference |

## 7. Product invariants

- Một sự thật nguồn không được ghi official ledger hai lần cho cùng purpose/policy version.
- Forecast/estimate không đi vào official ledger nếu owner chưa xác lập quyền/nghĩa vụ.
- Theme 09 không mutate authoritative balance của Theme 6 hoặc official cost/tồn kho của Theme 7.
- Entry đã post không update amount/source; sửa bằng reversal/adjustment.
- Locked period không nhận back-post im lặng.
- Mọi entry truy được source, policy version, accounting date, recorded time và actor/system origin.
- Tax result truy được calculation snapshot và source set.

## 8. MVP success đề xuất

Baseline chỉ định nghĩa semantic; metric cụ thể cần Product chốt. Các success signal đề xuất:
- tỷ lệ giao dịch đủ điều kiện được ghi sổ tự động;
- số ca bị treo vì thiếu mapping/rule/source conflict;
- thời gian từ source finality đến accounting posting;
- số lần mở lại kỳ;
- tỷ lệ dòng sổ truy được source 100%;
- tỷ lệ hồ sơ thuế có đủ trace đến dữ liệu nguồn.
