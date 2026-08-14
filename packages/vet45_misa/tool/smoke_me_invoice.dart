import 'dart:io';

import 'package:vet45_misa/e_invoice.dart';

import 'smoke_env.dart';
import 'smoke_token_store.dart';

/// Live smoke against MISA meInvoice (templates / publish / status / download).
///
/// MISA: Bearer ~14 days — **do not** call `/auth/token` per invoice/smoke.
Future<void> main(List<String> args) async {
  if (args.isEmpty || hasFlag(args, 'help') || hasFlag(args, 'h')) {
    _printUsage();
    exit(args.isEmpty ? 64 : 0);
  }

  final command = args.firstWhere(
    (a) => !a.startsWith('-'),
    orElse: () => '',
  );
  if (command.isEmpty) {
    _printUsage();
    exit(64);
  }

  final envPath = resolveEnvFilePath(args);
  var env = Map<String, String>.from(Platform.environment);
  if (envPath != null) {
    env = loadDotEnvFile(envPath, existing: env);
    stderr.writeln('Loaded env file: $envPath');
  }

  var password = envGet(env, 'MISA_MEINVOICE_PASSWORD');
  if ((password == null || password.isEmpty) &&
      hasFlag(args, 'stdin-password')) {
    password = await readPasswordFromStdin();
    if (password != null && password.isNotEmpty) {
      env['MISA_MEINVOICE_PASSWORD'] = password;
    }
  }

  final tokenPath = resolveTokenFilePath(args);
  final withCode = _resolveWithCode(args, env);
  final year = int.tryParse(argValue(args, 'year') ?? '');

  if (command == 'token') {
    await _runTokenCommand(env, args, tokenPath);
    return;
  }

  final client = _buildClientForApi(env, args, tokenPath);
  switch (command) {
    case 'templates':
      await _runTemplates(client, withCode: withCode, year: year);
    case 'preview':
      await _runPreview(client, env, withCode: withCode);
    case 'publish':
      await _requirePublishConfirm(env);
      await _runPublish(client, env, args, withCode: withCode);
    case 'status':
      await _runStatus(client, env, args, withCode: withCode);
    case 'download':
      await _runDownload(client, env, args, withCode: withCode);
    case 'all':
      await _requirePublishConfirm(env);
      await _runAll(client, env, args, withCode: withCode, year: year);
    default:
      stderr.writeln('Unknown command: $command');
      _printUsage();
      exit(64);
  }
}

void _printUsage() {
  stdout.writeln('''
Smoke meInvoice outbound API (live network).

MISA: token ~14 days. Do NOT login on every smoke/invoice (IP block risk).

Commands:
  token       POST /auth/token once → save .meinvoice_token.local
  templates   GET  /invoice/templates   (uses saved token)
  preview     POST /invoice/unpublishview (draft preview link)
  publish     POST /invoice             (requires MISA_SMOKE_CONFIRM_PUBLISH=1)
  status      POST /invoice/status
  download    POST /invoice/download
  all         templates → publish → status → download (uses saved token)

Typical flow:
  dart run tool/smoke_me_invoice.dart token
  dart run tool/smoke_me_invoice.dart templates
  dart run tool/smoke_me_invoice.dart all

Env (or .env.misa.local):
  MISA_MEINVOICE_BASE_URL   default testapi
  MISA_MEINVOICE_APP_ID / TAX_CODE / USERNAME / PASSWORD   (for `token`)
  MISA_MEINVOICE_ACCESS_TOKEN / ACCESS_TOKEN_EXPIRES_AT    (optional override)
  MISA_MEINVOICE_WITH_CODE=true|false
  MISA_MEINVOICE_SERIES   optional for publish/preview
  MISA_MEINVOICE_BUYER_* / REF_ID / TRANSACTION_ID
  MISA_MEINVOICE_SIGN_TYPE=2|5          default 2 (HSM with CKS)
  MISA_SMOKE_CONFIRM_PUBLISH=1          required for publish|all

Flags:
  --env-file=PATH
  --token-file=PATH          default .meinvoice_token.local
  --force                    token: ignore cache and login again
  --allow-login              API cmds: allow /auth/token if no saved bearer
  --stdin-password
  --tx=TRANSACTION_ID
  --format=xml|pdf|all
  --with-code | --no-code
  --calcu | --no-calcu       MTT query flag cho status/download
  --year=YYYY
''');
}

