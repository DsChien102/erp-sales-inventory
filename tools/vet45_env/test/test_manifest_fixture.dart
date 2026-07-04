/// Shared minimal targets registry for unit tests.
const testTargetsJson = '''
  "targets": {
    "erp": {
      "description": "Flutter ERP",
      "keys": [
        { "name": "APP_ENV", "fromManifest": "appEnv" },
        {
          "name": "SUPABASE_CONNECTION_URL",
          "from": "SUPABASE_URL",
          "required": true
        },
        { "name": "SUPABASE_ANON_KEY", "required": true },
        { "name": "LOG_LEVEL", "default": "INFO" },
        { "name": "MESSAGING_CLIENT_POLL_ENABLED", "default": "false" }
      ]
    },
    "worker": {
      "description": "Messaging worker",
      "keys": [
        { "name": "SUPABASE_URL", "required": true },
        { "name": "SUPABASE_SERVICE_ROLE_KEY", "required": true },
        {
          "name": "WORKER_TICK_SECRET",
          "required": true,
          "autoGenerate": true
        },
        { "name": "WORKER_LOG_LEVEL", "default": "WARNING" },
        { "name": "WORKER_TENANT_BATCH_SIZE", "default": "20" },
        { "name": "WORKER_MODULE_BATCH_SIZE", "default": "10" },
        { "name": "WORKER_MAX_ROUNDS_PER_TICK", "default": "5" },
        { "name": "WORKER_TICK_ACTIVE_SECONDS", "default": "3" },
        { "name": "WORKER_TICK_IDLE_SECONDS", "default": "15" },
        { "name": "WORKER_TICK_MAX_IDLE_SECONDS", "default": "30" },
        { "name": "PORT", "default": "8080" }
      ]
    },
    "deploy": {
      "description": "iOS TestFlight (shared)",
      "secretsFile": "config/secrets/deploy.env",
      "writeEnvFile": false,
      "keys": [
        { "name": "APP_STORE_CONNECT_ISSUER_ID", "required": true },
        { "name": "APP_STORE_CONNECT_KEY_IDENTIFIER", "required": true }
      ]
    }
  }
''';

String manifestWithEnv(String environmentsJson, {String defaultId = 'local'}) {
  return '''
{
  "default": "$defaultId",
  $testTargetsJson,
  "environments": $environmentsJson
}
''';
}
