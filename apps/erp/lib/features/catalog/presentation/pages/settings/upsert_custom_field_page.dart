import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

class UpsertCustomFieldPage extends StatefulWidget {
  final String groupId;
  final CustomFieldConfigCubit cubit;
  final String? initialFieldId;

  const UpsertCustomFieldPage({
    super.key,
    required this.groupId,
    required this.cubit,
    this.initialFieldId,
  });

  @override
  State<UpsertCustomFieldPage> createState() => _UpsertCustomFieldPageState();
}

class _UpsertCustomFieldPageState extends State<UpsertCustomFieldPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  CustomFieldType _fieldType = CustomFieldType.text;
  bool _isRequired = false;
  bool _displayOnList = false;
  bool _isSearchable = false;
  bool _isFilterable = false;
  bool _isActive = true;
  final List<CustomFieldSelectOptionDto> _options = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialFieldId != null) {
      final group = widget.cubit.state.groups.firstWhere((g) => g.groupId == widget.groupId);
      final field = group.fields.firstWhere((f) => f.fieldId == widget.initialFieldId);
      _nameController.text = field.name;
      _fieldType = field.fieldType;
      _isRequired = field.isRequired;
      _displayOnList = field.displayOnList;
      _isSearchable = field.isSearchable;
      _isFilterable = field.isFilterable;
      _isActive = field.status.name == 'active';
      _options.addAll(field.options);
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
      VToast.show(context, title: 'Lỗi', message: 'Tên trường không được để trống', type: VToastType.danger);
      return;
    }

    if (_fieldType == CustomFieldType.singleSelect && _options.isEmpty) {
      VToast.show(context, title: 'Lỗi', message: 'Cần có ít nhất 1 tùy chọn', type: VToastType.danger);
      return;
    }

    final success = await widget.cubit.upsertField(
      fieldId: widget.initialFieldId,
      groupId: widget.groupId,
      name: name,
      fieldType: _fieldType,
      options: _fieldType == CustomFieldType.singleSelect ? _options : null,
      isRequired: _isRequired,
      displayOnList: _displayOnList,
      isSearchable: _isSearchable,
      isFilterable: _isFilterable,
      isActive: _isActive,
    );
    if (success && mounted) {
      context.pop();
    }
  }

  void _addOption() {
    setState(() {
      _options.add(CustomFieldSelectOptionDto(
        optionId: DateTime.now().millisecondsSinceEpoch.toString(),
        label: 'Tùy chọn ${_options.length + 1}',
      ));
    });
  }

  Widget _buildPropertyRow(String label, String? subtitle, bool value, ValueChanged<bool> onChanged, VColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: VTypography.bodyDefault.copyWith(color: VColors.textPrimary, fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VTypography.bodySmall.copyWith(color: VColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: VColors.success,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: VColors.borderStrong,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final group = widget.cubit.state.groups.firstWhere((g) => g.groupId == widget.groupId);

    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: VAppBar(
          title: widget.initialFieldId == null ? 'Tạo trường thông tin' : 'Cấu hình trường',
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
                      color: VColors.success,
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
            VTextField(
              controller: _nameController,
              label: 'Tên trường *',
              hintText: 'Nhập tên trường',
            ),
            const SizedBox(height: VSpacing.space4),
            VTextField(
              controller: _descriptionController,
              label: 'Mô tả (tuỳ chọn)',
              hintText: 'Nhập mô tả',
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: VSpacing.space4),
            VDropdown<CustomFieldType>(
              label: 'Kiểu dữ liệu *',
              value: _fieldType,
              onChanged: widget.initialFieldId == null ? (val) {
                if (val != null) setState(() => _fieldType = val);
              } : null, // Not allowed to change fieldType if editing (Image 3)
              items: const [
                DropdownMenuItem(value: CustomFieldType.text, child: Text('Text')),
                DropdownMenuItem(value: CustomFieldType.number, child: Text('Số')),
                DropdownMenuItem(value: CustomFieldType.singleSelect, child: Text('Single select')),
                DropdownMenuItem(value: CustomFieldType.date, child: Text('Ngày')),
                DropdownMenuItem(value: CustomFieldType.boolean, child: Text('Bật/Tắt')),
              ],
            ),
            if (widget.initialFieldId != null) ...[
              const SizedBox(height: VSpacing.space2),
              Text(
                'Không đổi được kiểu dữ liệu do đã có dữ liệu.',
                style: VTypography.bodySmall.copyWith(color: VColors.warning),
              ),
            ],
            const SizedBox(height: VSpacing.space4),
            VTextField(
              controller: TextEditingController(text: group.name),
              label: 'Nhóm *',
              enabled: false,
            ),
            
            if (_fieldType == CustomFieldType.singleSelect) ...[
              const SizedBox(height: VSpacing.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tùy chọn',
                    style: VTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: VColors.textSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space3),
              ..._options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, color: VColors.textMuted, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(VRadius.r8),
                          border: Border.all(color: VColors.borderDefault),
                        ),
                        child: Text(opt.label),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: VColors.danger),
                      onPressed: () {
                        setState(() {
                          _options.remove(opt);
                        });
                      },
                    ),
                  ],
                ),
              )),
            ],

            const SizedBox(height: VSpacing.space6),
            Text(
              'THUỘC TÍNH',
              style: VTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: VColors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space3),
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(VRadius.r12),
                border: Border.all(color: VColors.borderDefault),
              ),
              child: Column(
                children: [
                  _buildPropertyRow('Bắt buộc', 'Tham gia tính readiness của sản phẩm', _isRequired, (v) => setState(() => _isRequired = v), colors),
                  const Divider(height: 1, color: VColors.borderDefault),
                  _buildPropertyRow('Cho phép tìm kiếm', null, _isSearchable, (v) => setState(() => _isSearchable = v), colors),
                  const Divider(height: 1, color: VColors.borderDefault),
                  _buildPropertyRow('Cho phép lọc', null, _isFilterable, (v) => setState(() => _isFilterable = v), colors),
                  const Divider(height: 1, color: VColors.borderDefault),
                  _buildPropertyRow('Hiển thị trên danh sách sản phẩm', 'Danh sách sản phẩm chỉ hiển thị giới hạn field.', _displayOnList, (v) => setState(() => _displayOnList = v), colors),
                ],
              ),
            ),
            
            if (widget.initialFieldId != null) ...[
              const SizedBox(height: VSpacing.space6),
              Text(
                'TRẠNG THÁI',
                style: VTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: VColors.textSecondary,
                ),
              ),
              const SizedBox(height: VSpacing.space3),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(VRadius.r12),
                  border: Border.all(color: VColors.borderDefault),
                ),
                child: _buildPropertyRow('Đang dùng', null, _isActive, (v) => setState(() => _isActive = v), colors),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
