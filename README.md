# Turing Smart Screen Docker

Languages: [English](README.md) | [简体中文](README.zh-CN.md)

Unofficial Docker packaging for
[`mathoudebine/turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python),
targeting FnOS/NAS hosts such as Intel N100 mini PCs with Turing/TURZX smart
screens.

This project replaces a manual FnOS deployment based on Python venv plus systemd.
The host only needs Docker and access to the USB/serial device.

## Quick Start

For local build:

```bash
cp .env.example .env
ls -l /dev/ttyACM* /dev/ttyUSB*
docker compose up -d --build
docker logs -f turing-smart-screen
```

For a published image:

```bash
cp .env.example .env
sed -i 's|# IMAGE=.*|IMAGE=dff652/turing-smart-screen:latest|' .env
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

## Image Publishing

This repository includes `.github/workflows/docker-publish.yml`.

The workflow builds `linux/amd64` and publishes to:

- Docker Hub: `dff652/turing-smart-screen`
- GHCR: `ghcr.io/<github-owner>/turing-smart-screen`

Required GitHub repository secret:

```text
DOCKERHUB_TOKEN
```

Docker Hub automation should use a personal access token rather than an account
password. The Docker Hub namespace is configured in the workflow as `dff652`.

## Documentation

- [Project plan](docs/PROJECT_PLAN.md)
- [Roadmap and validation checklist](docs/ROADMAP.md)
- [Attribution and notices](NOTICE.md)

## License and Attribution

This project is an unofficial Docker packaging layer. It is not affiliated with
Turing, TURZX, XuanFang, Kipye, FnOS, or the upstream maintainers.

The upstream project is GPL-3.0. This packaging repo is GPL-3.0-or-later and
keeps upstream source and license references in `NOTICE.md`.
