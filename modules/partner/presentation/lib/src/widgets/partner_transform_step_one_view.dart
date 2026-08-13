import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_domain/domain.dart';

import 'partner_transform_blocking_banner.dart';
import 'partner_transform_organization_form.dart';
import 'partner_transform_primary_contact_card.dart';
import 'partner_transform_step_one_validator.dart';
import 'partner_transform_stepper.dart';

class PartnerTransformStepOneView extends StatefulWidget {
  const PartnerTransformStepOneView({
    super.key,
    required this.partner,
    required this.onCancel,
    required this.onContinue,
    this.initialValue,
    this.serverFieldErrors = const {},
  });

  final PartnerDetailDto partner;
  final VoidCallback onCancel;
  final ValueChanged<OrganizationProfileInput> onContinue;
  final OrganizationProfileInput? initialValue;
  final Map<String, String> serverFieldErrors;

  @override
  State<PartnerTransformStepOneView> createState() => _PartnerTransformStepOneViewState();
}

class _PartnerTransformStepOneViewState extends State<PartnerTransformStepOneView> {
  OrganizationType? _organizationType;
  late String _organizationName;
  late String _shortName;
  late String _internationalName;
  late String _phone;
  late String _email;
  late String _taxCode;
  bool _attemptedContinue = false;
  Map<String, String> _errors = const {};
  late Map<String, String> _serverErrors;

  bool get _showBlockingBanner => _attemptedContinue && _errors.isNotEmpty && _serverErrors.isEmpty;

  bool get _canContinue => PartnerTransformStepOneValidator.validate(
    organizationType: _organizationType,
    organizationName: _organizationName,
    phone: _phone,
    email: _email,
    taxCode: _taxCode,
  ).isEmpty;

  Map<String, String> get _displayErrors => {
    ...(_attemptedContinue ? _errors : const <String, String>{}),
    ..._serverErrors,
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _organizationType = initial?.organizationType;
    _organizationName = initial?.organizationName ?? '';
    _shortName = initial?.shortName ?? '';
    _internationalName = initial?.intlName ?? '';
    _phone = initial?.phone ?? '';
    _email = initial?.email ?? '';
    _taxCode = initial?.taxCode ?? '';
    _serverErrors = Map<String, String>.from(widget.serverFieldErrors);
  }

  @override
  void didUpdateWidget(covariant PartnerTransformStepOneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapEquals(oldWidget.serverFieldErrors, widget.serverFieldErrors)) {
      _serverErrors = Map<String, String>.from(widget.serverFieldErrors);
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.partner.personProfile;
    assert(person != null, 'Transform step one requires a person profile');

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        VSpacing.space3,
        VSpacing.space3,
        VSpacing.space3,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PartnerTransformStepper(),
          const SizedBox(height: VSpacing.space3),
          Align(
            child: Container(
              width: 96,
              height: 4,
              decoration: BoxDecoration(
                color: context.vColors.borderStrong,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: VSpacing.space4),
          PartnerTransformOrganizationForm(
            organizationType: _organizationType,
            organizationName: _organizationName,
            shortName: _shortName,
            internationalName: _internationalName,
            phone: _phone,
            email: _email,
            taxCode: _taxCode,
            errors: _displayErrors,
            onOrganizationTypeChanged: (value) {
              setState(() {
                _organizationType = value;
                _refreshErrors();
              });
            },
            onOrganizationNameChanged: (value) {
              setState(() {
                _organizationName = value;
                _serverErrors.remove('organizationName');
                _refreshErrors();
              });
            },
            onShortNameChanged: (value) {
              setState(() => _shortName = value);
            },
            onInternationalNameChanged: (value) {
              setState(() => _internationalName = value);
            },
            onPhoneChanged: (value) {
              setState(() {
                _phone = value;
                _serverErrors.remove('phone');
                _refreshErrors();
              });
            },
            onEmailChanged: (value) {
              setState(() {
                _email = value;
                _serverErrors.remove('email');
                _refreshErrors();
              });
            },
            onTaxCodeChanged: (value) {
              setState(() {
                _taxCode = value;
                _serverErrors.remove('taxCode');
                _refreshErrors();
              });
            },
          ),
          const SizedBox(height: VSpacing.space4),
          PartnerTransformPrimaryContactCard(person: person!),
          if (_showBlockingBanner) ...[
            const SizedBox(height: VSpacing.space3),
            const PartnerTransformBlockingBanner(),
          ],
          const SizedBox(height: VSpacing.space3),
          _TransformActions(
            canContinue: !_attemptedContinue || _canContinue,
            onCancel: widget.onCancel,
            onContinue: _submit,
          ),
        ],
      ),
    );
  }

  void _refreshErrors() {
    if (!_attemptedContinue) return;
    _errors = PartnerTransformStepOneValidator.validate(
      organizationType: _organizationType,
      organizationName: _organizationName,
      phone: _phone,
      email: _email,
      taxCode: _taxCode,
    );
  }

  void _submit() {
    final errors = PartnerTransformStepOneValidator.validate(
      organizationType: _organizationType,
      organizationName: _organizationName,
      phone: _phone,
      email: _email,
      taxCode: _taxCode,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _attemptedContinue = true;
        _errors = errors;
      });
      return;
    }

    final organizationType = _organizationType;
    if (organizationType == null) return;

    widget.onContinue(
      OrganizationProfileInput(
        organizationType: organizationType,
        organizationName: _organizationName.trim(),
        shortName: _optional(_shortName),
        intlName: _optional(_internationalName),
        phone: _phone.trim(),
        email: _optional(_email),
        taxCode: _optional(_taxCode),
      ),
    );
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

class _TransformActions extends StatelessWidget {
  const _TransformActions({
    required this.canContinue,
    required this.onCancel,
    required this.onContinue,
  });

  final bool canContinue;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: VSpacing.space3),
      child: Row(
        children: [
          Expanded(
            child: VButton(
              key: const Key('transform_cancel'),
              label: 'Bỏ qua',
              variant: VButtonVariant.secondary,
              foregroundColor: context.vColors.success,
              onPressed: onCancel,
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: VButton(
              key: const Key('transform_continue'),
              label: 'Tiếp',
              onPressed: canContinue ? onContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}
