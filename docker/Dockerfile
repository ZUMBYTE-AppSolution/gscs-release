# One image provides master, node and optional isolated game execution.
FROM docker:cli AS dockercli
FROM eclipse-temurin:17-jre-noble AS java17
FROM eclipse-temurin:21-jre-noble AS java21
FROM eclipse-temurin:25-jre-noble AS java25
FROM mcr.microsoft.com/dotnet/runtime:8.0 AS dotnet8
FROM mcr.microsoft.com/dotnet/runtime:9.0 AS dotnet9
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS dotnet10
FROM postgres:18-trixie AS environment
ARG TARGETARCH
ARG GSCS_VERSION=0.1.0-alpha.10
LABEL org.opencontainers.image.title="GSCS" \
 org.opencontainers.image.vendor="ZUMBYTE-AppSolution" \
 org.opencontainers.image.source="https://github.com/ZUMBYTE-AppSolution/gscs"
RUN apt-get update && apt-get install -y --no-install-recommends \
 ca-certificates curl libcurl4t64 libatomic1 libpulse0 libsdl2-2.0-0 \
 supervisor tini openssl jq xvfb xauth procps mono-runtime libgdiplus \
 wget git unzip bzip2 xz-utils file python3 python3-venv libfuse2t64 \
 libmono-system-xml4.0-cil libmono-system-data4.0-cil libmono-system-net-http4.0-cil \
 && if [ "$TARGETARCH" = amd64 ]; then \
  dpkg --add-architecture i386 && apt-get update \
  && apt-get install -y --no-install-recommends lib32gcc-s1 lib32stdc++6 lib32z1 wine wine64 wine32:i386 winbind; \
 fi \
 && groupadd --gid 10001 gscs && useradd --uid 10001 --gid 10001 --no-create-home --home-dir /var/lib/gscs/home --shell /usr/sbin/nologin gscs \
 && groupadd --gid 10000 gameserver && useradd --uid 10000 --gid 10000 --no-create-home --home-dir /home/container --shell /usr/sbin/nologin gameserver \
 && usermod -aG gscs postgres && rm -rf /var/lib/apt/lists/*
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=java17 /opt/java/openjdk/ /opt/gscs-java/17/
COPY --from=java21 /opt/java/openjdk/ /opt/gscs-java/21/
COPY --from=java25 /opt/java/openjdk/ /opt/gscs-java/25/
COPY --from=dotnet8 /usr/share/dotnet/shared/ /usr/share/dotnet/shared/
COPY --from=dotnet9 /usr/share/dotnet/shared/ /usr/share/dotnet/shared/
COPY --from=dotnet10 /usr/share/dotnet/ /usr/share/dotnet/
RUN ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet
COPY unified-entrypoint.sh /usr/local/bin/gscs-entrypoint
COPY start-panel.sh /usr/local/bin/gscs-start-panel
COPY healthcheck.sh /usr/local/bin/gscs-healthcheck
COPY watch-updates.sh /usr/local/bin/gscs-watch-updates
COPY maintenance-restart.sh /usr/local/bin/gscs-maintenance-restart
COPY runtime-entrypoint.sh /usr/local/bin/gscs-game-entrypoint
COPY install-proton.sh /usr/local/bin/gscs-install-proton
RUN if [ "$TARGETARCH" = amd64 ];then bash /usr/local/bin/gscs-install-proton /opt/gscs-proton;fi
RUN chmod 0755 /usr/local/bin/gscs-*
ENV GSCS_DATA=/var/lib/gscs GSCS_ROLE=master GSCS_UNIFIED=true \
 GSCS_CONTAINER_IMAGE=ghcr.io/zumbyte-appsolution/gscs:${GSCS_VERSION} \
 GSCS_PROTON_PATH=/opt/gscs-proton/proton DOTNET_ROOT=/usr/share/dotnet \
 JAVA_HOME=/opt/gscs-java/25 PATH=/opt/gscs-java/25/bin:$PATH DOTNET_EnableDiagnostics=0
WORKDIR /opt/gscs
EXPOSE 5080
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 CMD ["/usr/local/bin/gscs-healthcheck"]
ENTRYPOINT ["/usr/bin/tini","-g","--","/usr/local/bin/gscs-entrypoint"]
CMD []
FROM environment AS final
COPY packages/universal/linux-${TARGETARCH}/ /opt/gscs/
RUN chmod 0755 /opt/gscs/GSCS && /opt/gscs/GSCS --verify-payload
