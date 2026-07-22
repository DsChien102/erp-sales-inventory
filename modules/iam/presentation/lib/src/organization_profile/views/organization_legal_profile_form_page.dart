import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../data/vn_administrative_units_loader.dart';
import '../mock/organization_profile_mock_data.dart';
import '../models/organization_profile_ui_model.dart';
import '../widgets/tax_code_duplicate_warning_bottom_sheet.dart';
import '../../organizations/widgets/organization_empty_view.dart';

/// Trang Thêm / Chỉnh sửa hồ sơ pháp lý (TA-D-03 & TA-D-04).
class OrganizationLegalProfileFormPage extends StatefulWidget {
  final bool isEdit;
  final bool hasPermission;
  final LegalProfileUiModel? initialProfile;

  const OrganizationLegalProfileFormPage({
    super.key,
    this.isEdit = false,
    this.hasPermission = true,
    this.initialProfile = OrganizationProfileMockData.sampleLegalProfile,
  });

  @override
  State<OrganizationLegalProfileFormPage> createState() => _OrganizationLegalProfileFormPageState();
}

class _OrganizationLegalProfileFormPageState extends State<OrganizationLegalProfileFormPage> {
  late final TextEditingController _legalNameController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _addressController;
  late final Future<List<VnAdministrativeUnit>> _unitsFuture = VnAdministrativeUnitsLoader.load();

  String? _selectedEntityType;
  String? _selectedCity;
  String? _selectedWard;

  VnAdministrativeUnit? _findProvince(
    List<VnAdministrativeUnit> units,
    String? name,
  ) {
    if (name == null || name.isEmpty) return null;
    for (final unit in units) {
      if (unit.fullName == name ||
          unit.fullName.endsWith(name) ||
          name.endsWith(unit.fullName)) {
        return unit;
      }
    }
    return null;
  }

  VnWard? _findWard(
    List<VnWard> wards,
    String? name,
  ) {
    if (name == null || name.isEmpty) return null;
    for (final ward in wards) {
      if (ward.fullName == name ||
          ward.fullName.endsWith(name) ||
          name.endsWith(ward.fullName)) {
        return ward;
      }
    }
    return null;
  }

  // Validation error messages
  String? _entityTypeError;
  String? _legalNameError;
  String? _taxCodeError;

  // Initial values for change tracking
  late final String _initialEntityType;
  late final String _initialLegalName;
  late final String _initialTaxCode;
  late final String _initialAddress;
  late final String _initialCity;
  late final String _initialWard;

