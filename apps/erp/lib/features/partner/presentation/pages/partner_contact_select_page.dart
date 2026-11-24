import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/features/partner/presentation.dart';

class PartnerContactSelectPage extends StatelessWidget {
  const PartnerContactSelectPage({
    super.key,
    required this.partnerId,
    required this.repository,
    this.excludePersonPartnerIds = const [],
  });

  final String partnerId;
  final PartnerRepository repository;
  final List<String> excludePersonPartnerIds;

  @override
  Widget build(BuildContext context) {
    return VPageScaffold(
      title: 'Chọn từ cá nhân',
      body: PartnerContactSelectList(
        repository: repository,
        excludePersonPartnerIds: excludePersonPartnerIds,
        onSelect: (selectedContacts) {
          context.pop(selectedContacts);
        },
        onCancel: () => context.pop(),
      ),
    );
  }
}
