import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

import '../../widgets/product_form_bottom_bar.dart';
import '../../widgets/unsaved_changes_confirm_sheet.dart';
import '../../widgets/custom_field_group_deactivate_confirm_sheet.dart';

class UpsertCustomFieldGroupPage extends StatefulWidget {
  final CustomFieldConfigCubit cubit;
  final String? initialGroupId;

  const UpsertCustomFieldGroupPage({
    super.key,
    required this.cubit,
    this.initialGroupId,
  });

  @override
  State<UpsertCustomFieldGroupPage> createState() => _UpsertCustomFieldGroupPageState();
}

class _UpsertCustomFieldGroupPageState extends State<UpsertCustomFieldGroupPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedEmoji = '💊';
  bool _isActive = true;

  late final String _initialName;
  late final String _initialEmoji;
  late final bool _initialIsActive;

  final List<String> _availableEmojis = [
    '💊',
    '🧪',
    '💉',
    '🩺',
    '🧬',
    '🧫',
    '🏥',
    '🌡️',
    '📦',
    '🏷️',
    '📋',
    '📝',
    '🗂️',
    '🧾',
    '🔒',
    '⚠️',
    '🐄',
    '🐖',
    '🐔',
    '🐟',
    '🐶',
    '🐱',
    '🌾',
    '🏭',
    '🥛',
    '🍖',
    '🌿',
    '🔬',
    '🧴',
    '🧰',
  ];

  bool get _isCreate => widget.initialGroupId == null;

  bool get _hasChanges =>
      _nameController.text.trim() != _initialName ||
      _selectedEmoji != _initialEmoji ||
      _isActive != _initialIsActive;

  @override
  void initState() {
    super.initState();
    if (!_isCreate) {
      final group = widget.cubit.state.groups.firstWhere((g) => g.groupId == widget.initialGroupId);
      _nameController.text = group.name;
      _selectedEmoji = group.iconKey ?? '💊';
      _isActive = group.status.name == 'active';
    }
    _initialName = _nameController.text.trim();
    _initialEmoji = _selectedEmoji;
    _initialIsActive = _isActive;
    _nameController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleLeave() async {
    if (!_hasChanges) {
      if (mounted) context.pop();
      return;
    }
    final shouldLeave = await UnsavedChangesConfirmSheet.show(context);
    if (shouldLeave && mounted) {
      context.pop();
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      VToast.show(
        context,
        title: 'Lỗi',
        message: 'Tên nhóm không được để trống',
        type: VToastType.danger,
      );
      return;
    }
    final success = await widget.cubit.upsertGroup(
      groupId: widget.initialGroupId,
      name: name,
      iconKey: _selectedEmoji,
      isActive: _isActive,
    );
    if (success && mounted) {
      VToast.show(
        context,
        title: 'Thành công',
        message: _isCreate ? 'Đã tạo nhóm' : 'Đã cập nhật nhóm',
        type: VToastType.success,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: widget.cubit,
      child: PopScope(
        canPop: !_hasChanges,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleLeave();
        },
        child: VPageScaffold(
          title: _isCreate ? 'Tạo nhóm thông tin' : 'Sửa nhóm thông tin',
          showBackButton: false,
          leading: IconButton(
            icon: VIcon(icon: VIcons.arrowBack, color: colors.textPrimary),
            onPressed: _handleLeave,
          ),
          body: ListView(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            children: [
              VText(
                'Icon',
                variant: VTextVariant.bodyDefault,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: VSpacing.space2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(VRadius.r12),
                      border: Border.all(color: colors.borderDefault),
                    ),
                    alignment: Alignment.center,
                    child: VText(
                      _selectedEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: VText(
                      'Icon sẽ hiển thị trên card nhóm ở màn hình chi tiết sản phẩm và tạo sản phẩm.',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _availableEmojis[index];
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? colors.surfaceBrand : colors.surface,
                        borderRadius: BorderRadius.circular(VRadius.r8),
                        border: Border.all(
                          color: isSelected ? colors.primary : colors.borderDefault,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: VText(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: VSpacing.space4),
              VTextField(
                controller: _nameController,
                label: 'Tên nhóm *',
                hintText: 'Nhập tên nhóm',
              ),
              const SizedBox(height: VSpacing.space4),
              VTextFormField(
                controller: _descriptionController,
                label: 'Mô tả (tuỳ chọn)',
                hintText: 'Nhập mô tả nhóm',
                maxLines: 3,
              ),
              if (!_isCreate) ...[
                const SizedBox(height: VSpacing.space4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    VText(
                      'Trạng thái hoạt động',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textPrimary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (val) async {
                        if (!val) {
                          final group = widget.cubit.state.groups.firstWhere(
                            (g) => g.groupId == widget.initialGroupId,
                          );
                          final confirmed = await CustomFieldGroupDeactivateConfirmSheet.show(
                            context,
                            fieldCount: group.fieldCount,
                            requiredFieldCount: group.requiredFieldCount,
                          );
                          if (confirmed == true) {
                            setState(() => _isActive = false);
                          }
                        } else {
                          setState(() => _isActive = true);
                        }
                      },
                      activeThumbColor: colors.surface,
                      activeTrackColor: colors.success,
                      inactiveThumbColor: colors.surface,
                      inactiveTrackColor: colors.borderStrong,
                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                  ],
                ),
              ],
            ],
          ),
          bottomBar: BlocBuilder<CustomFieldConfigCubit, CustomFieldConfigState>(
            builder: (context, state) {
              return ProductFormBottomBar(
                onCancel: state.isSaving ? null : _handleLeave,
                isLoading: state.isSaving,
                saveEnabled: _hasChanges,
                onSave: _handleSave,
              );
            },
          ),
        ),
      ),
    );
  }
}
