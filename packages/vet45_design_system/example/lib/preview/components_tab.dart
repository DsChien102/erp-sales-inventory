import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'preview_section.dart';

class ComponentsPreviewTab extends StatefulWidget {
  const ComponentsPreviewTab({super.key});

  @override
  State<ComponentsPreviewTab> createState() => _ComponentsPreviewTabState();
}

class _ComponentsPreviewTabState extends State<ComponentsPreviewTab> {
  bool _loading = false;
  bool _obscure = true;
  bool _checkbox = true;
  bool _switch = false;
  String? _radio = 'a';
  String? _dropdownValue = 'r1';
  String? _searchableValue = 'hcm';
  String? _compactSearchableValue = 'hn';
  int _quantity = 2;
  int _tabIndex = 0;
  int _tabDisabledIndex = 0;
  double _progressValue = 0.4;
  int _currentStepIndex = 1;
  int _navIndex = 0;
  DateTime? _date;
  bool _centerTitle = false;
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      children: [
        PreviewSection(
          title: 'VButton',
          description: 'Variants, sizes, loading, disabled.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Loading toggle', style: VTypography.caption),
                  Switch(
                    value: _loading,
                    onChanged: (v) => setState(() => _loading = v),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.space2),
              PreviewStateRow(
                label: 'Variants',
                child: PreviewStateWrap(
                  children: [
                    for (final v in VButtonVariant.values)
                      VButton(
                        label: v.name,
                        variant: v,
                        size: VButtonSize.small,
                        onPressed: () {},
                        isLoading: _loading,
                      ),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Sizes',
                child: PreviewStateWrap(
                  children: [
                    VButton(label: 'Small', size: VButtonSize.small, onPressed: () {}),
                    VButton(label: 'Medium', size: VButtonSize.medium, onPressed: () {}),
                    VButton(label: 'Large', size: VButtonSize.large, onPressed: () {}),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Disabled / fullWidth / with icon',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VButton(label: 'Disabled', onPressed: null),
                    const SizedBox(height: VSpacing.space2),
                    VButton(
                      label: 'State disabled',
                      state: VComponentState.disabled,
                      onPressed: () {},
                    ),
                    const SizedBox(height: VSpacing.space2),
                    VButton(
                      label: 'State loading',
                      state: VComponentState.loading,
                      onPressed: () {},
                    ),
                    const SizedBox(height: VSpacing.space2),
                    VButton(
                      label: 'Full width',
                      fullWidth: true,
                      onPressed: () {},
                      leadingIcon: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VTextField',
          child: Column(
            children: [
              const PreviewStateRow(
                label: 'Default',
                child: VTextField(hintText: 'Enter text…'),
              ),
              PreviewStateRow(
                label: 'Label + helper',
                child: VTextField(
                  controller: _textController,
                  label: 'Customer phone',
                  hintText: '0901234567',
                  helperText: 'We will send SMS.',
                ),
              ),
              PreviewStateRow(
                label: 'Error',
                child: VTextField(
                  label: 'Email',
                  errorText: 'Email address is invalid.',
                ),
              ),
              const PreviewStateRow(
                label: 'Disabled',
                child: VTextField(
                  label: 'Store code',
                  hintText: 'VET45_HCM_01',
                  enabled: false,
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              PreviewStateRow(
                label: 'Password + suffix',
                child: VTextField(
                  label: 'Password',
                  obscureText: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const PreviewStateRow(
                label: 'Inline variant',
                child: VTextField(
                  variant: VTextFieldVariant.inline,
                  hintText: 'Inline edit',
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VTextFormField',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PreviewStateRow(
                  label: 'DefaultFormField',
                  child: VTextFormField(
                    hintText: 'Enter value...',
                  ),
                ),
                PreviewStateRow(
                  label: 'Required with Validator',
                  child: VTextFormField(
                    label: 'Required Field',
                    isRequired: true,
                    hintText: 'Type something to pass validation',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required.';
                      }
                      return null;
                    },
                  ),
                ),
                const PreviewStateRow(
                  label: 'Max Lines & Initial Value',
                  child: VTextFormField(
                    label: 'Description',
                    initialValue: 'This is the initial description text.',
                    maxLines: 3,
                  ),
                ),
                const PreviewStateRow(
                  label: 'With Character Counter (0/100)',
                  child: VTextFormField(
                    label: 'Short Bio',
                    hintText: 'Tell us about yourself...',
                    maxLength: 100,
                    minLines: 3,
                    maxLines: 5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      VButton(
                        label: 'Validate Form',
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Form is valid!')),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      VButton(
                        label: 'Reset Form',
                        variant: VButtonVariant.outline,
                        onPressed: () {
                          _formKey.currentState?.reset();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        PreviewSection(
          title: 'VDropdown',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Default',
                child: VDropdown<String>(
                  label: 'Reason',
                  value: _dropdownValue,
                  items: const [
                    DropdownMenuItem(value: 'r1', child: Text('Defective')),
                    DropdownMenuItem(value: 'r2', child: Text('Return')),
                  ],
                  onChanged: (v) => setState(() => _dropdownValue = v),
                ),
              ),
              PreviewStateRow(
                label: 'Disabled',
                child: VDropdown<String>(
                  label: 'Reason',
                  value: 'r1',
                  enabled: false,
                  items: const [
                    DropdownMenuItem(value: 'r1', child: Text('Defective')),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VSearchableDropdown',
          description: 'Direct component demo (not via VSelect).',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Default',
                child: VSearchableDropdown<String>(
                  label: 'Province',
                  value: _searchableValue,
                  hintText: 'Search…',
                  items: const [
                    DropdownMenuEntry(value: 'hcm', label: 'Hồ Chí Minh'),
                    DropdownMenuEntry(value: 'hn', label: 'Hà Nội'),
                    DropdownMenuEntry(value: 'dn', label: 'Đà Nẵng'),
                  ],
                  onChanged: (v) => setState(() => _searchableValue = v),
                ),
              ),
              PreviewStateRow(
                label: 'Disabled',
                child: VSearchableDropdown<String>(
                  label: 'Province',
                  value: 'hcm',
                  enabled: false,
                  items: const [
                    DropdownMenuEntry(value: 'hcm', label: 'Hồ Chí Minh'),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VCompactSearchableDropdown',
          description: 'Dense 40px searchable dropdown for ERP forms.',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Builtin trailing',
                child: VCompactSearchableDropdown<String>(
                  value: _compactSearchableValue,
                  hintText: 'Chọn tỉnh / thành phố',
                  items: const [
                    DropdownMenuEntry(value: 'hcm', label: 'Hồ Chí Minh'),
                    DropdownMenuEntry(value: 'hn', label: 'Hà Nội'),
                    DropdownMenuEntry(value: 'dn', label: 'Đà Nẵng'),
                  ],
                  onChanged: (v) => setState(() => _compactSearchableValue = v),
                ),
              ),
              PreviewStateRow(
                label: 'External trailing',
                child: VCompactSearchableDropdown<String>(
                  value: 'hn',
                  trailingMode: VCompactDropdownTrailingMode.external,
                  items: const [
                    DropdownMenuEntry(value: 'hn', label: 'Hà Nội'),
                    DropdownMenuEntry(value: 'hcm', label: 'Hồ Chí Minh'),
                  ],
                  onChanged: (_) {},
                ),
              ),
              PreviewStateRow(
                label: 'Disabled',
                child: VCompactSearchableDropdown<String>(
                  value: null,
                  enabled: false,
                  hintText: 'Chọn tỉnh / thành phố trước',
                  items: const [
                    DropdownMenuEntry(value: 'hn', label: 'Hà Nội'),
                  ],
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VCheckbox / VRadio / VSwitch',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewStateRow(
                label: 'VCheckbox',
                child: VCheckbox(
                  value: _checkbox,
                  label: 'Apply VAT',
                  onChanged: (v) => setState(() => _checkbox = v ?? false),
                ),
              ),
              PreviewStateRow(
                label: 'VRadio (RadioGroup)',
                child: RadioGroup<String>(
                  groupValue: _radio,
                  onChanged: (v) => setState(() => _radio = v),
                  child: Column(
                    children: [
                      VRadio(value: 'a', label: 'Option A', onChanged: null),
                      VRadio(value: 'b', label: 'Option B', onChanged: null),
                    ],
                  ),
                ),
              ),
              PreviewStateRow(
                label: 'VSwitch',
                child: VSwitch(
                  value: _switch,
                  label: 'Send digital receipt',
                  onChanged: (v) => setState(() => _switch = v),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VQuantitySelector',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Interactive (0–10)',
                child: VQuantitySelector(
                  value: _quantity,
                  min: 0,
                  max: 10,
                  onChanged: (v) => setState(() => _quantity = v),
                ),
              ),
              const PreviewStateRow(
                label: 'Disabled',
                child: VQuantitySelector(
                  value: 3,
                  enabled: false,
                  onChanged: _noopInt,
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VSearchBar',
          child: Column(
            children: [
              for (final variant in VSearchBarVariant.values)
                PreviewStateRow(
                  label: variant.name,
                  child: VSearchBar(
                    hintText: 'Search…',
                    variant: variant,
                    onTap: () {},
                  ),
                ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VDatePickerField',
          child: Column(
            children: [
              PreviewStateRow(
                label: 'Empty',
                child: VDatePickerField(
                  value: null,
                  label: 'Invoice date',
                  required: true,
                  onTap: () {},
                ),
              ),
              PreviewStateRow(
                label: 'Filled',
                child: VDatePickerField(
                  value: _date ?? DateTime(2026, 6, 3),
                  label: 'Invoice date',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null && mounted) {
                      setState(() => _date = picked);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VTabs',
          child: Column(
            children: [
              VTabs(
                tabs: const ['Overview', 'Items', 'Payments'],
                selectedIndex: _tabIndex,
                onTabSelected: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: VSpacing.space2),
              Text('Selected: $_tabIndex', style: VTypography.bodySmall),
            ],
          ),
        ),
        PreviewSection(
          title: 'VTabs (Có Disable)',
          child: Column(
            children: [
              VTabs(
                tabs: const ['Hoạt động', 'Thông tin', 'Thành viên (Disable)', 'Cấu hình'],
                selectedIndex: _tabDisabledIndex,
                disabledIndices: const {2},
                onTabSelected: (i) => setState(() => _tabDisabledIndex = i),
              ),
              const VGap.sm(),
              VText('Selected Tab: $_tabDisabledIndex', variant: VTextVariant.bodySmall),
            ],
          ),
        ),
        PreviewSection(
          title: 'VLoading',
          description: 'Xoay tròn thông thường, chế độ hiển thị nhiệm vụ và dạng hộp thoại overlay.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PreviewStateRow(
                label: 'Spinner mặc định',
                child: VLoading(),
              ),
              const VGap.md(),
              const PreviewStateRow(
                label: 'Hiển thị nhiệm vụ (Task mode)',
                child: VLoading(
                  title: 'Đang chuyển tổ chức',
                  description: 'Đang tải dữ liệu và quyền truy cập của Phòng khám Minh Tâm.',
                ),
              ),
              const VGap.md(),
              PreviewStateRow(
                label: 'Hộp thoại Modal Overlay',
                child: VButton(
                  label: 'Mở Loading Dialog',
                  onPressed: () {
                    VLoading.show(
                      context: context,
                      title: 'Đang tải dữ liệu',
                      description: 'Vui lòng đợi trong giây lát...',
                      barrierDismissible: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VSteps',
          description: 'Hiển thị các bước tiến trình dạng ngang (stepper) hoặc dạng danh sách (list).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText('Dạng hàng ngang (stepper):', variant: VTextVariant.headingH4),
              const VGap.md(),
              VSteps(
                steps: const [
                  VStepItem(title: 'Chủ sở hữu', subtitle: 'Hoàn tất'),
                  VStepItem(title: 'Tổ chức', subtitle: 'Đang thực hiện'),
                  VStepItem(title: 'Kiểm tra', subtitle: 'Chưa bắt đầu'),
                ],
                currentStep: _currentStepIndex,
              ),
              const VGap.lg(),
              VText('Dạng danh sách nằm ngang (list horizontal):', variant: VTextVariant.headingH4),
              const VGap.md(),
              VSteps(
                steps: const [
                  VStepItem(title: 'Bước 1', subtitle: 'Hoàn tất'),
                  VStepItem(title: 'Bước 2', subtitle: 'Đang thực hiện'),
                  VStepItem(title: 'Bước 3', subtitle: 'Chưa bắt đầu'),
                ],
                currentStep: _currentStepIndex,
                type: VStepsType.list,
                direction: Axis.horizontal,
              ),
              const VGap.lg(),
              VText('Dạng danh sách nằm dọc (list vertical):', variant: VTextVariant.headingH4),
              const VGap.md(),
              VSteps(
                steps: const [
                  VStepItem(title: 'Bước 1', subtitle: 'Hoàn tất'),
                  VStepItem(title: 'Bước 2', subtitle: 'Đang thực hiện'),
                  VStepItem(title: 'Bước 3', subtitle: 'Chưa bắt đầu'),
                ],
                currentStep: _currentStepIndex,
                type: VStepsType.list,
                direction: Axis.vertical,
              ),
              const VGap.md(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VButton(
                    label: 'Bước trước',
                    onPressed: _currentStepIndex > 0
                        ? () => setState(() => _currentStepIndex--)
                        : null,
                  ),
                  const VGap.horizontalMd(),
                  VButton(
                    label: 'Bước tiếp theo',
                    onPressed: _currentStepIndex < 2
                        ? () => setState(() => _currentStepIndex++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VProgress',
          description: 'Thanh tiến trình bo góc dày dặn kèm hiệu ứng chuyển động mượt mà.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VProgress(value: _progressValue),
              const VGap.md(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VText('Tiến trình: ${(_progressValue * 100).toStringAsFixed(0)}%', variant: VTextVariant.bodySmall),
                  Row(
                    children: [
                      VButton(
                        label: '-10%',
                        size: VButtonSize.small,
                        onPressed: _progressValue > 0.05
                            ? () => setState(() => _progressValue -= 0.1)
                            : null,
                      ),
                      const VGap.horizontalSm(),
                      VButton(
                        label: '+10%',
                        size: VButtonSize.small,
                        onPressed: _progressValue < 0.95
                            ? () => setState(() => _progressValue += 0.1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VCard',
          child: Column(
            children: [
              const PreviewStateRow(
                label: 'Default',
                child: VCard(child: Text('Card content')),
              ),
              PreviewStateRow(
                label: 'Tappable',
                child: VCard(
                  onTap: () {},
                  child: const Text('Tap me'),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VEmptyState',
          child: VEmptyState(
            iconData: Icons.inbox_outlined,
            title: 'No orders yet',
            description: 'Create your first sales order to get started.',
            actionLabel: 'Create order',
            onActionPressed: () {},
          ),
        ),
        PreviewSection(
          title: 'VTable',
          child: VTable(
            headers: const [
              VTableHeader(title: 'SKU'),
              VTableHeader(title: 'Qty'),
              VTableHeader(title: 'Amount'),
            ],
            rows: const [
              [Text('AMX-500'), Text('12'), Text('1.200.000')],
              [Text('ENR-10'), Text('4'), Text('840.000')],
            ],
            stripedRows: true,
          ),
        ),
        PreviewSection(
          title: 'VToast',
          child: PreviewStateWrap(
            children: [
              for (final type in VToastType.values)
                VButton(
                  label: type.name,
                  size: VButtonSize.small,
                  variant: VButtonVariant.outline,
                  onPressed: () {
                    VToast.show(
                      context,
                      title: type.name,
                      message: 'Toast sample for ${type.name}',
                      type: type,
                    );
                  },
                ),
            ],
          ),
        ),
        PreviewSection(
          title: 'Overlays',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VButton(
                label: 'showVConfirmDialog',
                onPressed: () {
                  showVConfirmDialog(
                    context: context,
                    title: 'Void invoice?',
                    message: 'This action cannot be undone.',
                    cancelLabel: 'Keep',
                    actionLabel: 'Void',
                    isDestructive: true,
                    onAction: () {},
                  );
                },
              ),
              const SizedBox(height: VSpacing.space2),
              VButton(
                label: 'showVBottomSheet',
                variant: VButtonVariant.secondary,
                onPressed: () {
                  showVBottomSheet(
                    context: context,
                    title: 'Order actions',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Edit'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          title: const Text('Print'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VFloatingActionButton',
          child: PreviewStateWrap(
            children: [
              VFloatingActionButton(iconData: Icons.add, onTap: () {}),
              VFloatingActionButton(
                iconData: Icons.qr_code_scanner,
                backgroundColor: VColors.info,
                onTap: () {},
              ),
              const VFloatingActionButton(
                iconData: Icons.print_outlined,
                onTap: null,
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VAppBar',
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.card),
                child: SizedBox(
                  height: 160,
                  child: Scaffold(
                    appBar: VAppBar(
                      title: 'Partner Profile',
                      subtitle: 'Retail · Active',
                      centerTitle: _centerTitle,
                      showBackButton: false,
                      actions: [
                        IconButton(
                          onPressed: () {},
                          icon: const VIcon(iconData: Icons.more_vert),
                        ),
                      ],
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(VSpacing.space3),
                      child: VSwitch(
                        value: _centerTitle,
                        label: 'Center title',
                        onChanged: (v) => setState(() => _centerTitle = v),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VHomeHeader',
          child: VHomeHeader(
            userName: 'Lan',
            branchName: 'CN Biên Hoà',
            hasNotification: true,
            onBranchTap: () {},
            onNotificationTap: () {},
            searchBar: VSearchBar(hintText: 'Search…', onTap: () {}),
          ),
        ),
        PreviewSection(
          title: 'VQuickActionButton',
          child: PreviewStateWrap(
            children: [
              VQuickActionButton(
                icon: const Icon(Icons.receipt_long),
                label: 'Orders',
                onTap: () {},
              ),
              VQuickActionButton(
                icon: const Icon(Icons.people),
                label: 'Customers',
                onTap: () {},
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VBottomNavigationBar',
          child: VBottomNavigationBar(
            currentIndex: _navIndex,
            items: const [
              VBottomNavigationItem(icon: Icon(Icons.home), label: 'Home'),
              VBottomNavigationItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
              VBottomNavigationItem(icon: Icon(Icons.more_horiz), label: 'More'),
            ],
            onTap: (i) => setState(() => _navIndex = i),
          ),
        ),
        PreviewSection(
          title: 'VGap',
          description: 'Vertical and horizontal spacing from tokens.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PreviewStateRow(
                label: 'Vertical',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 8, width: 48, color: VColors.primary100),
                    const VGap.xs(),
                    Container(height: 8, width: 48, color: VColors.primary200),
                    const VGap.sm(),
                    Container(height: 8, width: 48, color: VColors.primary300),
                    const VGap.md(),
                    Container(height: 8, width: 48, color: VColors.primary400),
                  ],
                ),
              ),
              PreviewStateRow(
                label: 'Horizontal',
                child: Row(
                  children: [
                    Container(height: 24, width: 24, color: VColors.primary100),
                    const VGap.horizontalSm(),
                    Container(height: 24, width: 24, color: VColors.primary200),
                    const VGap.horizontalMd(),
                    Container(height: 24, width: 24, color: VColors.primary300),
                  ],
                ),
              ),
            ],
          ),
        ),
        PreviewSection(
          title: 'VPagePadding',
          child: VPagePadding(
            child: VCard(
              child: VText(
                'Screen inset from VSpacing.screenMobile',
                variant: VTextVariant.bodySmall,
              ),
            ),
          ),
        ),
        PreviewSection(
          title: 'VSection',
          child: VSection(
            title: 'Thông tin chung',
            subtitle: 'Mã SKU, tên hiển thị',
            trailing: VButton(label: 'Sửa', variant: VButtonVariant.ghost, onPressed: () {}),
            child: VCard(
              child: VText('Section content', variant: VTextVariant.bodyDefault),
            ),
          ),
        ),
        PreviewSection(
          title: 'VPageScaffold',
          description: 'Page shell preview (embedded).',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.card),
            child: SizedBox(
              height: 280,
              child: VPageScaffold(
                title: 'Sản phẩm',
                subtitle: 'SKU-001',
                showBackButton: false,
                body: VPagePadding(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VCard(child: VText('Profile card', variant: VTextVariant.bodyDefault)),
                        const VGap.sm(),
                        VCard(child: VText('Section', variant: VTextVariant.bodyDefault)),
                      ],
                    ),
                  ),
                ),
                bottomBar: Padding(
                  padding: const EdgeInsets.all(VSpacing.md),
                  child: VButton(label: 'Lưu', onPressed: () {}),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _noopInt(int _) {}
