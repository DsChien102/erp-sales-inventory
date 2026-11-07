// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models.dart';

/// Lỗi hợp đồng sales như repository thật ném: `PERMISSION_DENIED` → `NO_PERMISSION`,
/// `details['blockers']` (DTO hoặc map) → danh sách map `{code, message, field}`,
/// `details` rỗng → `null`.
AppException salesContractError(
  String code, {
  String message = '',
  Map<String, Object?> details = const {},
}) {
  Map<String, dynamic>? mapped;
  if (details.isNotEmpty) {
    final rawBlockers = details['blockers'];
    if (rawBlockers is List) {
      mapped = <String, dynamic>{
        'blockers': [
          for (final b in rawBlockers)
            if (b is SalesBlockerDto)
              <String, dynamic>{'code': b.code, 'message': b.message, 'field': b.field}
            else if (b is Map)
              b.cast<String, dynamic>(),
        ],
      };
    } else {
      mapped = Map<String, dynamic>.from(details);
    }
  }
  return AppException(
    code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : code,
    serverMessage: message,
    details: mapped,
  );
}
