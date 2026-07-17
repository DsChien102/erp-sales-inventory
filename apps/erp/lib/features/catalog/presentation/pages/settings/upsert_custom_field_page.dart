import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_catalog_presentation/presentation.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

import '../../widgets/product_form_bottom_bar.dart';
import '../../widgets/unsaved_changes_confirm_sheet.dart';
import '../../widgets/custom_field_deactivate_confirm_sheet.dart';

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

  late final String _initialName;
  late final CustomFieldType _initialFieldType;
  late final bool _initialIsRequired;
  late final bool _initialDisplayOnList;
  late final bool _initialIsSearchable;
  late final bool _initialIsFilterable;
  late final bool _initialIsActive;
  late final List<({String id, String label, bool active})> _initialOptions;

  bool get _isCreate => widget.initialFieldId == null;

  bool get _hasChanges {
    if (_nameController.text.trim() != _initialName) return true;
    if (_fieldType != _initialFieldType) return true;
    if (_isRequired != _initialIsRequired) return true;
    if (_displayOnList != _initialDisplayOnList) return true;
    if (_isSearchable != _initialIsSearchable) return true;
    if (_isFilterable != _initialIsFilterable) return true;
    if (_isActive != _initialIsActive) return true;
    if (_optionIds.length != _initialOptions.length) return true;
    for (var i = 0; i < _optionIds.length; i++) {
      final id = _optionIds[i];
      final initial = _initialOptions[i];
      if (id != initial.id) return true;
      if ((_optionControllers[id]?.text.trim() ?? '') != initial.label) return true;
      if ((_optionActiveFlags[id] ?? true) != initial.active) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (!_isCreate) {
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
        final controller = TextEditingController(text: opt.label);
        controller.addListener(_onFormChanged);
        _optionControllers[opt.optionId] = controller;
        _optionActiveFlags[opt.optionId] = opt.isActive;
        _optionSortOrders[opt.optionId] = opt.sortOrder;
      }
    }
    _initialName = _nameController.text.trim();
    _initialFieldType = _fieldType;
    _initialIsRequired = _isRequired;
    _initialDisplayOnList = _displayOnList;
    _initialIsSearchable = _isSearchable;
    _initialIsFilterable = _isFilterable;
    _initialIsActive = _isActive;
    _initialOptions = [
      for (final id in _optionIds)
        (
          id: id,
          label: _optionControllers[id]!.text.trim(),
          active: _optionActiveFlags[id] ?? true,
        ),
    ];
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
    for (final c in _optionControllers.values) {
      c.removeListener(_onFormChanged);
      c.dispose();
    }
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
      VToast.show(
        context,
        title: 'Thành công',
        message: _isCreate ? 'Đã tạo trường' : 'Đã cập nhật trường',
        type: VToastType.success,
      );
      context.pop();
    }
  }

  void _addOption() {
    setState(() {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      _optionIds.add(newId);
      final controller = TextEditingController();
      controller.addListener(_onFormChanged);
      _optionControllers[newId] = controller;
      _optionActiveFlags[newId] = true;
      _optionSortOrders[newId] = _optionIds.length - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _optionControllers[_optionIds.last]?.selection = TextSelection.fromPosition(
        const TextPosition(offset: 0),
      );
    });
  }

  void _removeOption(String optionId) {
    setState(() {
      _optionIds.remove(optionId);
      _optionControllers.remove(optionId)
        ?..removeListener(_onFormChanged)
        ..dispose();
      _optionActiveFlags.remove(optionId);
      _optionSortOrders.remove(optionId);
    });
  }

  Widget _buildPropertyRow(
    String label,
    String? subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    VColorScheme colors, {
    Color? subtitleColor,
  }) {
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
                    style: VTypography.bodySmall.copyWith(
                      color: subtitleColor ?? VColors.textSecondary,
                    ),
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
      child: PopScope(
        canPop: !_hasChanges,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _handleLeave();
        },
        child: Scaffold(
          backgroundColor: colors.surface,
          appBar: VAppBar(
            title: _isCreate ? 'Tạo trường thông tin' : 'Cấu hình trường',
            showBackButton: false,
            leading: IconButton(
              icon: VIcon(icon: VIcons.arrowBack, color: colors.textPrimary),
              onPressed: _handleLeave,
            ),
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
                        if (val != null) {
                          setState(() {
                            _fieldType = val;
                            if (_fieldType != CustomFieldType.singleSelect &&
                                _fieldType != CustomFieldType.boolean) {
                              _isFilterable = false;
                            }
                          });
                        }
                      },
                items: customFieldTypes,
              ),
              if (_hasProductValues) ...[
                const SizedBox(height: VSpacing.space2),
                Text(
                  'Không đổi được kiểu dữ liệu do đã có dữ liệu.',
                  style: VTypography.bodySmall.copyWith(color: VColors.warning),
                ),
              ] else if (!_isCreate) ...[
                const SizedBox(height: VSpacing.space2),
                Text(
                  'Thay đổi kiểu dữ liệu có thể ảnh hưởng đến tương thích dữ liệu cũ.',
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
                      icon: const VIcon(icon: VIcons.add, size: 16),
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
                        const VIcon(icon: VIcons.gripVertical, color: VColors.textMuted, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: VTextField(
                            controller: controller,
                            hintText: 'Nhập tên tùy chọn',
                            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                          ),
                        ),
                        IconButton(
                          icon: const VIcon(icon: VIcons.delete, color: VColors.danger),
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
                      _isRequired ? 'Tham gia tính readiness của sản phẩm' : null,
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
                    if (_fieldType == CustomFieldType.singleSelect ||
                        _fieldType == CustomFieldType.boolean) ...[
                      const Divider(height: 1, color: VColors.borderDefault),
                      _buildPropertyRow(
                        'Cho phép lọc',
                        null,
                        _isFilterable,
                        (v) => setState(() => _isFilterable = v),
                        colors,
                      ),
                    ],
                    const Divider(height: 1, color: VColors.borderDefault),
                    _buildPropertyRow(
                      'Hiển thị trên danh sách sản phẩm',
                      _displayOnList ? 'Danh sách sản phẩm chỉ hiển thị giới hạn field.' : null,
                      _displayOnList,
                      (v) => setState(() => _displayOnList = v),
                      colors,
                    ),
                  ],
                ),
              ),

              if (!_isCreate) ...[
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
                    (v) async {
                      if (!v) {
                        final confirmed = await CustomFieldDeactivateConfirmSheet.show(context);
                        if (confirmed == true) {
                          setState(() => _isActive = false);
                        }
                      } else {
                        setState(() => _isActive = true);
                      }
                    },
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
