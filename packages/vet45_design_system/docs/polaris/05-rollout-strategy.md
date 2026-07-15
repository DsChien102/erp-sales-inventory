# 05 — Rollout Strategy

## Nguyên tắc

1. **Pattern trước, component sau** — ship layout primitives trước khi migrate hàng loạt.
2. **Golden trước, bulk sau** — một màn hình reference đúng chuẩn > rewrite 50 file lỗi.
3. **Không big-bang** — mỗi PR một lane/feature nhỏ.
4. **DS = mechanism; module = domain chrome** — không đưa product-specific copy vào `vet45_design_system`.

## Thứ tự migrate feature

| Thứ tự | Lane | Lý do |
|--------|------|-------|
| 1 | Product Control Center | Đủ pattern: sections, cards, overlays, status |
| 2 | Catalog settings (custom fields, price rules) | Nhiều form; reuse form recipe |
| 3 | Product guided create | Multi-step; test `VPageScaffold` + bottom bar |
| 4 | Partner presentation | Module presentation path |
| 5 | Dashboard (đã khá tốt) | Chỉ align spacing/typography |

## PR strategy

| PR | Nội dung | Risk |
|----|----------|------|
| PR1 | Polaris docs + skill links | Thấp |
| PR2 | Layout primitives + example | Trung bình — API mới |
| PR3 | CI guard (allowlist rộng) | Thấp — warn trước |
| PR4 | Golden migration + thắt allowlist | Trung bình — UI only |

## Khi nào promote widget lên DS?

Promote lên `vet45_design_system` khi:

- Dùng ở ≥2 module/feature
- Không chứa domain copy (label generic OK)
- Có example coverage đủ state API

Giữ ở `modules/*/presentation` khi:

- Copy/label domain-specific
- Chỉ dùng trong một bounded context

## Rollback

Layout primitives là additive — feature cũ không break. Guard có allowlist; thắt dần sau migrate.
