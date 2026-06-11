# 路线图

语言：[English](ROADMAP.md) | [简体中文](ROADMAP.zh-CN.md)

## 当前重点

1. 修复或确认 Docker Hub repository secret：

   ```text
   DOCKERHUB_TOKEN=<Docker Hub personal access token>
   ```

2. 重新运行 `Build and publish Docker image` GitHub Actions workflow。
3. 确认 workflow 能登录 Docker Hub，构建 `linux/amd64`，并推送镜像。
4. 对已发布镜像运行导入 smoke test：

   ```bash
   docker run --rm --entrypoint python dff652/turing-smart-screen:latest -c "import psutil, serial, usb; print('ok')"
   ```

5. 在真实 FnOS/NAS 主机和实际屏幕上测试。

## 验证清单

- GitHub Actions 成功完成。
- Docker Hub 包含 `dff652/turing-smart-screen:latest`。
- GHCR 包含 `ghcr.io/<github-owner>/turing-smart-screen:latest`。
- 导入 smoke test 输出 `ok`。
- 容器能看到真实屏幕设备，例如 `/dev/ttyACM0` 或 `/dev/ttyUSB0`。
- `config/config.yaml` 已针对实际屏幕型号、revision、亮度和主题调整。
- NAS 重启后容器能自动启动。

## 后续

- 首个镜像验证后创建并推送 `v0.1.0`。
- 等 `linux/amd64` 在 FnOS/NAS 上稳定后，再添加 `linux/arm64`。
- 如果 registry metadata 可以避开 Docker Hub secrets，再添加 pull request 构建。
- 如果 USB 调试期间需要 `privileged: true`，后续再收紧设备权限。
