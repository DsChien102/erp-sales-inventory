# Plan từng việc refactor

Mỗi **plan** trong bảng Plan của từng phase ở [PLAN.md](../PLAN.md) (mã `1-A`, `2-B1`, `7-3`…; một plan gom nhiều việc nhỏ, khoảng 0,5–1,5 ngày làm) có một file ở đây trước khi làm. **Claude viết plan và review; người dùng tự code.**

```text
plans/
  P2/2-B6-ui-ux-auth.md
  T7/T7-1-ton-kho-bj01.md
  P2/2-B1-dang-ky-cua-hang.md
  ...
```

Tên file: `<mã plan>-<tên ngắn không dấu>.md`. Plan đã làm + review xong thì xoá (còn trong lịch sử git); dòng của nó ở PLAN.md giữ trạng thái, cột file ghi "— (đã xoá)". Đầu file ghi các việc chi tiết mà plan gồm (cột "Gồm việc").

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
