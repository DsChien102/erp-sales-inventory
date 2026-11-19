import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/partner/logic/partner_error_messages.dart';
import 'package:erp/features/partner/presentation.dart';

/// Opens SG-04 add-contact entry from partner detail and reloads on success.
Future<void> runPartnerDetailAddContactFlow({
  required BuildContext context,
  required String partnerId,
  required PartnerRepository repository,
  required Future<void> Function() onReload,
  List<String> excludePersonPartnerIds = const [],
}) async {
  final method = await showPartnerContactAddMethodSheet(context);
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
        extra: excludePersonPartnerIds,
      );
      if (!context.mounted || result == null) return;
      if (result is! List) return;

      final ids = result.map((e) {
        final map = e as Map;
        return map['personPartnerId'] as String;
      }).toList();
      if (ids.isEmpty) return;

      try {
        for (final personPartnerId in ids) {
          await repository.addContact(
            organizationPartnerId: partnerId,
            personPartnerId: personPartnerId,
          );
        }
      } on Object catch (e) {
        if (!context.mounted) return;
        // Một phần có thể đã thêm: tải lại để màn khớp server.
        await onReload();
        if (!context.mounted) return;
        VToast.show(
          context,
          title: 'Không thành công',
          message: partnerErrorMessage(
            e,
            fallback: 'Không thể thêm người liên hệ. Vui lòng thử lại.',
            noPermission: 'Bạn không có quyền quản lý người liên hệ.',
          ),
          type: VToastType.danger,
        );
        return;
      }

      if (!context.mounted) return;
      await onReload();
      if (!context.mounted) return;
      VToast.show(
        context,
        title: 'Thành công',
        message: 'Thêm người liên hệ thành công',
        type: VToastType.success,
      );
  }
}
