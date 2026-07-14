import 'dart:convert';

import 'package:flutter/services.dart';

import 'vn_administrative_unit.dart';

final class VnAdministrativeUnitsLoader {
  static Future<List<VnAdministrativeUnit>>? _cache;

  static Future<List<VnAdministrativeUnit>> load() {
    return _cache ??= _load();
  }

  static Future<List<VnAdministrativeUnit>> _load() async {
    final jsonString = await rootBundle.loadString(VnAdministrativeUnitsAsset.path);
    final decoded = jsonDecode(jsonString);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Expected top-level JSON array');
    }
    return decoded
        .map(
          (item) => VnAdministrativeUnit.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
