import 'package:vet45_einvoice_domain/domain.dart';

final class IssuanceAttemptStatusDto {
  const IssuanceAttemptStatusDto({
    required this.attemptId,
    required this.status,
    this.lastErrorMessage,
  });

  final String attemptId;
  final IssuanceAttemptStatus status;
  final String? lastErrorMessage;
}
