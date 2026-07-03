FROM dart:stable AS build

WORKDIR /app

COPY . .
COPY apps/messaging_worker/docker/workspace.pubspec.yaml ./pubspec.yaml

RUN dart pub get

WORKDIR /app/apps/messaging_worker
RUN dart compile exe bin/worker.dart -o /worker

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /worker /worker

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/worker", "--serve"]