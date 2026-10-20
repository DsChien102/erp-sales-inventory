# 10-7 — Tinh chỉnh `vet45_design_system` từng mảng bằng impeccable

> Phase: P10 · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Độc lập với phase nghiệp vụ; chỉ đụng `packages/vet45_design_system` (và app khi một task đổi API công khai).
> Nguồn: hỏi đáp về lệnh `/impeccable` (2026-10-19).
> Tài liệu liên quan: [DESIGN.md](../../../../DESIGN.md), [PRODUCT.md](../../../../PRODUCT.md), README `packages/vet45_design_system` (quy tắc example catalog, version), các plan trước: [10-4](10-4-tuong-phan-mau-thanh-dieu-huong.md), [10-5](10-5-tuong-phan-tone-va-vien-o-nhap.md), [10-6](10-6-vung-cham-nhan-inset-chuyen-dong.md).

## 1. Mục tiêu

Chỉnh design system theo **từng mảng một**: mỗi task chạy một lệnh impeccable trên phạm vi hẹp, xem lại, kiểm tra, commit riêng. Đây là **tinh chỉnh**, không phải thiết kế lại: giữ nhận diện hiện tại (xanh lá phòng khám, Inter, "gọn như một quầy thuốc ngăn nắp" trong DESIGN.md), giữ hành vi và API công khai trừ khi task ghi rõ.

## 2. Thứ tự và cách làm

Thứ tự đi **token → theme → component → chữ trên giao diện**: sửa token trước để component ăn theo, đỡ chỉnh hai lần.

| # | Task | Lệnh | Phạm vi |
|---|---|---|---|
| 1 | Chữ | `typeset` | `tokens/v_typography.dart` |
| 2 | Khoảng cách, bo góc, nhịp bố cục | `layout` | `tokens/v_spacing.dart`, `v_radius.dart`, `patterns/` |
| 3 | Thêm điểm nhấn màu | `colorize` | `tokens/v_colors.dart`, `theme/v_color_scheme.dart` |
| 4 | Giảm màu / bóng chói, rối | `quieter` | `tokens/v_colors.dart`, `v_shadows.dart` |
| 5 | Responsive, mật độ hiển thị | `adapt` | `patterns/v_responsive*.dart`, `theme/v_density.dart` |
| 6 | Gọn component nhiều biến thể | `distill` | `components/v_combobox*.dart` |
| 7 | Bớt nhạt, an toàn quá | `bolder` | `components/` |
| 8 | Chuyển động | `animate` | `tokens/v_duration.dart` + component cụ thể |
| 9 | Trạng thái lỗi, rỗng, dữ liệu dài | `harden` | `components/v_input.dart`, `v_empty_state.dart` |
| 10 | Chữ trên nhãn, thông báo lỗi | `clarify` | `forms/` |

Đường dẫn trong bảng tính từ `packages/vet45_design_system/lib/src/`.

Task 3 và 4 đi ngược chiều nhau trên cùng file: làm task 3 xong, nhìn lại rồi mới quyết định có cần task 4 không. Task nào xem xong thấy không cần thì đánh ⏭ và ghi lý do một dòng.

### Vòng làm của mỗi task

1. Đứng ở gốc repo, `git status` sạch (hoặc chỉ còn việc không liên quan).
2. Chạy lệnh ở mục "Lệnh" của task. Đọc phần impeccable đề xuất **trước khi** nó sửa; gạt bỏ đề xuất ra ngoài phạm vi.
3. Chạy app example để nhìn: `melos run design-system:example` (hoặc `:web`). Xem cả sáng / tối nếu theme có hai chế độ.
4. Kiểm tra chung (mục 4) + kiểm tra riêng của task.
5. Ghi một dòng vào `CHANGELOG.md` mục `[Unreleased]`, commit riêng: `style(design-system): 10-7.<số> — <mảng>`.
6. Tích `- [ ] Xong (làm + review)` trong mục 3 (chỉ tích sau khi đã review xong), ghi ngày nếu cần.

## 3. Task

### Task 1 — Chữ (`typeset`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable typeset packages/vet45_design_system/lib/src/tokens/v_typography.dart — dễ đọc trên điện thoại, số liệu (tiền, số lượng) thẳng cột, dấu tiếng Việt không bị cắt
```

**Cần đạt**

- Thang cỡ chữ có thứ bậc rõ, không có hai bậc gần như bằng nhau.
- Số trong bảng / danh sách dùng chữ số đều độ rộng (tabular figures).
- Chiều cao dòng đủ cho dấu chồng (ví dụ "Ệ", "Ữ") không chạm dòng trên.

**Giữ nguyên:** font Inter; tên các style mà app đang gọi (grep `VTypography.` trong `apps/` trước khi đổi tên).

**Xong khi:** DESIGN.md mục `typography` vẫn khớp code (nếu lệch → ghi lại để task Cuối cập nhật).

### Task 2 — Khoảng cách, bo góc, nhịp bố cục (`layout`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable layout packages/vet45_design_system/lib/src/tokens/v_spacing.dart packages/vet45_design_system/lib/src/tokens/v_radius.dart packages/vet45_design_system/lib/src/patterns/
```

**Cần đạt**

- Thang spacing theo một bước cơ sở, không có giá trị lẻ dùng một lần.
- `VPageScaffold`, `VSection`, `VPagePadding` cho nhịp đều giữa các khối trên một màn.

**Giữ nguyên:** `VSpacing.minTouchTarget` (44, từ 10-6); inset thanh dưới (10-6 mục H).

