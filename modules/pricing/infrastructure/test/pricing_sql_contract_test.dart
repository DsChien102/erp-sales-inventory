import 'dart:io';

import 'package:test/test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  while (!Directory('${dir.path}/supabase/migrations/_drafts').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return dir;
}

void main() {
  final root = _repoRoot();

  test('provider snapshot functions are internal-only', () {
    final partner = File(
      '${root.path}/supabase/migrations/_drafts/'
      '001_partner_pricing_customer_snapshot.sql',
    ).readAsStringSync();
    final catalog = File(
      '${root.path}/supabase/migrations/_drafts/'
      '002_catalog_pricing_price_band_snapshot.sql',
    ).readAsStringSync();

    expect(partner, contains('partner._get_customer_snapshot_for_pricing'));
    expect(
      catalog,
      contains('catalog._get_product_price_band_snapshot_for_pricing'),
    );
    expect(catalog, contains("'sellable',"));
    expect(catalog, contains('p.reference_id as product_reference_id'));
    expect(catalog, contains('p.sku'));
    expect(catalog, contains("'product_reference_id',"));
    expect(catalog, contains("'sku',"));
    expect(catalog, contains('minor_units_valid'));
    expect(catalog, contains('trunc('));
    expect(partner, contains('from public, anon, authenticated'));
    expect(catalog, contains('from public, anon, authenticated'));
  });

  test('pricing draft owns atomic create and never reads provider tables', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '004_pricing_customer_price_rule_s1.sql',
    ).readAsStringSync();
    final createStart = sql.indexOf(
      'create or replace function pricing.create_customer_price_rule(',
    );
    final createEnd = sql.indexOf(
      'revoke all on function pricing.create_customer_price_rule(',
      createStart,
    );
    final createFunction = sql.substring(createStart, createEnd);

    expect(
      sql,
      contains('create table if not exists pricing.customer_price_rules'),
    );
    expect(
      sql,
      contains(
        'create table if not exists pricing.customer_price_rule_activities',
      ),
    );
    expect(
      sql,
      contains('pricing._auto_disable_overlapping_customer_price_rules'),
    );
    expect(sql, contains('pricing.get_customer_price_rule_create_context'));
    expect(sql, contains('pricing.create_customer_price_rule'));
    expect(sql, contains('pg_advisory_xact_lock'));
    expect(sql, contains('payload_hash'));
    expect(sql, contains('customer_price_rule_activities'));
    expect(sql, contains("'rule_id', v_rule.id"));
    expect(sql, contains("'price_check_status', v_price_check_status"));
    expect(
      sql,
      contains("status in ('active', 'disabled', 'needs_review', 'deleted')"),
    );
    expect(sql, isNot(contains("status in ('active', 'inactive', 'expired')")));
    expect(sql, contains("'customer_id', r.customer_id"));
    expect(sql, contains('product_reference_id_snapshot text'));
    expect(sql, contains('product_sku_snapshot text'));
    expect(sql, contains("'product_reference_id',"));
    expect(sql, contains("'sku', r.product_sku_snapshot"));
    expect(sql, contains('v_product ->> \'product_reference_id\''));
    expect(sql, contains('v_product ->> \'sku\''));
    expect(sql, contains("'customer_id', p_customer_id"));
    expect(sql, contains("'exists',"));
    expect(sql, contains("'is_customer',"));
    expect(sql, contains('p_rule_id uuid'));
    expect(sql, contains('p_rule_id,'));
    expect(sql, contains('r.idempotency_key <> btrim(p_idempotency_key)'));
    expect(sql, contains("'reason_code', 'AUTO_REPLACED_BY_RULE'"));
    expect(sql, contains("'replacement_rule_id', p_keep_rule_id"));
    expect(sql, contains("'replacement_action', p_replacement_action"));
    expect(sql, contains('from locked l'));
    expect(sql, contains('from updated u'));
    expect(createFunction, contains("'DUPLICATE_ACTIVE_RULE'"));
    expect(createFunction, contains("r.status = 'active'"));
    expect(
      createFunction,
      contains(
        "r.effective_from <= coalesce(p_effective_to, 'infinity'::date)",
      ),
    );
    expect(
      createFunction,
      contains(
        "p_effective_from <= coalesce(r.effective_to, 'infinity'::date)",
      ),
    );
    expect(
      createFunction,
      isNot(
        contains(
          'perform pricing._auto_disable_overlapping_customer_price_rules(',
        ),
      ),
    );
    expect(sql, contains("'idempotency_key_exists',"));
    expect(sql, contains('not coalesce(p_acknowledge_floor_warning, false)'));
    expect(
      RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(r'from\s+catalog\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
  });

  test('S1 view permission variable stays inside create-context scope', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '004_pricing_customer_price_rule_s1.sql',
    ).readAsStringSync();
    final contextStart = sql.indexOf(
      'create or replace function pricing.get_customer_price_rule_create_context(',
    );
    final createStart = sql.indexOf(
      'create or replace function pricing.create_customer_price_rule(',
    );
    final createEnd = sql.indexOf(
      'revoke all on function pricing.create_customer_price_rule(',
      createStart,
    );

    expect(contextStart, greaterThanOrEqualTo(0));
    expect(createStart, greaterThan(contextStart));
    expect(createEnd, greaterThan(createStart));

    final contextFunction = sql.substring(contextStart, createStart);
    final createFunction = sql.substring(createStart, createEnd);
    expect(contextFunction, contains('v_can_view_rules boolean := false;'));
    expect(
      contextFunction,
      contains("v_can_view_rules := iam.has_permission("),
    );
    expect(createFunction, isNot(contains('v_can_view_rules')));
    expect(createFunction, contains('v_conflicting_rule_id uuid;'));
  });

  test('S2 search draft has the exact public RPC and access boundary', () {
    final draft = File(
      '${root.path}/supabase/migrations/_drafts/'
      '005_pricing_customer_price_rule_search_s2.sql',
    );

    expect(
      draft.existsSync(),
      isTrue,
      reason: 'S2 search SQL must remain a draft-only migration',
    );
    if (!draft.existsSync()) return;

    final sql = draft.readAsStringSync();
    expect(sql, contains('create extension if not exists unaccent'));
    expect(sql, contains('pricing.search_customer_price_rules('));
    expect(sql, contains('p_tenant_id uuid'));
    expect(sql, contains('p_business_date date'));
    expect(sql, contains('p_q text default null'));
    expect(sql, contains("p_quick_filter text default 'all'"));
    expect(sql, contains('p_statuses text[] default null'));
    expect(sql, contains('p_sources text[] default null'));
    expect(sql, contains('p_customer_id uuid default null'));
    expect(sql, contains('p_product_id uuid default null'));
    expect(sql, contains('p_cursor text default null'));
    expect(sql, contains('p_limit integer default 20'));
    expect(sql, contains("'pricing.customer_price_rule.view'"));
    expect(sql, contains('auth.uid()'));
    expect(sql, isNot(contains('p_actor_id')));
    expect(
      RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(r'from\s+catalog\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      sql,
      contains(
        'revoke all on function pricing.search_customer_price_rules('
        'uuid, date, text, text, text[], text[], uuid, uuid, text, integer'
        ') from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function pricing.search_customer_price_rules('
        'uuid, date, text, text, text[], text[], uuid, uuid, text, integer'
        ') to authenticated, service_role',
      ),
    );
  });

  test('S2 search derives statuses with inclusive effective boundaries', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '005_pricing_customer_price_rule_search_s2.sql',
    ).readAsStringSync();

    final disabled = sql.indexOf("when r.status = 'disabled' then 'disabled'");
    final needsReview = sql.indexOf("then 'needs_review'");
    final expired = sql.indexOf(
      "r.effective_to < p_business_date then 'expired'",
    );
    final future = sql.indexOf(
      "r.effective_from > p_business_date then 'not_yet_effective'",
    );
    final applying = sql.indexOf("else 'applying'");

    expect(sql, contains("r.status <> 'deleted'"));
    expect(disabled, greaterThanOrEqualTo(0));
    expect(needsReview, greaterThan(disabled));
    expect(expired, greaterThan(needsReview));
    expect(future, greaterThan(expired));
    expect(applying, greaterThan(future));
    expect(sql, contains("v_quick_filter = 'applying'"));
    expect(sql, contains("v_quick_filter = 'below_floor'"));
    expect(sql, contains("'below_floor_price'"));
  });

  test('S2 search combines snapshot filters and stable seek pagination', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '005_pricing_customer_price_rule_search_s2.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains('extensions.unaccent(lower(r.customer_display_name_snapshot))'),
    );
    expect(
      sql,
      contains('extensions.unaccent(lower(r.product_name_snapshot))'),
    );
    expect(
      sql,
      contains('extensions.unaccent(lower(r.product_reference_id_snapshot))'),
    );
    expect(sql, contains('extensions.unaccent(lower(r.product_sku_snapshot))'));
    expect(sql, contains('r.customer_id = p_customer_id'));
    expect(sql, contains('r.product_id = p_product_id'));
    expect(sql, contains('r.source_type = any(p_sources)'));
    expect(sql, contains('derived_status = any(p_statuses)'));
    expect(sql, contains('r.updated_at < v_cursor_updated_at'));
    expect(sql, contains('r.updated_at = v_cursor_updated_at'));
    expect(sql, contains('r.id < v_cursor_id'));
    expect(sql, contains('order by r.updated_at desc, r.id desc'));
    expect(sql, contains('limit p_limit + 1'));
    expect(sql, contains("'next_cursor',"));
    expect(sql, contains("'has_more', v_has_more"));
  });

  test('S2 list redacts floor amount and exposes stable screen actions', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '005_pricing_customer_price_rule_search_s2.sql',
    ).readAsStringSync();

    expect(sql, isNot(contains("'floor_price',")));
    expect(sql, contains("'floor_price_hidden',"));
    expect(sql, contains("'warning_codes', r.warning_codes"));
    expect(sql, contains("'available_actions',"));
    expect(sql, contains("'create_manual'"));
    expect(sql, contains("'import'"));
    expect(sql, contains("'items',"));
    expect(sql, contains("'next_cursor',"));
    expect(sql, contains("'has_more',"));
  });

  test('S3 detail draft has the exact public RPC and access boundary', () {
    final draft = File(
      '${root.path}/supabase/migrations/_drafts/'
      '006_pricing_customer_price_rule_detail_s3.sql',
    );
    expect(draft.existsSync(), isTrue);
    final sql = draft.readAsStringSync();

    expect(
      sql,
      contains(
        'create or replace function pricing.get_customer_price_rule_detail(',
      ),
    );
    expect(sql, contains('p_tenant_id uuid'));
    expect(sql, contains('p_rule_id uuid'));
    expect(sql, contains('p_business_date date'));
    expect(sql, contains('auth.uid()'));
    expect(sql, contains("'pricing.customer_price_rule.view'"));
    expect(sql, contains("r.status <> 'deleted'"));
    expect(sql, contains("'NOT_FOUND'"));
    expect(sql, contains('pricing._raise_pricing_error'));
    expect(sql, isNot(contains('p_actor_id')));
    expect(sql, contains('partner._get_customer_snapshot_for_pricing'));
    expect(
      sql,
      contains('catalog._get_product_price_band_snapshot_for_pricing'),
    );
    expect(
      RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(r'from\s+catalog\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      sql,
      contains(
        'revoke all on function pricing.get_customer_price_rule_detail('
        'uuid, uuid, date) from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function pricing.get_customer_price_rule_detail('
        'uuid, uuid, date) to authenticated, service_role',
      ),
    );
    expect(sql, isNot(contains('customer_price_rule_activities')));
    expect(sql.toLowerCase(), isNot(contains('insert into')));
    expect(sql.toLowerCase(), isNot(contains('update ')));
    expect(sql.toLowerCase(), isNot(contains('delete from')));
  });

  test(
    'S3 detail derives status with inclusive boundaries and health codes',
    () {
      final sql = File(
        '${root.path}/supabase/migrations/_drafts/'
        '006_pricing_customer_price_rule_detail_s3.sql',
      ).readAsStringSync();

      final disabled = sql.indexOf(
        "when v_rule.status = 'disabled' then 'disabled'",
      );
      final needsReview = sql.indexOf("then 'needs_review'");
      final expired = sql.indexOf(
        "and v_rule.effective_to < p_business_date then 'expired'",
      );
      final future = sql.indexOf(
        "when v_rule.effective_from > p_business_date then 'not_yet_effective'",
      );
      final applying = sql.indexOf("else 'applying'");

      expect(disabled, greaterThanOrEqualTo(0));
      expect(needsReview, greaterThan(disabled));
      expect(expired, greaterThan(needsReview));
      expect(future, greaterThan(expired));
      expect(applying, greaterThan(future));
      expect(sql, contains("'customer_reference_inactive'"));
      expect(sql, contains("'customer_reference_missing'"));
      expect(sql, contains("'product_unit_reference_inactive'"));
      expect(sql, contains("'product_unit_reference_missing'"));
      expect(sql, contains("'price_band_currency_mismatch'"));
      expect(sql, contains("'price_band_minor_units_invalid'"));
      expect(sql, contains("'below_floor_price'"));
      expect(sql, contains('used_stored_price_band_snapshot'));
      expect(sql, contains("'floor_price_hidden'"));
      expect(
        sql,
        contains("'pricing.customer_price_rule.override_floor_price'"),
      );
      expect(sql, contains("'pricing.customer_price_rule.view_history'"));
      expect(sql, contains("'pricing.customer_price_rule.update'"));
      expect(sql, contains("'pricing.customer_price_rule.disable'"));
      expect(sql, contains("'pricing.customer_price_rule.reenable'"));
      expect(sql, contains("'edit'"));
      expect(sql, contains("'disable'"));
      expect(sql, contains("'reenable'"));
      expect(sql, contains("'history'"));
      expect(sql, contains("'source_trace'"));
      expect(sql, contains("'reference_health'"));
    },
  );

  test('S1 create helper emits S3-compatible health and lifecycle actions', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '004_pricing_customer_price_rule_s1.sql',
    ).readAsStringSync();

    expect(sql, contains("'reference_health'"));
    expect(sql, contains("'source_trace'"));
    expect(sql, contains("'used_stored_price_band_snapshot', false"));
    expect(sql, contains("else 'applying'"));
    expect(sql, contains("'edit'"));
    expect(sql, contains("'disable'"));
    expect(sql, contains("'reenable'"));
    expect(sql, contains("'history'"));
    expect(sql, isNot(contains("jsonb_build_array('view')")));
  });

  test('S1 result helper includes disabled lifecycle audit fields', () {
    final sql = File(
      '${root.path}/supabase/migrations/_drafts/'
      '004_pricing_customer_price_rule_s1.sql',
    ).readAsStringSync();
    final helperStart = sql.indexOf(
      'create or replace function pricing._customer_price_rule_result(',
    );
    final helperEnd = sql.indexOf(
      'revoke all on function pricing._customer_price_rule_result',
      helperStart,
    );

    expect(helperStart, greaterThanOrEqualTo(0));
    expect(helperEnd, greaterThan(helperStart));
    final helperSql = sql.substring(helperStart, helperEnd);
    expect(helperSql, contains("'disabled_at', r.disabled_at"));
    expect(helperSql, contains("'disabled_by', r.disabled_by"));
    expect(helperSql, contains("'disabled_reason', r.disabled_reason"));
  });

  test('S5 update draft exposes exact RPC signatures and grants', () {
    final draft = File(
      '${root.path}/supabase/migrations/_drafts/'
      '007_pricing_customer_price_rule_update_s5.sql',
    );
    expect(draft.existsSync(), isTrue);
    final sql = draft.readAsStringSync();
    expect(
      sql,
      contains(
        '-- Touches: get_customer_price_rule_update_context, '
        'update_customer_price_rule',
      ),
    );
    expect(sql, contains('pricing.get_customer_price_rule_update_context('));
    expect(sql, contains('pricing.update_customer_price_rule('));
    expect(sql, contains('p_expected_version integer'));
    expect(sql, contains("'pricing.customer_price_rule.update'"));
    expect(sql, isNot(contains('p_actor_id')));
    expect(
      sql,
      contains(
        'pricing.get_customer_price_rule_update_context('
        'uuid, uuid, integer, bigint, date, date)',
      ),
    );
    expect(
      sql,
      contains(
        'pricing.update_customer_price_rule('
        'uuid, uuid, integer, bigint, date, date, text, boolean)',
      ),
    );
  });

  test('S5 activity constraint accepts rows written by later slices', () {
    final sql = _s5UpdateSql(root);

    expect(
      sql,
      contains(
        "check (activity_type in (\n"
        "    'created', 'updated', 'disabled', 'reenabled',\n"
        "    'import_created', 'import_updated',\n"
        "    'memory_created', 'memory_updated'\n"
        '  ));',
      ),
    );
  });

  test(
    'S5 authoritative update locks version and suppresses no-op activity',
    () {
      final sql = _s5UpdateSql(root);
      final lock = sql.indexOf('for update;');
      final version = sql.indexOf('v_rule.version <> p_expected_version');
      final noOp = sql.indexOf('v_is_noop :=');
      final providers = sql.indexOf(
        'partner._get_customer_snapshot_for_pricing',
      );
      final helper = sql.indexOf(
        'perform pricing._auto_disable_overlapping_customer_price_rules(',
      );
      final update = sql.indexOf('update pricing.customer_price_rules');
      final activity = sql.indexOf(
        'insert into pricing.customer_price_rule_activities',
      );
      expect(lock, greaterThanOrEqualTo(0));
      expect(version, greaterThan(lock));
      expect(noOp, greaterThan(version));
      expect(providers, greaterThan(noOp));
      expect(helper, greaterThan(providers));
      expect(update, greaterThan(helper));
      expect(activity, greaterThan(update));
      expect(sql, contains("if v_is_noop then"));
      expect(sql, contains("activity_type,\n    old_value,\n    new_value"));
      expect(sql, contains("'updated'"));
    },
  );

  test('S5 update uses provider functions without private table reads', () {
    final sql = _s5UpdateSql(root);
    expect(sql, contains('partner._get_customer_snapshot_for_pricing'));
    expect(
      sql,
      contains('catalog._get_product_price_band_snapshot_for_pricing'),
    );
    expect(
      RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(r'from\s+catalog\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(sql, contains("when v_rule.status = 'disabled' then 'disabled'"));
    expect(sql, contains("else 'active'"));
    expect(sql, contains("status <> 'deleted'"));
  });

  test('S6 disable draft is atomic, idempotent-before-version, draft-only', () {
    final draft = File(
      '${root.path}/supabase/migrations/_drafts/'
      '008_pricing_customer_price_rule_disable_s6.sql',
    );
    expect(draft.existsSync(), isTrue);
    final sql = draft.readAsStringSync();

    expect(
      sql,
      contains(
        '-- Touches: get_customer_price_rule_detail, disable_customer_price_rule',
      ),
    );
    expect(sql, contains('disabled_at timestamptz'));
    expect(sql, contains('disabled_by uuid'));
    expect(sql, contains('disabled_reason text'));
    expect(sql, contains('length(disabled_reason) <= 500'));
    expect(
      sql,
      contains(
        'drop constraint if exists '
        'customer_price_rules_disabled_reason_length',
      ),
    );
    expect(
      sql,
      contains(
        'drop constraint if exists '
        'customer_price_rules_disabled_audit_complete',
      ),
    );
    expect(
      sql,
      contains(
        "check (activity_type in (\n"
        "    'created', 'updated', 'disabled', 'reenabled',\n"
        "    'import_created', 'import_updated',\n"
        "    'memory_created', 'memory_updated'\n"
        '  ));',
      ),
    );
    expect(sql, contains('pricing.disable_customer_price_rule('));
    expect(sql, contains('p_tenant_id uuid'));
    expect(sql, contains('p_rule_id uuid'));
    expect(sql, contains('p_expected_version integer'));
    expect(sql, contains('p_reason text default null'));
    expect(sql, contains("'pricing.customer_price_rule.disable'"));
    expect(sql, contains('auth.uid()'));
    expect(sql, contains('for update'));
    expect(sql, isNot(contains('p_actor_id')));
    expect(sql, isNot(contains('partner.')));
    expect(sql, isNot(contains('catalog.')));
    expect(sql, isNot(contains('sales.')));
    expect(sql, isNot(contains('/migrations/20')));
    expect(
      RegExp(r'update\s+.*\borders\b', caseSensitive: false).hasMatch(sql),
      isFalse,
    );

    final idempotent = sql.indexOf("if v_rule.status = 'disabled' then");
    final version = sql.indexOf('if v_rule.version <> p_expected_version then');
    // Schema backfill also updates this table; locate the RPC mutation after
    // the version check so ordering asserts the disable body, not backfill.
    final update = sql.indexOf('update pricing.customer_price_rules', version);
    final activity = sql.indexOf(
      'insert into pricing.customer_price_rule_activities',
    );
    expect(idempotent, greaterThanOrEqualTo(0));
    expect(version, greaterThan(idempotent));
    expect(update, greaterThan(version));
    expect(activity, greaterThan(update));

    expect(
      sql,
      contains(
        "to_regprocedure(\n"
        "    'pricing._get_customer_price_rule_detail_s3(uuid,uuid,date)'\n"
        '  ) is null',
      ),
    );
    expect(sql, contains('rename to _get_customer_price_rule_detail_s3'));
    expect(sql, contains('pricing._get_customer_price_rule_detail_s3('));
    expect(
      sql,
      contains(
        'revoke all on function pricing.disable_customer_price_rule('
        'uuid, uuid, integer, text) from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function pricing.disable_customer_price_rule('
        'uuid, uuid, integer, text) to authenticated, service_role',
      ),
    );
  });

  test('S7 reenable draft defines helper, RPCs, fingerprint, and ordering', () {
    final draft = File(
      '${root.path}/supabase/migrations/_drafts/'
      '009_pricing_customer_price_rule_reenable_s7.sql',
    );
    expect(draft.existsSync(), isTrue);
    final sql = draft.readAsStringSync();

    expect(
      sql,
      contains(
        '-- Touches: _customer_price_rule_reenable_context, '
        'precheck_customer_price_rule_reenable, '
        'reenable_customer_price_rule',
      ),
    );
    expect(
      sql,
      contains(
        "activity_type in ('created', 'updated', 'disabled', 'reenabled')",
      ),
    );
    expect(sql, contains("'pricing-reenable-s7-v1'"));
    expect(sql, contains('partner._get_customer_snapshot_for_pricing'));
    expect(
      sql,
      contains('catalog._get_product_price_band_snapshot_for_pricing'),
    );
    expect(sql, contains("'pricing.customer_price_rule.reenable'"));
    expect(sql, contains("'pricing.customer_price_rule.override_floor_price'"));
    expect(
      sql,
      contains('pricing._auto_disable_overlapping_customer_price_rules('),
    );
    expect(
      RegExp(
        r'create or replace function pricing\.(?:precheck_customer_price_rule_reenable|reenable_customer_price_rule)\([^)]*p_actor_id',
        dotAll: true,
      ).hasMatch(sql),
      isFalse,
    );
    expect(sql, contains('pricing.precheck_customer_price_rule_reenable('));
    expect(sql, contains('pricing.reenable_customer_price_rule('));
    expect(
      RegExp(r'from\s+partner\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      RegExp(r'from\s+catalog\.', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(sql, isNot(contains('sales.')));
    expect(
      RegExp(r'update\s+.*\borders\b', caseSensitive: false).hasMatch(sql),
      isFalse,
    );
    expect(
      sql,
      contains(
        'revoke all on function pricing.precheck_customer_price_rule_reenable('
        'uuid, uuid, integer, date) from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function pricing.precheck_customer_price_rule_reenable('
        'uuid, uuid, integer, date) to authenticated, service_role',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function pricing.reenable_customer_price_rule('
        'uuid, uuid, integer, date, text, boolean) from public, anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function pricing.reenable_customer_price_rule('
        'uuid, uuid, integer, date, text, boolean) to authenticated, service_role',
      ),
    );

    final lock = sql.indexOf('for update;');
    final version = sql.indexOf('v_rule.version <> p_expected_version', lock);
    final status = sql.indexOf("v_rule.status <> 'disabled'", version);
    final duplicateLock = sql.indexOf('pg_advisory_xact_lock(', status);
    final context = sql.indexOf(
      'pricing._customer_price_rule_reenable_context(',
      duplicateLock,
    );
    final token = sql.indexOf('v_current_token <> p_precheck_token', context);
    final helper = sql.indexOf(
      'perform pricing._auto_disable_overlapping_customer_price_rules(',
      token,
    );
    final update = sql.indexOf('update pricing.customer_price_rules', helper);
    final activity = sql.indexOf(
      'insert into pricing.customer_price_rule_activities',
      update,
    );
    expect(version, greaterThan(lock));
    expect(status, greaterThan(version));
    expect(duplicateLock, greaterThan(status));
    expect(context, greaterThan(duplicateLock));
    expect(token, greaterThan(context));
    expect(helper, greaterThan(token));
    expect(update, greaterThan(helper));
    expect(activity, greaterThan(update));

    expect(sql, contains('vault.decrypted_secrets'));
    expect(sql, contains("'pricing_reenable_fingerprint_hmac_v1'"));
    expect(sql, contains('extensions.hmac('));
    expect(sql, isNot(contains('extensions.digest(')));
    expect(sql, contains("'has_floor_price', v_floor_price_minor is not null"));
    expect(sql, isNot(contains("'has_conflicting_rule'")));
    expect(sql, isNot(contains("'duplicate', jsonb_build_object(")));
    expect(
      sql,
      contains(
        "when not coalesce((v_context ->> 'has_floor_price')::boolean, false)",
      ),
    );
    expect(
      sql,
      contains(
        "'floor_price_hidden', v_floor_price_minor is not null\n"
        '      and not v_can_override_floor',
      ),
    );
  });
}

String _s5UpdateSql(Directory root) => File(
  '${root.path}/supabase/migrations/_drafts/'
  '007_pricing_customer_price_rule_update_s5.sql',
).readAsStringSync();
