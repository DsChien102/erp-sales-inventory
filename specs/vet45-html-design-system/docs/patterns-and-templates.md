# Patterns & Templates

## Pattern

Giải quyết recurring local composition, interaction hoặc layout problem. Pattern compose canonical Components; không encode business entity/status thành canonical structure.

Canonical families hiện hành:

- Page Structure
- Layout
- Responsive
- Interaction & Overlay
- List
- Form
- State
- Detail Patterns — **Under Review**

## State scope

Full-page → Section-level → Inline. Dùng scope nhỏ nhất mô tả chính xác vùng bị ảnh hưởng.

- Initial Empty = dataset chưa có dữ liệu.
- No Results = dữ liệu có thể tồn tại nhưng query/filter không tìm thấy.
- Error giữ recovery action gần failure và giữ unaffected context.
- Blocking Loading chỉ khi task không thể tiếp tục.

## Page Templates

Tám archetype source:

1. Mobile / Root List
2. Mobile / Nested List
3. Mobile / Detail
4. Mobile / Form
5. Mobile / Wizard
6. Mobile / Search & Select
7. Mobile / State
8. Mobile / Identity

Tất cả source master dùng frame 402×874. Template quyết định structure, không quyết định business copy/data.
