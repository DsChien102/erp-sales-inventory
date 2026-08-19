import 'package:equatable/equatable.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import '../support/configuration_query_failure.dart';

sealed class ProviderConnectionState extends Equatable {
  const ProviderConnectionState();

  @override
  List<Object?> get props => [];
}

final class ProviderConnectionInitial extends ProviderConnectionState {
  const ProviderConnectionInitial();
}

final class ProviderConnectionLoading extends ProviderConnectionState {
  const ProviderConnectionLoading();
}

final class ProviderConnectionLoaded extends ProviderConnectionState {
  const ProviderConnectionLoaded({
    required this.screen,
    this.reconnectMode = false,
    this.isSubmitting = false,
    this.accountError,
    this.passwordError,
  });

  final ProviderConnectionScreenDto screen;
  final bool reconnectMode;
  final bool isSubmitting;
  final String? accountError;
  final String? passwordError;

  bool get showsForm {
    if (reconnectMode) {
      return true;
    }
    final status = screen.connection.status;
    return status == ProviderConnectionStatus.disconnected ||
        status == ProviderConnectionStatus.reconnectRequired;
  }

  ProviderConnectionLoaded copyWith({
    ProviderConnectionScreenDto? screen,
    bool? reconnectMode,
    bool? isSubmitting,
    String? accountError,
    String? passwordError,
    bool clearFieldErrors = false,
  }) {
    return ProviderConnectionLoaded(
      screen: screen ?? this.screen,
      reconnectMode: reconnectMode ?? this.reconnectMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      accountError: clearFieldErrors ? accountError : accountError ?? this.accountError,
      passwordError: clearFieldErrors ? passwordError : passwordError ?? this.passwordError,
    );
  }

  @override
  List<Object?> get props => [
    screen.legalProfile.taxCode,
    screen.connection.connectionId,
    screen.connection.status,
    screen.connection.lastCheckedAt,
    reconnectMode,
    isSubmitting,
    accountError,
    passwordError,
  ];
}

final class ProviderConnectionError extends ProviderConnectionState {
  const ProviderConnectionError(this.failure);

  final ConfigurationQueryFailure failure;

  @override
  List<Object?> get props => [failure];
}
