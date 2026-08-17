import '../../shared/effective_buyer_preview_dto.dart';

final class BuyerCompletionResultDto {
  const BuyerCompletionResultDto({
    required this.locked, required this.effectiveBuyer,
  });

  final bool locked;
  final EffectiveBuyerPreviewDto effectiveBuyer;
}
