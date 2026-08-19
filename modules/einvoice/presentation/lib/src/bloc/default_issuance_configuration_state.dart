import 'package:equatable/equatable.dart';
import 'package:vet45_einvoice_application/application.dart';

import '../support/configuration_query_failure.dart';

sealed class DefaultIssuanceConfigurationState extends Equatable {
  const DefaultIssuanceConfigurationState();

  @override
  List<Object?> get props => [];
}

final class DefaultIssuanceConfigurationInitial extends DefaultIssuanceConfigurationState {
  const DefaultIssuanceConfigurationInitial();
}

final class DefaultIssuanceConfigurationLoading extends DefaultIssuanceConfigurationState {
  const DefaultIssuanceConfigurationLoading();
}

final class DefaultIssuanceConfigurationLoaded extends DefaultIssuanceConfigurationState {
  const DefaultIssuanceConfigurationLoaded({
    required this.profile,
    required this.templates,
    this.selectedTemplateId,
    this.isSubmitting = false,
    this.templateError,
  });

  final IssuanceProfileDto profile;
  final List<ProviderTemplateDto> templates;
  final String? selectedTemplateId;
  final bool isSubmitting;
  final String? templateError;

  ProviderTemplateDto? get selectedTemplate {
    final id = selectedTemplateId;
    if (id == null) {
      return null;
    }
    for (final template in templates) {
      if (template.templateId == id) {
        return template;
      }
    }
    return null;
  }

  DefaultIssuanceConfigurationLoaded copyWith({
    IssuanceProfileDto? profile,
    List<ProviderTemplateDto>? templates,
    String? selectedTemplateId,
    bool? isSubmitting,
    String? templateError,
    bool clearTemplateError = false,
  }) {
    return DefaultIssuanceConfigurationLoaded(
      profile: profile ?? this.profile,
      templates: templates ?? this.templates,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      templateError: clearTemplateError ? templateError : templateError ?? this.templateError,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    templates,
    selectedTemplateId,
    isSubmitting,
    templateError,
  ];
}

final class DefaultIssuanceConfigurationError extends DefaultIssuanceConfigurationState {
  const DefaultIssuanceConfigurationError(this.failure);

  final ConfigurationQueryFailure failure;

  @override
  List<Object?> get props => [failure];
}
