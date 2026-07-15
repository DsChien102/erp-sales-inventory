import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_presentation/presentation.dart';

class PartnerChangeHistoryPage extends StatelessWidget {
  const PartnerChangeHistoryPage({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  final String partnerId;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerChangeHistoryCubit()..loadHistory(partnerId),
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

  String _formatDateTime(DateTime occurredAt) {
    final local = occurredAt.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: VAppBar(
        title: 'Lịch sử thao tác',
        subtitle: partnerName,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/partner/$partnerId');
            }
          },
        ),
      ),
      body: BlocBuilder<PartnerChangeHistoryCubit, PartnerChangeHistoryState>(
        builder: (context, state) {
          if (state.status == PartnerChangeHistoryStatus.initial ||
              state.status == PartnerChangeHistoryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PartnerChangeHistoryStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.danger),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Đã xảy ra lỗi',
                    style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  VButton(
                    onPressed: () => context.read<PartnerChangeHistoryCubit>().refresh(partnerId),
                    label: 'Thử lại',
                    variant: VButtonVariant.outline,
                  ),
                ],
              ),
            );
          }

          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: colors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử thao tác nào',
                    style: VTypography.bodyDefault.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PartnerChangeHistoryCubit>().refresh(partnerId);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final entry = state.items[index];
                final dateStr = _formatDateTime(entry.occurredAt);

                String valueDescription = '';
                if (entry.valueBefore != null && entry.valueAfter != null) {
                  valueDescription = '${entry.valueBefore} — ${entry.valueAfter}';
                } else if (entry.valueBefore != null) {
                  valueDescription = entry.valueBefore!;
                } else if (entry.valueAfter != null) {
                  valueDescription = entry.valueAfter!;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: VSpacing.space3),
                  padding: const EdgeInsets.all(VSpacing.space4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(VRadius.card),
                    border: Border.all(color: colors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.summary,
                              style: VTypography.bodyDefault.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: VTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (valueDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          valueDescription,
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'bởi ${entry.actorDisplayName}',
                        style: VTypography.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
