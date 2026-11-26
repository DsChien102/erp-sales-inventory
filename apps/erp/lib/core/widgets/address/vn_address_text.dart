import 'package:flutter/widgets.dart';

import 'vn_administrative_units_loader.dart';

/// Ghép "địa chỉ, xã, tỉnh"; bỏ phần trống; phần nào đã nằm trong [text]
/// (không phân biệt hoa thường) thì không ghép lại.
String composeVnAddress({
  required String text,
  String? provinceCode,
  String? communeCode,
  required List<VnAdministrativeUnit> units,
}) {
  final trimmed = text.trim();
  final lower = trimmed.toLowerCase();

  VnAdministrativeUnit? province;
  if (provinceCode != null && provinceCode.isNotEmpty) {
    for (final unit in units) {
      if (unit.code == provinceCode) {
        province = unit;
        break;
      }
    }
  }

  VnWard? commune;
  if (province != null && communeCode != null && communeCode.isNotEmpty) {
    for (final ward in province.wards) {
      if (ward.code == communeCode) {
        commune = ward;
        break;
      }
    }
  }

  final parts = <String>[];
  if (trimmed.isNotEmpty) {
    parts.add(trimmed);
  }
  if (commune != null &&
      commune.fullName.isNotEmpty &&
      !lower.contains(commune.fullName.toLowerCase())) {
    parts.add(commune.fullName);
  }
  if (province != null &&
      province.fullName.isNotEmpty &&
      !lower.contains(province.fullName.toLowerCase())) {
    parts.add(province.fullName);
  }
  return parts.join(', ');
}

/// Nạp danh mục đơn vị hành chính Việt Nam và truyền chuỗi địa chỉ đã ghép
/// cho [builder]. Khi đang nạp hoặc nạp lỗi thì chỉ truyền [text].
class VnAddressBuilder extends StatefulWidget {
  const VnAddressBuilder({
    super.key,
    required this.text,
    this.provinceCode,
    this.communeCode,
    required this.builder,
  });

  final String text;
  final String? provinceCode;
  final String? communeCode;
  final Widget Function(BuildContext context, String address) builder;

  @override
  State<VnAddressBuilder> createState() => _VnAddressBuilderState();
}

class _VnAddressBuilderState extends State<VnAddressBuilder> {
  List<VnAdministrativeUnit>? _units = VnAdministrativeUnitsLoader.cachedUnits;

  @override
  void initState() {
    super.initState();
    if (_units == null) {
      _loadUnits();
    }
  }

  Future<void> _loadUnits() async {
    try {
      final units = await VnAdministrativeUnitsLoader.load();
      if (!mounted) return;
      setState(() => _units = units);
    } catch (_) {
      // Nạp lỗi danh mục → chỉ hiện địa chỉ gốc.
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = _units;
    final address = units == null
        ? widget.text.trim()
        : composeVnAddress(
            text: widget.text,
            provinceCode: widget.provinceCode,
            communeCode: widget.communeCode,
            units: units,
          );
    return widget.builder(context, address);
  }
}
