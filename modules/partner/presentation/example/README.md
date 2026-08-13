# Partner presentation example

Flutter catalog app để **preview / audit** widget của bounded context Partner trước khi gắn vào `apps/erp`.

Không phải ERP shell. Không gọi live Supabase. Không cần `env:doctor`.

Đây là **golden layout** cho module presentation example — clone thư mục này khi catalog/pricing/sales bắt đầu ship FE widgets.

## Chạy

```bash
vet45 run partner_presentation debug
vet45 run partner_presentation debug:web
vet45 run partner_presentation debug:ios

cd modules/partner/presentation/example
flutter pub get
flutter run
```

VS Code: **Run and Debug** → `Partner presentation · example`.

```bash
cd modules/partner/presentation/example && flutter analyze
```

## Tabs

| Tab | Nội dung |
| --- | --- |
| Overview | Intro + coverage checklist |
| List | Tile, skeleton, search, filters, sort, ward |
| Detail | DetailView (Fake DI), cards, banners, feedback |
| Create | Action sheet, CreateForm (Fake DI), duplicate, toasts, leave |
| Contact | Contacts card, sheets, ContactForm states, SelectList |
| Transform | Step one, preview, banners, blocked, confirmation, toast |
| Sheets | Detail actions + status/delete confirmation sheets |

Public reusable widget mới trong `modules/partner/presentation/lib` → **cùng PR** thêm `PreviewSection` dưới tab phù hợp.
