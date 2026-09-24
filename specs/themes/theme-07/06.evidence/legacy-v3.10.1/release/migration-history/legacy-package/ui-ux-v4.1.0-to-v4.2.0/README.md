# Migration UI/UX v4.1.0 → v4.2.0-rc1

- 14 Screen Group active cũ được chuyển thành alias migration và đánh dấu `RETIRED`.
- 83 Screen được đánh ID liên tục `SCR-001…SCR-083`.
- Sáu Navigation Area chỉ phục vụ kiến trúc thông tin; không thay Screen Group trong traceability.
- Prototype cũ không được mang sang làm bằng chứng; vòng này đặt `NOT_RENDERED`.

| SG cũ | Tên | Navigation Area | Screen mới |
|---|---|---|---|
| `SG-01` | Tồn kho và khả dụng | NAV-01 | SCR-001, SCR-002, SCR-003, SCR-004, SCR-005 |
| `SG-02` | Nhận hàng | NAV-02 | SCR-006, SCR-007, SCR-008, SCR-009, SCR-010, SCR-011, SCR-012, SCR-013 |
| `SG-03` | Hàng chờ giá | NAV-04 | SCR-014, SCR-015, SCR-016, SCR-017, SCR-018, SCR-019 |
| `SG-04` | Reservation và thiếu hàng | NAV-02 | SCR-020, SCR-021, SCR-022, SCR-023, SCR-024 |
| `SG-06` | Pick, pack và bàn giao | NAV-02 | SCR-025, SCR-026, SCR-027, SCR-028, SCR-029 |
| `SG-07` | Khách trả và phân loại | NAV-02 | SCR-030, SCR-031, SCR-032, SCR-033, SCR-034, SCR-035 |
| `SG-08` | Trạng thái, trả nhà cung cấp và tiêu hủy | NAV-02 | SCR-036, SCR-037, SCR-038, SCR-039, SCR-040, SCR-041 |
| `SG-09` | Kiểm kê | NAV-02 | SCR-042, SCR-043, SCR-044, SCR-045, SCR-046, SCR-047 |
| `SG-10` | Operation, phê duyệt và sửa sai | NAV-03 | SCR-048, SCR-049, SCR-050, SCR-051, SCR-052, SCR-053 |
| `SG-11` | Thẻ kho và lịch sử | NAV-05 | SCR-054, SCR-055, SCR-056, SCR-057, SCR-058, SCR-059 |
| `SG-12` | Chính sách tồn sản phẩm và chỉ báo | NAV-01, NAV-06 | SCR-060, SCR-061, SCR-062, SCR-063, SCR-064, SCR-065 |
| `SG-13` | Opening balance và Chuyển đổi chính thức | NAV-06 | SCR-066, SCR-067, SCR-068, SCR-069, SCR-070, SCR-071 |
| `SG-14` | Tính giá vốn và đóng kỳ | NAV-04 | SCR-072, SCR-073, SCR-074, SCR-075, SCR-076, SCR-077 |
| `SG-15` | Tin cậy, UNKNOWN và đối soát | NAV-03 | SCR-078, SCR-079, SCR-080, SCR-081, SCR-082, SCR-083 |
