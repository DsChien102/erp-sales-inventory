import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/invitation_acceptance_cubit.dart';
import '../bloc/invitation_acceptance_state.dart';
import '../widgets/invitation_registration_form.dart';
import '../widgets/invitation_token_entry_form.dart';

/// New-account registration step for S8 — email locked from inspection DTO.
class InvitationRegistrationPage extends StatelessWidget {
  const InvitationRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvitationAcceptanceCubit, InvitationAcceptanceState>(
      builder: (context, state) {
        final inspection = state.inspection;
        if (inspection == null) {
          return InvitationTokenEntryForm(
            isSubmitting: false,
            onInspect: context.read<InvitationAcceptanceCubit>().inspect,
          );
        }
        final cubit = context.read<InvitationAcceptanceCubit>();
        return InvitationRegistrationForm(
          inspection: inspection,
          isSubmitting: state.isSubmitting,
          onBack: cubit.reset,
          onRegister:
              ({
                required String givenName,
                required String familyName,
                String? phone,
                required String password,
              }) {
                return cubit.registerAndAccept(
                  givenName: givenName,
                  familyName: familyName,
                  phone: phone,
                  password: password,
                );
              },
        );
      },
    );
  }
}
