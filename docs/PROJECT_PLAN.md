# Project Plan

Languages: [English](PROJECT_PLAN.md) | [简体中文](PROJECT_PLAN.zh-CN.md)

## Background

The original FnOS deployment note used a manual Python virtual environment and a
systemd service:

1. Install Python venv dependencies on the NAS.
2. Clone or place `turing-smart-screen-python` under an absolute path.
3. Install `requirements.txt` in a venv.
4. Create `start_turing.sh`.
5. Create and enable a `turing-screen.service` systemd unit.
6. Fix common issues such as CRLF line endings, wrong shebang paths, moved venvs,
   and `/dev/ttyACM0` permission errors.

The Docker packaging replaces venv and systemd with a container runtime. The host
only needs Docker and USB/serial device access.

## Current State

- Local project path: `/home/dff652/my_project/turing-smart-screen-docker`
- Source prototype path: `/home/dff652/my_project/homelab/nas/turing-smart-screen`
- Original note path: `/home/dff652/my_project/homelab/nas/docs/turing-smart N100.md`
- Dockerfile, Compose file, entrypoint, README, and GitHub Actions workflow exist.
- Default upstream ref is `3.10.0`.
- Build target is `linux/amd64` first, matching Intel N100/FnOS.
- GitHub remote is configured:
  `git@github.com:dff652/turing-smart-screen-docker.git`.
- `main` has been pushed to GitHub at commit
  `7c61e0e Initial Docker packaging`.

Verified locally on 2026-06-11:

- `docker compose config` worked in the prototype directory.
- Docker pulled `python:3.10-slim-bookworm` successfully.
- Build reached apt/source stages before user interruption.
- Final image has not yet been fully built.
- No background build process or running turing container was left behind.

## Environment and Size Notes

Known local measurements:

- `python:3.10-slim-bookworm`: about 195 MB after pull.
- BuildKit cache after partial build: about 162 MB.
- Dockerfile frontend cache from the prototype: about 43.4 MB. The standalone
  Dockerfile no longer requires the external frontend directive, so future local
  builds should avoid this extra pull.
- Runtime apt packages: about 11.5 MB download, about 62.6 MB installed.
- Builder apt packages: about 85 MB download, about 368 MB installed in build layers.
- Upstream source archive download reached 14 MB before interruption.
- Project files are tiny, around tens of KB.

Expected space requirement:

- Final runtime image: roughly 450-750 MB.
- First build peak: reserve at least 2 GB, preferably 3 GB.

Slow downloads are expected on networks with poor access to Docker Hub, Debian
mirrors, GitHub, or PyPI. GitHub Actions is preferred for image builds so the NAS
only pulls the final image.

## Publishing Strategy

Use GitHub Actions to build and publish images. The first workflow intentionally
publishes only on `main`, version tags, or manual dispatch; pull request builds
can be added later after registry metadata no longer depends on Docker Hub
secrets.

Registries:

- Docker Hub: `DOCKERHUB_USERNAME/turing-smart-screen`
- GHCR: `ghcr.io/<github-owner>/turing-smart-screen`

Required GitHub repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

Tag policy:

- `latest` for the default branch.
- Git tag versions such as `v0.1.0`.
- `git-<sha>` for traceability.
- `upstream-3.10.0` for upstream source traceability.

Start with `linux/amd64`. Add `linux/arm64` only after the amd64 image is proven
on the N100/FnOS target.

## Remaining Work

1. Build the image fully, preferably in GitHub Actions.
2. If the build fails, add only the minimum missing dependencies.
3. Run an import smoke test:

   ```bash
   docker run --rm <image> python -c "import psutil, serial, usb; print('ok')"
   ```

4. Test on the real FnOS/NAS host with the screen attached.
5. Confirm whether `/dev/ttyACM0`, `/dev/ttyUSB0`, or direct USB mode is needed.
6. Tune `config/config.yaml` for the actual screen model, theme, revision, and
   brightness.
7. Decide whether `privileged: true` is needed as a temporary TUR_USB debug mode.

## GitHub Repository Setup

`gh` is not installed in the current environment. The remote was created/pushed
manually by the user.

Current remote:

```bash
origin git@github.com:dff652/turing-smart-screen-docker.git
```

Pushed commit:

```text
7c61e0e Initial Docker packaging
```

The setup commands already run:

```bash
cd /home/dff652/my_project/turing-smart-screen-docker
git remote add origin git@github.com:dff652/turing-smart-screen-docker.git
git push -u origin main
```

Then add Docker Hub secrets in GitHub:

```text
DOCKERHUB_USERNAME=<your Docker Hub username>
DOCKERHUB_TOKEN=<Docker Hub personal access token>
```

Create a release tag to publish a version:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## New Session Starting Point

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
