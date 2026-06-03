FROM ubuntu:24.04

ARG XASH_RELEASE_TAG=continuous
ARG XASHDS_TARBALL=xashds-linux-arm64.tar.gz

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar libstdc++6 libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/cs16

RUN set -eux; \
    found=0; \
    for tag in "${XASH_RELEASE_TAG}" continuous continuous-gha-arm; do \
      url="https://github.com/FWGS/xash3d-fwgs/releases/download/${tag}/${XASHDS_TARBALL}"; \
      if curl -fL "${url}" -o /tmp/xashds.tar.gz; then \
        echo "Downloaded ${XASHDS_TARBALL} from tag ${tag}"; \
        found=1; \
        break; \
      fi; \
    done; \
    test "${found}" = "1"; \
    tar -xzf /tmp/xashds.tar.gz -C /opt/cs16; \
    rm /tmp/xashds.tar.gz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 27015/udp
EXPOSE 27015/tcp

ENTRYPOINT ["/entrypoint.sh"]
