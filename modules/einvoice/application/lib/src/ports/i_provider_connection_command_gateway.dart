import '../configuration/commands/connect_provider/connect_provider_command.dart';
import '../configuration/commands/connect_provider/connect_provider_result.dart';
import '../configuration/commands/disconnect_provider/disconnect_provider_command.dart';
import '../configuration/commands/record_connection_verified/record_connection_verified_command.dart';
import '../configuration/commands/reconnect_provider/reconnect_provider_command.dart';
import '../configuration/commands/verify_provider_connection/verify_provider_connection_command.dart';
import '../configuration/commands/verify_provider_connection/verify_provider_connection_result.dart';

/// Mutations for provider connection lifecycle.
abstract interface class IProviderConnectionCommandGateway {
  Future<ProviderConnectionResultDto> connect(ConnectProviderCommand command);

  Future<ProviderConnectionCheckResultDto> verify(
    VerifyProviderConnectionCommand command,
  );

  Future<ProviderConnectionResultDto> reconnect(
    ReconnectProviderCommand command,
  );

  Future<ProviderConnectionResultDto> disconnect(
    DisconnectProviderCommand command,
  );

  Future<ProviderConnectionResultDto> recordConnectionVerified(
    RecordConnectionVerifiedCommand command,
  );
}