Future<void> _runTokenCommand(
  Map<String, String> env,
  List<String> args,
  String tokenPath,
) async {
  final force = hasFlag(args, 'force');
  final existing = loadSmokeToken(tokenPath);
  if (!force && existing != null && !existing.isExpired) {
    stdout.writeln(
      'Cached token still valid until ${existing.expiresAt.toUtc().toIso8601String()}',
    );
    stdout.writeln('File: $tokenPath');
    stdout.writeln('Use --force to call /auth/token again (avoid unless needed).');
    return;
  }

  final loginConfig = MeInvoiceConfig(
    baseUrl:
        envGet(env, 'MISA_MEINVOICE_BASE_URL') ?? MeInvoiceConfig.testBaseUrl,
    appId: envGet(env, 'MISA_MEINVOICE_APP_ID'),
    taxCode: envGet(env, 'MISA_MEINVOICE_TAX_CODE'),
    username: envGet(env, 'MISA_MEINVOICE_USERNAME'),
    password: envGet(env, 'MISA_MEINVOICE_PASSWORD'),
  );
  if (!loginConfig.hasLoginCredentials) {
    stderr.writeln(
      'Config error: ${loginConfig.missingCredentialError ?? 'missing_login'}',
    );
    stderr.writeln(
      '`token` needs APP_ID, TAX_CODE, USERNAME, PASSWORD '
      '(env / .env.misa.local / --stdin-password).',
    );
    exit(1);
  }

  stdout.writeln('→ obtainAccessToken(forceLogin=$force)  [/auth/token]');
  final client = MeInvoiceClient(config: loginConfig);
  final result = await client.obtainAccessToken(forceLogin: force);
  _failIfNeeded(result);
  final session = result.data!;
  final record = SmokeTokenRecord(
    accessToken: session.value,
    expiresAt: session.expiresAt,
    baseUrl: loginConfig.baseUrl,
    taxCode: loginConfig.taxCode,
  );
  saveSmokeToken(tokenPath, record);
  final preview = session.value.length <= 12
      ? session.value
      : '${session.value.substring(0, 8)}…';
  stdout.writeln('OK token=$preview expiresAt=${session.expiresAt.toUtc().toIso8601String()}');
  stdout.writeln('Saved: $tokenPath');
  stdout.writeln('Reuse with: dart run tool/smoke_me_invoice.dart templates');
}

MeInvoiceClient _buildClientForApi(
  Map<String, String> env,
  List<String> args,
  String tokenPath,
) {
  final baseUrl =
      envGet(env, 'MISA_MEINVOICE_BASE_URL') ?? MeInvoiceConfig.testBaseUrl;
  final envToken = envGet(env, 'MISA_MEINVOICE_ACCESS_TOKEN');
  final envExpiryRaw = envGet(env, 'MISA_MEINVOICE_ACCESS_TOKEN_EXPIRES_AT');
  DateTime? envExpiry;
  if (envExpiryRaw != null) {
    envExpiry = DateTime.tryParse(envExpiryRaw)?.toUtc();
  }

  final fileToken = loadSmokeToken(tokenPath);
  String? accessToken = envToken;
  DateTime? accessExpires = envExpiry;
  if (accessToken == null || accessToken.isEmpty) {
    if (fileToken != null && !fileToken.isExpired) {
      accessToken = fileToken.accessToken;
      accessExpires = fileToken.expiresAt;
      stderr.writeln(
        'Using cached token until ${fileToken.expiresAt.toUtc().toIso8601String()} ($tokenPath)',
      );
    }
  }

  final allowLogin = hasFlag(args, 'allow-login');
  if (accessToken == null || accessToken.isEmpty) {
    if (!allowLogin) {
      stderr.writeln(
        'No Bearer cache. Run: dart run tool/smoke_me_invoice.dart token',
      );
      stderr.writeln(
        '(MISA: avoid login-per-call. Pass --allow-login only if you must.)',
      );
      exit(1);
    }
    stderr.writeln('WARNING: --allow-login will call /auth/token (IP risk).');
  }

  final config = MeInvoiceConfig(
    baseUrl: fileToken?.baseUrl ?? baseUrl,
    appId: envGet(env, 'MISA_MEINVOICE_APP_ID'),
    taxCode: envGet(env, 'MISA_MEINVOICE_TAX_CODE') ?? fileToken?.taxCode,
    username: envGet(env, 'MISA_MEINVOICE_USERNAME'),
    password: envGet(env, 'MISA_MEINVOICE_PASSWORD'),
    accessToken: accessToken,
    accessTokenExpiresAt: accessExpires,
  );

  final missing = config.missingCredentialError;
  if (missing != null) {
    stderr.writeln('Config error: $missing');
    exit(1);
  }
  return MeInvoiceClient(config: config);
}

