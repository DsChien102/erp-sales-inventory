import 'package:equatable/equatable.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/configuration_query_failure.dart';

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

/// Non-form provider connection surfaces on the same page (D04-B/C/D).
enum ProviderConnectionInfoKind {
  connected,
  pending,
  error,
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

  /// D04-A form: disconnected, or reconnect mode entered from D04-D.
  bool get showsForm {
    if (reconnectMode) {
      return true;
    }
    return screen.connection.status == ProviderConnectionStatus.disconnected;
  }

  /// Presentation surface for non-form connection states.
  ProviderConnectionInfoKind? get infoKind {
    if (showsForm) {
      return null;
    }
    return switch (screen.connection.status) {
      ProviderConnectionStatus.connected => ProviderConnectionInfoKind.connected,
      ProviderConnectionStatus.checkRequired => ProviderConnectionInfoKind.pending,
      ProviderConnectionStatus.reconnectRequired => ProviderConnectionInfoKind.error,
      ProviderConnectionStatus.disconnected => null,
    };
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
        screen.connection.maskedAccount,
        screen.connection.connectionVersion,
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
