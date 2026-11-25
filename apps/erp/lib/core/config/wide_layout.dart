import 'package:flutter/widgets.dart';

/// Ngưỡng bố cục web của Theme 1 (10-8): cửa sổ rộng ≥ 840 **và** cao ≥ 480.
/// iPhone xoay ngang (844 × 390, 932 × 430) vẫn dùng bố cục iPhone.
const double wideLayoutMinWidth = 840;
const double wideLayoutMinHeight = 480;

bool isWideSize(Size size) =>
    size.width >= wideLayoutMinWidth && size.height >= wideLayoutMinHeight;

/// Dùng kích thước **cửa sổ** (`MediaQuery.sizeOf`), không dùng `viewInsets`:
/// bàn phím mở không làm bố cục nhảy khi đang gõ.
bool isWideLayout(BuildContext context) => isWideSize(MediaQuery.sizeOf(context));
