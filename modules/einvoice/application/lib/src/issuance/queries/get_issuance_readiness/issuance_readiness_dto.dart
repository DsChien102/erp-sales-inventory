import 'package:vet45_einvoice_domain/domain.dart';
import '../../../configuration/shared/readiness_blocker_dto.dart';
import '../../../configuration/shared/readiness_warning_dto.dart';

final class IssuanceReadinessDto {
  const IssuanceReadinessDto({
    required this.level,
    required this.blockers,
    required this.warnings,
    required this.buyerCompletionState,
  });

  final IssuanceReadinessLevel level;
  final List<ReadinessBlockerDto> blockers;
  final List<ReadinessWarningDto> warnings;
  final BuyerCompletionStatus buyerCompletionState;
}
