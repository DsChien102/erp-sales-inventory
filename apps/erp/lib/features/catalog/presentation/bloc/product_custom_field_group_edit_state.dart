import 'package:vet45_catalog_application/application.dart';

abstract class ProductCustomFieldGroupEditState {
  const ProductCustomFieldGroupEditState();
}

class ProductCustomFieldGroupEditInitial extends ProductCustomFieldGroupEditState {}

class ProductCustomFieldGroupEditLoading extends ProductCustomFieldGroupEditState {}

class ProductCustomFieldGroupEditLoaded extends ProductCustomFieldGroupEditState {
  const ProductCustomFieldGroupEditLoaded({
    required this.group,
    required this.inputs,
    this.isSubmitting = false,
    this.error,
    this.validationErrors = const {},
  });

  final ProductCustomFieldValueGroupDto group;
  final Map<String, ProductCustomFieldValueInput> inputs;
  final bool isSubmitting;
  final String? error;
  
  /// Key: fieldId, Value: validation error message
  final Map<String, String> validationErrors;

  ProductCustomFieldGroupEditLoaded copyWith({
    ProductCustomFieldValueGroupDto? group,
    Map<String, ProductCustomFieldValueInput>? inputs,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    Map<String, String>? validationErrors,
  }) {
    return ProductCustomFieldGroupEditLoaded(
      group: group ?? this.group,
      inputs: inputs ?? this.inputs,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class ProductCustomFieldGroupEditSuccess extends ProductCustomFieldGroupEditState {}
