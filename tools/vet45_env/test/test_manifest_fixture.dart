import 'dart:convert';
import 'dart:io';

import 'package:vet45_env/manifest.dart';
import 'package:vet45_env/profile_registry.dart';

const _erpActions = {
  'debug': {
    'command': 'flutter',
    'args': [
      'run',
      '--flavor',
      '{{flavor}}',
      '--dart-define-from-file={{envBasename}}',
    ],
    'cwd': '.',
    'requireEnvFile': true,
  },
  'debug:web': {
    'command': 'flutter',
    'args': [
      'run',
      '-d',
      'chrome',
      '--flavor',
      '{{flavor}}',
      '--dart-define-from-file={{envBasename}}',
    ],
    'cwd': '.',
    'requireEnvFile': true,
  },
  'debug:ios': {
    'command': 'flutter',
    'args': [
      'run',
      '-d',
      'ios',
      '--flavor',
      '{{flavor}}',
      '--dart-define-from-file={{envBasename}}',
    ],
    'cwd': '.',
    'platforms': ['macos'],
    'requireEnvFile': true,
  },
};

const _workerActions = {
  'serve': {
    'command': 'dart',
    'args': ['run', 'bin/worker.dart', '--serve'],
    'cwd': '.',
    'passEnvFile': true,
    'localSupabaseCheck': true,
    'requireEnvFile': true,
  },
  'once': {
    'command': 'dart',
    'args': ['run', 'bin/worker.dart', '--once'],
    'cwd': '.',
    'passEnvFile': true,
    'localSupabaseCheck': true,
    'requireEnvFile': true,
  },
  'docker': {
    'command': 'docker',
    'args': ['compose', 'up', '--build', 'messaging-worker'],
    'cwd': '{{workspaceRoot}}',
    'env': {
      'WORKER_ENV_FILE': '{{envFile}}',
      'WORKER_SUPABASE_URL': '{{dockerSupabaseUrl}}',
    },
    'requireEnvFile': true,
  },
  'deploy': {
    'command': './scripts/deploy.sh',
    'args': ['--env', '{{railwayEnvironment}}'],
    'cwd': '.',
    'requireRailwayEnvironment': true,
  },
};

/// Writes a minimal workspace + target layout under [root] for unit tests.
///
/// Profiles are local dirs under `.vet45/profiles/<id>/` (not in workspace JSON).
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
  /// Profile ids to create as `.vet45/profiles/<id>/` directories.
  List<String> profileIds = const ['default'],
  String activeProfile = 'default',
  bool writeActive = true,
  bool includeTemplates = false,
  bool includeDoctorAlignHosts = true,
}) {
  final environments = <String, dynamic>{
    for (final id in environmentIds)
      id: {
        'description': 'test $id',
        'supabaseSource': 'secrets',
        ...?environmentMeta?[id],
      },
  };

  final workspace = {
    'version': 1,
    'defaultEnvironment': defaultEnvironment,
    'scan': {
      'include': [
        'apps/**/vet45.target.json',
        'deploy/**/vet45.target.json',
      ],
      'exclude': [
        '**/.dart_tool/**',
        '**/build/**',
        '**/.vet45/profiles/**',
      ],
    },
    'environments': environments,
    if (includeDoctorAlignHosts && includeErp && includeWorker)
      'doctor': {
        'alignHosts': [
          {
            'name': 'supabase host',
            'targets': ['erp', 'worker'],
            'keys': ['SUPABASE_CONNECTION_URL', 'SUPABASE_URL'],
          },
        ],
      },
  };

  File('${root.path}/vet45.workspace.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(workspace)}\n',
  );

  if (includeTemplates) {
    // Legacy flag — templates/ removed; no-op kept for old call sites.
  }

  for (final id in profileIds) {
    Directory('${root.path}/.vet45/profiles/$id').createSync(recursive: true);
  }

  if (writeActive && profileIds.contains(activeProfile)) {
    writeActiveState(
      root,
      ActiveState(
        profileId: activeProfile,
        environmentId: defaultEnvironment,
      ),
    );
  }

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
          'description': 'Supabase project URL for ERP',
        },
        {
          'name': 'SUPABASE_ANON_KEY',
          'required': true,
          'description': 'Supabase anon key for ERP',
        },
        {
          'name': 'LOG_LEVEL',
          'default': 'INFO',
          'description': 'ERP log level',
        },
        {
          'name': 'MESSAGING_CLIENT_POLL_ENABLED',
          'default': 'false',
          'description': 'ERP messaging poll flag',
        },
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
      actions: _erpActions,
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
          'description': 'Supabase project URL for Admin',
        },
        {
          'name': 'SUPABASE_ANON_KEY',
          'required': true,
          'description': 'Supabase anon key for Admin',
        },
      ],
      environments: {
        for (final id in environmentIds)
          id: {
            'envFile': '.env',
            'flavor': 'development',
            'appEnv': 'development',
          },
      },
      actions: _erpActions,
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
        {
          'name': 'SUPABASE_URL',
          'required': true,
          'description': 'Supabase project URL for worker',
        },
        {
          'name': 'SUPABASE_SERVICE_ROLE_KEY',
          'required': true,
          'description': 'Supabase service role for worker',
        },
        {
          'name': 'WORKER_TICK_SECRET',
          'required': true,
          'autoGenerate': true,
          'description': 'Worker tick auth secret',
        },
        {
          'name': 'WORKER_LOG_LEVEL',
          'default': 'WARNING',
          'description': 'Worker log level',
        },
        {
          'name': 'WORKER_TENANT_BATCH_SIZE',
          'default': '20',
          'description': 'Worker tenant batch size',
        },
        {
          'name': 'WORKER_MODULE_BATCH_SIZE',
          'default': '10',
          'description': 'Worker module batch size',
        },
        {
          'name': 'WORKER_MAX_ROUNDS_PER_TICK',
          'default': '5',
          'description': 'Worker max rounds per tick',
        },
        {
          'name': 'WORKER_TICK_ACTIVE_SECONDS',
          'default': '3',
          'description': 'Worker active tick sleep',
        },
        {
          'name': 'WORKER_TICK_IDLE_SECONDS',
          'default': '15',
          'description': 'Worker idle tick sleep',
        },
        {
          'name': 'WORKER_TICK_MAX_IDLE_SECONDS',
          'default': '30',
          'description': 'Worker max idle sleep',
        },
        {
          'name': 'PORT',
          'default': '8080',
          'description': 'Worker HTTP port',
        },
      ],
      environments: {
        for (final id in environmentIds)
          id: workerEnvOverrides?[id] ?? {'envFile': '.env'},
      },
      actions: _workerActions,
    );
  }

  if (includeDeploy) {
    _writeTarget(
      root,
      dir: 'deploy',
      id: 'deploy',
      description: 'iOS TestFlight (shared)',
      writeEnvFile: false,
      secretsFile: 'deploy.env',
      keys: [
        {
          'name': 'APP_STORE_CONNECT_ISSUER_ID',
          'required': true,
          'description': 'ASC issuer ID',
        },
        {
          'name': 'APP_STORE_CONNECT_KEY_IDENTIFIER',
          'required': true,
          'description': 'ASC key identifier',
        },
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
  Map<String, Map<String, dynamic>>? actions,
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
    if (actions != null) 'actions': actions,
  };
  File('${targetDir.path}/vet45.target.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
}

WorkspaceContext testContext(EnvManifest manifest, String environmentId) =>
    manifest.context(environmentId: environmentId);
