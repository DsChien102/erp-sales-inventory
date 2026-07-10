import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';

/// Opens SG-04 add-contact entry from partner detail and reloads on success.
Future<void> runPartnerDetailAddContactFlow({
  required BuildContext context,
  required String partnerId,
  required Future<void> Function() onReload,
}) async {
  final method = await showModalBottomSheet<AddContactMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const PartnerContactAddMethodSheet(),
  );
  if (!context.mounted || method == null) return;

  switch (method) {
    case AddContactMethod.createNew:
      final result = await context.push<Object?>(
        '/partner/$partnerId/contacts/new',
      );
      if (!context.mounted) return;
      await onReload();
      if (!context.mounted) return;
      if (result == true) {
        VToast.show(
          context,
          title: 'Thành công',
          message: 'Thêm người liên hệ thành công',
          type: VToastType.success,
        );
      }
    case AddContactMethod.selectExisting:
      final result = await context.push<Object?>(
        '/partner/$partnerId/contacts/select',
      );
      if (!context.mounted || result == null) return;
      if (result is! Map<String, dynamic>) return;

      final formResult = await context.push<Object?>(
        '/partner/$partnerId/contacts/new',
        extra: PartnerContactDto(
          personPartnerId: result['personPartnerId'] as String,
          displayName: result['displayName'] as String,
          isPrimary: false,
        ),
      );
      if (!context.mounted) return;
      await onReload();
      if (!context.mounted) return;
      if (formResult == true) {
        VToast.show(
          context,
          title: 'Thành công',
          message: 'Thêm người liên hệ thành công',
          type: VToastType.success,
        );
      }
  }
}
