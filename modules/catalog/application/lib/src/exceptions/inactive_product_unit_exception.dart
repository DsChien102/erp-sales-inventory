import 'package:vet45_shared_application/application.dart';

final class InactiveProductUnitException extends ApplicationException {
  InactiveProductUnitException([
    super.message = 'Đơn vị bán đang không hoạt động.',
  ]);
}
