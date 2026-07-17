const reenableToken =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, dynamic> reenablePrecheckJson({
  String outcome = 'valid',
  List<String> warningCodes = const [],
  List<String> blockingCodes = const [],
  String token = reenableToken,
  int ruleVersion = 4,
  String businessDate = '2026-07-16',
  bool floorPriceHidden = false,
}) => {
  'validation_outcome': {
    'outcome': outcome,
    'warning_codes': warningCodes,
    'blocking_codes': blockingCodes,
    'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
    'floor_price': floorPriceHidden
        ? null
        : {'amount_minor': 125000, 'currency_code': 'VND'},
    'floor_price_hidden': floorPriceHidden,
  },
  'precheck_token': token,
  'rule_version': ruleVersion,
  'business_date': businessDate,
};

Map<String, dynamic> reenableDetailJson({
  int version = 5,
  String outcome = 'valid',
  List<String> warningCodes = const [],
}) => {
  'id': '00000000-0000-4000-8000-000000000001',
  'customer': {
    'customer_id': '00000000-0000-4000-8000-000000000002',
    'display_name': 'Phòng khám A',
    'status': 'active',
  },
  'product_unit': {
    'product_id': '00000000-0000-4000-8000-000000000003',
    'product_name': 'Vaccine A',
    'product_unit_id': '00000000-0000-4000-8000-000000000004',
    'unit_name': 'Lọ',
    'sellable_status': 'active',
  },
  'price': {'amount_minor': 90000, 'currency_code': 'VND'},
  'effective_period': {'effective_from': '2026-07-01'},
  'rule_type': 'special_price',
  'source_type': 'manual',
  'persisted_status': 'active',
  'derived_status': 'applying',
  'validation_outcome': {
    'outcome': outcome,
    'warning_codes': warningCodes,
    'blocking_codes': [],
    'floor_price_hidden': warningCodes.isEmpty,
  },
  'reference_health': {
    'customer_state': 'valid',
    'product_unit_state': 'valid',
    'price_band_state': 'current',
    'issue_codes': [],
    'used_stored_price_band_snapshot': false,
  },
  'source_trace': {'hidden': false},
  'created_by': 'context-user',
  'created_at': '2026-07-16T09:00:00Z',
  'updated_by': 'context-user',
  'updated_at': '2026-07-16T10:00:00Z',
  'version': version,
  'available_actions': ['edit', 'disable', 'history'],
  'disabled_at': null,
  'disabled_by': null,
  'disabled_reason': null,
};
