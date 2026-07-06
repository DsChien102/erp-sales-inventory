import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class MissingBasePriceException extends DomainException {
  MissingBasePriceException([
    super.message = 'Chưa thiết lập giá vốn cơ sở để tính toán khung giá.',
  ]);
}
