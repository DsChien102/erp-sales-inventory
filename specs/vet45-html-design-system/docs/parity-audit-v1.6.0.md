# Historical / superseded audit

> This document records HTML DS v1.6.0 history only. It is **not** authority for HTML DS v2.0.0. Flutter DS 1.4.1 supersedes the Figma-first decisions described below.

# Parity audit — HTML DS v1.6.0

## Phạm vi

Vòng này sửa toàn bộ typography runtime và contract trên baseline v1.5.0. Figma DS v2 tiếp tục là visual authority; Flutter DS 1.4.1 chỉ dùng để đối chiếu asset/package behavior.

## Kết quả chính

- Khóa family runtime về `VET45 Inter` và `VET45 JetBrains Mono`.
- Khóa Inter weight 400/500/600/700/800 và JetBrains Mono 400 theo family mà Flutter package đang nhúng.
- Không phân phối font binary trong HTML package; host phải cung cấp font theo `contracts/font-contract.json`.
- Thêm runtime check `verifyTypographyRuntime()` và strict check `assertTypographyReady()`; thiếu font là parity failure, không còn silent fallback sang Segoe UI/system font.
- Thêm cảnh báo font trực tiếp trong `index.html` và `showcase/index.html`.
- `font-synthesis:none` để browser không tự tạo fake weight.
- Global type scale bám snapshot Figma: D1, H1–H4, Body, Label, Action, Caption, Overline, Mono/Numeric.
- Sửa Metric Card value về Inter Bold 22/28, tracking -0.3 theo master; loại legacy JetBrains Mono 16/22.
- Dọn typography override chồng lớp; mỗi selector typography chỉ có một canonical declaration layer.
- Tạo `contracts/component-typography.json` để inventory toàn bộ typography declaration trong source và phân biệt global style với component-local style.

## Drift Flutter 1.4.1 không được đẩy ngược vào HTML

Flutter source hiện có một số khác biệt với Figma: H4 14 thay vì 16; Body weight 500 thay vì 400; Label Small 11/14; Caption 600; Mono Numeric 500 14/20. HTML giữ Figma vì đây là visual authority.

## Giới hạn có chủ đích

Package không chứa `.ttf/.otf/.woff/.woff2`. Điều này không phải fallback policy; host phải cấp font. Release gate kiểm package không vô tình đóng gói font binary và runtime sẽ báo thiếu font khi mở catalog.
