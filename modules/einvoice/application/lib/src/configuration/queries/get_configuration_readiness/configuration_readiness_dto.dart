import 'package:vet45_einvoice_domain/domain.dart';
import '../../shared/readiness_blocker_dto.dart';
import '../../shared/readiness_warning_dto.dart';

final class ConfigurationReadinessDto {
  const ConfigurationReadinessDto({
    required this.level,
    required this.blockers,
    required this.warnings,
  });

  final ConfigurationReadinessLevel level;
  final List<ReadinessBlockerDto> blockers;
  final List<ReadinessWarningDto> warnings;
}
