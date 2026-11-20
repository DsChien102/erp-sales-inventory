import 'package:equatable/equatable.dart';
import 'package:erp/features/catalog/data/models.dart';

class CustomFieldConfigState extends Equatable {
  final bool isLoading;
  final List<CustomFieldGroupConfigDto> groups;
  final String? error;
  final bool isSaving;

  const CustomFieldConfigState({
    this.isLoading = false,
    this.groups = const [],
    this.error,
    this.isSaving = false,
  });

  CustomFieldConfigState copyWith({
    bool? isLoading,
    List<CustomFieldGroupConfigDto>? groups,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return CustomFieldConfigState(
      isLoading: isLoading ?? this.isLoading,
      groups: groups ?? this.groups,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [isLoading, groups, error, isSaving];
}
