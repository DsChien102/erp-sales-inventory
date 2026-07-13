import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

import '../../widgets/product_form_bottom_bar.dart';

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
  bool _hasProductValues = false;
  final List<String> _optionIds = [];
  final Map<String, TextEditingController> _optionControllers = {};
  final Map<String, bool> _optionActiveFlags = {};
  final Map<String, int> _optionSortOrders = {};

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
      _hasProductValues = field.hasProductValues;
      for (final opt in field.options) {
        _optionIds.add(opt.optionId);
        _optionControllers[opt.optionId] = TextEditingController(text: opt.label);
        _optionActiveFlags[opt.optionId] = opt.isActive;
        _optionSortOrders[opt.optionId] = opt.sortOrder;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final c in _optionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      VToast.show(
        context,
        title: 'Lỗi',
        message: 'Tên trường không được để trống',
        type: VToastType.danger,
      );
      return;
    }

    if (_fieldType == CustomFieldType.singleSelect && _optionIds.isEmpty) {
      VToast.show(
        context,
        title: 'Lỗi',
        message: 'Cần có ít nhất 1 tùy chọn',
        type: VToastType.danger,
      );
      return;
    }

    // Validate: tất cả option phải có label
    for (final id in _optionIds) {
      final label = _optionControllers[id]?.text.trim() ?? '';
      if (label.isEmpty) {
        VToast.show(
          context,
          title: 'Lỗi',
          message: 'Tên tùy chọn không được để trống',
          type: VToastType.danger,
        );
        return;
      }
    }

    // Build options từ controllers
    final builtOptions = _fieldType == CustomFieldType.singleSelect
        ? _optionIds.asMap().entries.map((entry) {
            final idx = entry.key;
            final id = entry.value;
            return CustomFieldSelectOptionDto(
              optionId: id,
              label: _optionControllers[id]!.text.trim(),
              sortOrder: idx,
              isActive: _optionActiveFlags[id] ?? true,
            );
          }).toList()
        : null;

    final success = await widget.cubit.upsertField(
      fieldId: widget.initialFieldId,
      groupId: widget.groupId,
      name: name,
      fieldType: _fieldType,
      options: builtOptions,
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
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      _optionIds.add(newId);
      _optionControllers[newId] = TextEditingController();
      _optionActiveFlags[newId] = true;
      _optionSortOrders[newId] = _optionIds.length - 1;
    });
    // Focus vào field mới thêm sau khi rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _optionControllers[_optionIds.last]?.selection = TextSelection.fromPosition(
        const TextPosition(offset: 0),
      );
    });
  }

  void _removeOption(String optionId) {
    setState(() {
      _optionIds.remove(optionId);
      _optionControllers.remove(optionId)?.dispose();
      _optionActiveFlags.remove(optionId);
      _optionSortOrders.remove(optionId);
    });
  }

  Widget _buildPropertyRow(
    String label,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    VColorScheme colors,
  ) {
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
                  style: VTypography.bodyDefault.copyWith(
                    color: VColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
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

    final customFieldTypes = CustomFieldType.values
        .map(
          (type) => DropdownMenuItem(
            value: type,
            child: Text(type.labelVi),
          ),
        )
        .toList();

    return BlocProvider.value(
      value: widget.cubit,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: VAppBar(
          title: widget.initialFieldId == null ? 'Tạo trường thông tin' : 'Cấu hình trường',
          showBackButton: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          children: [
            VTextField(
              controller: _nameController,
              label: 'Tên trường',
              isRequired: true,
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
            VSelect<CustomFieldType>(
              label: 'Kiểu dữ liệu',
              isRequired: true,
              enabled: !_hasProductValues,
              value: _fieldType,
              onChanged: _hasProductValues
                  ? null
                  : (val) {
                      if (val != null) setState(() => _fieldType = val);
                    },
              items: customFieldTypes,
            ),
            if (_hasProductValues) ...[
              const SizedBox(height: VSpacing.space2),
              Text(
                'Không đổi được kiểu dữ liệu do đã có dữ liệu.',
                style: VTypography.bodySmall.copyWith(color: VColors.warning),
              ),
            ],
            const SizedBox(height: VSpacing.space4),
            VTextField(
              controller: TextEditingController(text: group.name),
              label: 'Nhóm',
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
              ..._optionIds.map((optId) {
                final controller = _optionControllers[optId]!;
                return Padding(
                  key: ValueKey(optId),
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.drag_indicator, color: VColors.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VTextField(
                          controller: controller,
                          hintText: 'Nhập tên tùy chọn',
                          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: VColors.danger),
                        onPressed: () => _removeOption(optId),
                      ),
                    ],
                  ),
                );
              }),
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
                  _buildPropertyRow(
                    'Bắt buộc',
                    'Tham gia tính readiness của sản phẩm',
                    _isRequired,
                    (v) {
                      if (v) {
                        showVConfirmDialog(
                          context: context,
                          title: 'Bật bắt buộc cho trường',
                          message:
                              'Sản phẩm hiện tại chưa điền trường này có thể phát sinh blocker readiness. '
                              'Dữ liệu hiện có không bị xóa.',
                          cancelLabel: 'Hủy',
                          actionLabel: 'Xác nhận',
                          onAction: () => setState(() => _isRequired = true),
                        );
                      } else {
                        setState(() => _isRequired = v);
                      }
                    },
                    colors,
                  ),
                  const Divider(height: 1, color: VColors.borderDefault),
                  _buildPropertyRow(
                    'Cho phép tìm kiếm',
                    null,
                    _isSearchable,
                    (v) => setState(() => _isSearchable = v),
                    colors,
                  ),
                  const Divider(height: 1, color: VColors.borderDefault),
                  _buildPropertyRow(
                    'Cho phép lọc',
                    null,
                    _isFilterable,
                    (v) => setState(() => _isFilterable = v),
                    colors,
                  ),
                  const Divider(height: 1, color: VColors.borderDefault),
                  _buildPropertyRow(
                    'Hiển thị trên danh sách sản phẩm',
                    'Danh sách sản phẩm chỉ hiển thị giới hạn field.',
                    _displayOnList,
                    (v) => setState(() => _displayOnList = v),
                    colors,
                  ),
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
                child: _buildPropertyRow(
                  'Đang dùng',
                  null,
                  _isActive,
                  (v) => setState(() => _isActive = v),
                  colors,
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
        bottomNavigationBar: BlocBuilder<CustomFieldConfigCubit, CustomFieldConfigState>(
          builder: (context, state) {
            return ProductFormBottomBar(
              onCancel: state.isSaving ? null : () => context.pop(),
              isLoading: state.isSaving,
              onSave: _handleSave,
            );
          },
        ),
      ),
    );
  }
}

extension on CustomFieldType {
  String get labelVi {
    switch (this) {
      case CustomFieldType.text:
        return 'Văn bản';
      case CustomFieldType.number:
        return 'Số';
      case CustomFieldType.singleSelect:
        return 'Tùy chọn';
      case CustomFieldType.date:
        return 'Ngày';
      case CustomFieldType.boolean:
        return 'Bật/Tắt';
    }
  }
}
