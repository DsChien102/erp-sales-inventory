import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/partner_change_history_body.dart';

class PartnerChangeHistoryPage extends StatelessWidget {
  const PartnerChangeHistoryPage({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerModule,
    required this.executionContext,
  });

  final String partnerId;
  final String partnerName;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerChangeHistoryCubit(
        partnerModule: partnerModule,
        executionContext: executionContext,
      )..loadHistory(partnerId),
      child: _PartnerChangeHistoryView(
        partnerId: partnerId,
        partnerName: partnerName,
      ),
    );
  }
}

class _PartnerChangeHistoryView extends StatelessWidget {
  const _PartnerChangeHistoryView({
    required this.partnerId,
    required this.partnerName,
  });

  final String partnerId;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      key: const Key('partner_change_history_page'),
      title: 'Lịch sử thao tác',
      subtitle: partnerName,
      leading: IconButton(
        icon: VIcon(icon: VIcons.arrowBack, color: colors.textPrimary),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/partner/$partnerId');
          }
        },
      ),
      body: BlocBuilder<PartnerChangeHistoryCubit, PartnerChangeHistoryState>(
        builder: (context, state) => PartnerChangeHistoryBody(
          state: state,
          onRetry: () => context.read<PartnerChangeHistoryCubit>().refresh(partnerId),
          onRefresh: () async {
            await context.read<PartnerChangeHistoryCubit>().loadHistory(partnerId);
          },
        ),
      ),
    );
  }
}
