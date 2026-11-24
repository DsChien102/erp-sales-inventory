import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đặt mặt vẽ thật của test bằng [size] (dpr 1) và trả lại sau test.
///
/// Chỉ đặt `MediaQuery(size:)` thì mặt vẽ vẫn là 800 × 600 mặc định: bố cục,
/// `LayoutBuilder` và lỗi tràn không đúng với 390 / 1280 (T7-G5-0a R1-3).
void useInventoryTestSurface(Size size) {
  final view =
      TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
  view.physicalSize = size;
  view.devicePixelRatio = 1;
  addTearDown(view.reset);
}
