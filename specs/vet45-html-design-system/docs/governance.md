# Governance

## Authority chain

**Product/BJ/UC/UI Contract → Figma DS → HTML DS → Theme prototype → Production**

- Product documents: what/why/business behavior.
- Figma DS: canonical UI expression.
- HTML DS: executable prototype implementation of the Figma contract.
- Theme: business composition only.

## Hierarchy

Foundations → Primitives → Components → Patterns → Templates → Product UI.

Chỉ dùng lớp dưới để xây lớp trên. Không promote feature-specific UI thành shared DS chỉ vì nó lặp lại trong cùng một feature.

## Reuse-first decision

1. Component đã có?
2. Pattern đã có?
3. Template đã có?
4. Có thể compose chuẩn từ các asset trên?
5. Nếu không: DS Gap → review → bổ sung shared DS → Theme consume.

## Boundary

- Component: control/element tái sử dụng độc lập.
- Pattern: nhiều component giải quyết một composition/interaction/local layout lặp lại.
- Template: cấu trúc toàn màn hình.
- Product UI: business-specific content/composition.

Detail Patterns hiện vẫn Under Review theo source; không coi các detail specimen là canonical pattern nếu chưa đủ bằng chứng cross-domain.
