import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Success toast after creating a partner (D-10 / VD-09 / UI-13).
void showPartnerCreateSuccessToast(BuildContext context) {
  VToast.show(
    context,
    title: 'Thành công',
    message: 'Đã tạo KH & NCC thành công',
    type: VToastType.success,
  );
}

/// Success toast after updating a partner (UI-14 / IR-14 / VD-09).
void showPartnerUpdateSuccessToast(BuildContext context) {
  VToast.show(
    context,
    title: 'Thành công',
    message: 'Đã cập nhật hồ sơ KH & NCC',
    type: VToastType.success,
  );
}
