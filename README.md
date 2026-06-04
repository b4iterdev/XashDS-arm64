# CS1.6 XashDS ARM64 Docker Setup

This project runs a **native ARM64** Xash3D FWGS dedicated server for CS1.6.

## Requirements

- ARM64 host (or ARM64 VM)
- Docker
- Legal Counter-Strike/Half-Life assets containing:
  - `valve/`
  - `cstrike/`

## Why this setup

- Uses official XashDS ARM64 artifact (`xashds-linux-arm64.tar.gz`)
- **Native build**: Runs native ARM64 `hl_arm64.so` from `hlsdk-portable`, ARM64 `cs_arm64.so` from `rehlds/ReGameDLL_CS`, and ARM64 `metamod_arm64.so` from `FWGS/metamod-fwgs`.
- Keeps legal game assets completely outside the image — simply mount your host folders into the container.
- Dedicated mode boot (`-dedicated -game cstrike`) with configurable map/players/port.
- Metamod-FWGS is enabled by default and can be disabled with `ENABLE_METAMOD=0`.

## Quick start (GHCR)

The easiest way to run the server is to pull the pre-built image from the GitHub Container Registry.

```bash
docker run -d --name cs16-server \
  --restart unless-stopped \
  -p 27015:27015/udp -p 27015:27015/tcp \
  -e MAP=de_dust2 -e MAXPLAYERS=16 -e PORT=27015 \
  -v /absolute/path/to/your/legal/cs16:/opt/cs16 \
  ghcr.io/b4iterdev/xashds-arm64:main
```

*Note: Ensure your host directory `/absolute/path/to/your/legal/cs16` contains the `valve/` and `cstrike/` folders before running.*

## Building locally (Docker Compose)

If you prefer to build the image locally from source:

1. Copy env template and set your legal assets path:

```bash
cp .env.example .env
```

Edit `.env`:

```bash
CS16_ASSETS_PATH=/absolute/path/to/your/legal/cs16
```

2. Build and run:

```bash
docker compose up --build -d
```

3. Logs:

```bash
docker compose logs -f
```

## Metamod-FWGS

Metamod-FWGS is installed dynamically during container startup directly into your mounted `cstrike` folder:

```text
cstrike/addons/metamod/metamod_arm64.so
cstrike/addons/metamod/config.ini
cstrike/addons/metamod/plugins.ini
```

The generated `config.ini` chain-loads:

```text
dlls/cs_arm64.so
```

Set `ENABLE_METAMOD=0` to bypass Metamod and load ReGameDLL directly.

## AMX Mod X

AMX Mod X is intentionally not included. Current upstream AMX Mod X is still tied to 32-bit x86 Linux (`-m32`, `_i386` outputs, x86 NASM/JIT pieces), so it will not load into this native ARM64 Xash3D/Metamod process without a real ARM64 port.

Instead, we recommend using native Metamod plugins that have been compiled for ARM64, such as our port of MatchBot.

## GitHub Actions build (no local Docker needed)

This repository includes `.github/workflows/build-arm64.yml` that builds the ARM64 image on every push and pull request.

### GHCR publishing

- On `main` pushes, CI publishes: `ghcr.io/b4iterdev/xashds-arm64:main`
- On git tag pushes, CI publishes a matching tag image (for example, `v1.0.0`).
- Pull requests run build validation only and do not publish.

Edit `.env`:

```bash
CS16_ASSETS_PATH=/absolute/path/to/your/legal/cs16
```

2. Build and run:

```bash
docker compose up --build -d
```

3. Logs:

```bash
docker compose logs -f
```

4. Stop:

```bash
docker compose down
```

## Direct docker run

```bash
docker buildx build --platform linux/arm64 -t cs16-xashds:arm64 --load .
docker run --rm -it \
  --platform linux/arm64 \
  -p 27015:27015/udp -p 27015:27015/tcp \
  -e MAP=de_dust2 -e MAXPLAYERS=16 -e PORT=27015 \
  -e ENABLE_METAMOD=1 \
  -v /absolute/path/to/your/legal/cs16:/assets:ro \
  cs16-xashds:arm64
```

## Metamod-FWGS

Metamod-FWGS is installed into the container's writable shadow copy of your mounted `cstrike` folder:

```text
cstrike/addons/metamod/metamod_arm64.so
cstrike/addons/metamod/config.ini
cstrike/addons/metamod/plugins.ini
```

The generated `config.ini` chain-loads:

```text
dlls/cs_arm64.so
```

Set `ENABLE_METAMOD=0` to bypass Metamod and load ReGameDLL directly.

## AMX Mod X

AMX Mod X is intentionally not included. Current upstream AMX Mod X is still tied to 32-bit x86 Linux (`-m32`, `_i386` outputs, x86 NASM/JIT pieces), so it will not load into this native ARM64 Xash3D/Metamod process without a real ARM64 port.

## GitHub Actions build (no local Docker needed)

This repository includes `.github/workflows/build-arm64.yml` that builds the ARM64 image on every push and pull request.

### GHCR publishing

- On `main` pushes, CI publishes: `ghcr.io/b4iterdev/xashds-arm64:main`
- On git tag pushes, CI publishes a matching tag image (for example, `v1.0.0`).
- Pull requests run build validation only and do not publish.

Pull example:

```bash
docker pull ghcr.io/b4iterdev/xashds-arm64:main
```


Edit `.env`:

```bash
CS16_ASSETS_PATH=/absolute/path/to/your/legal/cs16
```

2. Build and run:

```bash
docker compose up --build -d
```

3. Logs:

```bash
docker compose logs -f
```

4. Stop:

```bash
docker compose down
```

## Direct docker run

```bash
docker buildx build --platform linux/arm64 -t cs16-xashds:arm64 --load .
docker run --rm -it \
  --platform linux/arm64 \
  -p 27015:27015/udp -p 27015:27015/tcp \
  -e MAP=de_dust2 -e MAXPLAYERS=16 -e PORT=27015 \
  -v /absolute/path/to/your/legal/cs16:/assets:ro \
  cs16-xashds:arm64
```

## Helper script

Build once:

```bash
docker buildx build --platform linux/arm64 -t cs16-xashds:arm64 --load .
chmod +x run.sh
```

Run:

```bash
./run.sh /absolute/path/to/your/legal/cs16
```

Show help:

```bash
./run.sh --help
```

## Notes

- If startup fails with missing game library, ensure `cstrike/dlls/cs_arm64.so` or `cstrike/dlls/cs.so` exists and matches ARM64.
- Old x86 ReHLDS/Metamod/AMXX binaries are not native ARM64 and should not be expected to work unchanged.
- Default `server.cfg` is provided and copied to `cstrike/server.cfg` if missing.

## GitHub Actions build (no local Docker needed)

This repository includes `.github/workflows/build-arm64.yml` that builds the ARM64 image on every push and pull request.

To use it:

1. Create a GitHub repository.
2. Push this project.
3. Open the **Actions** tab and watch the `Build ARM64 XashDS image` workflow.

This CI job validates the Docker build; it does not run the game server because legal `valve/` and `cstrike/` assets are not part of the repository.

### GHCR publishing

- On `main` pushes, CI publishes: `ghcr.io/b4iterdev/xashds-arm64:main`
- On git tag pushes, CI publishes a matching tag image (for example, `v1.0.0`).
- Pull requests run build validation only and do not publish.

Pull example:

```bash
docker pull ghcr.io/b4iterdev/xashds-arm64:main
```
