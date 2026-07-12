import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../floor_price.dart';
import '../../list_price.dart';

final class FloorPriceNotGreaterThanListPriceRule implements IBusinessRule {
  FloorPriceNotGreaterThanListPriceRule({
    required FloorPrice? floorPrice,
    required ListPrice? listPrice,
  }) : _floorPrice = floorPrice,
       _listPrice = listPrice;

  final FloorPrice? _floorPrice;
  final ListPrice? _listPrice;

  @override
  bool isBroken() {
    if (_floorPrice == null || _listPrice == null) return false;
    return _floorPrice.amount > _listPrice.amount;
  }

  @override
  String get message => 'Giá sàn không được lớn hơn Giá niêm yết (BR-04).';
}
