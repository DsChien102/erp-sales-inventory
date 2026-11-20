/// Product reference ID derivation from UUID (TH-02).
library;

import 'package:crypto/crypto.dart';

String productReferenceIdFromUuid(String uuid) {
  final bytes = _uuidBytes(uuid);
  final hash = sha256.convert(bytes).bytes;
  final encoded = _base32Encode(hash).substring(0, 10);
  return 'P$encoded';
}

List<int> _uuidBytes(String uuid) {
  final normalized = uuid.replaceAll('-', '').trim();
  if (normalized.length != 32) {
    throw ArgumentError('Invalid UUID length for reference id generation: $uuid');
  }
  final bytes = <int>[];
  for (var i = 0; i < normalized.length; i += 2) {
    final byte = int.tryParse(normalized.substring(i, i + 2), radix: 16);
    if (byte == null) {
      throw ArgumentError('Invalid hex characters in UUID: $uuid');
    }
    bytes.add(byte);
  }
  return bytes;
}

String _base32Encode(List<int> bytes) {
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

