import 'package:crypto/crypto.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../ids/product_id.dart';

final class ProductReferenceId extends ValueObject {
  ProductReferenceId(String value) : value = value.trim() {
    if (this.value.isEmpty) {
      throw DomainException('Product reference id must not be empty.');
    }
    if (this.value.length < 3 || this.value.length > 32) {
      throw DomainException(
        'Product reference id must be between 3 and 32 characters.',
      );
    }
    if (!_pattern.hasMatch(this.value)) {
      throw DomainException(
        'Product reference id contains invalid characters.',
      );
    }
  }

  static final RegExp _pattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$');

  final String value;

  factory ProductReferenceId.fromProductId(ProductId id) {
    final bytes = _uuidBytes(id.value);
    final hash = sha256.convert(bytes).bytes;
    final encoded = _base32Encode(hash).substring(0, 10);
    return ProductReferenceId('P$encoded');
  }

  static List<int> _uuidBytes(String uuid) {
    final normalized = uuid.replaceAll('-', '');
    if (normalized.length != 32) {
      throw DomainException('Invalid product id for reference id generation.');
    }
    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  static String _base32Encode(List<int> bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    var buffer = 0;
    var bitsLeft = 0;
    final output = StringBuffer();

    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      while (bitsLeft >= 5) {
        bitsLeft -= 5;
        final index = (buffer >> bitsLeft) & 0x1f;
        output.write(alphabet[index]);
      }
    }

    if (bitsLeft > 0) {
      final index = (buffer << (5 - bitsLeft)) & 0x1f;
      output.write(alphabet[index]);
    }

    return output.toString();
  }

  @override
  List<Object?> get props => [value];
}
