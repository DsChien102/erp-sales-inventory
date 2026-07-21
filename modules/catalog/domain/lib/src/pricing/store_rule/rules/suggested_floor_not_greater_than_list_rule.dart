import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class SuggestedFloorNotGreaterThanListRule implements IBusinessRule {
  SuggestedFloorNotGreaterThanListRule({
    required this.basePrice,
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
  });

  final double basePrice;
  final double listMarkupRatio;
  final double floorMarkupRatio;

  @override
  bool isBroken() {
    final listPrice = (basePrice * (1 + listMarkupRatio)).roundToDouble();
    final floorPrice = (basePrice * (1 + floorMarkupRatio)).roundToDouble();
    return floorPrice > listPrice;
  }

  @override
  String get message =>
      'Giá sàn không được lớn hơn giá niêm yết.';
}
