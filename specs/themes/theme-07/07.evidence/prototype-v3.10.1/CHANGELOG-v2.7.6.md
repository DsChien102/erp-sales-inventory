# Changelog — v2.7.6

- Reorganized BJ05 `SCR-027 — Chi tiết lấy hàng` into a denser Product → LOT task hierarchy; removed the visual impression of disconnected stacked blocks.
- Product context now uses canonical `DS v2 / List Row` Status anatomy at 64px feature density; LOT blocks use compact section rhythm with one divider between allocations.
- Reduced repeated vertical gaps around LOT header, quantity field, helper and `Đổi lô` action while preserving 44px input/action interaction requirements where applicable.
- Tightened BJ05 LOT replacement composition while preserving the canonical `VBottomSheet` shell and current business behavior.
- Desktop review stage now visually scales the decorative phone only when browser height is insufficient, while the Product viewport remains exactly `402×874` CSS px and is not resized.
