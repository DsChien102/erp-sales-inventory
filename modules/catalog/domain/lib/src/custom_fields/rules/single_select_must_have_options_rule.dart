import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../custom_field_type.dart';

final class SingleSelectMustHaveOptionsRule implements IBusinessRule {
  const SingleSelectMustHaveOptionsRule({
    required this.fieldType,
    required this.options,
  });

  final CustomFieldType fieldType;
  final List<String> options;

  @override
  bool isBroken() {
    if (fieldType != CustomFieldType.singleSelect) return false;
    return options.where((o) => o.trim().isNotEmpty).isEmpty;
  }

  @override
  String get message => 'Trường single select phải có ít nhất một option hợp lệ.';
}
