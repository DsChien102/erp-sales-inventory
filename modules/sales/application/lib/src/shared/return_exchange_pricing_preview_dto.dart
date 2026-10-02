import 'money_dto.dart';

final class ReturnExchangePricingLineInput {
  const ReturnExchangePricingLineInput({required this.productId, required this.productUnitId});

  final String productId;
  final String productUnitId;
}

final class ReturnExchangePricedLineDto {
  const ReturnExchangePricedLineDto({
    required this.productUnitId,
    required this.unitPrice,
    required this.sourceCode,
    this.warningCodes = const [],
  });

  final String productUnitId;
  final MoneyDto unitPrice;
  final String sourceCode;
  final List<String> warningCodes;
}

final class ReturnExchangePricingPreviewDto {
  const ReturnExchangePricingPreviewDto({required this.lines});

  final List<ReturnExchangePricedLineDto> lines;
}
