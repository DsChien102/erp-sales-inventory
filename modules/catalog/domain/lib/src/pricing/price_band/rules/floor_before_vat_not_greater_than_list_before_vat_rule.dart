import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../money.dart';

final class FloorBeforeVatNotGreaterThanListBeforeVatRule
    implements IBusinessRule {
  FloorBeforeVatNotGreaterThanListBeforeVatRule({
    required Money? floorBeforeVat,
    required Money? listBeforeVat,
  }) : _floorBeforeVat = floorBeforeVat,
       _listBeforeVat = listBeforeVat;

  final Money? _floorBeforeVat;
  final Money? _listBeforeVat;

  @override
  bool isBroken() {
    if (_floorBeforeVat == null || _listBeforeVat == null) return false;
    return _floorBeforeVat > _listBeforeVat;
  }

  @override
  String get message => 'Giá sàn không được lớn hơn Giá niêm yết (BR-04).';
}
