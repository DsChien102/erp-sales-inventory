import 'package:erp/features/partner/data/models/partner_action_log.dart';
import 'package:erp/features/partner/data/models/partner_detail.dart';
import 'package:erp/features/partner/data/models/partner_duplicate_match.dart';
import 'package:erp/features/partner/data/models/partner_enums.dart';
import 'package:erp/features/partner/data/models/partner_inputs.dart';
import 'package:erp/features/partner/data/models/partner_list_item.dart';
import 'package:erp/features/partner/data/models/partner_write_results.dart';
import 'package:erp/features/partner/data/partner_repository.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

/// Một lời gọi method của repository: tên method + đối số có tên (khoá = tên tham số).
final class RepoCall {
  const RepoCall(this.method, this.args);

  final String method;
  final Map<String, Object?> args;

  @override
  String toString() => '$method($args)';
}

/// `PartnerRepository` chạy kịch bản do test đưa vào: mỗi lời gọi được ghi vào [invocations]
/// rồi chuyển cho [onCall]; giá trị trả về (hoặc lỗi ném ra) là kết quả của method.
/// Dùng khi test cần ném lỗi cụ thể hoặc kiểm đối số; muốn dữ liệu mẫu có sẵn thì dùng
/// `FakePartnerRepository`.
final class ScriptedPartnerRepository extends PartnerRepository {
  ScriptedPartnerRepository({this.onCall})
    : super(
        rpc: SupabaseRpc(_UnusedClient()),
        tenantId: () async => 'tenant-1',
        actorId: () async => 'user-1',
      );

  final Object? Function(String method, Map<String, Object?> args)? onCall;
  final invocations = <RepoCall>[];

  List<String> get methods => [for (final c in invocations) c.method];

  Iterable<RepoCall> callsOf(String method) => invocations.where((c) => c.method == method);

  /// Kịch bản có thể trả giá trị thường hoặc `Future` (để test giữ lời gọi đang chờ).
  Future<Object?> _script(String method, Map<String, Object?> args) async {
    final result = onCall?.call(method, args);
    return result is Future ? await result : result;
  }

  Future<T> _run<T>(String method, Map<String, Object?> args) async {
    invocations.add(RepoCall(method, args));
    return await _script(method, args) as T;
  }

  @override
  Future<PartnerSearchResultDto> search({
    String? query,
    PartnerType? partnerType,
    PartnerRoleType? role,
    bool requireBothRoles = false,
    bool requireAnyRole = false,
    PartnerStatus? status,
    int? updatedWithinDays,
    int page = 1,
    int limit = 20,
    String? sort,
  }) => _run('search', {
    'query': query,
    'partnerType': partnerType,
    'role': role,
    'requireBothRoles': requireBothRoles,
    'requireAnyRole': requireAnyRole,
    'status': status,
    'updatedWithinDays': updatedWithinDays,
    'page': page,
    'limit': limit,
    'sort': sort,
  });

  @override
  Future<PartnerDetailDto> getDetail(String partnerId) =>
      _run('getDetail', {'partnerId': partnerId});

  @override
  Future<List<PartnerDuplicateMatchDto>> checkDuplicates({
    String? phone,
    String? email,
    String? taxCode,
    String? name,
    String? excludePartnerId,
  }) => _run('checkDuplicates', {
    'phone': phone,
    'email': email,
    'taxCode': taxCode,
    'name': name,
    'excludePartnerId': excludePartnerId,
  });

  @override
  Future<DeleteEligibilityDto> checkDeleteEligibility(String partnerId) =>
      _run('checkDeleteEligibility', {'partnerId': partnerId});

  @override
  Future<PartnerActionLogPage> getActionLogs(String partnerId, {int page = 1, int limit = 20}) =>
      _run('getActionLogs', {'partnerId': partnerId, 'page': page, 'limit': limit});

  @override
  Future<CreatePartnerResult> create({
    required PartnerType partnerType,
    required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile,
    OrganizationProfileInput? organizationProfile,
    PersonProfileInput? organizationPrimaryContact,
    bool confirmDuplicate = false,
  }) => _run('create', {
    'partnerType': partnerType,
    'roles': roles,
    'personProfile': personProfile,
    'organizationProfile': organizationProfile,
    'organizationPrimaryContact': organizationPrimaryContact,
    'confirmDuplicate': confirmDuplicate,
  });

  @override
  Future<UpdatePartnerProfileResult> update({
    required String partnerId,
    required int expectedVersion,
    required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile,
    OrganizationProfileInput? organizationProfile,
    bool confirmDuplicate = false,
  }) => _run('update', {
    'partnerId': partnerId,
    'expectedVersion': expectedVersion,
    'roles': roles,
    'personProfile': personProfile,
    'organizationProfile': organizationProfile,
    'confirmDuplicate': confirmDuplicate,
  });

  @override
  Future<String> transformToOrganization({
    required String partnerId,
    required int expectedVersion,
    required OrganizationProfileInput organizationProfile,
    bool confirmDuplicate = false,
  }) => _run('transformToOrganization', {
    'partnerId': partnerId,
    'expectedVersion': expectedVersion,
    'organizationProfile': organizationProfile,
    'confirmDuplicate': confirmDuplicate,
  });

  @override
  Future<AddOrganizationContactResult> addContact({
    required String organizationPartnerId,
    String? personPartnerId,
    PersonProfileInput? newPersonProfile,
    String? contactRole,
    bool isPrimary = false,
  }) => _run('addContact', {
    'organizationPartnerId': organizationPartnerId,
    'personPartnerId': personPartnerId,
    'newPersonProfile': newPersonProfile,
    'contactRole': contactRole,
    'isPrimary': isPrimary,
  });

  @override
  Future<void> updateContact({
    required String organizationPartnerId,
    required String personPartnerId,
    String? contactRole,
    bool? isPrimary,
    String? note,
    PersonProfileInput? personProfile,
  }) async {
    invocations.add(
      RepoCall('updateContact', {
        'organizationPartnerId': organizationPartnerId,
        'personPartnerId': personPartnerId,
        'contactRole': contactRole,
        'isPrimary': isPrimary,
        'note': note,
        'personProfile': personProfile,
      }),
    );
    await _script('updateContact', invocations.last.args);
  }

  @override
  Future<void> removeContact({
    required String organizationPartnerId,
    required String personPartnerId,
  }) async {
    invocations.add(
      RepoCall('removeContact', {
        'organizationPartnerId': organizationPartnerId,
        'personPartnerId': personPartnerId,
      }),
    );
    await _script('removeContact', invocations.last.args);
  }

  @override
  Future<PartnerVersionResult> deactivate(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) => _run('deactivate', {
    'partnerId': partnerId,
    'expectedVersion': expectedVersion,
    'reason': reason,
  });

  @override
  Future<PartnerVersionResult> reactivate(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) => _run('reactivate', {
    'partnerId': partnerId,
    'expectedVersion': expectedVersion,
    'reason': reason,
  });

  @override
  Future<PartnerVersionResult> softDelete(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) => _run('softDelete', {
    'partnerId': partnerId,
    'expectedVersion': expectedVersion,
    'reason': reason,
  });
}
