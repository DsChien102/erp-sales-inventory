import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class NotBasicStockModeException extends DomainException {
  NotBasicStockModeException([
    super.message = 'Sản phẩm không áp dụng chế độ tồn kho cơ bản (Basic stock mode).',
  ]);
}
