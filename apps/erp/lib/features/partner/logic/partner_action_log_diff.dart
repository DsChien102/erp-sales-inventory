import 'package:equatable/equatable.dart';

/// How a field changed between the two audit snapshots.
enum PartnerFieldChangeKind {
  /// Field had no value before and has one now.
  added,

  /// Field had a value before and is now empty.
  removed,

  /// Field value was replaced by another value.
  modified,
}

/// One human-readable field change extracted from audit snapshots.
class PartnerFieldChange extends Equatable {
  const PartnerFieldChange({
    required this.label,
    required this.before,
    required this.after,
    required this.kind,
  });

  final String label;
  final String before;
  final String after;
  final PartnerFieldChangeKind kind;

  @override
  List<Object?> get props => [label, before, after, kind];
}

/// Computes field-by-field changes between `before_state` / `after_state`
/// snapshots of `partner_action_logs` (shape of `partner.v_partner_detail`).
class PartnerActionLogDiff {
  const PartnerActionLogDiff._();

  static const emptyValueLabel = '(trống)';

  /// Snapshot keys that are technical/bookkeeping — never shown to users.
  static const _ignoredKeys = {
    'partner_id',
    'tenant_id',
    'expected_version',
    'created_at',
    'updated_at',
    // Contact links are audited via add_contact/remove_contact actions;
    // detailed contact diff is out of scope.
    'contacts',
  };

  static const _fieldLabels = <String, String>{
    'display_name': 'Tên hiển thị',
    'partner_type': 'Loại đối tác',
    'status': 'Trạng thái',
    'roles': 'Vai trò',
    'title': 'Danh xưng',
    'full_name': 'Họ và tên',
    'nickname': 'Tên thường gọi',
    'phone': 'SĐT chính',
    'phone2': 'SĐT phụ',
    'email': 'Email',
    'tax_code': 'MST',
    'note': 'Ghi chú',
    'organization_type': 'Loại tổ chức',
    'organization_name': 'Tên tổ chức',
    'short_name': 'Tên viết tắt',
    'intl_name': 'Tên quốc tế',
    'company_address': 'Địa chỉ công ty',
    'invoice.name': 'Tên xuất hóa đơn',
    'invoice.address': 'Địa chỉ xuất hóa đơn',
    'invoice.email': 'Email nhận hóa đơn',
    'delivery.province': 'Tỉnh/TP giao hàng',
    'delivery.commune': 'Phường/Xã giao hàng',
    'delivery.address': 'Địa chỉ giao hàng',
  };

  static const _valueLabels = <String, String>{
    'person': 'Cá nhân',
    'organization': 'Tổ chức',
    'active': 'Đang hoạt động',
    'inactive': 'Ngừng hoạt động',
    'deleted': 'Đã xóa',
    'customer': 'Khách hàng',
    'supplier': 'Nhà cung cấp',
    'company': 'Công ty',
    'business_household': 'Hộ kinh doanh',
    'other': 'Khác',
  };

  static List<PartnerFieldChange> compute(
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  ) {
    if (before == null || after == null) return const [];

    final beforeFlat = _flatten(before);
    final afterFlat = _flatten(after);
    final keys = <String>{...beforeFlat.keys, ...afterFlat.keys};

    final changes = <PartnerFieldChange>[];
    for (final key in keys) {
      final oldValue = _format(beforeFlat[key]);
      final newValue = _format(afterFlat[key]);
      if (oldValue == newValue) continue;
      final kind = oldValue == emptyValueLabel
          ? PartnerFieldChangeKind.added
          : newValue == emptyValueLabel
          ? PartnerFieldChangeKind.removed
          : PartnerFieldChangeKind.modified;
      changes.add(
        PartnerFieldChange(
          label: _labelFor(key),
          before: oldValue,
          after: newValue,
          kind: kind,
        ),
      );
    }

    changes.sort((a, b) => a.label.compareTo(b.label));
    return changes;
  }

  /// Flattens nested snapshot maps into dotted keys, dropping the
  /// profile wrapper segment so person/organization share field labels
  /// (`person_profile.invoice.name` → `invoice.name`).
  static Map<String, Object?> _flatten(
    Map<String, dynamic> source, [
    String prefix = '',
  ]) {
    final result = <String, Object?>{};
    source.forEach((key, value) {
      if (prefix.isEmpty && _ignoredKeys.contains(key)) return;
      final isProfileWrapper =
          prefix.isEmpty && (key == 'person_profile' || key == 'organization_profile');
      final path = isProfileWrapper
          ? ''
          : prefix.isEmpty
          ? key
          : '$prefix.$key';
      if (value is Map) {
        result.addAll(_flatten(value.cast<String, dynamic>(), path));
      } else {
        result[path] = value;
      }
    });
    return result;
  }

  static String _labelFor(String key) {
    final label = _fieldLabels[key];
    if (label != null) return label;
    // Fall back to the last segment so unknown/new fields still render.
    final leaf = key.split('.').last;
    return _fieldLabels[leaf] ?? leaf;
  }

  static String _format(Object? value) {
    if (value == null) return emptyValueLabel;
    if (value is List) {
      if (value.isEmpty) return emptyValueLabel;
      return value.map((v) => _format(v)).join(', ');
    }
    final text = value.toString().trim();
    if (text.isEmpty) return emptyValueLabel;
    return _valueLabels[text] ?? text;
  }
}
