# Build stage
FROM --platform=linux/arm64 ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git cmake g++ make \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone --recursive https://github.com/FWGS/hlsdk-portable.git .
RUN cmake -DCMAKE_BUILD_TYPE=Release -D64BIT=ON -B build -S . \
    && cmake --build build

# Final stage
FROM --platform=linux/arm64 ubuntu:24.04

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

# Copy native libs built in the first stage
# XashDS expects them in valve/dlls and cstrike/dlls
RUN mkdir -p /opt/cs16/valve/dlls /opt/cs16/cstrike/dlls
COPY --from=builder /build/build/valve/dlls/hl.so /opt/cs16/valve/dlls/hl.so
COPY --from=builder /build/build/cstrike/dlls/cs.so /opt/cs16/cstrike/dlls/cs.so

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 27015/udp
EXPOSE 27015/tcp

ENTRYPOINT ["/entrypoint.sh"]
