# VET45 HTML Design System — Parity Audit v1.5.0

## Mục tiêu

v1.5.0 sửa nguyên nhân gốc của các lỗi nhìn thấy trong v1.4: catalog có markup nhưng thiếu CSS anatomy, icon runtime chỉ phủ một phần registry, và tên Figma / Flutter / selector HTML bị trình bày như thể cùng một loại định danh.

## Authority

1. **Figma live DS** quyết định tên master/variant, variables, text/effect styles, anatomy, geometry, fill/stroke, icon instance và pattern/template visual.
2. **Flutter DS 1.4.1** quyết định public API, semantic icon mapping trong `VIcons`, behavior/accessibility và cung cấp nguồn đối chiếu implementation.
3. Khi hai nguồn drift ở visual value, HTML dùng Figma và ghi drift; không lấy trung bình, không tạo giá trị thứ ba.

## Naming gate

- `figmaName` được giữ nguyên 100%, gồm cả typo nguồn như `DS v2 / Avata Card`, `State=Defualt`, `State=Disable` và khoảng trắng cuối của `VSegmentedControl `.
- `flutterPublicApi` là mapping nullable. Không có public class 1:1 thì để `null`.
- `htmlSelector` là implementation detail, không phải tên component.

## Các lỗi v1.4 đã sửa

- `DS v2 / Avata Card`: chuyển từ generic flex sang absolute anatomy 370×92, avatar 52×52, copy/radio đúng tọa độ và typography nguồn.
- `DS v2 / Product Result Card`: 370×104; media 56×56; content 278×80; name/commercial/footer đúng 14/20, 13/20 và các cột 112/52/38/52.
- `DS v2 / Order Line Row`: bỏ card tự bịa 92px; trả về row 370×64, inner 354×48, media 40×40, product info và quantity hit-area 44px đúng source. Custom product vector lấy từ node Figma, không gán `box` giả.
- `VToast`: 370×56, semantic icon container 24×24, message 14/22.
- `VEmptyState`: icon container 64×64, title 18/24, description 14/22, action 14/20.
- `VModal`: 360×250, padding20, gap12, radius16, shadow 0/8/24/18%, title/description/flexible-space/action row đúng master.
- Token layer cập nhật theo live Figma, gồm Primary/50, warning scale, Surface/Toast, text styles và effect styles.

## Release gates mới

- 65 component masters + 22 pattern/template masters = 87/87.
- 0 class `v-*` trong `index.html` thiếu CSS selector.
- Sáu root component từng lỗi (`Avata Card`, `Product Result Card`, `Order Line Row`, `VToast`, `VEmptyState`, `VModal`) chỉ còn **một canonical root rule**, không còn cascade “sai trước, sửa đè sau”.
- 0 `data-v-icon` trong catalog bị thiếu runtime resolution.
- 8 glyph critical (`plus`, `x`, `info`, `circle-check`, `triangle-alert`, `circle-x`, `image`, `banknote-arrow-down`) dùng exact SVG export từ Figma; Order Line dùng exact custom vector của master.
- 87 heading catalog phải bằng Figma source names sau HTML entity decode.
- token snapshot critical values phải khớp CSS.
- không có font binary trong package.

## Giới hạn bằng chứng pixel

Chromium headless của sandbox tiếp tục không kết thúc ổn định ở vòng QA cuối, nên v1.5.0 **không tự gắn nhãn pixel-perfect toàn bộ 87 master**. Specimen nhỏ đã được render bằng engine tĩnh để bắt anatomy/layout lớn, nhưng engine đó không được dùng làm bằng chứng pixel cuối cho JS/icon hydration. Source-level contract và geometry được lấy trực tiếp từ Figma; pixel gate toàn bộ cần chạy trong browser engine ổn định ở môi trường repo/CI.
