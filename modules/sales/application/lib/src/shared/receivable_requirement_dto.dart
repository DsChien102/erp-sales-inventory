import 'money_dto.dart';

final class ReceivableRequirementDto {
  const ReceivableRequirementDto({
    required this.isRequired,
    required this.amount,
    this.customerId,
  });

  final bool isRequired;
  final MoneyDto amount;
  final String? customerId;
}
