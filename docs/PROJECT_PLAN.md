# Project Plan

Languages: [English](PROJECT_PLAN.md) | [简体中文](PROJECT_PLAN.zh-CN.md)

## Background

The original FnOS deployment note used a manual Python virtual environment and a
systemd service:

1. Install Python venv dependencies on the NAS.
2. Clone or place `turing-smart-screen-python` under an absolute path.
3. Install `requirements.txt` in a venv.
4. Create `start_turing.sh`.
5. Create and enable a `turing-screen.service` systemd unit.
6. Fix common issues such as CRLF line endings, wrong shebang paths, moved venvs,
   and `/dev/ttyACM0` permission errors.

The Docker packaging replaces venv and systemd with a container runtime. The host
only needs Docker and USB/serial device access.

## Design

- The upstream source is fetched during the image build.
- Python dependencies are installed into a virtual environment inside the image.
- `/config/config.yaml` is persisted outside the image.
- Custom themes can be mounted under `/config/themes`.
- NAS startup is handled by Docker restart policy instead of a custom systemd
  service.

Default build settings:

- Upstream ref: `3.10.0`
- Initial platform: `linux/amd64`
- Runtime base image: `python:3.10-slim-bookworm`

Start with `linux/amd64`, matching Intel N100/FnOS. Add `linux/arm64` only after
the amd64 image is proven on the target host.

## Environment and Size Notes

Known local measurements from early build testing:

- `python:3.10-slim-bookworm`: about 195 MB after pull.
- BuildKit cache after partial build: about 162 MB.
- Runtime apt packages: about 11.5 MB download, about 62.6 MB installed.
- Builder apt packages: about 85 MB download, about 368 MB installed in build
  layers.

Expected space requirement:

- Final runtime image: roughly 450-750 MB.
- First build peak: reserve at least 2 GB, preferably 3 GB.

Slow downloads are expected on networks with poor access to Docker Hub, Debian
mirrors, GitHub, or PyPI. GitHub Actions is preferred for image builds so the NAS
only pulls the final image.

## Publishing Strategy

Use GitHub Actions to build and publish images. The workflow publishes on
`main`, version tags, or manual dispatch.

Registries:

- Docker Hub: `dff652/turing-smart-screen`
- GHCR: `ghcr.io/<github-owner>/turing-smart-screen`

Required GitHub repository secret:

- `DOCKERHUB_TOKEN`

Tag policy:

- `latest` for the default branch.
- Git tag versions such as `v0.1.0`.
- `git-<sha>` for traceability.
- `upstream-3.10.0` for upstream source traceability.

Docker Hub automation should use a personal access token rather than an account
password. The Docker Hub namespace is configured in the workflow as `dff652`.

## Validation

After a published image is available, run the import smoke test:

```bash
docker run --rm --entrypoint python dff652/turing-smart-screen:latest -c "import psutil, serial, usb; print('ok')"
```

Then test on the real FnOS/NAS host with the screen attached:

```bash
cp .env.example .env
sed -i 's|# IMAGE=.*|IMAGE=dff652/turing-smart-screen:latest|' .env
docker compose up -d
docker logs -f turing-smart-screen
```

See [ROADMAP.md](ROADMAP.md) for the current work checklist.
