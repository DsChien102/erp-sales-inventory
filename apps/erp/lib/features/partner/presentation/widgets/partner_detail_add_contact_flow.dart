import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

/// Opens SG-04 add-contact entry from partner detail and reloads on success.
Future<void> runPartnerDetailAddContactFlow({
  required BuildContext context,
  required String partnerId,
  required IPartnerModule partnerModule,
  required IExecutionContext executionContext,
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

      final tenantId = await executionContext.requireTenantId();
      final actorId = await executionContext.requireUserId();
      for (final personPartnerId in ids) {
        await partnerModule.executeCommandAsync(
          AddOrganizationContactCommand(
            tenantId: tenantId,
            actorId: actorId,
            organizationPartnerId: partnerId,
            personPartnerId: personPartnerId,
          ),
        );
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