bool _resolveWithCode(List<String> args, Map<String, String> env) {
  if (hasFlag(args, 'with-code')) {
    return true;
  }
  if (hasFlag(args, 'no-code')) {
    return false;
  }
  return envFlag(env, 'MISA_MEINVOICE_WITH_CODE', defaultValue: true);
}

MeInvoiceInvoiceQuery _invoiceQuery(bool withCode, {bool? invoiceCalcu}) {
  if (invoiceCalcu != null) {
    return MeInvoiceInvoiceQuery(
      invoiceWithCode: withCode,
      invoiceCalcu: invoiceCalcu,
    );
  }
  final calcuFlag = Platform.environment['MISA_MEINVOICE_INVOICE_CALCU'];
  if (calcuFlag != null) {
    return MeInvoiceInvoiceQuery(
      invoiceWithCode: withCode,
      invoiceCalcu: calcuFlag == '1' || calcuFlag.toLowerCase() == 'true',
    );
  }
  return MeInvoiceInvoiceQuery(invoiceWithCode: withCode);
}

bool _resolveInvoiceCalcu(List<String> args, Map<String, String> env) {
  if (hasFlag(args, 'calcu')) {
    return true;
  }
  if (hasFlag(args, 'no-calcu')) {
    return false;
  }
  return envFlag(env, 'MISA_MEINVOICE_INVOICE_CALCU');
}

MeInvoiceSignType _resolveSignType(Map<String, String> env) {
  final raw = envGet(env, 'MISA_MEINVOICE_SIGN_TYPE') ?? '2';
  return switch (raw) {
    '5' => MeInvoiceSignType.hsmNoCks,
    _ => MeInvoiceSignType.hsmWithCks,
  };
}

