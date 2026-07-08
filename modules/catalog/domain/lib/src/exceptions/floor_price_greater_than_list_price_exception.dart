import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class FloorPriceGreaterThanListPriceException extends DomainException {
  FloorPriceGreaterThanListPriceException([
    super.message = 'Giá sàn không được lớn hơn Giá niêm yết (BR-04).',
  ]);
}
