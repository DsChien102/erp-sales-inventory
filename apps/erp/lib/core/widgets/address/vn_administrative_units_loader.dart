import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class VnAdministrativeUnit {
  const VnAdministrativeUnit({
    required this.code,
    required this.fullName,
    required this.wards,
  });

  final String code;
  final String fullName;
  final List<VnWard> wards;

  factory VnAdministrativeUnit.fromJson(Map<String, dynamic> json) {
    final wardsJson = json['Wards'] as List<dynamic>? ?? const [];
    return VnAdministrativeUnit(
      code: json['Code'] as String,
      fullName: json['FullName'] as String,
      wards: wardsJson
          .map((ward) => VnWard.fromJson(ward as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

final class VnWard {
  const VnWard({
    required this.code,
    required this.fullName,
    required this.provinceCode,
  });

  final String code;
  final String fullName;
  final String provinceCode;

  factory VnWard.fromJson(Map<String, dynamic> json) {
    return VnWard(
      code: json['Code'] as String,
      fullName: json['FullName'] as String,
      provinceCode: json['ProvinceCode'] as String,
    );
  }
}

abstract final class VnAdministrativeUnitsAsset {
  static const String path = 'assets/data/vn_administrative_units.json';
}

final class VnAdministrativeUnitsLoader {
  static Future<List<VnAdministrativeUnit>>? _cache;
  static List<VnAdministrativeUnit>? _cachedUnits;

  /// Danh mục đã nạp xong từ `rootBundle` (đọc đồng bộ, `null` khi chưa nạp).
  static List<VnAdministrativeUnit>? get cachedUnits => _cachedUnits;

  static Future<List<VnAdministrativeUnit>> load({AssetBundle? bundle}) {
    if (bundle != null) {
      return _load(bundle);
    }
    return _cache ??= _load(rootBundle);
  }

  static void resetCache() {
    _cache = null;
    _cachedUnits = null;
  }

  @visibleForTesting
  static void seedCacheForTest(List<VnAdministrativeUnit> units) {
    _cachedUnits = units;
    _cache = Future.value(units);
  }

  static Future<List<VnAdministrativeUnit>> _load(AssetBundle bundle) async {
    final jsonString = await bundle.loadString(VnAdministrativeUnitsAsset.path);
    final decoded = jsonDecode(jsonString);
    if (decoded is! List<dynamic>) {
      throw const FormatException('Expected top-level JSON array');
    }
    final units = decoded
        .map(
          (item) => VnAdministrativeUnit.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
    if (bundle == rootBundle) {
      _cachedUnits = units;
    }
    return units;
  }
}
