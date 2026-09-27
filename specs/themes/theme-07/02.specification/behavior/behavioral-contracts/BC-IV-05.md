---
id: BC-IV-05
type: behavioral-contract
theme: theme-07
title: "Dựng preview giá trị nhập ban đầu"
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# BC-IV-05 — Dựng preview giá trị nhập ban đầu

## 1. Ý định

Trả danh sách hàng đang chờ giá trị, các căn cứ có thể sử dụng và cấu thành giá trị dự kiến **trước khi commit**. Query này giúp kế toán hiểu “giá trị này đến từ đâu” nhưng không ghi ledger, không đổi valuation state và không tạo Official Cost.

## 2. Phạm vi áp dụng

- **Loại:** Query / preview.
- **Owner:** `DOM-IV`, đọc receipt facts của `DOM-IO` và nguồn thương mại/tax/FX có thẩm quyền.
- **Journey / UC:** `BJ-03` / `UC-03-01`.

## 3. Đầu vào nghiệp vụ

- Worklist filter hoặc receipt item cần xử lý.
- Căn cứ/source hiện có và version/effectivity của chúng.
- Exact quantity còn `VALUATION_PENDING`.
- Tax/FX/allocation policy version khi cần.
- Với Quick: direct price basis draft nếu kế toán đang bổ sung căn cứ.

## 4. Điều kiện trước

Actor được phép xem dữ liệu tài chính; receipt thuộc tenant; quantity còn pending; nguồn ngoài Theme chỉ được đọc theo authority của nguồn.

## 5. Quy tắc nghiệp vụ

1. Nhóm dữ liệu theo **dòng hàng thực nhận và phạm vi của căn cứ**, không theo technical line chỉ vì persistence chia nhỏ.
2. Xác định readiness:
   - `READY` — có bộ căn cứ đầy đủ, current và không có conflict chưa giải quyết;
   - `CONFLICT` — có các căn cứ hợp lệ dẫn tới value khác nhau và owner resolution chưa xong;
   - `WAITING_EVIDENCE` — thiếu fact bắt buộc để tính value.
3. Với nhận theo chứng từ, sử dụng commercial facts mà Theme 10 đã xác lập; nếu Theme 10 đang dispute, trả trạng thái chờ thay vì tự chọn PO/invoice.
4. Với Quick, cho phép dựng preview từ direct basis hợp lệ theo quyền/policy.
5. Áp công thức tổng quát: **giá mua − khoản giảm giá trị mua + thuế/phí không thu hồi + chi phí mua trực tiếp đã biết ± component hợp lệ**.
6. Thuế/phí thu hồi được không đi vào inventory value; tax treatment do policy cung cấp.
7. Trả `basis_version/hash`, scope version, calculation hash và breakdown đủ để confirm recheck.

## 6. Điều kiện bắt buộc

- Không tạo “giá gốc” hoặc “chiết khấu” nếu source chỉ cho biết giá mua cuối cùng.
- Không bắt buộc hóa đơn nhà cung cấp để Quick receipt đủ điều kiện BJ03.
- Không expose `DirectCostBasis` như thuật ngữ người dùng bắt buộc hiểu.
- Partial scope chỉ xuất hiện khi source/evidence coverage thực sự nhỏ hơn quantity còn pending.

## 7. Ảnh hưởng trạng thái

Read-only. Không tạo movement, CommandReceipt, Official Cost hoặc mutation nguồn.

## 8. Tính nguyên tử và kết quả cuối

Query có thể refetch an toàn. Query timeout không tạo business `UNKNOWN` vì không có side effect.

## 9. Kết quả và semantics lỗi

`VALUATION_SCOPE_NOT_FOUND`, `PRICE_EVIDENCE_REQUIRED`, `VALUATION_BASIS_CONFLICT`, `FINANCIAL_FIELD_FORBIDDEN`, `FX_BASIS_REQUIRED`.

## 10. Domain và UC sử dụng

- **Domain / Entity:** đọc `ENT-IO-01/02`, `ENT-IV-01`, policy/source references.
- **UC:** `UC-03-01`.
- **API trace:** `API-Q-11`.
- **Decision:** `T7-DR-025`, `150…154`, `186…190`.
