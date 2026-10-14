import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/warehouse_task_item.dart';
import '../../logic/warehouse_home_cubit.dart';
import '../../logic/warehouse_home_state.dart';
import '../widgets/warehouse_start_new_sheet.dart';
import '../widgets/warehouse_task_card.dart';

class WarehouseHomePage extends StatelessWidget {
  const WarehouseHomePage({
    super.key,
    this.cubit,
  });

  final WarehouseHomeCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _WarehouseHomeView(),
      );
    }

    return BlocProvider(
      create: (_) => WarehouseHomeCubit(),
      child: const _WarehouseHomeView(),
    );
  }
}

class _WarehouseHomeView extends StatefulWidget {
  const _WarehouseHomeView();

  @override
  State<_WarehouseHomeView> createState() => _WarehouseHomeViewState();
}

class _WarehouseHomeViewState extends State<_WarehouseHomeView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<WarehouseHomeCubit>();
    if (cubit.state is WarehouseHomeInitial) {
      cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VPageScaffold(
      title: 'Kho',
      showBackButton: true,
      centerTitle: false,
      body: BlocBuilder<WarehouseHomeCubit, WarehouseHomeState>(
        builder: (context, state) {
          if (state is WarehouseHomeLoading || state is WarehouseHomeInitial) {
            return const Center(
              child: VLoading(),
            );
          }

          if (state is WarehouseHomeError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      'Có lỗi xảy ra',
                      style: VTypography.headingH4.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.danger,
                      ),
                    ),
                    const SizedBox(height: VSpacing.space2),
                    VText(
                      state.message,
                      style: VTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VSpacing.space4),
                    VButton(
                      label: 'Thử lại',
                      variant: VButtonVariant.secondary,
                      onPressed: () => context.read<WarehouseHomeCubit>().load(),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is! WarehouseHomeLoaded) {
            return const SizedBox.shrink();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<WarehouseHomeCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space3,
              ),
              children: [
                VSearchBar(
                  hintText: 'Tìm sản phẩm, SKU hoặc lô',
                  onChanged: (query) =>
                      context.read<WarehouseHomeCubit>().search(query),
                ),
                const SizedBox(height: VSpacing.space5),
                // Section "Việc của bạn"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VText(
                      'Việc của bạn',
                      style: VTypography.headingH4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    VText(
                      '${state.filteredTasks.length} việc',
                      style: VTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.space3),
                ...state.filteredTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.space3),
                    child: WarehouseTaskCard(
                      item: task,
                      onTap: () => task.routePath != null
                          ? context.push(task.routePath!)
                          : VToast.show(
                              context,
                              title: task.title,
                              message: task.subtitle,
                              type: VToastType.info,
                            ),
                    ),
                  ),
                ),
                // Card "Bắt đầu việc mới"
                Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.space3),
                  child: WarehouseTaskCard(
                    item: const WarehouseTaskItem(
                      id: 'start_new_work',
                      title: 'Bắt đầu việc mới',
                      subtitle:
                          'Nhập hàng nhanh, kiểm kê, đổi tình trạng hoặc tiêu hủy',
                    ),
                    onTap: () {
                      WarehouseStartNewSheet.show(
                        context,
                        actions: state.manualActions,
                        onSelectAction: (action) => action.routePath != null
                            ? context.push(action.routePath!)
                            : VToast.show(
                                context,
                                title: action.title,
                                message: action.subtitle,
                                type: VToastType.info,
                              ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: VSpacing.space4),
                // Section "Tra cứu"
                VText(
                  'Tra cứu',
                  style: VTypography.headingH4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: VSpacing.space3),
                ...state.utilities.map(
                  (utility) => Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.space3),
                    child: WarehouseTaskCard(
                      item: utility,
                      onTap: () {
                        if (utility.routePath != null) {
                          context.push(utility.routePath!);
                        } else {
                          VToast.show(
                            context,
                            title: utility.title,
                            message: utility.subtitle,
                            type: VToastType.info,
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.space6),
              ],
            ),
          );
        },
      ),
    );
  }
}
