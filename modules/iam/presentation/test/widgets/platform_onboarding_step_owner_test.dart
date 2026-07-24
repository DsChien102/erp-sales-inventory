import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_presentation/src/widgets/platform_onboarding_step_owner.dart';

void main() {
  final sampleUsers = <PlatformUserSummaryDto>[
    PlatformUserSummaryDto(
      userId: 'u1',
      fullName: 'Lê Thị Lan',
      email: 'lan@gmail.com',
      status: PlatformUserStatus.active,
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
    ),
    PlatformUserSummaryDto(
      userId: 'u2',
      fullName: 'Trần Thị Hoa',
      email: 'hoa@gmail.com',
      status: PlatformUserStatus.active,
      createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
    ),
  ];

  Widget buildTestableWidget({
    bool isNewOwner = false,
    PlatformUserSummaryDto? selectedOwner,
    List<PlatformUserSummaryDto>? searchResults,
    ValueChanged<PlatformUserSummaryDto?>? onOwnerSelected,
    ValueChanged<bool>? onToggleNewOwner,
    ValueChanged<String>? onSearchQueryChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PlatformOnboardingStepOwner(
          isNewOwner: isNewOwner,
          selectedOwner: selectedOwner,
          lastNameController: TextEditingController(),
          firstNameController: TextEditingController(),
          emailController: TextEditingController(),
          phoneController: TextEditingController(),
          searchResults: searchResults ?? sampleUsers,
          onOwnerSelected: onOwnerSelected ?? (_) {},
          onToggleNewOwner: onToggleNewOwner ?? (_) {},
          onSearchQueryChanged: onSearchQueryChanged ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('renders VSearchBar initially without dropdown overlay', (tester) async {
    await tester.pumpWidget(buildTestableWidget());

    expect(find.byType(VSearchBar), findsOneWidget);
    expect(find.text('Lê Thị Lan'), findsNothing);
  });

  testWidgets('tapping search bar opens dropdown overlay with scrollable user VCards', (tester) async {
    await tester.pumpWidget(buildTestableWidget());

    await tester.tap(find.byType(VSearchBar));
    await tester.pumpAndSettle();

    expect(find.text('Lê Thị Lan'), findsOneWidget);
    expect(find.text('Trần Thị Hoa'), findsOneWidget);
    // 1 VCard cho container overlay + 2 VCard cho 2 item người dùng
    expect(find.byType(VCard), findsNWidgets(3));
  });

  testWidgets('selecting an item from dropdown overlay immediately displays selected owner VCard', (tester) async {
    PlatformUserSummaryDto? currentSelected;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: PlatformOnboardingStepOwner(
                isNewOwner: false,
                selectedOwner: currentSelected,
                lastNameController: TextEditingController(),
                firstNameController: TextEditingController(),
                emailController: TextEditingController(),
                phoneController: TextEditingController(),
                searchResults: sampleUsers,
                onOwnerSelected: (user) {
                  setState(() {
                    currentSelected = user;
                  });
                },
                onToggleNewOwner: (_) {},
                onSearchQueryChanged: (_) {},
              ),
            ),
          );
        },
      ),
    );

    // Initial state: no selected owner VCard
    expect(find.text('Người dùng đã chọn'), findsNothing);

    // Tap search bar to open overlay dropdown
    await tester.tap(find.byType(VSearchBar));
    await tester.pumpAndSettle();

    // Select 'Lê Thị Lan'
    await tester.tap(find.text('Lê Thị Lan'));
    await tester.pumpAndSettle();

    // Overlay list closed and selected VCard displayed right below search bar
    expect(find.text('Người dùng đã chọn'), findsOneWidget);
    expect(find.text('Lê Thị Lan'), findsOneWidget);
    expect(find.text('lan@gmail.com'), findsOneWidget);
    expect(find.text('Trần Thị Hoa'), findsNothing);

    // Tapping VSearchBar again resets search and re-opens overlay
    await tester.tap(find.byType(VSearchBar));
    await tester.pumpAndSettle();

    // Overlay is open again showing candidate list, selected VCard is hidden while overlay is open
    expect(find.text('Người dùng đã chọn'), findsNothing);
    expect(find.text('Trần Thị Hoa'), findsOneWidget);
  });

  testWidgets('renders creation form directly without top header row when isNewOwner is true', (tester) async {
    await tester.pumpWidget(buildTestableWidget(isNewOwner: true));

    expect(find.text('Tạo chủ sở hữu mới'), findsNothing);
    expect(find.text('Chọn người dùng cũ'), findsNothing);
    expect(find.byType(VTextField), findsNWidgets(4));
    expect(find.text('Quy ước tài khoản'), findsOneWidget);
  });
}
