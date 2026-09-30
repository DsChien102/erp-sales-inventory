# VET45 HTML Design System

**HTML DS:** 1.5.0  
**Figma DS authority:** 2.0.3  
**Figma file:** `QVJolM5tAdFKkhP7RIwe3y`

Shared executable Design System for every VET45 HTML prototype. Intended repository location:

```text
spec/
├─ design-system/
│  └─ html/        ← package này
└─ theme/
   ├─ theme-01/
   ├─ theme-07/
   └─ ...
```

## Xem toàn bộ Design System

Mở trực tiếp `index.html`. Đây là **Component Explorer chuẩn** của package, hiển thị đủ 65 component masters và 22 pattern/template masters từ Figma hiện hành. Có tìm kiếm, lọc theo nhóm, live preview, Figma node ID, selector HTML và toàn bộ variant/property axes.

`showcase/index.html` chỉ còn là trang tổng quan chọn lọc; không dùng nó để kết luận coverage của Design System.


## Authority

1. Product/BJ/UC/UI Contract quyết định **nghiệp vụ và hành vi**.
2. Figma Design System quyết định **cách biểu diễn UI chuẩn**.
3. HTML Design System là **bản hiện thực chuẩn cho prototype HTML**.
4. Theme prototype **compose/reuse**, không copy component CSS để tạo fork cục bộ.
5. Production implementation quyết định kỹ thuật triển khai cuối cùng nhưng phải bảo toàn contract UI đã chốt.

## Source pages đã QA trực tiếp

- `505:5889` — DS v2 — 01 Foundations & Icons
- `505:5890` — DS v2 - 02 Components
- `505:5891` — DS v2 — 03 Patterns & Templates

Release v1.5.0 khóa inventory hiện tại ở **65 component masters**, **22 pattern/template masters**, **35 icon meanings**, **4 local variable collections**.

## Cách dùng trong Theme prototype

Import duy nhất entry CSS cao nhất và module JS:

```html
<link rel="stylesheet" href="../../design-system/html/src/templates.css">
<script type="module" src="../../design-system/html/src/vet45-ds.js"></script>
```

`templates.css` import ngược `patterns.css → components.css → base.css → tokens.css`, do đó không import lặp lại cả năm file.

Ví dụ:

```html
<button class="v-btn" data-hierarchy="primary">Lưu</button>

<div class="v-field" data-kind="text" data-state="error">
  <label>Tên sản phẩm</label>
  <input class="v-control" value="">
  <span class="v-helper">Nhập tên sản phẩm.</span>
</div>
```

## Quy tắc bắt buộc

- Reuse existing Component → Pattern → Template trước khi tạo composition mới.
- Không hardcode màu/spacing/radius nếu đã có token tương đương.
- Không sửa shared component trong Theme để phục vụ một case riêng.
- Nếu DS thiếu asset: ghi nhận **DS gap**, cập nhật package dùng chung trước, rồi Theme consume version mới.
- Disabled dùng root/component opacity `0.4` tại nơi Figma định nghĩa; không tự tạo màu disabled riêng.
- Business state không được nhúng vào shared component nếu chỉ có ý nghĩa trong một Theme.
- Template định nghĩa cấu trúc màn hình, không định nghĩa business copy/data.

## Thư mục

```text
html/
├─ src/
│  ├─ tokens.css
│  ├─ base.css
│  ├─ components.css
│  ├─ patterns.css
│  ├─ templates.css
│  └─ vet45-ds.js
├─ contracts/
│  ├─ figma-source.json
│  ├─ component-map.json
│  ├─ pattern-map.json
│  ├─ icon-registry.json
│  ├─ variant-contracts.json
│  ├─ flutter-source.json
│  ├─ flutter-public-api.json
│  ├─ flutter-test-contracts.json
│  ├─ parity-matrix.json
│  └─ qa-baseline.json
├─ docs/
├─ showcase/
│  └─ index.html
├─ qa.sh
├─ VERSION
├─ CHANGELOG.md
└─ package.json
```

## QA

Chạy:

```bash
./qa.sh
```

QA v1.5.0 chặn trực tiếp các lỗi đã xuất hiện ở v1.4: class dùng trong catalog nhưng không có CSS; icon được tham chiếu nhưng không resolve; tên master bị đổi khỏi Figma; token visual drift khỏi live Figma; mapping Flutter bị dùng như tên thay thế. Catalog `index.html` luôn hiển thị **tên master Figma nguyên văn**. `HTML impl:` chỉ là selector triển khai, `Flutter:` chỉ là public API đối chiếu khi có quan hệ 1:1.

Mở `showcase/index.html` để kiểm tra visual catalog và 8 mobile Page Templates.


## v1.5.0 parity rule

v1.5.0 được đối chiếu thêm với Flutter DS 1.4.1 từ package dự án. Khi Figma và Flutter drift ở visual token/master, Figma thắng; Flutter là nguồn xác nhận public API, behavior, density và accessibility. Xem `docs/parity-audit-v1.5.0.md` và `contracts/parity-matrix.json`.
