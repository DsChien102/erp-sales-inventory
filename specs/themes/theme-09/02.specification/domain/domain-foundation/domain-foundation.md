# Domain Foundation — Theme 09 Kế toán

## 1. Domain map

| Domain ID | Tên Việt | Trách nhiệm |
|---|---|---|
| D09-01 | Hồ sơ & chế độ kế toán | Xác định đơn vị đang áp dụng chế độ nào, hiệu lực từ khi nào, policy set nào |
| D09-02 | Tiếp nhận & ghi sổ | Nhận sự thật nguồn, kiểm tra điều kiện, áp policy, tạo kết quả ghi sổ |
| D09-03 | Kỳ kế toán | Mở/khóa/mở lại kỳ, kiểm soát ngày ghi sổ |
| D09-04 | Sổ kế toán | Bản ghi kế toán, dòng ghi sổ, projection theo sổ/chế độ |
| D09-05 | Thuế | Hồ sơ thuế, kỳ thuế, phép tính, snapshot hồ sơ khai |
| D09-06 | Đối chiếu & điều chỉnh | Xử lý mismatch, late event, correction, reversal, manual adjustment |

## 2. Core model

```text
Source Business Fact
      │
      ▼
Accounting Case ── captures immutable fact snapshot/reference
      │
      ├─ validate source finality / period / policy
      ▼
Accounting Policy Version
      │
      ▼
Accounting Entry (posted representation)
      │
      ├─ Ledger / Book projections
      └─ Tax projections
```

Điểm khóa: `Accounting Fact` và `Accounting Entry` không phải một khái niệm.

- **Sự thật kế toán**: điều đã xảy ra ở Theme nguồn và có ý nghĩa kế toán.
- **Bút toán/bản ghi kế toán**: cách Theme 09 biểu diễn sự thật đó dưới policy/chế độ hiệu lực.

## 3. Ownership and anti-corruption boundary

Theme 09 lưu `SourceReference` và snapshot tối thiểu đủ để audit. Không rehydrate toàn bộ aggregate của Theme nguồn thành entity nội bộ.

Khi semantic upstream khác nhau, adapter chuyển về `AccountingFact` canonical. Adapter không được tự thay business meaning.

## 4. Accounting time

Mỗi nghiệp vụ cần phân biệt tối thiểu:
- `source_effective_at`: thời điểm nghiệp vụ có hiệu lực ở domain nguồn.
- `accounting_date`: ngày được ghi nhận vào kỳ kế toán.
- `recorded_at`: thời điểm Theme 09 ghi record.
- `policy_effective_date`: mốc chọn policy version.

Không dùng `created_at` thay cho ngày nghiệp vụ hoặc ngày kế toán.

## 5. Lifecycle

### 5.1 Accounting Case

```text
RECEIVED
  → VALIDATING
      → READY
          → POSTED
      → REJECTED
      → PERIOD_LOCKED
      → RECONCILIATION_NEEDED
```

- `POSTED`: đã tạo kết quả kế toán authoritative trong Theme 09.
- `REJECTED`: nguồn/policy không hợp lệ về nghiệp vụ; retry kỹ thuật không được vượt rejection.
- `PERIOD_LOCKED`: nghiệp vụ hợp lệ nhưng accounting date rơi vào kỳ không được ghi.
- `RECONCILIATION_NEEDED`: không thể kết luận an toàn do mismatch/unknown source lineage.

### 5.2 Accounting Period

```text
OPEN → LOCKED
LOCKED --privileged reopen--> OPEN
```

Mỗi lần reopen tạo audit event và tăng `reopen_count`; không xóa lịch sử lock trước đó.

### 5.3 Accounting Entry

```text
POSTED → REVERSED (bằng entry mới)
```

Không có transition `POSTED → EDITED`.

## 6. Consistency boundaries

- Source transaction commit thuộc Theme nguồn; accounting posting không rollback giao dịch nguồn đã final.
- Ghi `AccountingEntry` và cập nhật trạng thái `AccountingCase=POSTED` phải cùng consistency boundary của Theme 09.
- Period state được kiểm tra tại thời điểm commit posting, không chỉ lúc preview.
- Rule/policy version dùng để post được lưu cố định trên entry.
- Reversal và replacement phải liên kết entry gốc và reason.

## 7. Accounting scheme abstraction

Theme 09 không mặc định mọi chế độ đều dùng hệ thống tài khoản.

`AccountingSchemeVersion` xác định:
- loại sổ áp dụng;
- rule validation;
- dimension bắt buộc;
- có/không dùng account code;
- có/không yêu cầu cân bằng Nợ/Có;
- mapping sang tax categories nếu áp dụng.

Với HKD theo TT152, UI và storage có thể ưu tiên book/category semantics. Với chế độ doanh nghiệp có hệ thống tài khoản, cùng canonical fact có thể được chuyển sang entry lines có account/side.

## 8. Late and corrected source data

- Source correction không sửa entry cũ.
- Nếu correction còn trong kỳ mở: sinh adjustment/reversal theo policy.
- Nếu correction liên quan kỳ khóa: tạo `PERIOD_LOCKED` hoặc `RECONCILIATION_NEEDED`; policy Phase 1 đề xuất post vào kỳ mở gần nhất và giữ original effective date, trừ khi người có quyền mở lại kỳ.
- Event đến muộn phải phân biệt “ngày nghiệp vụ gốc” với “kỳ thực tế ghi sổ”.

## 9. Tax boundary inside Theme 09

Tax Compliance sử dụng accounting/source facts nhưng không đồng nhất thuế với sổ kế toán.

- Một khoản có thể có cách xử lý thuế khác cách trình bày kế toán.
- Mỗi calculation giữ `tax_policy_version` và source set.
- Hồ sơ khai đã snapshot không tự thay đổi khi master data hiện hành đổi.
- Submission tới cơ quan thuế là capability riêng, deferred ở Phase 1.

## 10. Legal regime notes

TT152/2025 có hiệu lực từ 01/01/2026 và hướng dẫn kế toán cho hộ/cá nhân kinh doanh. Các mẫu sổ S1a-HKD, S2a-HKD, S2b-HKD, S2c-HKD, S2d-HKD, S2e-HKD, S3a-HKD áp dụng theo nhóm/nghĩa vụ tương ứng; không phải một checklist bắt buộc đồng thời cho mọi đơn vị.

TT58/2026 là input cho hướng mở rộng doanh nghiệp siêu nhỏ; baseline này không trộn rule TT58 vào Phase 1.
