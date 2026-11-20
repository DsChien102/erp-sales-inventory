import '../../data/models/catalog_enums.dart';

export '../../data/models/catalog_enums.dart' show ProductBusinessStatus;

extension ProductBusinessStatusUi on ProductBusinessStatus {
  bool get isActive => this == ProductBusinessStatus.active;
  bool get isInactive => this == ProductBusinessStatus.inactive;
  bool get isSoftDeleted => this == ProductBusinessStatus.softDeleted;

  String get label {
    if (this == ProductBusinessStatus.active) {
      return 'Đang KD';
    }
    if (this == ProductBusinessStatus.inactive) {
      return 'Ngừng KD';
    }
    return 'Đã xóa';
  }
}
