# Prototype dùng chung (`specs/prototype/shared/`)

Nền chung cho prototype HTML của các theme: **token màu / cỡ / bo góc** (`tokens.css`), **component DS** (`components.css`), **icon** (`icons.js`), **khung app** (`shell.js` + `shell.css`: thanh bên web, thanh dưới iPhone, màn chờ; xem `specs/prototype/shell/html/README.md`).

Mỗi theme vẫn giữ prototype riêng (màn, dữ liệu, trang xem). Theme dùng nền chung qua symlink `html/shared` → `specs/prototype/shared`:

| Theme | Trạng thái |
|---|---|
| Theme 6 | Dùng nền chung (`index.html` nạp `shared/tokens.css`, `shared/components.css`; `app/icon.js` re-export `shared/icons.js`). Chạy bằng `python3 tools/serve.py`. |
| Theme 7 | **FROZEN**, chưa dùng nền chung: vẫn có bản `styles/tokens.css`, `styles/components.css` riêng. `shared/` hiện là bản sao của hai file đó. |

## Xem mọi prototype một chỗ

```bash
python3 specs/prototype/serve.py   # cổng 8760 → http://127.0.0.1:8760/ (mục lục specs/index.html)
```

Mỗi trang xem (trừ Theme 7 FROZEN) có link "← Mục lục". Thêm prototype mới: thêm một dòng vào `specs/index.html` và link `← Mục lục` (đường dẫn tương đối tới `specs/index.html`) vào trang xem của nó. Link chỉ chạy khi mở qua máy chủ chung này.

## Quy tắc
- Sửa token / component dùng chung: sửa ở `shared/`. Theme 7 chưa theo, nên chạy `bash specs/prototype/shared/check-sync.sh` để biết còn lệch.
- Theme mới: tạo symlink `html/shared`, nạp CSS từ `shared/`, thêm rule riêng của theme vào file CSS của theme (đặt tên tiền tố riêng như `rc-`, `rv-`, `rw-`).
- Không chép tay `tokens.css` / `components.css` vào theme nữa.

## Lưu ý khi chuyển Theme 6 sang nền chung (2026-11-18)
`components.css` cũ của Theme 6 là bản trích từ Theme 7 và thiếu một số rule Theme 7 khai báo lại về sau (như `.button`, `.app-header`). Nền chung dùng bản đầy đủ nên 57/90 ảnh Theme 6 lệch vài điểm ảnh (khoảng cách dòng); nhìn bằng mắt giống nhau. Muốn chặt hơn thì chụp lại `tools/proto-final/` và so.
