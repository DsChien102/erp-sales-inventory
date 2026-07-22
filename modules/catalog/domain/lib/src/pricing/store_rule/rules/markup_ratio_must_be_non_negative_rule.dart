import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class MarkupRatioMustBeNonNegativeRule implements IBusinessRule {
  MarkupRatioMustBeNonNegativeRule({required this.ratio, this.label = 'Markup ratio'});

  final double ratio;
  final String label;

  @override
  bool isBroken() => ratio < 0;

  @override
  String get message => '$label phải lớn hơn hoặc bằng 0.';
}
