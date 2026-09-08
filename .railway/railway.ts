import { defineRailway, image, preserve, project, service } from "railway/iac";

const workerImage =
  "registry.gitlab.hamsa.co/vet45/vet45/messaging-worker";

export default defineRailway((ctx) => {
  const env = ctx.environment ?? "staging";

  const messagingWorker = service("messaging-worker", {
    source: image(`${workerImage}:${env}`),
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
      SUPABASE_URL: ctx.shared.SUPABASE_URL,
      APP_LINK_BASE_URL: ctx.shared.APP_LINK_BASE_URL,
      SUPABASE_SERVICE_ROLE_KEY: preserve(),
      WORKER_TICK_SECRET: preserve(),
      RESEND_API_KEY: preserve(),
      RESEND_FROM_DOMAIN: preserve(),
    },
  });

  return project("VET45", {
    resources: [messagingWorker],
  });
});
