import '../product_image.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class AtMostOnePrimaryImageRule implements IBusinessRule {
  AtMostOnePrimaryImageRule(this._images);

  final List<ProductImage> _images;

  @override
  bool isBroken() =>
      _images.where((image) => image.isPrimary).length > 1;

  @override
  String get message => 'A product may have at most one primary image.';
}
