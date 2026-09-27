---
id: BC-IV-06
type: behavioral-contract
theme: theme-07
title: "Dựng preview điều chỉnh giá trị hàng nhập"
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# BC-IV-06 — Dựng preview điều chỉnh giá trị hàng nhập

## 1. Ý định

Chuẩn hóa source component, xác định target và dựng allocation preview cho một adjustment dương hoặc âm trước khi ghi value ledger.

## 2. Phạm vi áp dụng

- **Loại:** Query / preview.
- **Owner:** `DOM-IV`.
- **Journey / UC:** `BJ-13` / `UC-13-01`.

## 3. Đầu vào nghiệp vụ

`source_component_key`, source revision/evidence, signed amount, currency/tax/FX facts, target-scope contract, allowed allocation method/policy và expected exposure/metric/period versions.

## 4. Điều kiện trước

Actor được phép xem dữ liệu tài chính; source current; component chưa được ghi trùng; route là `ADJUSTMENT`; authoritative target scope hợp lệ; target đã initial-valued; posting-period mapping tồn tại.

## 5. Quy tắc nghiệp vụ

1. Chuẩn hóa signed amount sang VND theo nguồn FX có thẩm quyền.
2. Áp tax treatment từ policy; không hỏi user recoverability.
3. Resolve authoritative target scope và materialize immutable `ValuationExposure` snapshots.
4. Nạp metric snapshot theo allocation method/policy.
5. Xác định original/posting period cho từng exposure.
6. Phân bổ deterministic theo stable exposure order và reconciliation rounding.
7. Derive dirty `Product + posting period` scopes.
8. Trả `value_adjustment_basis_hash` + `allocation_hash` để commit recheck.

## 6. Điều kiện bắt buộc

- Source amount có thể dương hoặc âm; zero chỉ hợp lệ nếu business fact thực sự bằng 0 và policy cho phép giữ no-op preview.
- Fixed scope không cho user tùy ý bỏ target.
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
- **Decision:** `T7-DR-157…163`, `191…193`.
