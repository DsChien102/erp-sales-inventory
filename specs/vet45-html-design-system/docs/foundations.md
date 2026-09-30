# Foundations — extracted from Figma DS v2

## Color

HTML sử dụng cùng WEB variable names mà Figma đã khai báo khi có thể. Primitive và semantic layers đều nằm trong `src/tokens.css`; product UI ưu tiên semantic tokens.

## Typography

- Display/D1 — Inter Extra Bold 40/44, -1px
- H1 — Bold 28/34, -0.5px
- H2 — Bold 22/28, -0.3px
- H3 — Semi Bold 18/24, -0.2px
- H4 — Semi Bold 16/22
- Body/Default — Regular 14/22
- Body/Small — Regular 13/20
- Label/Default — Semi Bold 14/20
- Label/Small — Semi Bold 12/16
- Action/Default — Semi Bold 14/20
- Caption — Medium 12/16, +0.1px
- Overline — Semi Bold 11/14, +0.4px
- Mono/Numeric — JetBrains Mono 14/22
- Mono/Small — JetBrains Mono 13/20
- Mono/Emphasis — JetBrains Mono 16/22

## Dimension

Spacing: 0, 4, 8, 12, 16, 20, 24, 32, 40, 48.  
Radius: 4, 6, 8, 12, 16, 20, Pill.  
Touch minimum: 44.  
Mobile reference: 402×874.  
Page edge: mobile 16, tablet 24, desktop 32.

## Breakpoints

- Mobile: `< 600px`
- Tablet: `600–1023px`
- Desktop: `≥ 1024px`

Breakpoints thay đổi layout structure/behavior, không dùng để target model thiết bị cụ thể.

## Density

Compact: control 32/40/48; field padding 10/14.  
Comfortable: 36/44/52; field padding 12/16.

Density là runtime preset; không mặc định Compact=desktop hay Comfortable=mobile.

## Motion

Fast 150ms · Medium 200ms · Normal 300ms · Slow 350ms · Pulse 1000ms.

## Icons

Lucide là vendor source mặc định; product UI dùng approved VET45 registry thay vì chèn icon tùy ý. Icon size và touch target độc lập. Disabled không phải icon tone; dùng parent/component opacity 0.4.
