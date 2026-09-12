import 'package:flutter/widgets.dart';
import 'package:vet45_design_system/design_system.dart';

void showSalesBarcodeSearchHint(BuildContext context) {
  VToast.show(
    context,
    title: 'Quét mã',
    message: 'Nhập barcode vào ô tìm kiếm rồi nhấn tìm.',
    type: VToastType.info,
  );
}
