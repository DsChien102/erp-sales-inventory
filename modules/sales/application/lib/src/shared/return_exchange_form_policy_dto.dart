import 'return_exchange_policy_option_dto.dart';

final class ReturnExchangeFormPolicyDto {
  ReturnExchangeFormPolicyDto({
    required List<ReturnExchangePolicyOptionDto> reasons,
    required List<ReturnExchangePolicyOptionDto> conditions,
  }) : reasons = List.unmodifiable(reasons),
       conditions = List.unmodifiable(conditions);

  final List<ReturnExchangePolicyOptionDto> reasons;
  final List<ReturnExchangePolicyOptionDto> conditions;
}
