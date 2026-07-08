import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class MissingBaseUnitException extends DomainException {
  MissingBaseUnitException([
    super.message = 'Sản phẩm bắt buộc phải thiết lập Đơn vị cơ sở trước khi thực hiện thao tác này.',
  ]);
}