  @override
  void initState() {
    super.initState();
    final profile = widget.isEdit ? widget.initialProfile : null;

    _initialEntityType = profile?.entityType ?? '';
    _initialLegalName = profile?.legalName ?? '';
    _initialTaxCode = profile?.taxCode ?? '';
    _initialAddress = profile?.registeredAddress ?? '';
    _initialCity = profile?.city ?? '';
    _initialWard = profile?.ward ?? '';

    _selectedEntityType = widget.isEdit ? profile?.entityType : null;
    _selectedCity = widget.isEdit ? profile?.city : null;
    _selectedWard = widget.isEdit ? profile?.ward : null;

    _legalNameController = TextEditingController(text: _initialLegalName);
    _taxCodeController = TextEditingController(text: _initialTaxCode);
    _addressController = TextEditingController(text: _initialAddress);

    _legalNameController.addListener(_onFieldChanged);
    _taxCodeController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      if (_legalNameController.text.trim().isNotEmpty) {
        _legalNameError = null;
      }
      if (_taxCodeController.text.trim().isNotEmpty) {
        _taxCodeError = null;
      }
    });
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _taxCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (!widget.isEdit) {
      return (_selectedEntityType != null && _selectedEntityType!.isNotEmpty) ||
          _legalNameController.text.trim().isNotEmpty ||
          _taxCodeController.text.trim().isNotEmpty ||
          _addressController.text.trim().isNotEmpty ||
          (_selectedCity != null && _selectedCity!.isNotEmpty) ||
          (_selectedWard != null && _selectedWard!.isNotEmpty);
    } else {
      return (_selectedEntityType ?? '') != _initialEntityType ||
          _legalNameController.text.trim() != _initialLegalName ||
          _taxCodeController.text.trim() != _initialTaxCode ||
          _addressController.text.trim() != _initialAddress ||
          (_selectedCity ?? '') != _initialCity ||
          (_selectedWard ?? '') != _initialWard;
    }
  }

  void _saveProfile() {
    // 1. Kiểm tra các trường bắt buộc
    bool isValid = true;

    if (_selectedEntityType == null || _selectedEntityType!.isEmpty) {
      _entityTypeError = 'Vui lòng chọn loại chủ thể';
      isValid = false;
    } else {
      _entityTypeError = null;
    }

    if (_legalNameController.text.trim().isEmpty) {
      _legalNameError = 'Vui lòng nhập tên pháp lý';
      isValid = false;
    } else {
      _legalNameError = null;
    }

    if (_taxCodeController.text.trim().isEmpty) {
      _taxCodeError = 'Vui lòng nhập mã số thuế';
      isValid = false;
    } else {
      _taxCodeError = null;
    }

    if (!isValid) {
      setState(() {});
      VToast.show(
        context,
        title: 'Thiếu thông tin',
        message: 'Vui lòng điền đầy đủ các thông tin bắt buộc',
        type: VToastType.danger,
      );
      return;
    }

    // 2. Giả lập kiểm tra trùng mã số thuế (TA-O-02)
    final taxCode = _taxCodeController.text.trim();
    if (taxCode == '360123456789' || taxCode.endsWith('999')) {
      showVBottomSheet(
        context: context,
        child: TaxCodeDuplicateWarningBottomSheet(
          onSaveAnyway: () {
            _completeSave();
          },
          onReview: () {},
        ),
      );
    } else {
      _completeSave();
    }
  }

  void _completeSave() {
    VToast.show(
      context,
      title: 'Đã lưu hồ sơ pháp lý.',
      message: '',
      type: VToastType.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasPermission) {
      return VPageScaffold(
        title: widget.isEdit ? 'Chỉnh hồ sơ pháp lý' : 'Thêm hồ sơ pháp lý',
        body: OrganizationEmptyView(
          type: OrganizationEmptyStateType.unauthorized,
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final colors = context.vColors;

    return VPageScaffold(
      title: widget.isEdit ? 'Chỉnh hồ sơ pháp lý' : 'Thêm hồ sơ pháp lý',
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Row(
          children: [
            Expanded(
              child: VButton(
                label: 'Hủy',
                variant: VButtonVariant.outline,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: VButton(
                label: 'Lưu hồ sơ',
                variant: VButtonVariant.primary,
                tone: VComponentTone.success,
                fullWidth: true,
                onPressed: _hasChanges ? _saveProfile : null,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        children: [
          VText(
            'Thay đổi hiện tại không làm thay đổi chứng từ lịch sử.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.md(),

          // Field 1: Loại chủ thể *
          VDropdown<String>(
            label: 'Loại chủ thể',
            hintText: 'Chọn loại chủ thể',
            value: _selectedEntityType,
            tone: _entityTypeError != null ? VComponentTone.danger : VComponentTone.neutral,
            items: const [
              DropdownMenuItem(value: 'Hộ kinh doanh', child: VText('Hộ kinh doanh')),
              DropdownMenuItem(value: 'Công ty TNHH', child: VText('Công ty TNHH')),
              DropdownMenuItem(value: 'Công ty Cổ phần', child: VText('Công ty Cổ phần')),
              DropdownMenuItem(value: 'Doanh nghiệp tư nhân', child: VText('Doanh nghiệp tư nhân')),
            ],
            onChanged: (val) {
              setState(() {
                _selectedEntityType = val;
                _entityTypeError = null;
              });
            },
          ),
          if (_entityTypeError != null) ...[
            const VGap.xs(),
            VText(
              _entityTypeError!,
              variant: VTextVariant.bodySmall,
              color: colors.danger,
            ),
          ],
          const VGap.md(),

          // Field 2: Tên pháp lý *
          VTextField(
            label: 'Tên pháp lý',
            isRequired: true,
            hintText: 'Nhập tên pháp lý',
            controller: _legalNameController,
            errorText: _legalNameError,
            tone: _legalNameError != null ? VComponentTone.danger : VComponentTone.neutral,
          ),
          const VGap.md(),

          // Field 3: Mã số thuế *
          VTextField(
            label: 'Mã số thuế',
            isRequired: true,
            hintText: 'Nhập mã số thuế',
            controller: _taxCodeController,
            keyboardType: TextInputType.number,
            errorText: _taxCodeError,
            tone: _taxCodeError != null ? VComponentTone.danger : VComponentTone.neutral,
          ),
          const VGap.md(),

          // Field 4: Địa chỉ đăng ký
          VTextField(
            label: 'Địa chỉ đăng ký',
            hintText: 'Nhập địa chỉ đăng ký',
            controller: _addressController,
          ),
          const VGap.md(),

          // Field 5 & 6: Tỉnh / thành phố & Xã / phường
          FutureBuilder<List<VnAdministrativeUnit>>(
            future: _unitsFuture,
            builder: (context, snapshot) {
              final units = snapshot.data ?? const [];
              final selectedProvince = _findProvince(units, _selectedCity);
              final provinceItems = units.isNotEmpty
                  ? units
                      .map((u) => DropdownMenuItem<String>(
                            value: u.fullName,
                            child: VText(u.fullName),
                          ))
                      .toList(growable: false)
                  : [
                      if (_selectedCity != null)
                        DropdownMenuItem<String>(
                          value: _selectedCity,
                          child: VText(_selectedCity!),
                        ),
                    ];

              final wardList = selectedProvince?.wards ?? const <VnWard>[];
              final wardItems = wardList.isNotEmpty
                  ? wardList
                      .map((w) => DropdownMenuItem<String>(
                            value: w.fullName,
                            child: VText(w.fullName),
                          ))
                      .toList(growable: false)
                  : [
                      if (_selectedWard != null)
                        DropdownMenuItem<String>(
                          value: _selectedWard,
                          child: VText(_selectedWard!),
                        ),
                    ];

              final effectiveCity = provinceItems.any((item) => item.value == _selectedCity)
                  ? _selectedCity
                  : (selectedProvince?.fullName ?? _selectedCity);

              final effectiveWard = wardItems.any((item) => item.value == _selectedWard)
                  ? _selectedWard
                  : (_findWard(wardList, _selectedWard)?.fullName ?? _selectedWard);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VDropdown<String>(
                    label: 'Tỉnh / thành phố',
                    hintText: 'Chọn tỉnh / thành phố',
                    value: effectiveCity,
                    items: provinceItems,
                    onChanged: (val) {
                      setState(() {
                        _selectedCity = val;
                        _selectedWard = null;
                      });
                    },
                  ),
                  const VGap.md(),
                  VDropdown<String>(
                    label: 'Xã / phường',
                    hintText: _selectedCity != null && _selectedCity!.isNotEmpty
                        ? 'Chọn xã / phường'
                        : 'Chọn tỉnh / thành phố trước',
                    enabled: _selectedCity != null && _selectedCity!.isNotEmpty,
                    value: effectiveWard,
                    items: wardItems,
                    onChanged: (val) {
                      setState(() {
                        _selectedWard = val;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          const VGap.md(),
        ],
      ),
    );
  }
}
