import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import 'package:vet45_partner_presentation/presentation.dart';
import 'package:vet45_shared_application/application.dart';

class PartnerContactFormPage extends StatefulWidget {
  const PartnerContactFormPage({
    super.key,
    required this.partnerId,
    this.contactId,
    this.contact,
    required this.partnerModule,
    required this.executionContext,
  });

  final String partnerId;
  final String? contactId;
  final PartnerContactDto? contact;
  final IPartnerModule partnerModule;
  final IExecutionContext executionContext;

  @override
  State<PartnerContactFormPage> createState() => _PartnerContactFormPageState();
}

class _PartnerContactFormPageState extends State<PartnerContactFormPage> {
  late final PartnerContactFormCubit _cubit;
  VoidCallback? _submitForm;

  String? _lastFullName;
  String? _lastPhone;
  String? _lastEmail;
  String? _lastContactRole;
  bool _lastIsPrimary = false;
  String? _lastNote;

  @override
  void initState() {
    super.initState();
    _cubit = PartnerContactFormCubit(
      partnerModule: widget.partnerModule,
      executionContext: widget.executionContext,
    );

    if (widget.contactId != null) {
      _cubit.loadPersonDetail(widget.contactId!);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _showDuplicate(
    BuildContext context,
    PartnerContactFormState state,
  ) async {
    final level = state.duplicateLevel;
    if (level == null || state.duplicateMatches.isEmpty) return;
    final firstMatch = state.duplicateMatches.first;
    await showPartnerDuplicateSheet(
      context: context,
      level: level,
      matches: state.duplicateMatches,
      onBack: () {
        Navigator.of(context).pop();
        _cubit.dismissDuplicate();
      },
      onOpenExisting: () {
        Navigator.of(context).pop();
        context.push('/partner/${firstMatch.partnerId}');
      },
      onContinue: level == PartnerDuplicateMatchLevel.possible
          ? () {
              Navigator.of(context).pop();
              if (mounted) {
                _cubit.createContact(
                  organizationPartnerId: widget.partnerId,
                  fullName: _lastFullName ?? '',
                  phone: _lastPhone ?? '',
                  email: _lastEmail,
                  contactRole: _lastContactRole,
                  isPrimary: _lastIsPrimary,
                  note: _lastNote,
                  ignoreDuplicate: true,
                );
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEdit = widget.contactId != null;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: VAppBar(
          title: isEdit ? 'Chỉnh sửa liên hệ' : 'Thêm người liên hệ',
          centerTitle: true,
          leading: TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Hủy',
              style: VTypography.bodyDefault.copyWith(
                color: colors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _submitForm,
              child: Text(
                'Lưu',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        body: BlocConsumer<PartnerContactFormCubit, PartnerContactFormState>(
          listener: (context, state) {
            if (state.status == PartnerContactFormStatus.success) {
              // Pop first — toast on this route is cleared when the page disposes.
              context.pop(true);
            }
            if (state.status == PartnerContactFormStatus.duplicate) {
              _showDuplicate(context, state);
            }
          },
          builder: (context, state) {
            if (state.status == PartnerContactFormStatus.loadingPersonDetail) {
              return const Center(child: CircularProgressIndicator());
            }

            return PartnerContactForm(
              key: const Key('wgt_contact_form'),
              contact: widget.contact,
              isSubmitting: state.status == PartnerContactFormStatus.submitting,
              errorMessage: state.errorMessage,
              onFormCreated: (submitFn) {
                if (_submitForm == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _submitForm = submitFn;
                      });
                    }
                  });
                }
              },
              onSubmit: (fullName, phone, email, contactRole, isPrimary, note) {
                _lastFullName = fullName;
                _lastPhone = phone;
                _lastEmail = email;
                _lastContactRole = contactRole;
                _lastIsPrimary = isPrimary;
                _lastNote = note;

                if (isEdit) {
                  _cubit.editContact(
                    organizationPartnerId: widget.partnerId,
                    personPartnerId: widget.contactId!,
                    fullName: fullName,
                    phone: phone,
                    email: email,
                    contactRole: contactRole,
                    isPrimary: isPrimary,
                    note: note,
                  );
                } else {
                  _cubit.createContact(
                    organizationPartnerId: widget.partnerId,
                    fullName: fullName,
                    phone: phone,
                    email: email,
                    contactRole: contactRole,
                    isPrimary: isPrimary,
                    note: note,
                  );
                }
              },
              onCancel: () => context.pop(),
            );
          },
        ),
      ),
    );
  }
}
