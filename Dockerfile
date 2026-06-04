FROM ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git cmake g++ make python3 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build/hlsdk-portable
RUN git clone --recursive https://github.com/FWGS/hlsdk-portable.git .

RUN cmake -DCMAKE_BUILD_TYPE=Release -D64BIT=ON -B build_hl -S . \
    && cmake --build build_hl

WORKDIR /build/cs16-client
RUN git clone --recursive https://github.com/Velaron/cs16-client.git .
RUN cmake -DCMAKE_BUILD_TYPE=Release -B build_cs -S . \
    && cmake --build build_cs --target regamedll

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
    tar -xzf /tmp/xashds.tar.gz -C /opt/cs16 --strip-components=1; \
    rm /tmp/xashds.tar.gz

RUN mkdir -p /opt/cs16/native_dlls
COPY --from=builder /build/hlsdk-portable/build_hl/dlls/hl_arm64.so /opt/cs16/native_dlls/hl_arm64.so
COPY --from=builder /build/cs16-client/build_cs/3rdparty/ReGameDLL_CS/regamedll/cs_arm64.so /opt/cs16/native_dlls/cs_arm64.so

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 27015/udp
EXPOSE 27015/tcp

ENTRYPOINT ["/entrypoint.sh"]
