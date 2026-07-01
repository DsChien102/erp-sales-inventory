import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../../core/di/injection.dart';

class PartnerListPage extends StatelessWidget {
  const PartnerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocProvider(
      create: (_) => PartnerListCubit(
        partnerModule: getIt<IPartnerModule>(),
        executionContext: getIt<IExecutionContext>(),
      ),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: dynamicColors.background,
            appBar: VAppBar(
              title: 'Khách hàng & Nhà cung cấp',
              showBackButton: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.more_horiz, color: dynamicColors.textPrimary),
                  onPressed: () {
                    showVBottomSheet(
                      context: context,
                      child: PartnerOptionsBottomSheet(
                        onExportExcel: () {
                          // TODO: Implement export excel
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                const PartnerSearchBar(),
                Expanded(
                  child: BlocBuilder<PartnerListCubit, PartnerListState>(
                    builder: (context, state) {
                      if (state.status == PartnerListStatus.loading && state.partners.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.status == PartnerListStatus.failure) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(VSpacing.space6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.errorMessage ?? 'Không tải được danh sách đối tác',
                                  style: VTypography.bodyDefault.copyWith(
                                    color: dynamicColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: VSpacing.space4),
                                VButton(
                                  onPressed: () => context.read<PartnerListCubit>().load(),
                                  label: 'Tải lại',
                                  variant: VButtonVariant.primary,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state.partners.isEmpty) {
                        final hasActiveFilters =
                            state.searchQuery.trim().isNotEmpty ||
                            state.filterRole != null ||
                            state.filterProfileType != null ||
                            (state.filterStatus != null && state.filterStatus != 'Đang hoạt động');

                        return RefreshIndicator(
                          onRefresh: () async {
                            await context.read<PartnerListCubit>().load();
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 200,
                              child: PartnerEmptyState(
                                title: hasActiveFilters
                                    ? 'Không tìm thấy KH & NCC phù hợp'
                                    : 'Chưa có đối tác nào',
                                message: hasActiveFilters
                                    ? 'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc.'
                                    : 'Bấm nút + để ghi nhận đối tác mới.',
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await context.read<PartnerListCubit>().load();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(VSpacing.space4),
                          itemCount: state.partners.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: VSpacing.space3),
                          itemBuilder: (context, index) {
                            final partner = state.partners[index];
                            return GestureDetector(
                              onTap: () async {
                                final canViewDetail = getIt<IPrincipalSnapshot>().hasPermission(
                                  PartnerPermissions.viewDetail,
                                );
                                if (!canViewDetail) {
                                  VToast.show(
                                    context,
                                    title: 'Lỗi',
                                    message: 'Bạn không có quyền phù hợp.',
                                    type: VToastType.danger,
                                  );
                                  return;
                                }

                                await context.push(
                                  '/partner/detail',
                                  extra: partner,
                                );
                                if (context.mounted) {
                                  await context.read<PartnerListCubit>().load();
                                }
                              },
                              child: PartnerListItem(
                                avatarText: partner.avatarText,
                                name: partner.name,
                                role: partner.role,
                                roleColor: partner.role == 'Khách hàng'
                                    ? VColors.info
                                    : (partner.role == 'Nhà cung cấp'
                                          ? VColors.warning
                                          : VColors.primary),
                                roleBgColor: partner.role == 'Khách hàng'
                                    ? VColors.infoBg
                                    : (partner.role == 'Nhà cung cấp'
                                          ? VColors.warningBg
                                          : VColors.primary100),
                                status: partner.status,
                                statusColor: partner.status == 'Ngừng hoạt động'
                                    ? VColors.textSecondary
                                    : VColors.success,
                                statusBgColor: partner.status == 'Ngừng hoạt động'
                                    ? VColors.neutral200
                                    : VColors.successBg,
                                info: partner.phone.isNotEmpty ? partner.phone : '',
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton:
                getIt<IPrincipalSnapshot>().hasPermission(PartnerPermissions.create)
                ? FloatingActionButton(
                    onPressed: () async {
                      await context.push('/partner/create');
                      if (context.mounted) {
                        await context.read<PartnerListCubit>().load();
                      }
                    },
                    backgroundColor: VColors.success,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          );
        },
      ),
    );
  }
}
