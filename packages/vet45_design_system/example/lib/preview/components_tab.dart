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
  int _navIndex = 0;
  DateTime? _date;
  bool _centerTitle = false;
  final _textController = TextEditingController();

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
      ],
    );
  }
}

void _noopInt(int _) {}
