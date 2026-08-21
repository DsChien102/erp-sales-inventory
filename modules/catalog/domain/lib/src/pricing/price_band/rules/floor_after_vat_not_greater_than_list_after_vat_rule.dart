import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class FloorAfterVatNotGreaterThanListAfterVatRule implements IBusinessRule {
  FloorAfterVatNotGreaterThanListAfterVatRule({
    required Money? floorAfterVat,
    required Money? listAfterVat,
  }) : _floorAfterVat = floorAfterVat,
       _listAfterVat = listAfterVat;

  final Money? _floorAfterVat;
  final Money? _listAfterVat;

  @override
  bool isBroken() {
    if (_floorAfterVat == null || _listAfterVat == null) return false;
    return _floorAfterVat > _listAfterVat;
  }

  @override
  String get message => 'Giá sàn sau VAT không được lớn hơn Giá niêm yết sau VAT.';
}
