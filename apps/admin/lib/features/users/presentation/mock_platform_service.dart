import 'package:flutter/foundation.dart';
import 'package:vet45_iam_application/application.dart';

class MockPlatformService extends ChangeNotifier {
  MockPlatformService._() {
    _initMockData();
  }

  static final MockPlatformService instance = MockPlatformService._();

  late List<PlatformUserDetailDto> _users;
  late List<Map<String, dynamic>> _organizations; // tenantId, name, status, createdAt

  void _initMockData() {
    _organizations = [
      {
        'tenantId': 'mau-hien',
        'name': 'Mậu Hiên',
        'status': 'active',
        'createdAt': DateTime(2026, 7, 12, 8, 0),
      },
      {
        'tenantId': 'asc-commerce',
        'name': 'ASC Commerce',
        'status': 'active',
        'createdAt': DateTime(2026, 7, 13, 8, 20),
      },
    ];

    _users = [
      PlatformUserDetailDto(
        userId: 'lan-le',
        fullName: 'Lê Thị Lan',
        email: 'lan@gmail.com',
        status: PlatformUserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 7, 12, 7, 0),
        lastLoginAt: DateTime(2026, 7, 13, 9, 18),
        memberships: [
          const PlatformUserMembershipDto(
            tenantId: 'mau-hien',
            tenantName: 'Mậu Hiên',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
          const PlatformUserMembershipDto(
            tenantId: 'asc-commerce',
            tenantName: 'ASC Commerce',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
          ),
        ],
      ),
      PlatformUserDetailDto(
        userId: 'hoa-tran',
        fullName: 'Trần Thị Hoa',
        email: 'hoa@gmail.com',
        status: PlatformUserStatus.pendingActivation,
        emailVerified: false,
        createdAt: DateTime(2026, 7, 12, 15, 0),
        memberships: [
          const PlatformUserMembershipDto(
            tenantId: 'mau-hien',
            tenantName: 'Mậu Hiên',
            roleLabel: 'Nhân viên',
            isOwner: false,
          ),
          const PlatformUserMembershipDto(
            tenantId: 'asc-commerce',
            tenantName: 'ASC Commerce',
            roleLabel: 'Nhân viên',
            isOwner: false,
          ),
        ],
      ),
      PlatformUserDetailDto(
        userId: 'minh-nguyen',
        fullName: 'Nguyễn Văn Minh',
        email: 'minh@gmail.com',
        status: PlatformUserStatus.suspended,
        emailVerified: true,
        createdAt: DateTime(2026, 7, 12, 15, 5),
        lastLoginAt: DateTime(2026, 7, 13, 9, 30),
        memberships: [
          const PlatformUserMembershipDto(
            tenantId: 'mau-hien',
            tenantName: 'Mậu Hiên',
            roleLabel: 'Quản trị viên',
            isOwner: false,
          ),
        ],
      ),
      PlatformUserDetailDto(
        userId: 'ha-pham',
        fullName: 'Phạm Thu Hà',
        email: 'ha@gmail.com',
        status: PlatformUserStatus.active,
        emailVerified: true,
        createdAt: DateTime(2026, 7, 12, 16, 0),
        lastLoginAt: DateTime(2026, 7, 13, 11, 20),
        memberships: [],
      ),
    ];
  }

  // --- Queries ---

  List<PlatformUserSummaryDto> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  }) {
    Iterable<PlatformUserDetailDto> filtered = _users;

    if (status != null) {
      filtered = filtered.where((u) => u.status == status);
    }

    if (query != null && query.isNotEmpty) {
      final normalizedQuery = query.toLowerCase();
      filtered = filtered.where((u) =>
          u.fullName.toLowerCase().contains(normalizedQuery) ||
          u.email.toLowerCase().contains(normalizedQuery));
    }

    return filtered
        .map((u) => PlatformUserSummaryDto(
              userId: u.userId,
              fullName: u.fullName,
              email: u.email,
              status: u.status,
              createdAt: u.createdAt,
            ))
        .toList();
  }

  PlatformUserDetailDto? getPlatformUser(String userId) {
    try {
      return _users.firstWhere((u) => u.userId == userId);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getOrganizations() {
    return _organizations;
  }

  // --- Commands ---

  void suspendPlatformUser(String userId, String reason) {
    final index = _users.indexWhere((u) => u.userId == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = PlatformUserDetailDto(
        userId: user.userId,
        fullName: user.fullName,
        email: user.email,
        status: PlatformUserStatus.suspended,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
        memberships: user.memberships,
      );
      notifyListeners();
    }
  }

  void restorePlatformUser(String userId) {
    final index = _users.indexWhere((u) => u.userId == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = PlatformUserDetailDto(
        userId: user.userId,
        fullName: user.fullName,
        email: user.email,
        status: PlatformUserStatus.active,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
        memberships: user.memberships,
      );
      notifyListeners();
    }
  }

  void sendActivationInvitation(String userId) {
    // Simulates sending activation email
    notifyListeners();
  }

  void requestPlatformPasswordReset(String userId) {
    // Simulates sending password reset email
    notifyListeners();
  }

  TenantOnboardingResultDto createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    String? idempotencyKey,
  }) {
    final tenantId = 'tenant-${DateTime.now().millisecondsSinceEpoch}';
    final membershipId = 'mem-${DateTime.now().millisecondsSinceEpoch}';
    String ownerUserId = '';
    bool isNewUser = false;

    if (owner.isExisting) {
      ownerUserId = owner.existingUserId!;
      final userIndex = _users.indexWhere((u) => u.userId == ownerUserId);
      if (userIndex != -1) {
        final user = _users[userIndex];
        final newMembership = PlatformUserMembershipDto(
          tenantId: tenantId,
          tenantName: organizationName,
          roleLabel: 'Chủ cửa hàng',
          isOwner: true,
        );
        _users[userIndex] = PlatformUserDetailDto(
          userId: user.userId,
          fullName: user.fullName,
          email: user.email,
          status: user.status,
          emailVerified: user.emailVerified,
          createdAt: user.createdAt,
          lastLoginAt: user.lastLoginAt,
          memberships: [...user.memberships, newMembership],
        );
      }
    } else {
      ownerUserId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      isNewUser = true;
      final newMembership = PlatformUserMembershipDto(
        tenantId: tenantId,
        tenantName: organizationName,
        roleLabel: 'Chủ cửa hàng',
        isOwner: true,
      );
      final newUser = PlatformUserDetailDto(
        userId: ownerUserId,
        fullName: '${owner.lastName} ${owner.firstName}'.trim(),
        email: owner.email!,
        status: PlatformUserStatus.pendingActivation,
        emailVerified: false,
        createdAt: DateTime.now(),
        memberships: [newMembership],
      );
      _users.add(newUser);
    }

    _organizations.add({
      'tenantId': tenantId,
      'name': organizationName,
      'status': 'provisioning',
      'createdAt': DateTime.now(),
    });

    notifyListeners();

    return TenantOnboardingResultDto(
      tenantId: tenantId,
      ownerMembershipId: membershipId,
      ownerUserId: ownerUserId,
      tenantStatus: 'provisioning',
      correlationId: 'corr-${DateTime.now().millisecondsSinceEpoch}',
      isNewUser: isNewUser,
    );
  }
}
