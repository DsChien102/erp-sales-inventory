import '../../shared/legal_profile_summary_dto.dart';
import '../../shared/provider_connection_summary_dto.dart';

final class ProviderConnectionScreenDto {
  const ProviderConnectionScreenDto({
    required this.legalProfile, required this.connection,
  });

  final LegalProfileSummaryDto legalProfile;
  final ProviderConnectionSummaryDto connection;
}
