import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import '../../../../../core/di/injection.dart';

class CustomFieldGroupsPage extends StatefulWidget {
  const CustomFieldGroupsPage({super.key});

  @override
  State<CustomFieldGroupsPage> createState() => _CustomFieldGroupsPageState();
}

class _CustomFieldGroupsPageState extends State<CustomFieldGroupsPage> {
  late final CustomFieldConfigCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = CustomFieldConfigCubit(
      getIt<ICatalogModule>(),
      getIt<IExecutionContext>(),
    )..loadGroups();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: _cubit,
      child: VPageScaffold(
        title: 'Nhóm & trường thông tin',
        actions: [
          IconButton(
            icon: VIcon(icon: VIcons.add, color: colors.primary),
            onPressed: () async {
              await context.push(
                '/more/product-settings/custom-fields/upsert-group',
                extra: _cubit,
              );
              _cubit.loadGroups();
            },
          ),
        ],
        body: BlocConsumer<CustomFieldConfigCubit, CustomFieldConfigState>(
          listener: (context, state) {
            if (state.error != null) {
              VToast.show(
                context,
                title: 'Lỗi',
                message: state.error!,
                type: VToastType.danger,
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.groups.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VIcon(icon: VIcons.inbox, size: 64, color: colors.textMuted),
                    const SizedBox(height: VSpacing.space4),
                    VText(
                      'Chưa có nhóm thông tin nào',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(height: VSpacing.space4),
                    VButton(
                      label: 'Tạo mẫu mặc định',
                      onPressed: () => _cubit.initializeTemplate(),
                    ),
                  ],
                ),
              );
            }

            final groups = List<CustomFieldGroupConfigDto>.from(state.groups);
            // Sort inactive groups to the bottom, keeping their relative order otherwise.
            groups.sort((a, b) {
              final aActive = a.status.name == 'active' ? 1 : 0;
              final bActive = b.status.name == 'active' ? 1 : 0;
              if (aActive != bActive) {
                return bActive.compareTo(aActive);
              }
              return a.sortOrder.compareTo(b.sortOrder);
            });

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.screenMobile,
                    vertical: VSpacing.space3,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(VSpacing.space3),
                      decoration: BoxDecoration(
                        color: colors.warningBg,
                        borderRadius: BorderRadius.circular(VRadius.r8),
                        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VIcon(icon: VIcons.info, color: colors.warning, size: 20),
                          const SizedBox(width: VSpacing.space2),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text:
                                    'Thứ tự nhóm và trường sẽ hiển thị tương ứng trong màn hình sản phẩm. Kéo ',
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: VIcon(
                                      icon: VIcons.gripVertical,
                                      size: 16,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  const TextSpan(text: ' để sắp xếp.'),
                                ],
                              ),
                              style: VTypography.bodySmall.copyWith(color: colors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverReorderableList(
                  itemCount: groups.length,
                  onReorderItem: (oldIndex, newIndex) {
                    if (newIndex == oldIndex) return;

                    final reordered = List<CustomFieldGroupConfigDto>.from(groups);
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);
                    _cubit.reorderGroups(
                      reordered.map((group) => group.groupId).toList(),
                    );
                  },
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _buildGroupCard(context, group, index);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, CustomFieldGroupConfigDto group, int index) {
    final colors = context.vColors;

    return Container(
      key: ValueKey(group.groupId),
      margin: const EdgeInsets.only(
        left: VSpacing.screenMobile,
        right: VSpacing.screenMobile,
        bottom: VSpacing.space3,
      ),
      child: VCard(
        onTap: () async {
          await context.push(
            '/more/product-settings/custom-fields/${group.groupId}',
            extra: _cubit,
          );
          _cubit.loadGroups();
        },
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: VSpacing.space3),
                child: VIcon(
                  icon: VIcons.gripVertical,
                  color: colors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: VText(
                          group.name,
                          variant: VTextVariant.headingH4,
                          color: colors.textPrimary,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: VSpacing.space2),
                      VBadge(
                        label: group.status.name == 'active' ? 'Đang dùng' : 'Tạm tắt',
                        status: group.status.name == 'active'
                            ? VBadgeStatus.success
                            : VBadgeStatus.draft,
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.space1),
                  VText(
                    '${group.fieldCount} trường • ${group.requiredFieldCount} bắt buộc',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            VIcon(
              icon: VIcons.chevronRight,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
