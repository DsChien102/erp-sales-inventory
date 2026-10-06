# Changelog v0.3.2 — DS audit + Inspect mode

## Mục tiêu

Rà lại các sai lệch Design System từ review v0.3.1 và bổ sung công cụ **Inspect** để kiểm tra trực tiếp component mapping + browser box model trong HTML prototype.

## Design System corrections

### SCR-009
- `VButton(label="Thêm lô")`: bỏ icon tự phát; contract pin `leadingIcon=null`, `trailingIcon=null`.
- `ReceivingBalanceSummary`: giữ `VCard` neutral; trạng thái/cân bằng được render bằng `VBanner` semantic thay vì đổi màu toàn card.
- Balance feedback dùng đúng `VBanner.info/success/warning`, kèm default icon của Flutter DS.
- Banner tác động giá đổi thành title ổn định `Đang chờ xác nhận giá`; quantity nằm trong description để tránh vỡ hierarchy/UI.

### SCR-012
- `VEmptyState/VEmptyMedia` được căn lại theo Flutter source: media 64, icon ~28, radius 16, semantic success/danger color.
- `VIcons.success` dùng Lucide-equivalent `checkCircle2`; `VIcons.error` được sửa visual sang `alertCircle` (không còn x-circle giả).
- `VLoading`: size 40, stroke 4, semantic `success`; loại bỏ track màu tự chế.
- `VBanner.info` dùng đúng icon/color semantic.
- `VToast`: chuyển từ outer-review overlay thành floating feedback **bên trong product viewport**, với anatomy `VToast -> VIconBox + message + VIcons.close`.

### SCR-013
- `TERMINAL`: không còn render spinner/loading; dùng `VBanner.success` trước khi route về SCR-012.
- `PROCESSING_OR_UNKNOWN/STALE`: tiếp tục dùng `VLoading` + warning state khi cần.
- `OperationEvidenceTimeline` được đánh dấu rõ là **Theme 7 composition**, vì Flutter DS hiện chưa public Timeline pattern. Composition chỉ dùng `VCard/VIconBox/VText/VBadge`.
- Timeline icon boxes dùng semantic `VComponentTone.neutral/success/warning` thay vì màu tự chế không trace được.

### Permission denied
- Bỏ custom `VEmptyState` cho `PERMISSION_DENIED`.
- Render theo UIF-02 contract bằng `VBanner.error`; dữ liệu/action phía sau bị mask.

## Inspect mode

Nút **Inspect** nằm cạnh viewport switcher, thuộc review tooling — không thuộc product UI/Flutter DS.

Khi bật:
- Hover component trong phone → overlay Box Model kiểu DevTools: margin / border / padding / content.
- Tooltip hiển thị `V*` component hoặc `Theme7.*` composition.
- Panel bên phải hiển thị:
  - Flutter DS component;
  - Theme composition;
  - authority;
  - component profile;
  - `data-ds-prop-*` mapping;
  - DS gap nếu có;
  - box model T/R/B/L và content size.
- Click component → pin selection.
- `Esc` → bỏ pin.
- Trong Inspect mode, click trong product viewport **không kích hoạt business interaction**.
- Có thể mở trực tiếp bằng query `&inspect=1`.

## Boundary

- Flutter code vẫn là semantic/API authority.
- Vercel render từ Flutter source vẫn là canonical visual authority.
- HTML Inspect chỉ đọc mapping metadata/computed CSS; không tạo token/component semantics mới.
- Inline SVG chỉ là browser representation của semantic `VIcons.*`; Flutter implementation vẫn dùng Lucide font glyph qua `VIcons`.
