import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../../logic/partner_status_cubit.dart';

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

/// Success toast after deactivating a partner (S7).
void showPartnerDeactivateSuccessToast(BuildContext context) {
  VToast.show(
    context,
    title: 'Thành công',
    message: PartnerStatusCubit.deactivateSuccessMessage,
    type: VToastType.success,
  );
}

/// Success toast after reactivating a partner (S7).
void showPartnerReactivateSuccessToast(BuildContext context) {
  VToast.show(
    context,
    title: 'Thành công',
    message: PartnerStatusCubit.reactivateSuccessMessage,
    type: VToastType.success,
  );
}

/// Success toast after soft-deleting a partner (S8).
void showPartnerSoftDeleteSuccessToast(BuildContext context) {
  VToast.show(
    context,
    title: 'Thành công',
    message: PartnerStatusCubit.softDeleteSuccessMessage,
    type: VToastType.success,
  );
}
