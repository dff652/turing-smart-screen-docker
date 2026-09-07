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
  RESET_ON_STARTUP: false
```

For a Turing 3.5" rev-A screen, pin the in-container port to `/dev/ttyACM0` and
disable startup reset to avoid USB re-enumeration changing the device node.

## Verified on hardware (2026-06-12 and 2026-09-07, Turing 3.5" rev A)

Validated on FnOS `zbox-ci331` (Intel N100) with a Turing 3.5" screen. The host
device was `/dev/ttyACM0` during the first deployment. On 2026-09-07 it
re-enumerated as `/dev/ttyACM1`, and the old compose failed before container
startup because `/dev/ttyACM0` no longer existed.

This screen has a stable host path,
`/dev/serial/by-id/usb-Turing_UsbMonitor_USB35INCHIPSV2-if00`. This "pull image"
compose maps that path to a fixed `/dev/ttyACM0` inside the container:

```yaml
services:
  turing-smart-screen:
    image: dff652/turing-smart-screen:latest
    container_name: turing-smart-screen
    restart: unless-stopped
    network_mode: host
    environment:
      TZ: Asia/Shanghai
    devices:
      - /dev/serial/by-id/usb-Turing_UsbMonitor_USB35INCHIPSV2-if00:/dev/ttyACM0
    device_cgroup_rules:
      - "c 166:* rmw"   # ttyACM*
      - "c 188:* rmw"   # ttyUSB*
      - "c 189:* rmw"   # USB bus (TUR_USB)
    cap_add:
      - NET_RAW
    volumes:
      - ./config:/config
      - /dev/bus/usb:/dev/bus/usb
      - /sys:/sys:ro
      - /run/udev:/run/udev:ro
```

Pin `./config/config.yaml` accordingly:

```yaml
config:
  COM_PORT: "/dev/ttyACM0"
display:
  RESET_ON_STARTUP: false
```

**Why this is stable:**

1. The host-side `by-id` path is based on the USB serial number and survives
   changes between `ttyACM0` and `ttyACM1`.
2. The container always uses `/dev/ttyACM0`, matching `COM_PORT`. Disabling
   `RESET_ON_STARTUP` prevents a rev-A startup reset from triggering another
   re-enumeration.
3. The `/sys:ro`, `/run/udev:ro`, and `/dev/bus/usb` mounts remain available for
   pyserial metadata and other USB modes.
4. `REVISION: A` + `THEME: 3.5inchTheme2` match this screen. Set `ETH: "enp2s0"`
   to enable the network-speed widget on this FnOS host.

**Hardware rule (image-independent):** the screen must be on a USB port that
carries **data**. A power-only USB-C port lit the screen but never enumerated the
serial device (no `/dev/ttyACM*`); a motherboard **USB-A** port loaded `cdc_acm`
and created a serial device.

> For other models / unstable AUTO, still pin `COM_PORT` and set `REVISION`/`THEME`
> per the section below.

## Device Access

Most UART-based screens appear as `/dev/ttyACM0` or `/dev/ttyUSB0`.

Prefer a stable device path when one is available:

```bash
ls -l /dev/serial/by-id/
```

For `by-id`, set distinct host and container paths in compose, for example
`/dev/serial/by-id/<device-id>:/dev/ttyACM0`, and set `COM_PORT` to the
in-container `/dev/ttyACM0`. The default `TURING_SERIAL_DEVICE` uses the same
path on both sides and is intended for direct `/dev/ttyACM*` or `/dev/ttyUSB*`
paths.

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
