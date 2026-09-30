# EVD — Navigation / Information Architecture Contract v4.6.4

## Kết quả

**PASS — 64/64 checks.**

## Phạm vi thay đổi

- `03.design/patterns/PAT-NAV.md` được nâng thành authority chính thức cho Navigation / Information Architecture.
- Bổ sung `SCR-090`–`SCR-096` với `screen_class: NAVIGATION`.
- `PAT-UI-UX.md` cho phép navigation screen trace theo `PAT-NAV → destination` và không bắt buộc BJ/UC/UIF owner riêng.
- Screen Registry nhận diện 7 navigation screen mới.
- Workbench/Inspect dùng Screen ID canonical mới; Product UI v4.6.3 không thay visual.

## Không thay đổi

- 17 Business Journey giữ nguyên.
- 64 Use Case giữ nguyên.
- 17 UIF giữ nguyên.
- Không thêm mutation Action/BC/API cho navigation-only transition.
- `v463-warehouse-hub-candidate.js` và `.css` được kiểm tra byte-identical với package v4.6.3.

## Runtime check

- `SCR-090` được nhận diện tại Hub candidate.
- `SCR-094` được nhận diện tại workspace Giá trị kho.
- Authority hiển thị: `PAT-NAV`.
- Viewport: `402×874`.
- Horizontal overflow: không có.
- Browser errors: `0`.

Nguồn chi tiết: `03.design/prototype/html/qa/NAVIGATION-IA-CONTRACT-QA-v4.6.4.json`.
