import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

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

  final List<String> _availableEmojis = [
    '💊', '🧪', '💉', '🩺', '🧬', '🧫', '🏥', '🌡️',
    '📦', '🏷️', '📋', '📝', '🗂️', '🧾', '🔒', '⚠️',
    '🐄', '🐖', '🐔', '🐟', '🐶', '🐱', '🌾', '🏭',
    '🥛', '🍖', '🌿', '🔬', '🧴', '🧰',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroupId != null) {
      final group = widget.cubit.state.groups.firstWhere((g) => g.groupId == widget.initialGroupId);
      _nameController.text = group.name;
      _selectedEmoji = group.iconKey ?? '💊';
      _isActive = group.status.name == 'active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }



  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      VToast.show(context, title: 'Lỗi', message: 'Tên nhóm không được để trống', type: VToastType.danger);
      return;
    }
    final success = await widget.cubit.upsertGroup(
      groupId: widget.initialGroupId,
      name: name,
      iconKey: _selectedEmoji,
      isActive: _isActive,
    );
    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: VAppBar(
          title: widget.initialGroupId == null ? 'Tạo nhóm thông tin' : 'Sửa nhóm thông tin',
          showBackButton: true,
          actions: [
            BlocBuilder<CustomFieldConfigCubit, CustomFieldConfigState>(
              builder: (context, state) {
                if (state.isSaving) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return TextButton(
                  onPressed: _handleSave,
                  child: Text(
                    'Lưu',
                    style: VTypography.bodyDefault.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          children: [
            Text(
              'Icon',
              style: VTypography.bodyDefault.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
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
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Text(
                    'Icon sẽ hiển thị trên card nhóm ở màn hình chi tiết sản phẩm và tạo sản phẩm.',
                    style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
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
                    child: Text(
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
            VTextField(
              controller: _descriptionController,
              label: 'Mô tả (tuỳ chọn)',
              hintText: 'Nhập mô tả nhóm',
              maxLines: 3,
            ),
            if (widget.initialGroupId != null) ...[
              const SizedBox(height: VSpacing.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trạng thái hoạt động',
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (val) {
                      if (!val) {
                        showVConfirmDialog(
                          context: context,
                          title: 'Tạm tắt nhóm thông tin',
                          message:
                              'Dữ liệu đã nhập trên sản phẩm sẽ được giữ lại. '
                              'Nhóm đang tạm tắt sẽ không hiển thị khi tạo hoặc sửa sản phẩm mới.',
                          cancelLabel: 'Hủy',
                          actionLabel: 'Xác nhận',
                          onAction: () => setState(() => _isActive = false),
                        );
                      } else {
                        setState(() => _isActive = true);
                      }
                    },
                    activeThumbColor: colors.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
