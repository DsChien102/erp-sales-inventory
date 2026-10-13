import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/shared/sales_customer_selection.dart';
import '../support/sales_external_lookups.dart';

abstract final class SalesCustomerQuickCreateSheet {
  static Future<SalesCustomerSelection?> show(
    BuildContext context, {
    required SalesCustomerDuplicateCheckFn checkDuplicate,
    required SalesCustomerCreateFn createCustomer,
  }) {
    return showModalBottomSheet<SalesCustomerSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final bottomInset = media.viewInsets.bottom;
        final topSafe = media.viewPadding.top;
        final availableHeight = media.size.height - topSafe - bottomInset;
        final maxBodyHeight = (availableHeight - 36).clamp(180.0, media.size.height);

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: VBottomSheet(
              semanticLabel: 'Tạo nhanh khách hàng',
              maxHeightFraction: 1.0,
              child: SafeArea(
                top: false,
                child: _QuickCreateCustomerSheet(
                  checkDuplicate: checkDuplicate,
                  createCustomer: createCustomer,
                  maxBodyHeight: maxBodyHeight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _QuickCustomerType { person, organization }

class _QuickCreateCustomerSheet extends StatefulWidget {
  const _QuickCreateCustomerSheet({
    required this.checkDuplicate,
    required this.createCustomer,
    required this.maxBodyHeight,
  });

  final SalesCustomerDuplicateCheckFn checkDuplicate;
  final SalesCustomerCreateFn createCustomer;
  final double maxBodyHeight;

  @override
  State<_QuickCreateCustomerSheet> createState() => _QuickCreateCustomerSheetState();
}

class _QuickCreateCustomerSheetState extends State<_QuickCreateCustomerSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _addressController = TextEditingController();

  _QuickCustomerType _type = _QuickCustomerType.person;
  String? _nameError;
  String? _phoneError;
  String? _operationError;
  bool _submitting = false;
  bool _leaveConfirmOpen = false;

  bool get _isDirty =>
      _nameController.text.trim().isNotEmpty ||
      _phoneController.text.trim().isNotEmpty ||
      _taxCodeController.text.trim().isNotEmpty ||
      _addressController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    void mark() {
      if (mounted) setState(() {});
    }

    _nameController.addListener(mark);
    _phoneController.addListener(mark);
    _taxCodeController.addListener(mark);
    _addressController.addListener(mark);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _taxCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// O-05 — Danger confirmation khi đóng form có thay đổi chưa lưu.
  Future<bool> _confirmDiscard() async {
    if (_leaveConfirmOpen) return false;
    _leaveConfirmOpen = true;
    final discard = await showVBottomSheet<bool>(
      context: context,
      tone: VComponentTone.danger,
      semanticLabel: 'Bỏ thay đổi chưa lưu',
      child: VPagePadding(
        child: Column(
          key: const Key('wgt_sg04_discard_unsaved_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Bỏ thay đổi chưa lưu?',
              variant: VTextVariant.headingH4,
              color: context.vColors.danger,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.sm(),
            VText(
              'Thông tin khách hàng đang nhập sẽ không được lưu.',
              variant: VTextVariant.bodySmall,
              color: context.vColors.textSecondary,
            ),
            const VGap.md(),
            VButton(
              key: const Key('btn_sg04_discard_confirm'),
              label: 'Bỏ thay đổi',
              variant: VButtonVariant.secondary,
              tone: VComponentTone.danger,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const VGap.sm(),
            VButton(
              key: const Key('btn_sg04_discard_continue'),
              label: 'Tiếp tục nhập',
              variant: VButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const VGap.sm(),
          ],
        ),
      ),
    );
    _leaveConfirmOpen = false;
    return discard == true;
  }

  Future<void> _requestClose() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_isDirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) Navigator.of(context).pop();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Vui lòng nhập tên khách hàng' : null;
      _phoneError = VPhoneValidator.validate(_phoneController.text, isRequired: true);
    });
    return _nameError == null && _phoneError == null;
  }

  Future<bool> _confirmDuplicate(SalesCustomerListItemVm duplicate) async {
    final useExisting = await showVBottomSheet<bool>(
      context: context,
      child: VPagePadding(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VText(
              'Có thể khách hàng đã tồn tại',
              variant: VTextVariant.headingH4,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.sm(),
            VBanner(
              status: VBannerStatus.warning,
              title: 'Trùng số điện thoại',
              description: '${duplicate.phone} trùng với ${duplicate.displayName}.',
            ),
            const VGap.md(),
            VButton(
              key: const Key('btn_sg04_duplicate_choose_existing'),
              label: 'Chọn khách hàng này',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const VGap.sm(),
            VButton(
              key: const Key('btn_sg04_duplicate_force_create'),
              label: 'Vẫn tạo mới',
              variant: VButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    return useExisting == true;
  }

  SalesQuickCustomerDraft _buildDraft() {
    return SalesQuickCustomerDraft(
      type: _type == _QuickCustomerType.person
          ? SalesQuickCustomerType.person
          : SalesQuickCustomerType.organization,
      displayName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      taxCode: _nullable(_taxCodeController.text),
      address: _nullable(_addressController.text),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() {
      _operationError = null;
      _submitting = true;
    });

    try {
      final draft = _buildDraft();
      final duplicate = await widget.checkDuplicate(draft);
      if (!mounted) return;

      if (duplicate != null) {
        final chooseExisting = await _confirmDuplicate(duplicate);
        if (!mounted) return;
        if (chooseExisting) {
          Navigator.of(context).pop(duplicate.toSelection());
          return;
        }
      }

      final created = await widget.createCustomer(
        draft,
        confirmDuplicate: duplicate != null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) return;
      final message = error is SalesCustomerOperationException
          ? error.message
          : 'Không thể kết nối để tạo khách hàng. Vui lòng thử lại.';
      setState(() => _operationError = message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _requestClose();
      },
      // Chỉ đặt TRẦN chiều cao; sheet co theo nội dung (không ép cứng) nên khi ít
      // field thì thấp, đỉnh không đẩy lên sát status bar. Khi nội dung/bàn phím
      // vượt trần thì phần danh sách tự cuộn.
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxBodyHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VPagePadding(
              child: Row(
                children: [
                  const Expanded(
                    child: VText(
                      'Tạo nhanh khách hàng',
                      variant: VTextVariant.headingH3,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  VIconBox(
                    key: const Key('btn_sg04_quick_create_close'),
                    icon: VIcons.close,
                    semanticLabel: 'Đóng',
                    size: 40,
                    iconSize: 20,
                    backgroundColor: Colors.transparent,
                    onTap: _requestClose,
                  ),
                ],
              ),
            ),
            const VPagePadding(
              child: VText(
                'Chỉ nhập thông tin cần thiết để tiếp tục bán hàng.',
                variant: VTextVariant.bodySmall,
              ),
            ),
            const VGap.md(),
            const VPagePadding(child: VDivider()),
            const VGap.md(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: VSpacing.space3),
                children: [
                  VPagePadding(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Loại khách hàng',
                                style: VTypography.headingH4.copyWith(
                                  color: context.vColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: context.vColors.danger),
                              ),
                            ],
                          ),
                        ),
                        const VGap.sm(),
                        RadioGroup<_QuickCustomerType>(
                          groupValue: _type,
                          onChanged: (val) {
                            if (val != null) setState(() => _type = val);
                          },
                          child: Row(
                            children: [
                              VRadio<_QuickCustomerType>(
                                value: _QuickCustomerType.person,
                                onChanged: null,
                                label: 'Cá nhân',
                              ),
                              const VGap.horizontalLg(),
                              VRadio<_QuickCustomerType>(
                                value: _QuickCustomerType.organization,
                                onChanged: null,
                                label: 'Tổ chức',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VGap.sm(),
                  VPagePadding(
                    child: VField(
                      invalid: _nameError != null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VFieldLabel('Tên khách hàng', isRequired: true),
                          VTextField(
                            key: const Key('input_sg04_quick_name'),
                            controller: _nameController,
                            hintText: _type == _QuickCustomerType.person
                                ? 'Ví dụ: Nguyễn Văn Bình'
                                : 'Ví dụ: Công ty Minh Phát',
                            onChanged: (_) => setState(() => _nameError = null),
                          ),
                          if (_nameError != null) VFieldError(_nameError!),
                        ],
                      ),
                    ),
                  ),
                  const VGap.sm(),
                  VPagePadding(
                    child: VPhoneField(
                      key: const Key('input_sg04_quick_phone'),
                      controller: _phoneController,
                      validateOnChanged: false,
                      label: 'Số điện thoại',
                      isRequired: true,
                      hintText: 'Ví dụ: 0988123456',
                      errorText: _phoneError,
                      onChanged: (_) => setState(() => _phoneError = null),
                    ),
                  ),
                  const VGap.sm(),
                  VPagePadding(
                    child: VField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VFieldLabel('Mã số thuế', isRequired: false),
                          VTextField(
                            controller: _taxCodeController,
                            hintText: 'Ví dụ: 0101234567',
                          ),
                          const VFieldDescription('Không bắt buộc'),
                        ],
                      ),
                    ),
                  ),
                  const VGap.sm(),
                  VPagePadding(
                    child: VField(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VFieldLabel('Địa chỉ', isRequired: false),
                          VTextArea(
                            controller: _addressController,
                            hintText: 'Ví dụ: 123 Đường ABC, Quận XYZ, TP. HCM',
                            minLines: 3,
                          ),
                          const VFieldDescription('Không bắt buộc'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_operationError != null)
              VPagePadding(
                vertical: VSpacing.space2,
                child: VBanner(
                  key: const Key('banner_sg04_quick_create_error'),
                  status: VBannerStatus.error,
                  title: 'Không thể tạo khách hàng',
                  description: _operationError!,
                ),
              ),
            VPagePadding(
              vertical: VSpacing.space3,
              child: VButton(
                key: const Key('btn_sg04_quick_create_submit'),
                label: 'Tạo & chọn khách hàng',
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
