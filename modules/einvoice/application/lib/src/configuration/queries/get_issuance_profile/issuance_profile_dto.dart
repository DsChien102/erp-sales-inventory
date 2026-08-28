import 'package:vet45_einvoice_domain/domain.dart';

final class IssuanceProfileDto {
  const IssuanceProfileDto({
    required this.profileVersion,
    this.templateId,
    this.signingConfigId,
    this.signingMethod,
    required this.compatibilityWarnings,
  });

  final int profileVersion;
  final String? templateId;
  final String? signingConfigId;
  final SigningMethod? signingMethod;
  final List<String> compatibilityWarnings;
}
