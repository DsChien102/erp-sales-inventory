import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class NotManualBasePriceModeException extends DomainException {
  NotManualBasePriceModeException([
    super.message = 'Sản phẩm không áp dụng chế độ định giá thủ công (Manual base price mode).',
  ]);
}
