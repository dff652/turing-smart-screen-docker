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

## Verified on hardware (2026-06-12, Turing 3.5" rev A)

Validated on FnOS `zbox-ci331` (Intel N100) with a Turing 3.5" screen. Result:
**works out of the box for this screen, with no `config.yaml` edits.**

Use this "pull image" compose (drops `build:`, pins the published `image`). After
`docker compose up -d` the screen lights up within seconds and shows live sensors:

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
      - /dev/ttyACM0:/dev/ttyACM0
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

**Why no config edit is needed:**

1. **`COM_PORT: AUTO` auto-detects here.** This compose mounts `/sys:ro` +
   `/run/udev:ro` + `/dev/bus/usb`, so pyserial inside the container can read the
   screen's USB `serial_number` (`USB35INCHIPSV2` for the Turing 3.5"), and the
   rev-A auto-detect matches it to `/dev/ttyACM0`. Passing only the bare device
   node (as some third-party images do) lacks this `/sys` metadata and makes AUTO
   fail — mounting `/sys` is the key design choice here.
2. **Upstream defaults already match:** `config.yaml.dist` defaults to
   `REVISION: A` + `THEME: 3.5inchTheme2`, exactly right for a Turing 3.5" (rev A).
3. The only empty default is `ETH: ""`, which only affects the network-speed
   widget. Set it to the host NIC name (e.g. `enp2s0` on this FnOS box) if you want
   network stats.

**Hardware rule (image-independent):** the screen must be on a USB port that
carries **data**. A power-only USB-C port lit the screen but never enumerated the
serial device (no `/dev/ttyACM*`); a motherboard **USB-A** port loaded `cdc_acm`
and created `/dev/ttyACM0`.

> For other models / unstable AUTO, still pin `COM_PORT` and set `REVISION`/`THEME`
> per the section below.

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
