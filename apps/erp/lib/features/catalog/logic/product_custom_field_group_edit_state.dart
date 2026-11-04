import 'package:erp/features/catalog/data/models.dart';

abstract class ProductCustomFieldGroupEditState {
  const ProductCustomFieldGroupEditState();
}

class ProductCustomFieldGroupEditInitial extends ProductCustomFieldGroupEditState {}

class ProductCustomFieldGroupEditLoading extends ProductCustomFieldGroupEditState {}

class ProductCustomFieldGroupEditLoaded extends ProductCustomFieldGroupEditState {
  const ProductCustomFieldGroupEditLoaded({
    required this.group,
    required this.inputs,
    this.initialInputs = const {},
    this.isSubmitting = false,
    this.error,
    this.validationErrors = const {},
  });

  final ProductCustomFieldValueGroupDto group;
  final Map<String, ProductCustomFieldValueInput> inputs;
  final Map<String, ProductCustomFieldValueInput> initialInputs;
  final bool isSubmitting;
  final String? error;

  /// Key: fieldId, Value: validation error message
  final Map<String, String> validationErrors;

  bool get hasChanges {
    if (inputs.length != initialInputs.length) return true;
    for (final entry in inputs.entries) {
      final initial = initialInputs[entry.key];
      if (initial == null) return true;
      if (!_sameInput(entry.value, initial)) return true;
    }
    return false;
  }

  static bool _sameInput(
    ProductCustomFieldValueInput a,
    ProductCustomFieldValueInput b,
  ) {
    return a.fieldId == b.fieldId &&
        (a.textValue ?? '').trim() == (b.textValue ?? '').trim() &&
        a.numberValue == b.numberValue &&
        a.dateValue == b.dateValue &&
        a.booleanValue == b.booleanValue &&
        (a.optionId ?? '') == (b.optionId ?? '');
  }

  ProductCustomFieldGroupEditLoaded copyWith({
    ProductCustomFieldValueGroupDto? group,
    Map<String, ProductCustomFieldValueInput>? inputs,
    Map<String, ProductCustomFieldValueInput>? initialInputs,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    Map<String, String>? validationErrors,
  }) {
    return ProductCustomFieldGroupEditLoaded(
      group: group ?? this.group,
      inputs: inputs ?? this.inputs,
      initialInputs: initialInputs ?? this.initialInputs,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class ProductCustomFieldGroupEditSuccess extends ProductCustomFieldGroupEditState {}
