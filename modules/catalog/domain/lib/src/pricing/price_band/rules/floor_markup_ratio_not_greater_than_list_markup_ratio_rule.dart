import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class FloorMarkupRatioNotGreaterThanListMarkupRatioRule implements IBusinessRule {
  const FloorMarkupRatioNotGreaterThanListMarkupRatioRule({
    required this.listMarkupRatio,
    required this.floorMarkupRatio,
  });

  final double listMarkupRatio;
  final double? floorMarkupRatio;

  @override
  bool isBroken() => floorMarkupRatio != null && floorMarkupRatio! > listMarkupRatio;

  @override
  String get message => 'Floor markup ratio must not be greater than list markup ratio.';
}
