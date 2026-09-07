import 'package:async_query/async_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../support/configuration_query_failure.dart';
import '../support/einvoice_query_keys.dart';
import '../support/provider_connection_copy.dart';
import 'provider_connection_state.dart';

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

final class ProviderConnectionCubit extends Cubit<ProviderConnectionState> {
  ProviderConnectionCubit({
    required IEInvoiceModule einvoiceModule,
    required IExecutionContext executionContext,
    QueryClient? queryClient,
  }) : _einvoiceModule = einvoiceModule,
       _executionContext = executionContext,
       _queryClient = queryClient,
       super(const ProviderConnectionInitial());

  final IEInvoiceModule _einvoiceModule;
  final IExecutionContext _executionContext;
  final QueryClient? _queryClient;

  IEInvoiceModule get einvoiceModule => _einvoiceModule;
  IExecutionContext get executionContext => _executionContext;

  Future<void> _setConnectionQueryData(ProviderConnectionScreenDto screen) async {
    final client = _queryClient;
    if (client == null) return;
    try {
      client.setQueryData(
        EinvoiceQueryKeys.providerConnection('current-tenant'),
        screen,
      );
    } catch (_) {}
  }

  Future<void> _invalidateConnectionQuery() async {
    final client = _queryClient;
    if (client == null) return;
    try {
      await client.invalidateQueries(
        queryKey: EinvoiceQueryKeys.providerConnection('current-tenant'),
      );
    } catch (_) {}
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

  void updateErrorFromQuery(Object error) {
    if (isClosed) return;
    final current = state;
    if (current is! ProviderConnectionLoaded) {
      emit(ProviderConnectionError(mapConfigurationQueryFailure(error)));
    }
  }

  Future<void> load() async {
    emit(const ProviderConnectionLoading());
    try {
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final screen = await _einvoiceModule.executeQueryAsync(
        GetProviderConnectionScreenQuery(tenantId: tenantId, actorId: actorId),
      );
      if (isClosed) {
        return;
      }
      await _setConnectionQueryData(screen);
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

  Future<ProviderConnectionSubmitResult> recheck() async {
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final result = await _einvoiceModule.executeCommandAsync(
        VerifyProviderConnectionCommand(
          tenantId: tenantId,
          actorId: actorId,
          connectionId: connectionId,
        ),
      );
      if (isClosed) {
        return ProviderConnectionSubmitResult.failed;
      }
      final updatedScreen = ProviderConnectionScreenDto(
        legalProfile: current.screen.legalProfile,
        connection: ProviderConnectionSummaryDto(
          connectionId: result.connectionId,
          status: result.status,
          lastCheckedAt: result.checkedAt,
          maskedAccount: current.screen.connection.maskedAccount,
          connectionVersion: current.screen.connection.connectionVersion,
        ),
      );
      emit(
        current.copyWith(
          isSubmitting: false,
          screen: updatedScreen,
        ),
      );
      await _setConnectionQueryData(updatedScreen);
      await _invalidateConnectionQuery();
      return ProviderConnectionSubmitResult.verified;
    } on ProviderUnavailableException {
      _emitIdle(current);
      return ProviderConnectionSubmitResult.unavailable;
    } catch (_) {
      _emitIdle(current);
      return ProviderConnectionSubmitResult.failed;
    }
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final result = await _einvoiceModule.executeCommandAsync(
        DisconnectProviderCommand(
          tenantId: tenantId,
          actorId: actorId,
          connectionId: connectionId,
          confirm: true,
        ),
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
      await _setConnectionQueryData(updatedScreen);
      await _invalidateConnectionQuery();
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
      final tenantId = await _executionContext.requireTenantId();
      final actorId = await _executionContext.requireUserId();
      final ProviderConnectionResultDto result;
      if (reconnect) {
        final connectionId = current.screen.connection.connectionId;
        if (connectionId == null || connectionId.isEmpty) {
          _emitIdle(current);
          return ProviderConnectionSubmitResult.failed;
        }
        result = await _einvoiceModule.executeCommandAsync(
          ReconnectProviderCommand(
            tenantId: tenantId,
            actorId: actorId,
            connectionId: connectionId,
            username: trimmedAccount,
            password: password,
            expectedConnectionVersion: current.screen.connection.connectionVersion,
          ),
        );
      } else {
        result = await _einvoiceModule.executeCommandAsync(
          ConnectProviderCommand(
            tenantId: tenantId,
            actorId: actorId,
            username: trimmedAccount,
            password: password,
          ),
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
      await _setConnectionQueryData(updatedScreen);
      await _invalidateConnectionQuery();
      if (result.status == ProviderConnectionStatus.checkRequired) {
        return ProviderConnectionSubmitResult.verificationPending;
      }
      return reconnect
          ? ProviderConnectionSubmitResult.reconnected
          : ProviderConnectionSubmitResult.connected;
    } on ProviderAuthFailedException {
      _emitIdle(current);
      return ProviderConnectionSubmitResult.authFailed;
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
