---
id: BC-IV-05
type: behavioral-contract
theme: theme-07
title: "Dựng preview giá trị nhập ban đầu"
owner: BA
status: FROZEN
source_baseline: v4.6.1
---
# BC-IV-05 — Dựng preview giá trị nhập ban đầu

## 1. Ý định

Trả danh sách hàng đang chờ giá trị, các căn cứ có thể sử dụng và cấu thành giá trị dự kiến **trước khi commit**. Query này giúp kế toán hiểu “giá trị này đến từ đâu” nhưng không ghi ledger, không đổi valuation state và không tạo Official Cost.

## 2. Phạm vi áp dụng

- **Loại:** Query / preview.
- **Owner:** `DOM-IV`, đọc fact goods receipt của `DOM-IO` và nguồn thương mại/tax/FX có thẩm quyền.
- **Journey / UC:** `BJ-03` / `UC-03-01`.

## 3. Đầu vào nghiệp vụ

- Worklist filter hoặc mục hàng nhận cần xử lý.
- Căn cứ/source hiện có và version/effectivity của chúng.
- Exact quantity còn `VALUATION_PENDING`.
- Tax treatment/policy version khi cần; nếu nguồn ngoại tệ thì currency + FX authoritative được resolve theo contract hiện hành và giữ trong provenance kỹ thuật.
- Với Quick: direct price basis draft gồm đơn giá, tiền tệ, căn cứ giá cụ thể, ngày/hiệu lực, cách hiểu thuế và bằng chứng/tham chiếu khi có; UI không có field tỷ giá.

## 4. Điều kiện trước

Actor được phép xem dữ liệu tài chính; goods receipt thuộc tenant; quantity còn pending; nguồn ngoài Theme chỉ được đọc theo authority của nguồn.

## 5. Quy tắc nghiệp vụ

1. Nhóm dữ liệu theo **dòng hàng thực nhận và phạm vi của căn cứ**, không theo technical line chỉ vì persistence chia nhỏ.
2. Xác định readiness:
   - `READY` — có bộ căn cứ đầy đủ, current và không có conflict chưa giải quyết;
   - `CONFLICT` — có các căn cứ hợp lệ dẫn tới value khác nhau và owner resolution chưa xong;
   - `WAITING_EVIDENCE` — thiếu fact bắt buộc để tính value.
3. Với nhận theo chứng từ, sử dụng commercial facts mà Theme 10 đã xác lập; nếu Theme 10 đang dispute, trả trạng thái chờ thay vì tự chọn PO/invoice.
4. Với Quick, cho phép dựng preview từ direct basis hợp lệ theo quyền/policy. UI không nhập/chọn tỷ giá và không có taxonomy `Loại nguồn` do Theme 7 tự đặt. Direct basis phải có căn cứ giá cụ thể, ngày/hiệu lực, tiền tệ và lý do khi form được dùng vì chưa có nguồn mua cấu trúc.
5. UI phân biệt **nguồn có thẩm quyền** với **bằng chứng hỗ trợ**: email/file/mã tham chiếu không được dùng thay cho source authority.
6. Áp công thức tổng quát: **giá mua − khoản giảm giá trị mua + thuế/phí không thu hồi + chi phí mua trực tiếp đã biết ± component hợp lệ**.
7. Thuế/phí thu hồi được không đi vào inventory value; tax treatment do policy cung cấp. User chỉ cung cấp fact trên căn cứ (ví dụ giá đã/chưa gồm thuế, số thuế trên nguồn khi cần), không quyết định recoverability. Preview phải áp tax policy để derive phần thuế không thu hồi; không được gán thẳng toàn bộ số thuế user nhập thành `non-recoverable tax` nếu policy không nói vậy.
8. Trả `basis_version/hash`, scope version, calculation hash và breakdown đủ để confirm recheck.

## 6. Điều kiện bắt buộc

- Không tạo “giá gốc” hoặc “chiết khấu” nếu source chỉ cho biết giá mua cuối cùng.
- Không bắt buộc hóa đơn nhà cung cấp để quick receipt đủ điều kiện BJ03.
- Không expose `DirectCostBasis` như thuật ngữ người dùng bắt buộc hiểu.
- Partial scope chỉ xuất hiện khi source/evidence coverage thực sự nhỏ hơn quantity còn pending.

## 7. Ảnh hưởng trạng thái

Read-only. Không tạo movement, Official Cost hoặc mutation nguồn.

## 8. Tính nguyên tử và kết quả cuối

Query có thể refetch an toàn. Query timeout không tạo business `UNKNOWN` vì không có side effect.

## 9. Kết quả và semantics lỗi

`VALUATION_SCOPE_NOT_FOUND`, `PRICE_EVIDENCE_REQUIRED`, `VALUATION_BASIS_CONFLICT`, `FINANCIAL_FIELD_FORBIDDEN`, `NORMALIZED_VALUE_REQUIRED`. `FX_BASIS_REQUIRED` chỉ là compatibility/internal source error và không được biến thành field nhập tỷ giá trên UI Theme 7.

## 10. Domain và UC sử dụng

- **Domain / Entity:** đọc `ENT-IO-01/02`, `ENT-IV-01`, policy/source references.
- **UC:** `UC-03-01`.
- **API trace:** `API-Q-11`.
- **Decision:** `T7-DR-025`, `150…154`, `186…190`, `200…201`.