String _todayDateOnly() {
  final now = DateTime.now().toUtc();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

Future<List<MeInvoiceTemplate>> _runTemplates(
  MeInvoiceClient client, {
  required bool withCode,
  int? year,
}) async {
  stdout.writeln('→ listInvoiceTemplates(invoiceWithCode=$withCode, year=$year)');
  final result = await client.listInvoiceTemplates(
    invoiceWithCode: withCode,
    year: year,
  );
  _failIfNeeded(result);
  final list = result.data!;
  stdout.writeln('OK ${list.length} template(s)');
  for (final t in list) {
    stdout.writeln(
      '  ${t.ipTemplateId} | ${t.invTemplateNo} | ${t.invSeries} | ${t.templateName}'
      '${t.inactive ? ' [inactive]' : ''}',
    );
  }
  return list;
}

Future<MeInvoiceInvoiceData> _buildSmokeInvoice(
  Map<String, String> env, {
  required bool withCode,
  List<MeInvoiceTemplate>? templates,
}) async {
  var series = envGet(env, 'MISA_MEINVOICE_SERIES');
  if (series == null && templates != null) {
    final active = templates.where((t) => !t.inactive).toList();
    if (active.isNotEmpty) {
      series = active.first.invSeries;
    }
  }
  series ??= '1C25TYY';

  final refId =
      envGet(env, 'MISA_MEINVOICE_REF_ID') ??
      'smoke-${DateTime.now().toUtc().millisecondsSinceEpoch}';

  return MeInvoiceInvoiceData(
    refId: refId,
    invSeries: series,
    invDate: _todayDateOnly(),
    currencyCode: 'VND',
    exchangeRate: 1,
    paymentMethodName: 'TM/CK',
    isInvoiceSummary: !withCode,
    buyerLegalName: envGet(env, 'MISA_MEINVOICE_BUYER_NAME') ?? 'Smoke Buyer',
    buyerTaxCode: envGet(env, 'MISA_MEINVOICE_BUYER_TAX_CODE'),
    buyerAddress: envGet(env, 'MISA_MEINVOICE_BUYER_ADDRESS') ?? 'Ha Noi',
    buyerEmail: envGet(env, 'MISA_MEINVOICE_BUYER_EMAIL'),
    totalSaleAmountOc: 10000,
    totalSaleAmount: 10000,
    totalAmountWithoutVatOc: 10000,
    totalAmountWithoutVat: 10000,
    totalVatAmountOc: 1000,
    totalVatAmount: 1000,
    totalDiscountAmountOc: 0,
    totalDiscountAmount: 0,
    totalAmountOc: 11000,
    totalAmount: 11000,
    totalAmountInWords: 'Muoi mot nghin dong',
    originalInvoiceDetail: const [
      MeInvoiceOriginalInvoiceDetail(
        itemType: 1,
        lineNumber: 1,
        sortOrder: 1,
        itemName: 'Smoke line item',
        unitName: 'lan',
        quantity: 1,
        unitPrice: 10000,
        discountRate: 0,
        discountAmountOc: 0,
        amountOc: 10000,
        amount: 10000,
        amountWithoutVatOc: 10000,
        amountWithoutVat: 10000,
        vatRateName: '10%',
        vatAmountOc: 1000,
        vatAmount: 1000,
      ),
    ],
    taxRateInfo: const [
      MeInvoiceTaxRateInfo(
        vatRateName: '10%',
        amountWithoutVatOc: 10000,
        vatAmountOc: 1000,
      ),
    ],
  );
}

Future<void> _runPreview(
  MeInvoiceClient client,
  Map<String, String> env, {
  required bool withCode,
}) async {
  final templates = await _runTemplates(client, withCode: withCode);
  final invoice = await _buildSmokeInvoice(
    env,
    withCode: withCode,
    templates: templates,
  );
  stdout.writeln('→ previewUnpublished(refId=${invoice.refId})');
  final result = await client.previewUnpublished(invoice);
  _failIfNeeded(result);
  stdout.writeln('OK preview link: ${result.data}');
}

Future<void> _requirePublishConfirm(Map<String, String> env) async {
  if (!envFlag(env, 'MISA_SMOKE_CONFIRM_PUBLISH')) {
    stderr.writeln(
      'Refusing publish: set MISA_SMOKE_CONFIRM_PUBLISH=1 to allow live publish.',
    );
    exit(2);
  }
}

Future<MeInvoicePublishInvoiceResultItem> _runPublish(
  MeInvoiceClient client,
  Map<String, String> env,
  List<String> args, {
  required bool withCode,
  List<MeInvoiceTemplate>? templates,
}) async {
  final invoice = await _buildSmokeInvoice(
    env,
    withCode: withCode,
    templates: templates,
  );
  final signType = _resolveSignType(env);

  stdout.writeln(
    '→ publish(refId=${invoice.refId}, signType=${signType.wireValue})',
  );
  final result = await client.publish(
    MeInvoicePublishRequest(
      signType: signType,
      invoiceData: [invoice],
    ),
  );
  _failIfNeeded(result);
  final data = result.data!.first;
  stdout.writeln(
    'OK tx=${data.transactionId} invNo=${data.invNo ?? '-'} '
    'err=${data.errorCode ?? '-'}',
  );
  return data;
}

Future<MeInvoiceInvoiceStatus> _runStatus(
  MeInvoiceClient client,
  Map<String, String> env,
  List<String> args, {
  required bool withCode,
  String? transactionId,
  MeInvoiceInvoiceQuery? query,
  bool retryAfterPublish = false,
}) async {
  final tx =
      transactionId ??
      argValue(args, 'tx') ??
      envGet(env, 'MISA_MEINVOICE_TRANSACTION_ID');
  if (tx == null || tx.isEmpty) {
    stderr.writeln(
      'Missing transaction id (--tx or MISA_MEINVOICE_TRANSACTION_ID)',
    );
    exit(1);
  }
  final statusQuery =
      query ??
      _invoiceQuery(withCode, invoiceCalcu: _resolveInvoiceCalcu(args, env));

  const maxAttempts = 6;
  const retryDelay = Duration(seconds: 2);
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    stdout.writeln(
      '→ getStatus([$tx], invoiceWithCode=${statusQuery.invoiceWithCode}, '
      'invoiceCalcu=${statusQuery.invoiceCalcu}, attempt=$attempt/$maxAttempts)',
    );
    final result = await client.getStatus(
      ids: <String>[tx],
      inputType: MeInvoiceStatusInputType.transactionId,
      query: statusQuery,
    );
    if (result.isSuccess && result.data!.isNotEmpty) {
      final data = result.data!.first;
      stdout.writeln(
        'OK tx=${data.transactionId} status=${data.publishStatus} '
        'invNo=${data.invNo ?? '-'} invoiceCode=${data.invoiceCode ?? '-'}',
      );
      return data;
    }
    final err = result.error ?? 'meinvoice_status_empty_data';
    final shouldRetry =
        retryAfterPublish &&
        attempt < maxAttempts &&
        (err == 'meinvoice_status_empty_data' ||
            err.contains('InvoiceNotFound'));
    if (!shouldRetry) {
      stderr.writeln('FAIL: $err');
      if (err == 'meinvoice_status_empty_data') {
        stderr.writeln(
          'Hint: kiểm tra invoiceWithCode/invoiceCalcu khớp ký hiệu (vd. 2C26MYY → calcu). '
          'Thử --calcu hoặc truyền đúng InvSeries qua publish.',
        );
      }
      exit(1);
    }
    stderr.writeln('$err — retry sau ${retryDelay.inSeconds}s…');
    await Future<void>.delayed(retryDelay);
  }
  stderr.writeln('FAIL: meinvoice_status_empty_data sau $maxAttempts lần thử');
  exit(1);
}

