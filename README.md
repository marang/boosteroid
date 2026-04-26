# Boosteroid Flatpak (Unofficial)

This repo contains a local Flatpak packaging for the proprietary Boosteroid Linux client.

## What it does

- Builds app metadata/wrapper as Flatpak app `io.github.unofficial.boosteroid`.
- Downloads Boosteroid's official `.deb` during install (`extra-data`).
- Extracts payload into `/app/extra` and launches the original binary.

## Build and install locally

```bash
cd ~/Dev/boosteroid-flatpak
flatpak install --user -y flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08
flatpak-builder --user --install --force-clean build-dir org.boosteroid.Boosteroid.yml
```

Run:

```bash
flatpak run io.github.unofficial.boosteroid
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

## Notes for Flathub submission

- App is proprietary, so `extra-data` is the correct model.
- `libnuma` is bundled from `numactl` source because it is not present in the base runtime.
- You should verify redistribution and trademark permissions with Boosteroid before publishing under Flathub.
- Expect additional Flathub CI/policy requirements (AppStream details, screenshots, review fixes).
