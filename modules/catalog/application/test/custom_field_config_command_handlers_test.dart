import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingCustomFieldConfigGateway implements ICatalogCustomFieldConfigGateway {
  InitializeCustomFieldTemplateCommand? lastInitCommand;
  UpsertCustomFieldGroupCommand? lastUpsertGroupCommand;
  ReorderCustomFieldGroupsCommand? lastReorderGroupsCommand;
  UpsertCustomFieldCommand? lastUpsertFieldCommand;
  ConfigureCustomFieldAttributesCommand? lastConfigureCommand;
  ReorderCustomFieldsCommand? lastReorderFieldsCommand;
  String? lastListTenantId;

  InitializeCustomFieldTemplateResult initResult = const InitializeCustomFieldTemplateResult(
    groupsCreated: 2,
    fieldsCreated: 3,
    skippedCount: 0,
  );

  CustomFieldGroupConfigDto groupResult = const CustomFieldGroupConfigDto(
    groupId: 'group-1',
    name: 'Thông tin thuốc',
    iconKey: '💊',
  );

  CustomFieldDefinitionDto fieldResult = const CustomFieldDefinitionDto(
    fieldId: 'field-1',
    groupId: 'group-1',
    name: 'Thành phần',
    fieldType: CustomFieldType.text,
  );

  ConfigureCustomFieldAttributesResult configureResult = ConfigureCustomFieldAttributesResult(
    field: const CustomFieldDefinitionDto(
      fieldId: 'field-1',
      groupId: 'group-1',
      name: 'Thành phần',
      fieldType: CustomFieldType.text,
      isRequired: true,
    ),
    existingProductsMissingCount: 3,
  );

  CustomFieldConfigViewDto listResult = const CustomFieldConfigViewDto(
    groups: [],
  );

  @override
  Future<InitializeCustomFieldTemplateResult> initializeTemplate({
    required InitializeCustomFieldTemplateCommand command,
  }) async {
    lastInitCommand = command;
    return initResult;
  }

  @override
  Future<CustomFieldGroupConfigDto> upsertGroup({
    required UpsertCustomFieldGroupCommand command,
  }) async {
    lastUpsertGroupCommand = command;
    return groupResult;
  }

  @override
  Future<void> reorderGroups({
    required ReorderCustomFieldGroupsCommand command,
  }) async {
    lastReorderGroupsCommand = command;
  }

  @override
  Future<CustomFieldDefinitionDto> upsertField({
    required UpsertCustomFieldCommand command,
  }) async {
    lastUpsertFieldCommand = command;
    return fieldResult;
  }

  @override
  Future<ConfigureCustomFieldAttributesResult> configureAttributes({
    required ConfigureCustomFieldAttributesCommand command,
  }) async {
    lastConfigureCommand = command;
    return configureResult;
  }

  @override
  Future<void> reorderFields({
    required ReorderCustomFieldsCommand command,
  }) async {
    lastReorderFieldsCommand = command;
  }

  @override
  Future<CustomFieldConfigViewDto> listConfig({required String tenantId}) async {
    lastListTenantId = tenantId;
    return listResult;
  }
}

