FROM dart:3.13.4 AS build
WORKDIR /workspace
COPY packages/game_core packages/game_core
COPY services/game_engine services/game_engine
WORKDIR /workspace/services/game_engine
RUN dart pub get && dart compile exe bin/server.dart -o /engine
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /engine /app/engine
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/app/engine"]
