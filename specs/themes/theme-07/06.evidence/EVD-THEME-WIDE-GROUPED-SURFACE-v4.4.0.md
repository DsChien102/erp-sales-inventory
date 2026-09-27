# EVD — Theme-wide grouped surface v4.4.0

**Kết quả: PASS**

## Quy tắc khóa

Khi từ hai `Info Row` / `Key-value Row` trở lên cùng tạo thành một nhóm thông tin có chung ý nghĩa, nhóm đó phải có **một surface chung** gồm nền, viền mảnh và bo góc. Các row vẫn là primitive bên trong; không biến từng row thành card riêng. Collection của các `List Row` độc lập không áp dụng quy tắc này.

## Audit toàn Theme 7

- Quét đủ **17 UIF** và **486 screen/state render**.
- Regression thật còn lại ngoài valuation: `UIF-01 / SCR-003`, `UIF-02 / SCR-010`, `UIF-05 / SCR-028`.
- `UIF-03`, `UIF-13`, `UIF-14` giữ nguyên surface đã sửa ở v4.3.1.
- Các nhóm như UIF-07 đã có surface ở subgroup nên **không bọc thêm**, tránh card soup.

## Kiểm chứng

- Theme-wide grouped surface: **486/486 PASS**.
- Full Theme runtime: **86/86 PASS**.
- Valuation E2E: **29/29 PASS**.
- Valuation visual/runtime: **19/19 PASS**.
- Valuation full-state: **54/54 PASS**.
- Valuation grouped-surface: **8/8 PASS**.
- Browser runtime errors: **0**.

Không thay đổi nghiệp vụ, BJ, UC, UIF topology, action hoặc state machine.
