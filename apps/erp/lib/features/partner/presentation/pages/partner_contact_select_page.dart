import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerContactSelectPage extends StatelessWidget {
  const PartnerContactSelectPage({
    super.key,
    required this.partnerId,
    required this.partnerModule,
    required this.executionContext,
    this.excludePersonPartnerIds = const [],
  });

  final String partnerId;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;
  final List<String> excludePersonPartnerIds;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const VAppBar(
        title: 'Chọn từ cá nhân',
        showBackButton: true,
      ),
      body: PartnerContactSelectList(
        partnerModule: partnerModule,
        executionContext: executionContext,
        excludePersonPartnerIds: excludePersonPartnerIds,
        onSelect: (selectedContacts) {
          context.pop(selectedContacts);
        },
        onCancel: () => context.pop(),
      ),
    );
  }
}
