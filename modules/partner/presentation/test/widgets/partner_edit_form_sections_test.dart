import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_partner_presentation/presentation.dart';

void main() {
  testWidgets('edit form sections render loaded partner values', (tester) async {
    final nameController = TextEditingController(text: 'Nguyen Van An');
    final phoneController = TextEditingController(text: '0912345678');
    final emailController = TextEditingController(text: 'an@example.com');
    final addressController = TextEditingController(text: '123 Nguyen Trai');
    final taxController = TextEditingController(text: '0312345678');
    final billingNameController = TextEditingController(text: 'Cong ty An');
    final billingAddressController = TextEditingController(text: '456 Le Loi');
    final billingEmailController = TextEditingController(text: 'billing@example.com');
    final noteController = TextEditingController(text: 'Khach hang uu tien');

    addTearDown(() {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      addressController.dispose();
      taxController.dispose();
      billingNameController.dispose();
      billingAddressController.dispose();
      billingEmailController.dispose();
      noteController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                PartnerRoleTypeSection(
                  role: 'customer',
                  profileType: 'individual',
                  nameController: nameController,
                  name: nameController.text,
                  contactName: '',
                  onRoleChanged: (_) {},
                  onProfileTypeChanged: (_) {},
                  onNameChanged: (_) {},
                  onContactNameChanged: (_) {},
                  showValidationErrors: false,
                ),
                PartnerContactInfoSection(
                  phone: phoneController.text,
                  phoneController: phoneController,
                  onPhoneChanged: (_) {},
                  email: emailController.text,
                  emailController: emailController,
                  onEmailChanged: (_) {},
                  address: addressController.text,
                  addressController: addressController,
                  onAddressChanged: (_) {},
                  showValidationErrors: false,
                ),
                PartnerTaxInfoSection(
                  taxId: taxController.text,
                  taxIdController: taxController,
                  onTaxIdChanged: (_) {},
                  profileType: 'individual',
                  showValidationErrors: false,
                ),
                PartnerBillingInfoSection(
                  billingNameController: billingNameController,
                  billingAddressController: billingAddressController,
                  billingEmailController: billingEmailController,
                  onBillingNameChanged: (_) {},
                  onBillingAddressChanged: (_) {},
                  onBillingEmailChanged: (_) {},
                  billingEmail: billingEmailController.text,
                  showValidationErrors: false,
                ),
                PartnerNoteSection(
                  note: noteController.text,
                  noteController: noteController,
                  onNoteChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nguyen Van An'), findsOneWidget);
    expect(find.text('0912345678'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    expect(find.text('123 Nguyen Trai'), findsOneWidget);
    expect(find.text('0312345678'), findsOneWidget);
    expect(find.text('Cong ty An'), findsOneWidget);
    expect(find.text('456 Le Loi'), findsOneWidget);
    expect(find.text('billing@example.com'), findsOneWidget);
    expect(find.text('Khach hang uu tien'), findsOneWidget);
  });
}
