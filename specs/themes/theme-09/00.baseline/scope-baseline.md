# Scope Baseline — Theme 09

## 1. Product boundary

Theme 09 sở hữu **biểu diễn kế toán và tuân thủ kế toán/thuế phát sinh từ sự thật nghiệp vụ**, gồm trạng thái ghi sổ, kỳ kế toán, sổ kế toán, điều chỉnh kế toán, đối chiếu kế toán và dữ liệu kê khai thuộc phạm vi được Product chốt.

Theme 09 không sở hữu giao dịch nguồn.

## 2. End-state capabilities

| Capability | End-state | Phase 1 đề xuất |
|---|---|---|
| Hồ sơ & chế độ kế toán | In | In — TT152 trước |
| Tiếp nhận sự thật kế toán | In | In |
| Tự động xác định cách ghi sổ | In | In |
| Bút toán/bản ghi kế toán | In | In |
| Kỳ kế toán, khóa/mở lại | In | In |
| Sổ kế toán theo chế độ | In | In |
| Điều chỉnh/đảo bút toán | In | In có kiểm soát |
| Đối chiếu nguồn ↔ sổ | In | In cơ bản |
| Hồ sơ thuế, kỳ thuế | In | In |
| Tính số liệu khai thuế | In | In theo phạm vi HKD được chốt |
| Sinh hồ sơ/tờ khai | In | In nhưng form catalog phải version hóa |
| Nộp điện tử/nhận kết quả từ cơ quan thuế | In về dài hạn | Deferred |
| Chế độ DN siêu nhỏ | In về dài hạn | Deferred |
| Multi-currency | In về dài hạn | Deferred |
| Hợp nhất nhiều pháp nhân | Out hiện tại | Out |
| Payroll accounting | Out trừ khi có Theme nguồn | Out |
| Fixed asset subledger | Out cho baseline này | Out |
| Bank feed/reconciliation | Out cho baseline này | Out |

## 3. Cross-theme ownership

| Sự thật | Owner | Theme 09 được làm | Theme 09 không được làm |
|---|---|---|---|
| Đơn hàng/doanh thu nguồn | Theme 5 | Nhận sự thật đủ điều kiện, ghi sổ, lưu reference/snapshot cần thiết | Sửa đơn, giá, giảm giá, trạng thái đơn |
| Phải thu/phải trả, thu/chi, phân bổ | Theme 6 | Ghi tác động kế toán và đối chiếu | Tăng/giảm số dư công nợ trực tiếp |
| Tồn kho, LOT, valuation, official cost/COGS | Theme 7 | Ghi tác động kế toán/chi phí theo output authoritative | Tính lại hay sửa official cost/tồn kho |
| Hóa đơn điện tử | Theme 8 | Dùng hóa đơn đã phát hành và trace làm bằng chứng/đầu vào thuế | Phát hành, hủy, thay thế, sửa hóa đơn |
| Mua hàng, điều khoản NCC, discount entitlement | Theme 10 | Ghi tác động khi quyền lợi/nghĩa vụ được owner xác lập | Tự suy luận quyền lợi mua từ forecast |
| Tenant/legal profile/permission | Theme 1 | Đọc context, snapshot pháp lý khi cần | Sửa hồ sơ pháp lý/permission |
| Đối tác | Theme 3 | Tham chiếu partner identity | Tạo một master đối tác kế toán riêng |

## 4. Negative scope quan trọng

- Không coi “hạch toán” là lý do để Theme 09 chiếm ownership nghiệp vụ nguồn.
- Không sửa lịch sử bút toán đã ghi; điều chỉnh bằng record mới có liên kết.
- Không ghi official ledger từ dự báo/ước tính chưa trở thành quyền/nghĩa vụ thực tế.
- Không hard-code một biểu mẫu thuế hoặc chế độ kế toán vĩnh viễn vào data model.
- Không giả định mọi đơn vị đều dùng hệ thống tài khoản Nợ/Có.