void main() {
  group('custom field config handlers', () {
    late _RecordingCustomFieldConfigGateway gateway;

    setUp(() {
      gateway = _RecordingCustomFieldConfigGateway();
    });

    test('scn_e03_u01_fr01_01 initializes template through gateway', () async {
      final handler = InitializeCustomFieldTemplateCommandHandler(
        customFieldConfigGateway: gateway,
      );

      final result = await handler.handle(
        InitializeCustomFieldTemplateCommand(
          tenantId: 'tenant-1',
          templateId: 'vet_pharmacy_default',
        ),
      );

      expect(gateway.lastInitCommand?.tenantId, 'tenant-1');
      expect(gateway.lastInitCommand?.templateId, 'vet_pharmacy_default');
      expect(result.groupsCreated, 2);
      expect(result.fieldsCreated, 3);
    });

    test('scn_e03_u01_fr02_01 upserts group through gateway', () async {
      final handler = UpsertCustomFieldGroupCommandHandler(
        customFieldConfigGateway: gateway,
      );

      final result = await handler.handle(
        UpsertCustomFieldGroupCommand(
          tenantId: 'tenant-1',
          name: 'Thông tin thuốc',
          iconKey: '💊',
        ),
      );

      expect(gateway.lastUpsertGroupCommand?.name, 'Thông tin thuốc');
      expect(result.groupId, 'group-1');
      expect(result.name, 'Thông tin thuốc');
    });

    test('scn_e03_u01_fr03_01 reorders groups through gateway', () async {
      final handler = ReorderCustomFieldGroupsCommandHandler(
        customFieldConfigGateway: gateway,
      );

      await handler.handle(
        ReorderCustomFieldGroupsCommand(
          tenantId: 'tenant-1',
          orderedGroupIds: const ['group-2', 'group-1'],
        ),
      );

      expect(
        gateway.lastReorderGroupsCommand?.orderedGroupIds,
        ['group-2', 'group-1'],
      );
    });

    test('scn_e03_u01_fr04_01 upserts text field through gateway', () async {
      final handler = UpsertCustomFieldCommandHandler(
        customFieldConfigGateway: gateway,
      );

      final result = await handler.handle(
        UpsertCustomFieldCommand(
          tenantId: 'tenant-1',
          groupId: 'group-1',
          name: 'Thành phần',
          fieldType: CustomFieldType.text,
        ),
      );

      expect(gateway.lastUpsertFieldCommand?.fieldType, CustomFieldType.text);
      expect(result.fieldId, 'field-1');
      expect(result.name, 'Thành phần');
    });

    test('scn_e03_u01_fr05_01 configures required attributes', () async {
      final handler = ConfigureCustomFieldAttributesCommandHandler(
        customFieldConfigGateway: gateway,
      );

      final result = await handler.handle(
        ConfigureCustomFieldAttributesCommand(
          tenantId: 'tenant-1',
          fieldId: 'field-1',
          isRequired: true,
          isSearchable: false,
          isFilterable: false,
          displayOnList: false,
        ),
      );

      expect(gateway.lastConfigureCommand?.isRequired, isTrue);
      expect(result.existingProductsMissingCount, 3);
      expect(result.field.isRequired, isTrue);
    });

    test('scn_e03_u01_fr06_01 reorders fields through gateway', () async {
      final handler = ReorderCustomFieldsCommandHandler(
        customFieldConfigGateway: gateway,
      );

      await handler.handle(
        ReorderCustomFieldsCommand(
          tenantId: 'tenant-1',
          groupId: 'group-1',
          orderedFieldIds: const ['field-2', 'field-1'],
        ),
      );

      expect(gateway.lastReorderFieldsCommand?.groupId, 'group-1');
      expect(
        gateway.lastReorderFieldsCommand?.orderedFieldIds,
        ['field-2', 'field-1'],
      );
    });

    test('validator rejects blank group name', () async {
      final handler = UpsertCustomFieldGroupCommandHandler(
        customFieldConfigGateway: gateway,
      );

      await expectLater(
        handler.handle(
          UpsertCustomFieldGroupCommand(
            tenantId: 'tenant-1',
            name: '   ',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(gateway.lastUpsertGroupCommand, isNull);
    });

    test('validator rejects single select without options on create', () async {
      final handler = UpsertCustomFieldCommandHandler(
        customFieldConfigGateway: gateway,
      );

      await expectLater(
        handler.handle(
          UpsertCustomFieldCommand(
            tenantId: 'tenant-1',
            groupId: 'group-1',
            name: 'Loại',
            fieldType: CustomFieldType.singleSelect,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(gateway.lastUpsertFieldCommand, isNull);
    });

    test('list config query delegates to gateway', () async {
      final handler = ListCustomFieldConfigQueryHandler(
        customFieldConfigGateway: gateway,
      );

      final result = await handler.handle(
        ListCustomFieldConfigQuery(tenantId: 'tenant-1'),
      );

      expect(gateway.lastListTenantId, 'tenant-1');
      expect(result.groups, isEmpty);
    });
  });
}
