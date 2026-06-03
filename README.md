# CS1.6 XashDS ARM64 Docker Setup

This project runs a **native ARM64** Xash3D FWGS dedicated server for CS1.6.

## Requirements

- Docker with Buildx support
- ARM64 host (or ARM64 VM)
- Legal Counter-Strike/Half-Life assets containing:
  - `valve/`
  - `cstrike/`
- ARM64-compatible CS game library in `cstrike/dlls/`:
  - preferred: `cs_arm64.so`
  - fallback: `cs.so`

## Why this setup

- Uses official XashDS ARM64 artifact (`xashds-linux-arm64.tar.gz`)
- Tries `continuous` release first and falls back to `continuous-gha-arm` for resiliency
- Keeps legal game assets outside the image and mounts them read-only
- Dedicated mode boot (`-dedicated -game cstrike`) with configurable map/players/port

`Velaron/cs16-client` is useful here as confirmation of asset layout and legal-copy expectation (`valve` + `cstrike`), but it is not a server Docker baseline itself.

## Quick start (Docker Compose)

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
