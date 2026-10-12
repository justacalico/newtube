#!/usr/bin/env bash
# Package a built Flutter Linux bundle as an RPM for Fedora and friends.
# Installs to /opt/newtube with a /usr/bin/newtube symlink, matching the
# layout used by the .deb package built in CI.
#
# Usage: scripts/build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]
set -euo pipefail

BUNDLE_DIR="${1:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
VERSION="${2:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
ARCH="${3:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
OUT="${4:?usage: build-rpm.sh <bundle-dir> <version> <rpm-arch> <output-file> [release]}"
RELEASE="${5:-1}"

if ! command -v rpmbuild >/dev/null 2>&1; then
  echo "build-rpm: rpmbuild not found (install the rpm/rpm-build package)" >&2
  exit 1
fi
if [ ! -d "$BUNDLE_DIR" ]; then
  echo "build-rpm: bundle dir not found: $BUNDLE_DIR" >&2
  exit 1
fi
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
  echo "build-rpm: unsupported arch: $ARCH" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
LINUX_ASSETS="$REPO_ROOT/packaging/linux"
for f in "$LINUX_ASSETS/newtube.desktop" "$LINUX_ASSETS/newtube.png" "$REPO_ROOT/LICENSE"; do
  if [ ! -f "$f" ]; then
    echo "build-rpm: missing packaging asset: $f" >&2
    exit 1
  fi
done

RPM_VERSION="$(printf '%s' "$VERSION" | tr '-' '~')"

TOPDIR="$(mktemp -d)"
trap 'rm -rf "$TOPDIR"' EXIT
mkdir -p "$TOPDIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

BUNDLED_SOS="$(find "$BUNDLE_DIR" -type f -name '*.so*' -printf '%f\n' | sort -u | sed 's/\./[.]/g' | paste -sd'|')"
REQUIRES_EXCLUDE="^(${BUNDLED_SOS})([(].*[)])*$"

cat > "$TOPDIR/SPECS/newtube.spec" <<'EOF'
Name: newtube
Version: %{pkg_version}
Release: %{pkg_release}%{?dist}
Summary: NewTube desktop client
License: AGPL-3.0-only
URL: https://gitlab.com/HttpAnimations/newtube

%global debug_package %{nil}
%global __os_install_post %{nil}
%global __provides_exclude_from ^/opt/newtube/.*
%global __requires_exclude %{requires_exclude}

%description
A privacy-friendly YouTube client for desktop and mobile.

%install
mkdir -p %{buildroot}/opt/newtube %{buildroot}/usr/bin
cp -a "%{bundle_dir}/." %{buildroot}/opt/newtube/
ln -sf /opt/newtube/newtube %{buildroot}/usr/bin/newtube
install -Dm644 "%{linux_assets}/newtube.desktop" %{buildroot}/usr/share/applications/gitlab.httpanimations.newtube.desktop
install -Dm644 "%{linux_assets}/newtube.png" %{buildroot}/usr/share/icons/hicolor/256x256/apps/newtube.png
install -Dm644 "%{license_file}" %{buildroot}/usr/share/licenses/newtube/LICENSE

%files
/opt/newtube
/usr/bin/newtube
/usr/share/applications/gitlab.httpanimations.newtube.desktop
/usr/share/icons/hicolor/256x256/apps/newtube.png
%license /usr/share/licenses/newtube/LICENSE
EOF

rpmbuild -bb \
  --target "$ARCH" \
  --define "_topdir $TOPDIR" \
  --define "pkg_version $RPM_VERSION" \
  --define "pkg_release $RELEASE" \
  --define "bundle_dir $(realpath "$BUNDLE_DIR")" \
  --define "linux_assets $LINUX_ASSETS" \
  --define "license_file $REPO_ROOT/LICENSE" \
  --define "requires_exclude $REQUIRES_EXCLUDE" \
  "$TOPDIR/SPECS/newtube.spec"

RPM_PATH="$(find "$TOPDIR/RPMS" -name '*.rpm' -print -quit)"
if [ -z "$RPM_PATH" ]; then
  echo "build-rpm: rpmbuild produced no rpm" >&2
  exit 1
fi
cp "$RPM_PATH" "$OUT"
echo "build-rpm: $RPM_PATH -> $OUT"
