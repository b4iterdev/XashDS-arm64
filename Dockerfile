FROM ubuntu:24.04 AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git cmake g++ make ninja-build clang python3 libfontconfig-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build/hlsdk-portable
RUN git clone --recursive https://github.com/FWGS/hlsdk-portable.git .

RUN cmake -DCMAKE_BUILD_TYPE=Release -D64BIT=ON -B build_hl -S . \
    && cmake --build build_hl

WORKDIR /build/ReGameDLL_CS
# Use Velaron/ReGameDLL_CS at commit d1af1363 — this fork already contains both ARM64 fixes:
#   1. FORCE_STACK_ALIGN guarded to x86 only (osconfig.h)
#   2. DebuggerBreak() uses raise(SIGTRAP) instead of "int3;" (platform.h)
RUN git clone https://github.com/Velaron/ReGameDLL_CS.git . \
    && git checkout d1af1363e1aa91553ee5773217070208bf1e941f \
    && git submodule update --init --recursive
RUN cmake -S . -B build_cs -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DXASH_COMPAT=ON \
    && cmake --build build_cs

WORKDIR /build/metamod-fwgs
RUN git clone --recursive https://github.com/FWGS/metamod-fwgs.git .
RUN cmake -S . -B build_metamod -G Ninja -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build_metamod \
    && cmake --install build_metamod --prefix /build/metamod-install

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
COPY --from=builder /build/ReGameDLL_CS/build_cs/regamedll/cs_arm64.so /opt/cs16/native_dlls/cs_arm64.so
COPY --from=builder /build/metamod-install/metamod_arm64.so /opt/cs16/native_dlls/metamod_arm64.so

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 27015/udp
EXPOSE 27015/tcp

ENTRYPOINT ["/entrypoint.sh"]
