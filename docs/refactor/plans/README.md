# Plan từng việc refactor

Mỗi việc trong [PLAN.md](../PLAN.md) (mã `1.2`, `2A.3`, `3.5`…) có một file plan ở đây trước khi làm. **Claude viết plan và review; người dùng tự code.**

```text
plans/
  P1/1.1-cau-truc-core.md
  P1/1.2-app-exception.md
  P2/2A.1-create-tenant-for-owner.md
  ...
```

Tên file: `<mã việc>-<tên ngắn không dấu>.md`.

## Mẫu

```markdown
# <mã> — <tên việc>

> Phase: Px · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Tài liệu liên quan: PLAN mục …, TH-0x mục …, KI-…

## 1. Mục tiêu
Một hai câu: xong việc này thì có gì, thay cái gì.

## 2. Hiện trạng
File / symbol hiện có, ai đang dùng (grep), hành vi cần giữ.

## 3. Thay đổi
| File | Hành động (tạo / sửa / chuyển / xoá) | Nội dung |
|---|---|---|

## 4. Các bước
1. …
2. …
(Kèm mã mẫu khi cần: chữ ký class/hàm, mapping RPC → model.)

## 5. Kiểm tra
- [ ] `flutter analyze` không lỗi mới
- [ ] Test liên quan: …
- [ ] So với `TEST-BASELINE.md`: không lỗi thêm
- [ ] CHECKLIST: tick cột "Mới" các dòng …
- [ ] Thao tác tay: …

## 6. Rủi ro / lưu ý

## 7. Review
<!-- Claude ghi sau khi người dùng code xong -->
- Ngày, commit được review:
- Kết quả: ✅ đạt / 🔄 cần sửa
- Góp ý:
```

## Quy trình

1. Claude viết plan, đặt cột **Plan = 📝** trong PLAN.md.
2. Người dùng đọc, góp ý hoặc duyệt → **Plan = ✅**.
3. Người dùng code → **Làm = 🔄**, xong → **Làm = ✅**, báo Claude.
4. Claude review diff + chạy analyze/test → ghi mục 7 → **Review = ✅** hoặc **🔄** (kèm góp ý).
5. Review ✅ thì việc xong; ghi commit/PR vào bảng "Theo dõi tiến độ" của PLAN.md.
