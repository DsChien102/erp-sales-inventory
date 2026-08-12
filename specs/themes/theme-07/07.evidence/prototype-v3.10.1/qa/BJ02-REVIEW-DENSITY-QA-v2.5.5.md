# BJ02 Review Density QA — v2.5.5

**Result: PASS · 18/18 checks**

- SCR-010 review changed from expanded data dump to progressive disclosure.
- Default product/line summary uses existing DS v2 / List Row, Type=Status, Density=Compact.
- Exceptions are surfaced at list level; detailed classification and LOT/HSD remain available through VBottomSheet.
- SCR-011 approval reuses the same dense review anatomy.

## Checks

- [x] Eight receipt lines render as compact summary rows — `8`
- [x] Compact List Row geometry matches Figma 370x52 / gap8 / px12 / radius8 — `{'w': 370, 'h': 52, 'g': '8px', 'px': '12px', 'rad': '8px'}`
- [x] Review list avoids old expanded product blocks
- [x] Product summary count is visible
- [x] Review screen has no horizontal overflow
- [x] Eight-line review list stays compact — `472`
- [x] Exceptions surfaced in summary list — `['Đã xong', 'Có cách ly', 'Đã xong', 'Đã xong', 'Có hàng hỏng', 'Có từ chối', 'Đã xong', 'Đã xong']`
- [x] Tapping row opens VBottomSheet detail
- [x] Detail uses live VBottomSheet geometry — `{'w': 402, 'rtl': '20px', 'rtr': '20px', 'p': '12px', 'g': '12px'}`
- [x] Detail shows relevant non-zero classification facts
- [x] Detail does not dump zero-value Hỏng/Từ chối — `Nobivac DHPPi

NOB-DHPP · lọ

Có cách ly
Kiểm tra lại dòng hàng này trước khi xác nhận hồ sơ.
Phân loại số lượng
9 lọ
Đạt
8 lọ
Cách ly
1 lọ
Lô và hạn dùng
1 lô
Lô LOT101
HSD 2027-12-31
Số lượng
9 lọ
Đóng`
- [x] LOT detail remains accessible on demand
- [x] Detail sheet no horizontal overflow
- [x] Detail sheet closes without leaving review
- [x] Approval reuses compact product summaries
- [x] Approval screen no horizontal overflow
- [x] Review uses existing DS assets only
- [x] Browser errors zero — `[]`
