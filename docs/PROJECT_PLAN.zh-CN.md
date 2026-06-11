# 项目计划

语言：[English](PROJECT_PLAN.md) | [简体中文](PROJECT_PLAN.zh-CN.md)

## 背景

原先的 FnOS 部署笔记使用手工 Python 虚拟环境和 systemd 服务：

1. 在 NAS 上安装 Python venv 依赖。
2. 把 `turing-smart-screen-python` 克隆或放置到一个绝对路径下。
3. 在 venv 中安装 `requirements.txt`。
4. 创建 `start_turing.sh`。
5. 创建并启用 `turing-screen.service` systemd unit。
6. 修复常见问题，例如 CRLF 换行、错误 shebang 路径、venv 移动和
   `/dev/ttyACM0` 权限错误。

Docker 打包方案用容器运行时替代 venv 和 systemd。宿主机只需要 Docker，并能访问
USB/串口设备。

## 设计

- 构建镜像时拉取上游源码。
- Python 依赖安装到镜像内部的虚拟环境。
- `/config/config.yaml` 持久化在镜像外部。
- 自定义主题可以挂载到 `/config/themes`。
- NAS 开机启动交给 Docker restart policy，而不是自定义 systemd 服务。

默认构建设置：

- 上游版本：`3.10.0`
- 初始平台：`linux/amd64`
- 运行时基础镜像：`python:3.10-slim-bookworm`

先支持 `linux/amd64`，匹配 Intel N100/FnOS。等 amd64 镜像在目标主机验证后，再添加
`linux/arm64`。

## 环境和体积说明

早期构建测试中的已知本地测量值：

- `python:3.10-slim-bookworm`：拉取后约 195 MB。
- 部分构建后的 BuildKit 缓存：约 162 MB。
- 运行时 apt 包：下载约 11.5 MB，安装后约 62.6 MB。
- 构建阶段 apt 包：下载约 85 MB，安装到构建层后约 368 MB。

预期空间需求：

- 最终运行镜像：约 450-750 MB。
- 首次构建峰值：至少预留 2 GB，建议 3 GB。

如果网络访问 Docker Hub、Debian mirrors、GitHub 或 PyPI 较慢，下载慢是预期现象。
推荐用 GitHub Actions 构建镜像，让 NAS 只拉取最终镜像。

## 发布策略

使用 GitHub Actions 构建并发布镜像。workflow 会在 `main`、版本 tag 或手动触发时发布。

镜像仓库：

- Docker Hub：`dff652/turing-smart-screen`
- GHCR：`ghcr.io/<github-owner>/turing-smart-screen`

必需的 GitHub repository secret：

- `DOCKERHUB_TOKEN`

tag 策略：

- 默认分支生成 `latest`。
- Git tag 版本，例如 `v0.1.0`。
- `git-<sha>` 用于追踪构建来源。
- `upstream-3.10.0` 用于追踪上游源码版本。

Docker Hub 自动化发布应使用 personal access token，而不是账户密码。Docker Hub
namespace 已在 workflow 中配置为 `dff652`。

## 验证

镜像发布后，运行导入 smoke test：

```bash
docker run --rm --entrypoint python dff652/turing-smart-screen:latest -c "import psutil, serial, usb; print('ok')"
```

然后在真实 FnOS/NAS 主机和实际屏幕上测试：

```bash
cp .env.example .env
sed -i 's|# IMAGE=.*|IMAGE=dff652/turing-smart-screen:latest|' .env
docker compose up -d
docker logs -f turing-smart-screen
```

当前工作清单见 [ROADMAP.zh-CN.md](ROADMAP.zh-CN.md)。
