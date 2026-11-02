# Binary packages come from the signed GSCS release, never from an unverified URL.
FROM docker:cli AS dockercli
FROM mcr.microsoft.com/dotnet/runtime-deps:10.0-noble
ARG TARGETARCH
ARG GSCS_ROLE=master
LABEL org.opencontainers.image.title="GSCS GameServer Management" \
 org.opencontainers.image.vendor="ZUMBYTE-AppSolution" \
 org.opencontainers.image.source="https://github.com/ZUMBYTE-AppSolution/gscs-release"
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl libcurl4t64 \
 && if [ "$TARGETARCH" = amd64 ]; then apt-get install -y --no-install-recommends lib32gcc-s1 lib32stdc++6; fi \
 && rm -rf /var/lib/apt/lists/*
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
WORKDIR /opt/gscs
COPY packages/${GSCS_ROLE}/linux-${TARGETARCH}/ /opt/gscs/
RUN chmod 0755 /opt/gscs/GSCS
ENV GSCS_DATA=/var/lib/gscs GSCS_ROLE=${GSCS_ROLE} DOTNET_EnableDiagnostics=0
EXPOSE 5080
VOLUME ["/var/lib/gscs"]
ENTRYPOINT ["/opt/gscs/GSCS"]
