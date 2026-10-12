# NewTube

A privacy-friendly YouTube client for desktop and mobile. Watch videos
without the ads, the tracking or the clutter: your subscriptions and
history stay on your device.

[![Pipeline](https://gitlab.com/HttpAnimations/newtube/badges/main/pipeline.svg)](https://gitlab.com/HttpAnimations/newtube/-/pipelines)
[![Release](https://gitlab.com/HttpAnimations/newtube/-/badges/release.svg)](https://gitlab.com/HttpAnimations/newtube/-/releases)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](https://www.gnu.org/licenses/agpl-3.0.html)
[![Website](https://img.shields.io/badge/site-httpanimations.gitlab.io%2Fnewtube-blue)](https://httpanimations.gitlab.io/newtube/)

## What it does

- Watch YouTube videos with a real player: quality selection, audio-only
  mode and proper fullscreen.
- Subscribe to channels without an account. Your subscriptions live on
  your device, not in the cloud.
- Search videos and channels, browse channel uploads and keep a local
  watch history.
- Runs on Android, iOS, Linux, Windows and macOS, plus a web version.
- Checks itself for updates straight from the releases page.

## Get it

The [landing page](https://httpanimations.gitlab.io/newtube/) has
screenshots and one-click downloads for every platform, or grab the files
directly from the [releases page](https://gitlab.com/HttpAnimations/newtube/-/releases):

- **Android**: `.apk` or `.aab`
- **iOS**: `.ipa` via the AltStore source below
- **Linux**: AppImage, Flatpak repo, `.deb`, `.rpm`, `.zip`
- **Windows / macOS**: `.zip`
- **Web**: [httpanimations.gitlab.io/newtube/app/](https://httpanimations.gitlab.io/newtube/app/)

### AltStore source (iOS)

Add this source in AltStore to install and update NewTube:

```
https://gitlab.com/HttpAnimations/newtube/-/raw/main/repos/altstore.json
```

### Flatpak (Linux)

```
flatpak remote-add newtube https://httpanimations.gitlab.io/newtube/flatpak
flatpak install newtube gitlab.httpanimations.newtube
```

## Screenshots

![Desktop app](test/goldens/app_shell.png)
![Watch page](test/goldens/watch_page.png)
![Home feed](test/goldens/home_page.png)

## Source and licence

Source of truth lives on [GitLab](https://gitlab.com/HttpAnimations/newtube);
a mirror on [GitHub](https://github.com/justacalico/newtube) runs the builds
and the compiled releases come back to GitLab.

NewTube is free software licensed under the
[GNU Affero General Public Licence v3.0](LICENSE).
