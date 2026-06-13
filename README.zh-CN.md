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
  RESET_ON_STARTUP: true
```

如果 Docker 内部的 `COM_PORT: "AUTO"` 不稳定，请直接设置真实设备路径。

## 真机验证（2026-06-12，Turing 3.5" rev A）

已在 FnOS `zbox-ci331`（Intel N100）+ Turing 3.5" 副屏上跑通，结论：**对这块屏开箱即用，无需修改 `config.yaml`。**

直接用下面这份"拉镜像版" compose（去掉 `build:`，`image` 写死已发布镜像），`docker compose up -d` 后屏幕几秒内点亮、正常刷硬件信息：

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

**为什么不用改 config：**

1. **`COM_PORT: AUTO` 能自动认到**。本 compose 挂了 `/sys:ro` + `/run/udev:ro` + `/dev/bus/usb`，容器内 pyserial 能读到屏的 USB `serial_number`（Turing 3.5" 为 `USB35INCHIPSV2`），rev A 的 auto-detect 一匹配就找到了 `/dev/ttyACM0`。**只透传裸设备节点（如某些第三方镜像）会缺 `/sys` 元数据导致 AUTO 失败**——挂载 `/sys` 是本项目的关键设计。
2. **上游默认值正好匹配**：`config.yaml.dist` 默认 `REVISION: A` + `THEME: 3.5inchTheme2`，正是 Turing 3.5"（rev A）的正解，无需改。
3. 唯一默认空着的是 `ETH: ""`，只影响**网速组件**（其余 CPU/内存/温度/磁盘照常）。需要网速就把它设成本机网卡名（实测飞牛是 `enp2s0`）。

**硬件铁律（与镜像无关）**：屏必须接**能传数据的 USB 口**。实测某个 USB-C 口只供电、不枚举串口（`/dev/ttyACM*` 不出现）；换到主板 **USB-A** 数据口后 `cdc_acm` 自动加载、`/dev/ttyACM0` 才出现。

> 其他型号 / AUTO 不稳时，仍按下文「设备访问」写死 `COM_PORT`，并按屏改 `REVISION`、`THEME`。

## 设备访问

大多数 UART 屏幕会显示为 `/dev/ttyACM0` 或 `/dev/ttyUSB0`。

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
