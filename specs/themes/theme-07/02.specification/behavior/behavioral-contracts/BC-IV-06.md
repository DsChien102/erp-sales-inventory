---
id: BC-IV-06
type: behavioral-contract
theme: theme-07
title: "Dựng preview điều chỉnh giá trị hàng nhập"
owner: BA
status: FROZEN
source_baseline: v4.6.0
---
# BC-IV-06 — Dựng preview điều chỉnh giá trị hàng nhập

## 1. Ý định

Chuẩn hóa source component, xác định target và dựng allocation preview cho một adjustment dương hoặc âm trước khi ghi value ledger.

## 2. Phạm vi áp dụng

- **Loại:** Query / preview.
- **Owner:** `DOM-IV`.
- **Journey / UC:** `BJ-13` / `UC-13-01`.

## 3. Đầu vào nghiệp vụ

`source_component_key`, source revision/evidence, signed amount, **normalized VND amount**, target-scope contract, allowed allocation method/policy và expected exposure/metric/period versions. Source ngoại tệ có thể giữ currency/FX trong provenance kỹ thuật nhưng UI/preview nghiệp vụ không yêu cầu người dùng xử lý tỷ giá.

## 4. Điều kiện trước

Actor được phép xem dữ liệu tài chính; source current; component chưa được ghi trùng; route là `ADJUSTMENT`; authoritative target scope hợp lệ; target đã initial-valued; posting-period mapping tồn tại.

## 5. Quy tắc nghiệp vụ

1. Nhận signed amount đã chuẩn hóa sang VND từ source adapter có thẩm quyền; nếu chưa có normalized VND thì preview ở trạng thái chờ, không yêu cầu user nhập tỷ giá.
2. Áp tax treatment từ policy; không hỏi user recoverability.
3. Resolve authoritative target scope và materialize immutable `ValuationExposure` snapshots.
4. Nạp metric snapshot theo allocation method/policy. Phương pháp theo giá trị dùng `initial_valuation_value_before_adjustments`; phương pháp theo lượng chỉ hợp lệ khi metric quantity có cùng dimension/metric-unit trên toàn target scope.
5. Với normalized signed amount `A`, metric `m_i` và `M = Σm_i`: khi `M > 0`, tính `raw_i = A × m_i / M`; làm tròn VND theo policy, xử lý theo stable exposure order và dồn residual vào exposure cuối để `Σallocation_i = A`.
6. Nếu `M <= 0` hoặc metric không so sánh được, phương pháp bị chặn; không fallback chia đều.
7. Xác định original/posting period cho từng exposure.
8. Derive dirty `Product + posting period` scopes.
9. Trả metric value/unit/version/hash, tỷ trọng, allocated amount, `value_adjustment_basis_hash` và `allocation_hash` để UI giải thích được preview và commit recheck.

## 6. Điều kiện bắt buộc

- Source amount có thể dương hoặc âm; zero chỉ hợp lệ nếu business fact thực sự bằng 0 và policy cho phép giữ no-op preview.
- Fixed scope không cho user tùy ý bỏ target.
- Không cộng trực tiếp quantity khác UOM/dimension để làm trọng số. Một method chỉ được xuất hiện trên UI khi contract/policy chứng minh metric của toàn scope so sánh được.
- Projected/forecast component phải bị đánh dấu simulation-only và không chuyển sang BC-IV-04.

## 7. Ảnh hưởng trạng thái

Read-only preview. Không tạo entity adjustment, movement hay dirty cause.

## 8. Tính nguyên tử và kết quả cuối

Query timeout chỉ refetch; không tạo business `UNKNOWN`.

## 9. Kết quả và semantics lỗi

Tạm giữ compatibility codes `LATE_COST_*` như BC-IV-04; semantic v3.12.0 là `VALUE_ADJUSTMENT_*` tương ứng khi technical version mới được phát hành.

## 10. Domain và UC sử dụng

- **Domain / Entity:** đọc `ENT-IV-01/02`, `ValuationExposure`, period facts; chưa tạo `ENT-IV-07/08`.
- **UC:** `UC-13-01`.
- **API trace:** `API-Q-12`.
- **Decision:** `T7-DR-157…163`, `191…193`, `196`, `198`.
