---
id: EVD-VALUATION-SEMANTIC-v3.12.0
type: evidence
theme: theme-07
title: "Bằng chứng semantic BJ03 BJ13 BJ14"
owner: QA/HARNESS
status: PASS
version: v3.12.0
parent: v3.11.0
---
# EVD — Semantic BJ03 → BJ13 → BJ14 — v3.12.0

## 1. Chuỗi nghiệp vụ đã khóa

```text
BJ02 — Nhận hàng
  → BJ03 — Xác lập giá trị nhập ban đầu
  → BJ13 — Điều chỉnh giá trị hàng nhập, khi có fact hợp lệ đến sau
  → BJ14 — Tính và công bố giá vốn
```

Ranh giới này được phản ánh đồng thời ở Decision Register, BJ/UC, `DOM-IV`, Entity IV, Behavioral Contract, Integration và Technical Contract.

## 2. Các invariant trọng yếu

| Invariant | Nguồn canonical chính | Kết quả kiểm |
|---|---|---|
| BJ03 chỉ ghi giá trị nhập ban đầu, không tạo `OfficialCostVersion` | `T7-DR-185`, `UC-03-01`, `BC-IV-01`, `DOM-IV` | PASS |
| Nhận theo chứng từ có thể tiêu thụ commercial facts từ Theme 10 | `T7-DR-186`, `UC-03-01`, `INT-01` | PASS |
| Quick receipt hoàn tất BJ03 mà không phụ thuộc Theme 10 | `T7-DR-186/187`, `UC-03-01`, `BC-IV-01/05`, `INT-01` | PASS |
| Theme 7 không sửa PO/hóa đơn hoặc tự giải quyết commercial dispute thuộc Theme 10 | `T7-DR-190`, `UC-03-01`, `INT-01` | PASS |
| Partial valuation chỉ do coverage thật của căn cứ, không do user tùy ý chia lượng | `T7-DR-188`, `UC-03-01`, `BC-IV-01` | PASS |
| Tax treatment đến từ policy; user không chọn khả năng khấu trừ/thu hồi | `T7-DR-189`, `UC-03-01`, `BC-IV-01/05`, `DOM-IV` | PASS |
| Mô hình thuế mở cho công ty; Phase hiện tại hộ kinh doanh dùng phần VAT không thu hồi vào inventory value | `T7-DR-189`, `DOM-IV` | PASS |
| Fact có đủ căn cứ trước initial confirm có thể vào BJ03; fact đến sau đi BJ13 | `T7-DR-191`, `UC-03-01`, `UC-13-01` | PASS |
| Lỗi người dùng nhập sai sau commit đi BJ11/correction, không giả làm late adjustment | `T7-DR-191`, `BC-IV-01/04` | PASS |
| BJ13 xử lý signed adjustment: tăng hoặc giảm | `T7-DR-192`, `UC-13-01`, `BC-IV-04`, `ENT-IV-07/08` | PASS |
| Quyền lợi dự kiến chỉ mô phỏng, không ghi real ledger | `T7-DR-193`, `BC-IV-04` | PASS |
| Costing method là policy cấp tenant, không chọn theo run | `T7-DR-194`, `UC-14-01`, `BC-IV-02/03` | PASS |
| BJ14 là owner duy nhất của Official Cost | `T7-DR-195`, `UC-14-04`, `BC-IV-03`, `DOM-IV` | PASS |

## 3. Desk simulation

### 3.1 Nhận theo chứng từ, nguồn đầy đủ

1. BJ02 tạo quantity thực nhận và `VALUATION_PENDING`.
2. Theme 10 cung cấp commercial facts đã xác lập.
3. BJ03 tính và confirm initial value trên đúng source coverage.
4. Hệ thống ghi value movement + provenance, không tạo Official Cost.
5. Product + posting period được đánh dấu cần cập nhật giá vốn.
6. BJ14 tính theo costing policy của tenant; publication qua `UC-14-04` mới tạo/cập nhật Official Cost.

**Kết quả:** PASS; ownership không chồng lấn.

### 3.2 Quick receipt không có Theme 10

1. BJ02 hoàn tất Quick receipt theo rule hiện hành.
2. Kế toán có quyền lập căn cứ giá trực tiếp trong Theme 7.
3. BJ03 áp tax treatment từ policy và confirm initial value.
4. Không tạo PO/hóa đơn giả; Theme 10 không phải dependency.

**Kết quả:** PASS.

### 3.3 Hóa đơn đến sau Quick receipt

1. Quick receipt đã hoàn tất BJ03.
2. Sau đó Theme 10 tiếp nhận hóa đơn có giá khác và liên kết được với receipt.
3. Không mở lại/overwrite BJ03.
4. Chênh lệch đã xác lập đi BJ13, tạo signed adjustment và dirty scope.
5. BJ14 tính/rà soát/công bố lại đúng phạm vi.

**Kết quả:** PASS.

## 4. Red-team cases

| Case | Hành vi bắt buộc | Kết quả |
|---|---|---|
| PO và hóa đơn đang dispute | BJ03 giữ chờ; Theme 7 không tự chọn một giá | PASS |
| Source revision đổi sau preview | Reject trước mutation, refresh source | PASS |
| Giá đã gồm thuế | Không cộng thuế lần hai | PASS |
| Projected discount từ Theme 10 | Không ghi real value ledger | PASS |
| Adjustment gửi lặp | Stable source identity + idempotency ngăn double-write | PASS |
| User nhập sai fact đã biết | Route BJ11/correction | PASS |
| Run cố đổi costing method | Không có input chọn method; lấy tenant policy | PASS |
| Mutation timeout/finality chưa rõ | Giữ operation identity, route BJ17; không tạo command mới | PASS |

## 5. Giới hạn evidence

`03.design/` đang carry-forward từ v3.11.0 nên các copy/screen cũ như “Giá nhập thực tế”, “Late landed cost” có thể còn xuất hiện trong design registry/prototype. Đây là **known parity debt**, không phải semantic source của v3.12.0. Redesign và HTML parity thuộc v3.13.0.
