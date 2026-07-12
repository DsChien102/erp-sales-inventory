import 'package:vet45_catalog_domain/domain.dart';

export 'package:vet45_catalog_domain/domain.dart' show ProductBusinessStatus;

extension ProductBusinessStatusUi on ProductBusinessStatus {
  String get label {
    if (identical(this, ProductBusinessStatus.active) || isActive) {
      return 'Đang KD';
    }
    if (identical(this, ProductBusinessStatus.inactive) || isInactive) {
      return 'Ngừng KD';
    }
    return 'Đã xóa';
  }
}
