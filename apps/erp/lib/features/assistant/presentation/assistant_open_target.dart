import 'package:erp/features/assistant/data.dart';

String? assistantOpenLocation(OpenTarget target) {
  final id = target.id.trim();
  if (id.isEmpty) return null;
  final encoded = Uri.encodeComponent(id);
  return switch (target.loai) {
    'san_pham' => '/products/items/$encoded/view',
    'khach_hang' => '/partner/$encoded',
    'don_ban' => '/sales/orders/$encoded',
    _ => null,
  };
}
