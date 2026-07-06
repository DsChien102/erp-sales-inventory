import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class StaleStockQuantityException extends DomainException {
  StaleStockQuantityException([
    super.message =
        'Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.',
  ]);
}
