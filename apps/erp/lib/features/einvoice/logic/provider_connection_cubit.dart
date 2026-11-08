import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/configuration_query_failure.dart';
import 'package:erp/features/einvoice/logic/provider_connection_copy.dart';
import 'package:erp/features/einvoice/logic/provider_connection_state.dart';

enum ProviderConnectionSubmitResult {
  verificationPending,
  connected,
  reconnected,
  disconnected,
  verified,
  validationFailed,
  authFailed,
  unavailable,
  failed,
}

class ProviderConnectionCubit extends Cubit<ProviderConnectionState> {
  ProviderConnectionCubit({
    required EInvoiceConfigurationRepository repository,
    this.pollInterval = const Duration(seconds: 2),
  })  : _repository = repository,
        super(const ProviderConnectionInitial());

  final EInvoiceConfigurationRepository _repository;
  final Duration pollInterval;
  Timer? _pollTimer;
  bool _pollInFlight = false;

  void _syncPolling(ProviderConnectionState next) {
    final pending = next is ProviderConnectionLoaded &&
        next.screen.connection.status == ProviderConnectionStatus.checkRequired;
    if (pending) {
      if (_pollTimer == null && !isClosed) {
        _pollTimer = Timer.periodic(pollInterval, (_) => _pollOnce());
      }
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _pollOnce() async {
    if (_pollInFlight || isClosed) return;
    _pollInFlight = true;
    try {
      final screen = await _repository.getConnectionScreen();
      if (isClosed) return;
      final current = state;
      if (current is ProviderConnectionLoaded &&
          screen.connection.status != current.screen.connection.status) {
        updateScreenFromQuery(screen);
      }
    } catch (_) {
      // Nuốt lỗi khi hỏi lại theo spec
    } finally {
      _pollInFlight = false;
    }
  }

  @override
  void onChange(Change<ProviderConnectionState> change) {
    super.onChange(change);
    _syncPolling(change.nextState);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }

  void updateScreenFromQuery(ProviderConnectionScreenDto screen) {
    if (isClosed) return;
    final current = state;
    if (current is ProviderConnectionLoaded) {
      // Keep reconnectMode and errors if user is currently typing in form
      if (current.reconnectMode) {
        emit(
          current.copyWith(
            screen: screen,
          ),
        );
      } else {
        emit(
          current.copyWith(
            screen: screen,
            isSubmitting: false,
          ),
        );
      }
    } else {
      emit(ProviderConnectionLoaded(screen: screen));
    }
  }

  Future<void> load() async {
    emit(const ProviderConnectionLoading());
    try {
      final screen = await _repository.getConnectionScreen();
      if (isClosed) {
        return;
      }
      emit(ProviderConnectionLoaded(screen: screen));
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(ProviderConnectionError(mapConfigurationQueryFailure(error)));
    }
  }

  void enterReconnectMode() {
    final current = state;
    if (current is! ProviderConnectionLoaded) {
      return;
    }
    emit(current.copyWith(reconnectMode: true, clearFieldErrors: true));
  }

  Future<ProviderConnectionSubmitResult> connect({
    required String account,
    required String password,
  }) {
    return _submitCredentials(
      account: account,
      password: password,
      reconnect: false,
    );
  }

  Future<ProviderConnectionSubmitResult> reconnect({
    required String account,
    required String password,
  }) {
    return _submitCredentials(
      account: account,
      password: password,
      reconnect: true,
    );
  }

  Future<ProviderConnectionSubmitResult> disconnect() async {
    final current = state;
    if (current is! ProviderConnectionLoaded) {
      return ProviderConnectionSubmitResult.failed;
    }
    final connectionId = current.screen.connection.connectionId;
    if (connectionId == null || connectionId.isEmpty) {
      return ProviderConnectionSubmitResult.failed;
    }

    emit(current.copyWith(isSubmitting: true));
    try {
      final result = await _repository.disconnect(
        connectionId: connectionId,
        confirm: true,
      );
      if (isClosed) {
        return ProviderConnectionSubmitResult.failed;
      }
      final updatedScreen = ProviderConnectionScreenDto(
        legalProfile: current.screen.legalProfile,
        connection: ProviderConnectionSummaryDto(
          connectionId: result.connectionId,
          status: result.status,
          lastCheckedAt: current.screen.connection.lastCheckedAt,
          maskedAccount: null,
          connectionVersion: null,
        ),
      );
      emit(
        current.copyWith(
          isSubmitting: false,
          reconnectMode: false,
          clearFieldErrors: true,
          screen: updatedScreen,
        ),
      );
      return ProviderConnectionSubmitResult.disconnected;
    } catch (_) {
      _emitIdle(current);
      return ProviderConnectionSubmitResult.failed;
    }
  }

  Future<ProviderConnectionSubmitResult> _submitCredentials({
    required String account,
    required String password,
    required bool reconnect,
  }) async {
    final current = state;
    if (current is! ProviderConnectionLoaded) {
      return ProviderConnectionSubmitResult.failed;
    }

    final trimmedAccount = account.trim();
    final accountError = trimmedAccount.isEmpty ? ProviderConnectionCopy.accountRequired : null;
    final passwordError = password.isEmpty ? ProviderConnectionCopy.passwordRequired : null;
    if (accountError != null || passwordError != null) {
      emit(
        current.copyWith(
          accountError: accountError,
          passwordError: passwordError,
          clearFieldErrors: true,
        ),
      );
      return ProviderConnectionSubmitResult.validationFailed;
    }

    emit(current.copyWith(isSubmitting: true, clearFieldErrors: true));
    try {
      final ProviderConnectionResultDto result;
      if (reconnect) {
        final connectionId = current.screen.connection.connectionId;
        if (connectionId == null || connectionId.isEmpty) {
          _emitIdle(current);
          return ProviderConnectionSubmitResult.failed;
        }
        result = await _repository.reconnect(
          connectionId: connectionId,
          username: trimmedAccount,
          password: password,
          expectedConnectionVersion: current.screen.connection.connectionVersion,
        );
      } else {
        result = await _repository.connect(
          username: trimmedAccount,
          password: password,
        );
      }
      if (isClosed) {
        return ProviderConnectionSubmitResult.failed;
      }
      final updatedScreen = ProviderConnectionScreenDto(
        legalProfile: current.screen.legalProfile,
        connection: ProviderConnectionSummaryDto(
          connectionId: result.connectionId,
          status: result.status,
          lastCheckedAt: current.screen.connection.lastCheckedAt,
          maskedAccount: ProviderConnectionCopy.maskAccount(trimmedAccount),
          connectionVersion: current.screen.connection.connectionVersion,
        ),
      );
      emit(
        current.copyWith(
          isSubmitting: false,
          reconnectMode: false,
          clearFieldErrors: true,
          screen: updatedScreen,
        ),
      );
      if (result.status == ProviderConnectionStatus.checkRequired) {
        return ProviderConnectionSubmitResult.verificationPending;
      }
      return reconnect
          ? ProviderConnectionSubmitResult.reconnected
          : ProviderConnectionSubmitResult.connected;
    } on AppException catch (e) {
      _emitIdle(current);
      if (e.code == EInvoiceErrorCodes.providerAuthFailed) {
        return ProviderConnectionSubmitResult.authFailed;
      }
      return ProviderConnectionSubmitResult.failed;
    } catch (_) {
      _emitIdle(current);
      return ProviderConnectionSubmitResult.failed;
    }
  }

  void _emitIdle(ProviderConnectionLoaded current) {
    if (isClosed) {
      return;
    }
    emit(current.copyWith(isSubmitting: false));
  }
}
