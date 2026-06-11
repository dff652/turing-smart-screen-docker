# Turing Smart Screen Docker

Unofficial Docker packaging for
[`mathoudebine/turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python),
targeting FnOS/NAS hosts such as Intel N100 mini PCs with Turing/TURZX smart
screens.

This project replaces a manual FnOS deployment based on Python venv plus systemd.
The host only needs Docker and access to the USB/serial device.

## Status

Date: 2026-06-11.

- Project split target: `/home/dff652/my_project/turing-smart-screen-docker`
- Original prototype: `/home/dff652/my_project/homelab/nas/turing-smart-screen`
- Original deployment note: `/home/dff652/my_project/homelab/nas/docs/turing-smart N100.md`
- Default upstream ref: `3.10.0`
- First supported platform: `linux/amd64`
- Final Docker image has not been fully built yet.
- Local `gh` CLI is not installed, so GitHub repo creation and push are not done.

Local checks already done in the prototype:

- `docker compose config` rendered correctly.
- `python:3.10-slim-bookworm` pulled successfully.
- `docker compose build` reached apt/source stages before interruption.
- No background build process or turing container remains running.

## Why Docker

The original FnOS flow installed Python dependencies directly on the NAS, created
a virtual environment, wrote a `start_turing.sh`, then added a systemd unit. That
works, but it is fragile around absolute paths, CRLF line endings, moved venv
directories, bash paths, and `/dev/ttyACM0` permissions.

This image moves those concerns into a repeatable container build:

- dependencies are installed inside the image;
- `/config/config.yaml` is persisted outside the image;
- custom themes can be mounted under `/config/themes`;
- NAS startup is handled by Docker restart policy instead of a custom systemd
  service.

## Quick Start

For local build:

```bash
cd /home/dff652/my_project/turing-smart-screen-docker
cp .env.example .env
ls -l /dev/ttyACM* /dev/ttyUSB*
docker compose up -d --build
docker logs -f turing-smart-screen
```

For a prebuilt image after publishing:

```bash
cp .env.example .env
sed -i 's|# IMAGE=.*|IMAGE=your-dockerhub-user/turing-smart-screen:latest|' .env
docker compose up -d
```

First startup creates `./config/config.yaml`. Stop the container, edit the config,
then start it again:

```bash
docker compose stop
nano ./config/config.yaml
docker compose up -d
```

Common fields:

```yaml
config:
  COM_PORT: "/dev/ttyACM0"
  THEME: 3.5inchTheme2

display:
  REVISION: A
  BRIGHTNESS: 20
  RESET_ON_STARTUP: true
```

If `COM_PORT: "AUTO"` is unstable in Docker, set the real device path directly.

## Device Access

Most UART-based screens appear as `/dev/ttyACM0` or `/dev/ttyUSB0`.

Edit `.env` if needed:

```env
TURING_SERIAL_DEVICE=/dev/ttyUSB0
```

Debug commands:

```bash
lsusb
ls -l /dev/ttyACM* /dev/ttyUSB*
dmesg | tail -50
docker exec -it turing-smart-screen bash
ls -l /dev/ttyACM* /dev/ttyUSB* /dev/bus/usb
```

If direct TUR_USB mode cannot access USB, temporarily test with `privileged: true`
in `docker-compose.yml`, then reduce permissions after the device path is known.

## Custom Themes

Place custom themes here:

```text
./config/themes/<theme-name>/theme.yaml
```

The entrypoint links these folders into the upstream `res/themes/` directory.
Then set:

```yaml
config:
  THEME: <theme-name>
```

## Environment Size

Known measurements from the local machine:

- `python:3.10-slim-bookworm`: about 195 MB.
- BuildKit cache after partial build: about 162 MB.
- Dockerfile frontend cache from the prototype: about 43.4 MB. The standalone
  Dockerfile no longer requires the external frontend directive, so future local
  builds should avoid this extra pull.
- Runtime apt packages: about 11.5 MB download, about 62.6 MB installed.
- Builder apt packages: about 85 MB download, about 368 MB installed.
- Upstream source archive reached 14 MB before the interrupted download.
- Project files are around tens of KB.

Expected:

- final runtime image: roughly 450-750 MB;
- first build peak: reserve at least 2 GB, preferably 3 GB.

Slow downloads are usually caused by network access to Docker Hub, Debian apt,
GitHub, or PyPI. The preferred solution is GitHub Actions builds: the NAS pulls
the final image instead of compiling and downloading everything locally.

## Publishing

This repository includes `.github/workflows/docker-publish.yml`.

The workflow runs on pushes to `main`, version tags, or manual dispatch. It
builds `linux/amd64` and publishes to:

- Docker Hub: `DOCKERHUB_USERNAME/turing-smart-screen`
- GHCR: `ghcr.io/<github-owner>/turing-smart-screen`

Required GitHub repository secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

Tag strategy:

- `latest` from `main`;
- release tags such as `v0.1.0`;
- `git-<sha>`;
- `upstream-3.10.0`.

GitHub Actions can publish Docker images to Docker Hub or GitHub Packages/GHCR.
Docker Hub automation should use a personal access token rather than an account
password.

## Repository Setup

Local repo initialization:

```bash
cd /home/dff652/my_project/turing-smart-screen-docker
git init
git add .
git commit -m "Initial Docker packaging"
```

Remote setup after creating an empty GitHub repository:

```bash
git remote add origin git@github.com:<your-user>/turing-smart-screen-docker.git
git branch -M main
git push -u origin main
```

Publish a release image:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## Remaining Work

1. Build the image fully, preferably through GitHub Actions.
2. If build fails, add only the minimum missing package or library.
3. Run smoke test:

   ```bash
   docker run --rm <image> python -c "import psutil, serial, usb; print('ok')"
   ```

4. Test on the real FnOS/NAS host with the screen attached.
5. Confirm the real device path and update `.env`.
6. Tune `config/config.yaml` for screen size, revision, brightness, and theme.

## License and Attribution

This project is an unofficial Docker packaging layer. It is not affiliated with
Turing, TURZX, XuanFang, Kipye, FnOS, or the upstream maintainers.

The upstream project is GPL-3.0. This packaging repo is GPL-3.0-or-later and
keeps upstream source and license references in `NOTICE.md`.
