FROM --platform=linux/arm64 ubuntu:24.04

ARG XASH_RELEASE_TAG=continuous-gha-arm
ARG XASHDS_TARBALL=xashds-linux-arm64.tar.gz

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar libstdc++6 libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/cs16

RUN curl -fL "https://github.com/FWGS/xash3d-fwgs/releases/download/${XASH_RELEASE_TAG}/${XASHDS_TARBALL}" \
    -o /tmp/xashds.tar.gz \
    && tar -xzf /tmp/xashds.tar.gz -C /opt/cs16 \
    && rm /tmp/xashds.tar.gz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 27015/udp
EXPOSE 27015/tcp

ENTRYPOINT ["/entrypoint.sh"]
