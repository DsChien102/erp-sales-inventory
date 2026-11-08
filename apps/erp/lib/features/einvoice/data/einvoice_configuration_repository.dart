import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/mappers/configuration_json.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:erp/features/einvoice/logic/einvoice_rules.dart';

class EInvoiceConfigurationRepository {
  EInvoiceConfigurationRepository({
    required SupabaseRpc rpc,
    required EInvoiceProcessorTrigger trigger,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
  })  : _rpc = rpc,
        _trigger = trigger,
        _tenantId = tenantId,
        _actorId = actorId;

  final SupabaseRpc _rpc;
  final EInvoiceProcessorTrigger _trigger;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (e) {
      throw einvoiceException(e);
    }
  }

  Future<ProviderConnectionScreenDto> getConnectionScreen() {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_provider_connection_screen',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_provider_connection_screen returned no rows',
        );
      }
      return EInvoiceConfigurationJson.mapConnectionScreen(rows.first);
    });
  }

  Future<ProviderConnectionResultDto> connect({
    required String username,
    required String password,
    int? expectedConnectionVersion,
  }) {
    return _guard(() async {
      EInvoiceRules.checkConnect(username: username, password: password);
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_username': username.trim(),
        'p_password': password,
        'p_expected_connection_version': ?expectedConnectionVersion,
      };
      final rows = await _rpc.rows('einvoice', 'connect_provider', params: params);
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'connect_provider returned no rows',
        );
      }
      final result = EInvoiceConfigurationJson.mapConnectionResult(rows.first);
      _trigger.kick(tenant);
      return result;
    });
  }

  Future<ProviderConnectionResultDto> reconnect({
    required String connectionId,
    required String username,
    required String password,
    int? expectedConnectionVersion,
  }) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_connection_id': connectionId,
        'p_username': username.trim(),
        'p_password': password,
        'p_expected_connection_version': ?expectedConnectionVersion,
      };
      final rows = await _rpc.rows('einvoice', 'reconnect_provider', params: params);
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'reconnect_provider returned no rows',
        );
      }
      final result = EInvoiceConfigurationJson.mapConnectionResult(rows.first);
      _trigger.kick(tenant);
      return result;
    });
  }

  Future<ProviderConnectionResultDto> disconnect({
    required String connectionId,
    required bool confirm,
  }) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_connection_id': connectionId,
        'p_confirm': confirm,
      };
      final rows = await _rpc.rows('einvoice', 'disconnect_provider', params: params);
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'disconnect_provider returned no rows',
        );
      }
      return EInvoiceConfigurationJson.mapConnectionResult(rows.first);
    });
  }

  Future<List<ProviderTemplateDto>> listTemplates({
    bool? invoiceWithCode,
    int? year,
  }) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_invoice_with_code': ?invoiceWithCode,
        'p_year': ?year,
      };
      final rows = await _rpc.rows('einvoice', 'list_provider_templates', params: params);
      return EInvoiceConfigurationJson.mapTemplateList(rows);
    });
  }

  Future<IssuanceProfileDto> getIssuanceProfile() {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_issuance_profile',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_issuance_profile returned no rows',
        );
      }
      return EInvoiceConfigurationJson.mapIssuanceProfile(rows.first);
    });
  }

  Future<IssuanceProfileDto> setDefaultConfiguration({
    required String templateId,
    required String signingConfigId,
    int? expectedProfileVersion,
  }) {
    return _guard(() async {
      EInvoiceRules.checkSetDefaultConfiguration(
        templateId: templateId,
        signingConfigId: signingConfigId,
      );
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_template_id': templateId.trim(),
        'p_signing_config_id': signingConfigId.trim(),
        'p_expected_profile_version': ?expectedProfileVersion,
      };
      final rows = await _rpc.rows(
        'einvoice',
        'set_default_issuance_configuration',
        params: params,
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'set_default_issuance_configuration returned no rows',
        );
      }
      return EInvoiceConfigurationJson.mapIssuanceProfile(rows.first);
    });
  }

  Future<AutomationPolicyDto> getAutomationPolicy() {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final rows = await _rpc.rows(
        'einvoice',
        'get_automation_policy',
        params: {
          'p_tenant_id': tenant,
          'p_actor_id': actor,
        },
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_automation_policy returned no rows',
        );
      }
      return EInvoiceConfigurationJson.mapAutomationPolicy(rows.first);
    });
  }

  Future<AutomationPolicyDto> updateAutomationPolicy({
    required int expectedPolicyVersion,
    bool? autoIssueEnabled,
    bool? autoSendEnabled,
  }) {
    return _guard(() async {
      EInvoiceRules.checkUpdateAutomationPolicy(
        expectedPolicyVersion: expectedPolicyVersion,
        autoIssueEnabled: autoIssueEnabled,
        autoSendEnabled: autoSendEnabled,
      );
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        'p_auto_issue_enabled': ?autoIssueEnabled,
        'p_auto_send_enabled': ?autoSendEnabled,
        'p_expected_policy_version': expectedPolicyVersion,
      };
      final rows = await _rpc.rows(
        'einvoice',
        'update_automation_policy',
        params: params,
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'update_automation_policy returned no rows',
        );
      }
      return EInvoiceConfigurationJson.mapAutomationPolicy(rows.first);
    });
  }

  Future<ConfigurationReadinessDto> getConfigurationReadiness({
    IssuancePurpose? purpose,
  }) {
    return _guard(() async {
      final tenant = await _tenantId();
      final actor = await _actorId();
      final params = <String, dynamic>{
        'p_tenant_id': tenant,
        'p_actor_id': actor,
        if (purpose != null) 'p_purpose': purpose.name,
      };
      final rows = await _rpc.rows(
        'einvoice',
        'get_configuration_readiness',
        params: params,
      );
      if (rows.isEmpty) {
        throw const AppException(
          EInvoiceErrorCodes.systemError,
          serverMessage: 'get_configuration_readiness returned no rows',
        );
      }
      return EInvoiceConfigurationJson.mapConfigurationReadiness(rows.first);
    });
  }
}
