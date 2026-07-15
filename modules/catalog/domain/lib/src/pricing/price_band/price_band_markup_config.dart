import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../store_rule/rules/markup_ratio_must_be_non_negative_rule.dart';
import 'rules/floor_markup_ratio_not_greater_than_list_markup_ratio_rule.dart';

final class PriceBandMarkupConfig extends ValueObject {
  PriceBandMarkupConfig({
    required this.listMarkupRatio,
    this.floorMarkupRatio,
  }) {
    ValueObject.checkRule(
      MarkupRatioMustBeNonNegativeRule(
        ratio: listMarkupRatio,
        label: 'List markup ratio',
      ),
    );
    if (floorMarkupRatio != null) {
      ValueObject.checkRule(
        MarkupRatioMustBeNonNegativeRule(
          ratio: floorMarkupRatio!,
          label: 'Floor markup ratio',
        ),
      );
    }
    ValueObject.checkRule(
      FloorMarkupRatioNotGreaterThanListMarkupRatioRule(
        listMarkupRatio: listMarkupRatio,
        floorMarkupRatio: floorMarkupRatio,
      ),
    );
  }

  final double listMarkupRatio;
  final double? floorMarkupRatio;

  @override
  List<Object?> get props => [listMarkupRatio, floorMarkupRatio];
}
