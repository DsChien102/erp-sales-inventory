import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'invitation_entry_narrow.dart';
import 'invitation_entry_wide.dart';

/// ID-D-01 — Trang Nhập mã lời mời.
///
/// Ô nhập alphanumeric 8 ký tự (tự viết HOA); backend chuẩn hoá (bỏ gạch + viết HOA).
class InvitationTokenEntryForm extends StatefulWidget {
  const InvitationTokenEntryForm({
    super.key,
    required this.isSubmitting,
    required this.onInspect,
    this.errorMessage,
    this.onEditing,
  });

  final bool isSubmitting;
  final ValueChanged<String> onInspect;
  final String? errorMessage;
  final VoidCallback? onEditing;

  @override
  State<InvitationTokenEntryForm> createState() =>
      _InvitationTokenEntryFormState();
}

class _InvitationTokenEntryFormState extends State<InvitationTokenEntryForm> {
  final _codeFieldKey = GlobalKey();
  String _token = '';
  String? _error;

  static final _tokenPattern = RegExp(r'^[0-9A-Z]{8}$');

  void _submit() {
    final token = _token.trim();
    if (!_tokenPattern.hasMatch(token)) {
      setState(
        () => _error = token.isEmpty
            ? 'Vui lòng nhập mã lời mời'
            : 'Mã lời mời phải gồm 8 ký tự chữ hoặc số',
      );
      return;
    }
    setState(() => _error = null);
    widget.onInspect(token);
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final isSubmitting = widget.isSubmitting;
    final error = _error ?? widget.errorMessage;

    final codeField = VField(
      invalid: error != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Mã lời mời', isRequired: true),
          KeyedSubtree(
            key: const Key('invitation_token_input'),
            child: VVerificationCodeField(
              key: _codeFieldKey,
              length: 8,
              charset: VVerificationCodeCharset.alphanumeric,
              layout: wide
                  ? VVerificationCodeLayout.fill
                  : VVerificationCodeLayout.split4,
              autofocus: true,
              enabled: !isSubmitting,
              onChanged: (value) {
                setState(() {
                  _token = value;
                  if (_error != null) _error = null;
                });
                widget.onEditing?.call();
              },
              onCompleted: (_) => _submit(),
            ),
          ),
          if (error != null)
            VFieldError(error)
          else
            const VFieldDescription(
              'Mã không phân biệt chữ hoa và chữ thường.',
            ),
        ],
      ),
    );

    void onBack() => context.go('/login');

    return wide
        ? InvitationEntryWide(
            codeField: codeField,
            isSubmitting: isSubmitting,
            onSubmit: _submit,
            onBack: onBack,
          )
        : InvitationEntryNarrow(
            codeField: codeField,
            isSubmitting: isSubmitting,
            onSubmit: _submit,
            onBack: onBack,
          );
  }
}
