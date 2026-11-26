import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Icon app 256 × 256 (chép từ prototype Theme 1); bản 937 KB không vào bundle.
const String appIconAsset = 'assets/icon/app_icon_256.png';

/// Icon app bo 12, viền `borderBrand` 1. Trang trí, không có semantics.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VRadius.r12),
        ),
        // Vẽ trên ảnh: ảnh vuông đè mất viền ở bốn góc bo.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VRadius.r12),
          border: Border.all(color: context.vColors.borderBrand),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(appIconAsset, fit: BoxFit.cover),
      ),
    );
  }
}

/// Nạp bytes icon cho PDF. Lỗi → `null` (in phiếu quan trọng hơn logo).
Future<Uint8List?> loadAppIconBytes({AssetBundle? bundle}) async {
  try {
    final data = await (bundle ?? rootBundle).load(appIconAsset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {
    return null;
  }
}
