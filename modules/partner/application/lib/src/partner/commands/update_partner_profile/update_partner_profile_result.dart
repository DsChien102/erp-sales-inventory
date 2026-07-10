import '../../shared/partner_warning_dto.dart';

/// Result of a successful partner profile update.
final class UpdatePartnerProfileResult {
  const UpdatePartnerProfileResult({
    required this.partnerId,
    required this.expectedVersion,
    this.warnings = const [],
  });

  final String partnerId;
  final int expectedVersion;
  final List<PartnerWarningDto> warnings;
}
