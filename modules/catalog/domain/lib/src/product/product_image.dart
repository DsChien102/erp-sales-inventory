import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductImage extends ValueObject {
  const ProductImage({
    required this.storageKey,
    this.slotId,
    this.url,
    required this.isPrimary,
    required this.sortOrder,
  });

  final String storageKey;
  final String? slotId;
  final String? url;
  final bool isPrimary;
  final int sortOrder;

  @override
  List<Object?> get props => [storageKey, slotId, url, isPrimary, sortOrder];
}
