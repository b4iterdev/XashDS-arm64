# CS1.6 XashDS ARM64 Docker Setup

Native ARM64 Xash3D FWGS dedicated server for Counter-Strike 1.6.

## Requirements

- ARM64 host or ARM64 VM
- Docker or Podman
- Legal Counter-Strike/Half-Life files in one directory containing:
  - `valve/`
  - `cstrike/`

## Quick start with GHCR

Pull and run the prebuilt image from GitHub Container Registry:

```bash
podman run --rm -it \
  -p 27015:27015/udp -p 27015:27015/tcp \
  -e MAP=de_dust2 -e MAXPLAYERS=16 -e PORT=27015 \
  -v ./xash3d/xash:/opt/cs16 \
  ghcr.io/b4iterdev/xashds-arm64:main
```

Docker works the same way:

```bash
docker run --rm -it \
  --platform linux/arm64 \
  -p 27015:27015/udp -p 27015:27015/tcp \
  -e MAP=de_dust2 -e MAXPLAYERS=16 -e PORT=27015 \
  -v /absolute/path/to/your/legal/cs16:/opt/cs16 \
  ghcr.io/b4iterdev/xashds-arm64:main
```

The mounted directory must be writable. On startup, the container copies the ARM64 XashDS runtime and native libraries into the mounted `/opt/cs16` layout when they are missing.

## Expected host layout

```text
./xash3d/xash/
├── valve/
└── cstrike/
```

The container will add the generated native files, including:

```text
valve/dlls/hl_arm64.so
cstrike/dlls/cs_arm64.so
cstrike/addons/metamod/metamod_arm64.so
cstrike/addons/metamod/config.ini
```

## Docker Compose

```bash
cp .env.example .env
```

Set your legal assets path:

```bash
CS16_ASSETS_PATH=/absolute/path/to/your/legal/cs16
```

Build and run locally:

```bash
docker compose up --build -d
```

Logs:

```bash
docker compose logs -f
```

Stop:

```bash
docker compose down
```

## Metamod-FWGS

Metamod-FWGS is enabled by default. The container installs native ARM64 Metamod-FWGS into:

```text
cstrike/addons/metamod/metamod_arm64.so
```

The generated Metamod config chain-loads:

```text
dlls/cs_arm64.so
```

Disable Metamod with:

```bash
-e ENABLE_METAMOD=0
```

## AMX Mod X

AMX Mod X is intentionally not included. Current upstream AMX Mod X is tied to 32-bit x86 Linux (`-m32`, `_i386` outputs, x86 NASM/JIT pieces), so it will not load into this native ARM64 Xash3D/Metamod process without a real ARM64 port.

## Building

Build locally:

```bash
docker buildx build --platform linux/arm64 -t cs16-xashds:arm64 --load .
```

Run the local image:

```bash
docker run --rm -it \
  --platform linux/arm64 \
  -p 27015:27015/udp -p 27015:27015/tcp \
  -e MAP=de_dust2 -e MAXPLAYERS=16 -e PORT=27015 \
  -v /absolute/path/to/your/legal/cs16:/opt/cs16 \
  cs16-xashds:arm64
```

## GitHub Actions / GHCR

This repository includes `.github/workflows/build-arm64.yml`.

- Pushes to `main` publish: `ghcr.io/b4iterdev/xashds-arm64:main`
- Tags publish matching tag images, for example `v1.0.0`
- Pull requests run build validation only
