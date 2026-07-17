import 'dart:convert';
import 'dart:io';

import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';

/// Writes a minimal workspace + target layout under [root] for unit tests.
void writeTestWorkspace(
  Directory root, {
  String defaultEnvironment = 'local',
  List<String> environmentIds = const ['local'],
  bool includeErp = true,
  bool includeWorker = true,
  bool includeDeploy = true,
  bool includeAdmin = false,
  Map<String, Map<String, dynamic>>? erpEnvOverrides,
  Map<String, Map<String, dynamic>>? workerEnvOverrides,
  Map<String, Map<String, dynamic>>? environmentMeta,
  Map<String, Map<String, String>>? profiles,
  String defaultProfile = 'default',
}) {
  Directory('${root.path}/config/default').createSync(recursive: true);

  final environments = <String, dynamic>{
    for (final id in environmentIds)
      id: {
        'description': 'test $id',
        'supabaseSource': 'secrets',
        ...?environmentMeta?[id],
      },
  };

  final profileEntries = profiles ??
      {
        'default': {
          'description': 'test default',
          'secretsRoot': 'config/default',
        },
      };

  final workspace = {
    'version': 1,
    'defaultEnvironment': defaultEnvironment,
    'scan': {
      'include': [
        'apps/**/vet45.target.json',
        'config/**/vet45.target.json',
      ],
      'exclude': ['**/.dart_tool/**', '**/build/**'],
    },
    'profiles': {
      'defaultProfile': defaultProfile,
      'entries': profileEntries,
    },
    'environments': environments,
  };

  File('${root.path}/vet45.workspace.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(workspace)}\n',
  );

  if (includeErp) {
    _writeTarget(
      root,
      dir: 'apps/erp',
      id: 'erp',
      description: 'Flutter ERP',
      kind: 'flutter',
      keys: [
        {'name': 'APP_ENV', 'fromManifest': 'appEnv'},
        {
          'name': 'SUPABASE_CONNECTION_URL',
          'from': 'SUPABASE_URL',
          'required': true,
        },
        {'name': 'SUPABASE_ANON_KEY', 'required': true},
        {'name': 'LOG_LEVEL', 'default': 'INFO'},
        {'name': 'MESSAGING_CLIENT_POLL_ENABLED', 'default': 'false'},
      ],
      environments: {
        for (final id in environmentIds)
          id: erpEnvOverrides?[id] ??
              {
                'envFile': '.env',
                'flavor': 'development',
                'appEnv': 'development',
              },
      },
    );
  }

  if (includeAdmin) {
    _writeTarget(
      root,
      dir: 'apps/admin',
      id: 'admin',
      description: 'Flutter Platform Admin',
      kind: 'flutter',
      keys: [
        {'name': 'APP_ENV', 'fromManifest': 'appEnv'},
        {
          'name': 'SUPABASE_CONNECTION_URL',
          'from': 'SUPABASE_URL',
          'required': true,
        },
        {'name': 'SUPABASE_ANON_KEY', 'required': true},
      ],
      environments: {
        for (final id in environmentIds)
          id: {
            'envFile': '.env',
            'flavor': 'development',
            'appEnv': 'development',
          },
      },
    );
  }

  if (includeWorker) {
    _writeTarget(
      root,
      dir: 'apps/messaging_worker',
      id: 'worker',
      description: 'Messaging worker',
      kind: 'dart-worker',
      keys: [
        {'name': 'SUPABASE_URL', 'required': true},
        {'name': 'SUPABASE_SERVICE_ROLE_KEY', 'required': true},
        {
          'name': 'WORKER_TICK_SECRET',
          'required': true,
          'autoGenerate': true,
        },
        {'name': 'WORKER_LOG_LEVEL', 'default': 'WARNING'},
        {'name': 'WORKER_TENANT_BATCH_SIZE', 'default': '20'},
        {'name': 'WORKER_MODULE_BATCH_SIZE', 'default': '10'},
        {'name': 'WORKER_MAX_ROUNDS_PER_TICK', 'default': '5'},
        {'name': 'WORKER_TICK_ACTIVE_SECONDS', 'default': '3'},
        {'name': 'WORKER_TICK_IDLE_SECONDS', 'default': '15'},
        {'name': 'WORKER_TICK_MAX_IDLE_SECONDS', 'default': '30'},
        {'name': 'PORT', 'default': '8080'},
      ],
      environments: {
        for (final id in environmentIds)
          id: workerEnvOverrides?[id] ?? {'envFile': '.env'},
      },
    );
  }

  if (includeDeploy) {
    _writeTarget(
      root,
      dir: 'config/deploy',
      id: 'deploy',
      description: 'iOS TestFlight (shared)',
      writeEnvFile: false,
      secretsFile: 'deploy.env',
      keys: [
        {'name': 'APP_STORE_CONNECT_ISSUER_ID', 'required': true},
        {'name': 'APP_STORE_CONNECT_KEY_IDENTIFIER', 'required': true},
      ],
      environments: {
        for (final id in environmentIds) id: <String, dynamic>{},
      },
    );
  }
}

void _writeTarget(
  Directory root, {
  required String dir,
  required String id,
  required String description,
  required List<Map<String, dynamic>> keys,
  required Map<String, Map<String, dynamic>> environments,
  String? kind,
  bool writeEnvFile = true,
  String? secretsFile,
}) {
  final targetDir = Directory('${root.path}/$dir');
  targetDir.createSync(recursive: true);
  final json = <String, dynamic>{
    'version': 1,
    'id': id,
    'description': description,
    if (kind != null) 'kind': kind,
    'writeEnvFile': writeEnvFile,
    if (secretsFile != null) 'secretsFile': secretsFile,
    'keys': keys,
    'environments': environments,
  };
  File('${targetDir.path}/vet45.target.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
}

WorkspaceContext testContext(EnvManifest manifest, String environmentId) =>
    manifest.context(environmentId: environmentId);