Future<List<MeInvoiceInvoiceDataPublished>> _runDownload(
  MeInvoiceClient client,
  Map<String, String> env,
  List<String> args, {
  required bool withCode,
  String? transactionId,
  MeInvoiceInvoiceQuery? query,
}) async {
  final tx =
      transactionId ??
      argValue(args, 'tx') ??
      envGet(env, 'MISA_MEINVOICE_TRANSACTION_ID');
  if (tx == null || tx.isEmpty) {
    stderr.writeln(
      'Missing transaction id (--tx or MISA_MEINVOICE_TRANSACTION_ID)',
    );
    exit(1);
  }
  final formatName =
      (argValue(args, 'format') ??
              envGet(env, 'MISA_MEINVOICE_DOWNLOAD_FORMAT') ??
              'pdf')
          .toLowerCase();
  final format = switch (formatName) {
    'xml' => MeInvoiceDownloadDataType.xml,
    'all' => MeInvoiceDownloadDataType.all,
    _ => MeInvoiceDownloadDataType.pdf,
  };

  final downloadQuery =
      query ??
      _invoiceQuery(withCode, invoiceCalcu: _resolveInvoiceCalcu(args, env));

  stdout.writeln(
    '→ download([$tx], format=$formatName, '
    'invoiceWithCode=${downloadQuery.invoiceWithCode}, '
    'invoiceCalcu=${downloadQuery.invoiceCalcu})',
  );
  final result = await client.download(
    transactionIds: <String>[tx],
    query: downloadQuery,
    downloadDataType: format,
  );
  _failIfNeeded(result);
  final data = result.data!;
  stdout.writeln('OK ${data.length} item(s)');
  for (final item in data) {
    final bytesLen = item.bytes?.length ?? 0;
    final b64Len = item.data?.length ?? 0;
    stdout.writeln(
      '  ${item.transactionId} bytes=$bytesLen b64Chars=$b64Len',
    );
  }
  return data;
}

Future<void> _runAll(
  MeInvoiceClient client,
  Map<String, String> env,
  List<String> args, {
  required bool withCode,
  int? year,
}) async {
  final templates = await _runTemplates(
    client,
    withCode: withCode,
    year: year,
  );
  final published = await _runPublish(
    client,
    env,
    args,
    withCode: withCode,
    templates: templates,
  );
  final tx = published.transactionId;
  if (tx == null || tx.isEmpty) {
    stderr.writeln('Publish succeeded but no TransactionID returned.');
    exit(1);
  }
  final invSeries =
      published.invSeries ??
      envGet(env, 'MISA_MEINVOICE_SERIES') ??
      templates.firstWhere((t) => !t.inactive).invSeries;
  final postPublishQuery = MeInvoiceInvoiceQuery.fromInvSeries(invSeries);
  stderr.writeln(
    'Post-publish query from series $invSeries: '
    'invoiceWithCode=${postPublishQuery.invoiceWithCode}, '
    'invoiceCalcu=${postPublishQuery.invoiceCalcu}',
  );
  await _runStatus(
    client,
    env,
    args,
    withCode: withCode,
    transactionId: tx,
    query: postPublishQuery,
    retryAfterPublish: true,
  );
  await _runDownload(
    client,
    env,
    args,
    withCode: withCode,
    transactionId: tx,
    query: postPublishQuery,
  );
  stdout.writeln('All smoke steps finished.');
}

void _failIfNeeded<T>(MeInvoiceResult<T> result) {
  if (result.isSuccess) {
    return;
  }
  stderr.writeln(
    'FAIL: ${result.error}'
    '${result.rateLimited ? ' (rate limited)' : ''}',
  );
  exit(1);
}
