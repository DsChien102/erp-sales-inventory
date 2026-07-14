import '../../shared/partner_warning_dto.dart';

/// Result of a successful partner create mutation.
final class CreatePartnerResult {
  const CreatePartnerResult({
    required this.partnerId,
    this.warnings = const [],
  });

  final String partnerId;
  final List<PartnerWarningDto> warnings;
}
