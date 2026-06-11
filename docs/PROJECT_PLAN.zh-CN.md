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

## 当前状态

- 本地项目路径：`/home/dff652/my_project/turing-smart-screen-docker`
- 源原型路径：`/home/dff652/my_project/homelab/nas/turing-smart-screen`
- 原始笔记路径：`/home/dff652/my_project/homelab/nas/docs/turing-smart N100.md`
- Dockerfile、Compose 文件、entrypoint、README 和 GitHub Actions workflow 已存在。
- 默认上游版本是 `3.10.0`。
- 构建目标先从 `linux/amd64` 开始，匹配 Intel N100/FnOS。
- GitHub remote 已配置：
  `git@github.com:dff652/turing-smart-screen-docker.git`。
- `main` 已推送到 GitHub，commit 为
  `7c61e0e Initial Docker packaging`。

2026-06-11 已在本地验证：

- 原型目录中 `docker compose config` 可用。
- Docker 已成功拉取 `python:3.10-slim-bookworm`。
- 构建在用户中断前已经进入 apt/source 阶段。
- 最终镜像尚未完整构建。
- 没有残留后台构建进程或运行中的 turing 容器。

## 环境和体积说明

已知本地测量值：

- `python:3.10-slim-bookworm`：拉取后约 195 MB。
- 部分构建后的 BuildKit 缓存：约 162 MB。
- 原型中的 Dockerfile frontend 缓存：约 43.4 MB。独立 Dockerfile 已不再需要外部
  frontend directive，所以后续本地构建应避免这次额外拉取。
- 运行时 apt 包：下载约 11.5 MB，安装后约 62.6 MB。
- 构建阶段 apt 包：下载约 85 MB，安装到构建层后约 368 MB。
- 上游源码压缩包下载在中断前到达 14 MB。
- 项目文件很小，只有几十 KB。

预期空间需求：

- 最终运行镜像：约 450-750 MB。
- 首次构建峰值：至少预留 2 GB，建议 3 GB。

如果网络访问 Docker Hub、Debian mirrors、GitHub 或 PyPI 较慢，下载慢是预期现象。
推荐用 GitHub Actions 构建镜像，让 NAS 只拉取最终镜像。

## 发布策略

使用 GitHub Actions 构建并发布镜像。首版 workflow 只在 `main`、版本 tag 或手动触发时
发布；pull request 构建可以稍后添加，等 registry metadata 不再依赖 Docker Hub
secrets 后再处理。

镜像仓库：

- Docker Hub：`DOCKERHUB_USERNAME/turing-smart-screen`
- GHCR：`ghcr.io/<github-owner>/turing-smart-screen`

必需的 GitHub repository secrets：

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

tag 策略：

- 默认分支生成 `latest`。
- Git tag 版本，例如 `v0.1.0`。
- `git-<sha>` 用于追踪构建来源。
- `upstream-3.10.0` 用于追踪上游源码版本。

先支持 `linux/amd64`。等 amd64 镜像在 N100/FnOS 目标环境验证后，再添加
`linux/arm64`。

## 剩余工作

1. 完整构建镜像，优先在 GitHub Actions 中完成。
2. 如果构建失败，只添加最小必要依赖。
3. 运行导入 smoke test：

   ```bash
   docker run --rm <image> python -c "import psutil, serial, usb; print('ok')"
   ```

4. 在真实 FnOS/NAS 主机和实际屏幕上测试。
5. 确认需要 `/dev/ttyACM0`、`/dev/ttyUSB0`，还是直连 USB 模式。
6. 针对实际屏幕型号、主题、revision 和亮度调整 `config/config.yaml`。
7. 决定是否临时使用 `privileged: true` 调试 TUR_USB 模式。

## GitHub 仓库设置

当前环境没有安装 `gh`。remote 由用户手工创建并推送。

当前 remote：

```bash
origin git@github.com:dff652/turing-smart-screen-docker.git
```

已推送 commit：

```text
7c61e0e Initial Docker packaging
```

已经执行过的设置命令：

```bash
cd /home/dff652/my_project/turing-smart-screen-docker
git remote add origin git@github.com:dff652/turing-smart-screen-docker.git
git push -u origin main
```

然后在 GitHub 中添加 Docker Hub secrets：

```text
DOCKERHUB_USERNAME=<your Docker Hub username>
DOCKERHUB_TOKEN=<Docker Hub personal access token>
```

发布版本时创建 release tag：

```bash
git tag v0.1.0
git push origin v0.1.0
```

## GitHub Secrets 操作步骤

1. 打开 GitHub 仓库 `dff652/turing-smart-screen-docker`。
2. 进入 `Settings` -> `Secrets and variables` -> `Actions`。
3. 在 `Repository secrets` 中点击 `New repository secret`。
4. 添加 `DOCKERHUB_USERNAME`，值为 Docker Hub 用户名。
5. 添加 `DOCKERHUB_TOKEN`，值为 Docker Hub personal access token。
6. 打开仓库的 `Actions` 页面，查看 `Build and publish Docker image` 的首次运行结果。
7. 如果之前因为缺少 secrets 失败，点击失败 run 的 `Re-run jobs`，或推送一个小提交触发新构建。

## 新会话起点

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
