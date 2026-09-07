# Turing Smart Screen Docker

语言：[English](README.md) | [简体中文](README.zh-CN.md)

这是
[`mathoudebine/turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python)
的非官方 Docker 打包项目，目标环境是 FnOS/NAS 主机，例如 Intel N100 小主机，以及
Turing/TURZX 智能副屏。

本项目用于替代原先基于 Python venv 和 systemd 的 FnOS 手工部署方式。宿主机只需要
Docker，并能访问 USB/串口设备。

## 快速开始

本地构建：

```bash
cp .env.example .env
ls -l /dev/ttyACM* /dev/ttyUSB*
docker compose up -d --build
docker logs -f turing-smart-screen
```

使用已发布镜像：

```bash
cp .env.example .env
sed -i 's|# IMAGE=.*|IMAGE=dff652/turing-smart-screen:latest|' .env
docker compose up -d
```

首次启动会创建 `./config/config.yaml`。停止容器，编辑配置，然后重新启动：

```bash
docker compose stop
nano ./config/config.yaml
docker compose up -d
```

常用字段：

```yaml
config:
  COM_PORT: "/dev/ttyACM0"
  THEME: 3.5inchTheme2

display:
  REVISION: A
  BRIGHTNESS: 20
  RESET_ON_STARTUP: false
```

对于 Turing 3.5" rev A，建议把容器内串口固定为 `/dev/ttyACM0`，并关闭启动复位，
避免复位后 USB 重新枚举造成串口编号变化。

## 真机验证（2026-06-12、2026-09-07，Turing 3.5" rev A）

已在 FnOS `zbox-ci331`（Intel N100）+ Turing 3.5" 副屏上跑通。首次部署时宿主设备为
`/dev/ttyACM0`；2026-09-07 设备重新枚举为 `/dev/ttyACM1`，旧 compose 因仍引用
`/dev/ttyACM0` 而在创建容器时报 `no such file or directory`。

这块屏的稳定宿主路径为
`/dev/serial/by-id/usb-Turing_UsbMonitor_USB35INCHIPSV2-if00`。下面的"拉镜像版"
compose 把该路径映射到容器内固定的 `/dev/ttyACM0`：

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

同时把 `./config/config.yaml` 固定为：

```yaml
config:
  COM_PORT: "/dev/ttyACM0"
display:
  RESET_ON_STARTUP: false
```

**为什么这样更稳定：**

1. 宿主机用 USB 序列号生成的 `by-id` 路径，不受 `ttyACM0`、`ttyACM1` 编号变化影响。
2. 容器内始终使用 `/dev/ttyACM0`，与 `COM_PORT` 保持一致；关闭 `RESET_ON_STARTUP`
   可避免 rev A 启动复位触发重新枚举。
3. `/sys:ro`、`/run/udev:ro` 和 `/dev/bus/usb` 挂载仍保留，供 pyserial 和其他
   USB 模式读取设备元数据。
4. `REVISION: A` + `THEME: 3.5inchTheme2` 适配这块屏；`ETH: "enp2s0"` 可启用
   FnOS 主机的网速组件。

**硬件铁律（与镜像无关）**：屏必须接**能传数据的 USB 口**。实测某个 USB-C 口只供电、不枚举串口（`/dev/ttyACM*` 不出现）；换到主板 **USB-A** 数据口后 `cdc_acm` 自动加载并创建串口设备。

> 其他型号 / AUTO 不稳时，仍按下文「设备访问」写死 `COM_PORT`，并按屏改 `REVISION`、`THEME`。

## 设备访问

大多数 UART 屏幕会显示为 `/dev/ttyACM0` 或 `/dev/ttyUSB0`。

优先检查是否存在稳定路径：

```bash
ls -l /dev/serial/by-id/
```

如果使用 `by-id`，compose 的宿主路径和容器路径应分别填写，例如
`/dev/serial/by-id/<设备ID>:/dev/ttyACM0`，并让 `COM_PORT` 指向容器内的
`/dev/ttyACM0`。项目默认的 `TURING_SERIAL_DEVICE` 会把同一路径同时用于两侧，
适合直接使用 `/dev/ttyACM*` 或 `/dev/ttyUSB*` 的场景。

必要时编辑 `.env`：

```env
TURING_SERIAL_DEVICE=/dev/ttyUSB0
```

调试命令：

```bash
lsusb
ls -l /dev/ttyACM* /dev/ttyUSB*
dmesg | tail -50
docker exec -it turing-smart-screen bash
ls -l /dev/ttyACM* /dev/ttyUSB* /dev/bus/usb
```

如果直连 TUR_USB 模式无法访问 USB，可以临时在 `docker-compose.yml` 中测试
`privileged: true`，确认设备路径后再收紧权限。

## 自定义主题

把自定义主题放到这里：

```text
./config/themes/<theme-name>/theme.yaml
```

entrypoint 会把这些目录链接到上游的 `res/themes/` 目录。然后设置：

```yaml
config:
  THEME: <theme-name>
```

## 镜像发布

仓库包含 `.github/workflows/docker-publish.yml`。

workflow 会构建 `linux/amd64` 并发布到：

- Docker Hub：`dff652/turing-smart-screen`
- GHCR：`ghcr.io/<github-owner>/turing-smart-screen`

需要配置的 GitHub repository secret：

```text
DOCKERHUB_TOKEN
```

Docker Hub 自动化发布应使用 personal access token，而不是账户密码。Docker Hub
namespace 已在 workflow 中配置为 `dff652`。

## 文档

- [项目计划](docs/PROJECT_PLAN.zh-CN.md)
- [路线图和验证清单](docs/ROADMAP.zh-CN.md)
- [归属和声明](NOTICE.md)

## 许可证和归属

本项目是非官方 Docker 打包层，和 Turing、TURZX、XuanFang、Kipye、FnOS 或上游维护者
没有隶属关系。

上游项目使用 GPL-3.0。本打包仓库使用 GPL-3.0-or-later，并在 `NOTICE.md` 中保留上游
源码和许可证引用。
