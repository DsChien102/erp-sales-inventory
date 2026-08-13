import { defineRailway, preserve, project, service } from "railway/iac";

const workerWatchPatterns = [
  "apps/messaging_worker/**",
  "modules/partner/**",
  "packages/vet45_generator/**",
  "packages/vet45_lints/**",
  "packages/vet45_adapters/**",
  "packages/vet45_annotations/**",
  "packages/vet45_shared/**",
  "pubspec.yaml",
  "pubspec.lock",
];

export default defineRailway((ctx) => {
  const messagingWorker = service("messaging-worker", {
    build: {
      builder: "DOCKERFILE",
      buildEnvironment: "V3",
      dockerfilePath: "apps/messaging_worker/Dockerfile",
      watchPatterns: workerWatchPatterns,
    },
    healthcheck: "/health",
    healthcheckTimeout: 90,
    // restartPolicyType ON_FAILURE is the platform default; setting it in IaC
    // always plans as unset → ON_FAILURE (never converges).
    replicas: { "asia-southeast1-eqsg3a": 1 },
    env: {
      WORKER_ENV: ctx.environment ?? "staging",
      WORKER_LOG_LEVEL: "WARNING",
      WORKER_TENANT_BATCH_SIZE: "20",
      WORKER_MODULE_BATCH_SIZE: "10",
      WORKER_MAX_ROUNDS_PER_TICK: "5",
      WORKER_TICK_ACTIVE_SECONDS: "3",
      WORKER_TICK_IDLE_SECONDS: "15",
      WORKER_TICK_MAX_IDLE_SECONDS: "30",
      SUPABASE_URL: preserve(),
      SUPABASE_SERVICE_ROLE_KEY: preserve(),
      WORKER_TICK_SECRET: preserve(),
      RESEND_API_KEY: preserve(),
      RESEND_FROM_DOMAIN: preserve(),
      APP_LINK_BASE_URL: preserve(),
    },
  });

  return project("VET45", {
    resources: [messagingWorker],
  });
});
