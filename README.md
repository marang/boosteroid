# Boosteroid Flatpak (Community/Unofficial)

This repo contains a local Flatpak packaging for the proprietary Boosteroid Linux client.

## What it does

- Builds app metadata/wrapper as Flatpak app `io.github.marang.boosteroid`.
- Downloads Boosteroid's official `.deb` during install (`extra-data`).
- Extracts payload into `/app/extra` and launches the original binary.

## Build and install locally

Source: https://github.com/marang/boosteroid

```bash
cd ~/Dev/boosteroid-flatpak
flatpak install --user -y flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08
flatpak-builder --user --install --force-clean build-dir io.github.marang.boosteroid.yml
```

Run:

```bash
flatpak run io.github.marang.boosteroid
```

## One-step reliable sync

Use this single command for updates. It:
- checks for latest upstream `.deb` metadata and updates manifest when needed
- uninstalls current user Flatpak install
- reinstalls using `--user --install --force-clean`

```bash
cd ~/Dev/boosteroid-flatpak
./scripts/sync-latest.sh
```

For automated update checks (CI, cron, timer), use:

```bash
./scripts/sync-latest.sh --check --skip-reinstall
```

This updates only `io.github.marang.boosteroid.yml` when hash/size changed and exits without rebuilding/reinstalling.  
Use your preferred schedule (GitHub Actions, cron, systemd timer), then commit the generated manifest change and open/update the PR in Flathub.

### GitHub Actions automation (recommended)

This repository includes `.github/workflows/update-flathub-manifest.yml` which can:

- run on a daily schedule or manually,
- run `./scripts/sync-latest.sh --check --skip-reinstall`,
- copy updated manifest data to `marang/flathub` branch `new-pr` and push it.

To enable it you need a repository secret in this repo:

- `FLATHUB_TOKEN` with write access to `marang/flathub` (for branch `new-pr`).

## Notes for Flathub submission

- App is proprietary, so `extra-data` is the correct model.
- `libnuma` is bundled from `numactl` source because it is not present in the base runtime.
- You should verify redistribution and trademark permissions with Boosteroid before publishing under Flathub.
- Expect additional Flathub CI/policy requirements (AppStream details, screenshots, review fixes).
