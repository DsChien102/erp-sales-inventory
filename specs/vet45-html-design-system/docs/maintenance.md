# Maintain Figma → HTML Design System

## Luồng chuẩn

```text
Figma DS thay đổi
      ↓
Inventory source pages + variables/styles
      ↓
So diff contract/master/variant/token
      ↓
Cập nhật HTML DS
      ↓
QA parity + render showcase
      ↓
Nâng HTML DS version
      ↓
Theme nâng dependency / lock version
```

## Không cập nhật Theme trực tiếp từ thay đổi DS

Nếu Figma đổi `VListRow`, không sửa từng Theme trước. Cập nhật `spec/design-system/html`, QA, phát hành version, sau đó các Theme consume version mới.

## Release gate tối thiểu

1. 3 source pages vẫn truy cập được và đúng tên/responsibility.
2. Local variable collections/tokens được diff.
3. Exact master count không giảm/tăng mà chưa có giải thích.
4. Master mới phải có Figma node ID → HTML selector mapping.
5. Variant/state mới phải được cập nhật implementation/showcase hoặc ghi rõ gap.
6. Critical geometry (402×874 shell, 44px target, safe areas, overlay geometry) được kiểm tra.
7. `qa.sh` PASS.
8. Showcase render không có clipping/overflow bất thường.
9. Breaking change phải có migration note trong CHANGELOG.

## Versioning

- PATCH: sửa implementation nhưng không đổi public contract.
- MINOR: thêm component/pattern/template/variant tương thích ngược.
- MAJOR: thay contract hoặc migration bắt buộc cho Theme.

Figma version và HTML DS version là hai version độc lập. `contracts/figma-source.json` ghi cặp version đang đồng bộ.
