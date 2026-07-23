# Pricing Manual Create Duplicate Blocking Design

**Ngày:** 2026-07-22
**Phạm vi:** TH-04 EP02/US-04 — tạo giá riêng thủ công

## Mục tiêu

Khi người dùng tạo thủ công một rule giá riêng có cùng tenant, khách hàng,
sản phẩm, đơn vị bán và khoảng hiệu lực giao nhau với một rule đang hoạt động,
hệ thống phải chặn thao tác bằng lỗi `DUPLICATE_ACTIVE_RULE`. Rule cũ được giữ
nguyên; hệ thống không tạo rule mới và không tự động disable hay ghi đè rule cũ.

## Phạm vi và giới hạn

- Chỉ thay đổi luồng `CreateCustomerPriceRuleCommand` / RPC
  `pricing.create_customer_price_rule` và các fake/in-memory/UI tương ứng.
- Không thay đổi chính sách của luồng cập nhật rule hoặc bật lại rule trong công
  việc này.
- SQL chỉ được sửa trong `supabase/migrations/_drafts/`; không promote migration
  và không giả định draft đã được apply trên database.
- Giữ nguyên các kiểm tra tenant, quyền, reference, ngày hiệu lực, giá sàn và
  idempotency hiện có.

## Thiết kế luồng

1. Form có thể dùng create-context/precheck để báo trùng sớm cho người dùng,
   nhưng kết quả này chỉ mang tính tư vấn.
2. Khi người dùng bấm **Lưu**, command đi qua pipeline hiện tại tới RPC tạo rule.
3. RPC lấy advisory lock theo khóa tenant + customer + product + unit, rồi kiểm
   tra lại authoritative xem có rule persisted `active` với khoảng hiệu lực giao
   nhau hay không.
4. Nếu có conflict, RPC trả lỗi ổn định `DUPLICATE_ACTIVE_RULE` và kết thúc
   transaction mà không insert rule mới, không update/disable rule cũ và không
   tạo activity `AUTO_REPLACED_BY_RULE`.
5. Nếu không conflict, RPC tiếp tục tạo rule và activity `created` như hiện tại.
6. Presentation map `DUPLICATE_ACTIVE_RULE` thành thông báo chặn lưu, giữ dữ liệu
   người dùng đã nhập và cho phép họ sửa đối tượng hoặc khoảng hiệu lực.

Khoảng hiệu lực được tính inclusive. Hai khoảng giao nhau khi:

```text
existing.effective_from <= coalesce(new.effective_to, infinity)
and new.effective_from <= coalesce(existing.effective_to, infinity)
```

Chỉ rule persisted `active` và chưa bị xóa mới chặn tạo.

## Thành phần thay đổi

- **SQL draft:** bỏ lời gọi auto-disable trong create RPC; thay bằng duplicate
  check trả `DUPLICATE_ACTIVE_RULE` dưới advisory lock. Helper auto-disable vẫn
  tồn tại vì update/reenable có thể còn dùng.
- **Application fake:** scenario `createRuleDuplicate` trả blocked exception thay
  vì success.
- **ERP in-memory:** `_create` phát hiện conflict và ném lỗi; không gọi
  `_disableInternal` cho rule cũ.
- **Presentation:** bỏ nội dung nói tạo mới sẽ ghi đè; hiển thị duplicate là lỗi
  chặn lưu và giữ form hiện tại.
- **Contracts/docs:** US-04 và API contract thống nhất rằng duplicate tạo thủ
  công bị chặn.

## Xử lý lỗi

- Mã lỗi: `DUPLICATE_ACTIVE_RULE`.
- UI copy đề xuất: `Đã tồn tại giá riêng đang hoạt động trùng thời gian. Vui lòng
  điều chỉnh khoảng hiệu lực hoặc chọn đối tượng khác.`
- Lỗi không được chuyển thành cảnh báo có thể xác nhận, và submit lại cùng payload
  vẫn phải bị chặn.
- Các lỗi hệ thống, mất quyền, reference không hợp lệ và dưới giá sàn tiếp tục dùng
  mapping hiện tại.

## Kiểm thử

- SQL contract chứng minh create RPC có duplicate check, trả
  `DUPLICATE_ACTIVE_RULE`, và không gọi helper auto-disable trong thân create RPC.
- In-memory test chứng minh tạo trùng trả lỗi, số rule không tăng và rule cũ vẫn
  active với version không đổi.
- Fake application test chứng minh `createRuleDuplicate` trả đúng blocked code.
- Presentation widget/cubit test chứng minh thông báo không còn semantics ghi đè
  và dữ liệu form không bị xóa sau lỗi.
- Chạy regression cho create, update, reenable và import để đảm bảo thay đổi chỉ
  tác động tới tạo thủ công.

## Tiêu chí hoàn tất

- Không đường thực thi tạo thủ công nào tự disable rule active trùng.
- Không rule mới hoặc activity thay thế nào được tạo khi duplicate.
- Người dùng nhận lỗi rõ ràng và có thể chỉnh form để thử lại.
- Update, reenable và import giữ đúng policy đã được xác định riêng cho từng luồng.
