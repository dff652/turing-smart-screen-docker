# Turing Smart Screen Docker

语言：[English](README.md) | [简体中文](README.zh-CN.md)

这是
[`mathoudebine/turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python)
的非官方 Docker 打包项目，目标环境是 FnOS/NAS 主机，例如 Intel N100 小主机，以及
Turing/TURZX 智能副屏。

本项目用于替代原先基于 Python venv 和 systemd 的 FnOS 手工部署方式。宿主机只需要
Docker，并能访问 USB/串口设备。

## 状态

日期：2026-06-11。

- 项目拆分目标路径：`/home/dff652/my_project/turing-smart-screen-docker`
- 原型项目路径：`/home/dff652/my_project/homelab/nas/turing-smart-screen`
- 原始部署笔记：`/home/dff652/my_project/homelab/nas/docs/turing-smart N100.md`
- 默认上游版本：`3.10.0`
- 首个支持平台：`linux/amd64`
- 最终 Docker 镜像还没有完整构建完成。
- GitHub remote 已配置，并且 `main` 已推送：
  `git@github.com:dff652/turing-smart-screen-docker.git`
- 当前环境没有安装本地 `gh` CLI，但初始 remote 设置已经不再需要它。

原型目录中已经完成的本地检查：

- `docker compose config` 可以正确渲染。
- `python:3.10-slim-bookworm` 已成功拉取。
- `docker compose build` 在中断前已经进入 apt/source 阶段。
- 没有残留后台 build 进程或运行中的 turing 容器。

## 为什么使用 Docker

原先的 FnOS 流程会直接在 NAS 上安装 Python 依赖、创建虚拟环境、编写
`start_turing.sh`，然后添加 systemd unit。这个方式可用，但容易受绝对路径、
CRLF 换行、venv 目录移动、bash 路径和 `/dev/ttyACM0` 权限等问题影响。

这个镜像把这些问题移入可重复的容器构建中：

- 依赖安装在镜像内部；
- `/config/config.yaml` 持久化在镜像外部；
- 自定义主题可以挂载到 `/config/themes`；
- NAS 开机启动交给 Docker restart policy，而不是自定义 systemd 服务。

## 快速开始

本地构建：

```bash
cd /home/dff652/my_project/turing-smart-screen-docker
cp .env.example .env
ls -l /dev/ttyACM* /dev/ttyUSB*
docker compose up -d --build
docker logs -f turing-smart-screen
```

镜像发布后，使用预构建镜像：

```bash
cp .env.example .env
sed -i 's|# IMAGE=.*|IMAGE=your-dockerhub-user/turing-smart-screen:latest|' .env
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

## 环境体积

本机已知测量值：

- `python:3.10-slim-bookworm`：约 195 MB。
- 部分构建后的 BuildKit 缓存：约 162 MB。
- 原型中的 Dockerfile frontend 缓存：约 43.4 MB。独立 Dockerfile 已不再需要外部
  frontend directive，所以后续本地构建应避免这次额外拉取。
- 运行时 apt 包：下载约 11.5 MB，安装后约 62.6 MB。
- 构建阶段 apt 包：下载约 85 MB，安装后约 368 MB。
- 上游源码压缩包在中断前已下载到 14 MB。
- 项目文件只有几十 KB。

预期：

- 最终运行镜像：约 450-750 MB；
- 首次构建峰值：至少预留 2 GB，建议 3 GB。

下载慢通常是因为访问 Docker Hub、Debian apt、GitHub 或 PyPI 较慢。推荐用
GitHub Actions 构建镜像：NAS 只需要拉取最终镜像，不需要在本地编译和下载所有依赖。

## 发布

仓库包含 `.github/workflows/docker-publish.yml`。

workflow 会在推送到 `main`、推送版本 tag 或手动触发时运行。它构建
`linux/amd64` 并发布到：

- Docker Hub：`DOCKERHUB_USERNAME/turing-smart-screen`
- GHCR：`ghcr.io/<github-owner>/turing-smart-screen`

需要配置的 GitHub repository secrets：

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

tag 策略：

- `main` 分支生成 `latest`；
- 版本 tag，例如 `v0.1.0`；
- `git-<sha>`；
- `upstream-3.10.0`。

GitHub Actions 可以把 Docker 镜像发布到 Docker Hub 或 GitHub Packages/GHCR。
Docker Hub 自动化发布应使用 personal access token，而不是账户密码。

## GitHub Secrets 配置

下一步需要在 GitHub 仓库中添加两个 secrets：

1. 打开仓库 `dff652/turing-smart-screen-docker`。
2. 进入 `Settings` -> `Secrets and variables` -> `Actions`。
3. 点击 `New repository secret`。
4. 添加 `DOCKERHUB_USERNAME`，值为 Docker Hub 用户名。
5. 添加 `DOCKERHUB_TOKEN`，值为 Docker Hub personal access token。

Docker Hub token 建议在 Docker Hub 的 `Account Settings` -> `Personal access tokens`
中创建，权限至少需要能推送镜像。

配置完成后，到 GitHub 仓库的 `Actions` 页面检查首次构建。如果之前因为缺少 secrets
失败，可以重新运行失败的 workflow，或者推送一个小提交触发新构建。

构建成功后运行导入 smoke test：

```bash
docker run --rm <image> python -c "import psutil, serial, usb; print('ok')"
```

## 仓库设置

当前 remote：

```bash
git remote -v
# origin  git@github.com:dff652/turing-smart-screen-docker.git (fetch)
# origin  git@github.com:dff652/turing-smart-screen-docker.git (push)
```

当前已推送 commit：

```text
7c61e0e Initial Docker packaging
```

本地仓库初始化：

```bash
cd /home/dff652/my_project/turing-smart-screen-docker
git init
git add .
git commit -m "Initial Docker packaging"
```

创建空 GitHub 仓库后的 remote 设置：

```bash
git remote add origin git@github.com:<your-user>/turing-smart-screen-docker.git
git branch -M main
git push -u origin main
```

发布版本镜像：

```bash
git tag v0.1.0
git push origin v0.1.0
```

## 新会话继续点

可用下面内容作为新会话起始提示：

```text
Continue the Turing Smart Screen Docker packaging project in:
/home/dff652/my_project/turing-smart-screen-docker

Current state:
- GitHub remote is git@github.com:dff652/turing-smart-screen-docker.git.
- main has been pushed; current commit is 7c61e0e Initial Docker packaging.
- GitHub Actions workflow exists at .github/workflows/docker-publish.yml.
- Default upstream ref is 3.10.0.
- Build target is linux/amd64 first.
- Final Docker image has not been fully built yet.
- Docker Hub/GHCR publishing is planned.
- Required GitHub secrets still need to be configured:
  DOCKERHUB_USERNAME and DOCKERHUB_TOKEN.

Next tasks:
1. Check the GitHub Actions run after the push.
2. Add or verify GitHub repo secrets for Docker Hub publishing.
3. If Actions fails, inspect logs and patch only the minimum missing dependency or workflow issue.
4. After image build succeeds, run the import smoke test:
   docker run --rm <image> python -c "import psutil, serial, usb; print('ok')"
5. Create and push tag v0.1.0 after the image is verified.
6. Then test the published image on FnOS/NAS with the actual screen attached.
```

## 剩余工作

1. 完整构建镜像，优先通过 GitHub Actions。
2. 如果构建失败，只补充最小必要的缺失包或库。
3. 运行 smoke test：

   ```bash
   docker run --rm <image> python -c "import psutil, serial, usb; print('ok')"
   ```
