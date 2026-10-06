# Changelog v2.7.4

Parent: `v2.7.3`.

- Sửa lỗi font rơi về serif: exact Figma typography giữ `Inter` làm canonical font và bổ sung sans-system fallback để không rơi vào UA serif khi môi trường không có Inter.
- Dựng lại BJ05 `Chọn lô thay thế` theo đúng live `DS v2 / Form Sheet` `1353:6355`: 402×764, handle area 24, header 44, intro 40, canonical fields và Sticky Footer 92.
- Đồng bộ `VTextarea` `522:7212`, `VButton` `521:529`, `Icon Button` `4431:10317`, List Row Selection và VRadio theo DS.
- Disabled Primary button giữ primary surface và áp `Opacity/Disabled = 0.4`; không thay bằng màu xám riêng.
- Hard-gate `VBottomSheet`, `Confirmation Sheet` và `VNumericKeypadSheet` typography/geometry theo live DS; mọi `VBottomSheet` claim trong HTML được map về node `4695:6353`.
- Không thay đổi business behavior.
