import '../configuration/commands/set_default_issuance_configuration/set_default_issuance_configuration_command.dart';
import '../configuration/queries/get_issuance_profile/issuance_profile_dto.dart';

/// Issuance profile read/write port.
abstract interface class IIssuanceProfileGateway {
  Future<IssuanceProfileDto> getProfile({
    required String tenantId,
    required String actorId,
  });

  Future<IssuanceProfileDto> setDefaultConfiguration(
    SetDefaultIssuanceConfigurationCommand command,
  );
}
