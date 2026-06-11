# Roadmap

Languages: [English](ROADMAP.md) | [简体中文](ROADMAP.zh-CN.md)

## Current Focus

1. Fix or verify the Docker Hub repository secret:

   ```text
   DOCKERHUB_TOKEN=<Docker Hub personal access token>
   ```

2. Re-run the `Build and publish Docker image` GitHub Actions workflow.
3. Confirm the workflow logs in to Docker Hub, builds `linux/amd64`, and pushes
   the image.
4. Run the import smoke test against the published image:

   ```bash
   docker run --rm --entrypoint python dff652/turing-smart-screen:latest -c "import psutil, serial, usb; print('ok')"
   ```

5. Test on the real FnOS/NAS host with the screen attached.

## Validation Checklist

- GitHub Actions completes successfully.
- Docker Hub contains `dff652/turing-smart-screen:latest`.
- GHCR contains `ghcr.io/<github-owner>/turing-smart-screen:latest`.
- The import smoke test prints `ok`.
- The container can see the real screen device as `/dev/ttyACM0` or
  `/dev/ttyUSB0`.
- `config/config.yaml` is tuned for the actual screen model, revision,
  brightness, and theme.
- The container starts automatically after NAS reboot.

## Later

- Create and push `v0.1.0` after the first image is verified.
- Add `linux/arm64` after `linux/amd64` is stable on FnOS/NAS.
- Add pull request builds if registry metadata can avoid Docker Hub secrets.
- Tighten device permissions if `privileged: true` is needed during USB
  debugging.