### Task 3 — Thêm điểm nhấn màu (`colorize`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable colorize packages/vet45_design_system/lib/src/tokens/v_colors.dart packages/vet45_design_system/lib/src/theme/v_color_scheme.dart
```

**Cần đạt:** màu nhấn dùng có chủ đích (trạng thái, hành động chính), không rải đều.

**Giữ nguyên:** độ tương phản đã sửa ở 10-4 và 10-5 (chữ ≥ 4.5:1, viền ô nhập ≥ 3:1). Mọi màu mới phải đo lại tương phản.

### Task 4 — Giảm màu / bóng chói, rối (`quieter`)

- [x] Xong (làm + review) · hoặc ⏭ + lý do một dòng nếu bỏ

> Chỉ làm nếu sau task 3 vẫn thấy chói hoặc rối.

**Lệnh**

```
/impeccable:impeccable quieter packages/vet45_design_system/lib/src/tokens/v_colors.dart packages/vet45_design_system/lib/src/tokens/v_shadows.dart
```

**Cần đạt:** ít mức bóng hơn, mỗi mức có lý do (nổi lên khi kéo, sheet, menu).

**Giữ nguyên:** như task 3.

### Task 5 — Responsive, mật độ hiển thị (`adapt`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable adapt packages/vet45_design_system/lib/src/patterns/ packages/vet45_design_system/lib/src/theme/v_density.dart — điện thoại là chính, máy tính bảng ở quầy là phụ
```

**Cần đạt:** điểm ngắt (`v_breakpoints.dart`) và mật độ khớp nhau; bố cục không vỡ ở 320pt ngang và ở cỡ chữ hệ thống lớn.

**Kiểm tra riêng:** chạy example với cỡ chữ hệ thống lớn nhất (iOS Larger Text / Android Font size).

### Task 6 — Gọn component nhiều biến thể (`distill`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable distill packages/vet45_design_system/lib/src/components/v_combobox*.dart
```

**Cần đạt:** bớt tham số / biến thể không ai dùng.

**Trước khi xoá:** grep từng tham số trong `apps/` và `modules/`; chỉ xoá cái 0 chỗ dùng. Xoá tham số công khai = đổi API → ghi `### Removed` trong CHANGELOG.

**Kiểm tra riêng:** `test/v_combobox_layout_test.dart` vẫn qua.

### Task 7 — Bớt nhạt (`bolder`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable bolder packages/vet45_design_system/lib/src/components/ — app vận hành (Operate), mạnh ở chi tiết, không thêm trang trí
```

**Cần đạt:** hành động chính trên mỗi màn nhận ra ngay; trạng thái chọn / đang bấm rõ hơn.

**Giữ nguyên:** đây là app vận hành ở quầy, không biến thành trang quảng cáo. Gạt bỏ đề xuất gradient, hình minh hoạ, hiệu ứng lớn.

### Task 8 — Chuyển động (`animate`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable animate packages/vet45_design_system/lib/src/tokens/v_duration.dart — ghi thêm component cụ thể muốn có chuyển động
```

**Cần đạt:** ít mức thời lượng, mỗi mức gắn với một loại chuyển động (phản hồi bấm, mở sheet, chuyển màn).

**Giữ nguyên:** tôn trọng Giảm chuyển động (10-6 mục I, J). Mọi animation mới phải xét `MediaQuery.disableAnimations`.

### Task 9 — Trạng thái lỗi, rỗng, dữ liệu dài (`harden`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable harden packages/vet45_design_system/lib/src/components/v_input.dart packages/vet45_design_system/lib/src/components/v_empty_state.dart
```

**Cần đạt:** tên sản phẩm / khách hàng rất dài không tràn; số tiền lớn (≥ 1.000.000.000 ₫) không vỡ dòng; lỗi và rỗng có hướng dẫn bước tiếp theo.

**Kiểm tra riêng:** example catalog có thêm trạng thái dữ liệu dài và lỗi cho hai component này.

### Task 10 — Chữ trên nhãn, thông báo lỗi (`clarify`)

- [x] Xong (làm + review)

**Lệnh**

```
/impeccable:impeccable clarify packages/vet45_design_system/lib/src/forms/
```

**Cần đạt:** thông báo của validator nói rõ sai gì và sửa thế nào, cùng giọng văn; tiếng Việt có dấu đầy đủ.

**Giữ nguyên:** chuỗi chữ đã chốt trong spec (theo `docs/02-yeu-cau`); nếu đề xuất đổi chuỗi đã có trong spec thì hỏi trước, không tự sửa.

### Cuối — Rà soát và cập nhật DESIGN.md

- [ ] Xong (làm + review)

Sau khi xong các task cần làm:

```
/impeccable:impeccable polish packages/vet45_design_system
/impeccable:impeccable document
```

Rồi bump version bằng `scripts/bump_version.sh` (minor nếu chỉ thêm / chỉnh, major nếu task 6 xoá API công khai).

## 4. Kiểm tra chung (mỗi task)

- [ ] `flutter analyze` trong `packages/vet45_design_system` không có lỗi mới
- [ ] `flutter test` trong `packages/vet45_design_system` qua
- [ ] Example catalog phủ mọi trạng thái của component vừa đổi (quy tắc trong README package)
- [ ] Nếu đổi API công khai: `flutter analyze` ở `apps/erp` không lỗi mới
- [ ] Tương phản không tụt dưới mức 10-4 / 10-5
- [ ] Vùng chạm vẫn ≥ 44pt (10-6)
- [ ] Một dòng trong `CHANGELOG.md` mục `[Unreleased]`
