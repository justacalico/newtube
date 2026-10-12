#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

RELEASE_TAG="${RELEASE_TAG:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
PROJECT_DIR="${CI_PROJECT_DIR:-$PWD}"

GITHUB_REPO="justacalico/newtube"

cd "$PROJECT_DIR"

# Determine which GitHub release to sync.
if [ -z "$RELEASE_TAG" ]; then
  RELEASE_TAG=$(gh release view -R "$GITHUB_REPO" --json tagName -q .tagName)
fi

echo "Syncing GitHub release: $RELEASE_TAG"

# Resolve the commit that the release tag points to on GitHub.
# The GitLab pipeline may run on main, but the actual release tag may be a
# different commit (e.g. a version bump), so we use the tag's target commit.
RELEASE_COMMIT=$(gh api "repos/$GITHUB_REPO/commits?sha=$RELEASE_TAG&per_page=1" -q '.[0].sha' 2>/dev/null || true)
if [ -z "$RELEASE_COMMIT" ]; then
  echo "Warning: could not resolve tag $RELEASE_TAG on GitHub, falling back to $CI_COMMIT_SHA" >&2
  RELEASE_COMMIT="$CI_COMMIT_SHA"
fi

# Download assets from the GitHub release.
rm -rf release-assets SHA256SUMS.txt
mkdir -p release-assets
gh release download "$RELEASE_TAG" -R "$GITHUB_REPO" --dir release-assets

# Fetch GitHub Actions job logs if a run ID was provided.
if [ -n "$GITHUB_RUN_ID" ]; then
  gh run view "$GITHUB_RUN_ID" -R "$GITHUB_REPO" --log > github-logs.txt 2>/dev/null || true
  if [ -s github-logs.txt ]; then
    cp github-logs.txt release-assets/
  fi
fi

# Generate checksums.
cd release-assets
sha256sum * > "$PROJECT_DIR/SHA256SUMS.txt"
cd "$PROJECT_DIR"
cp SHA256SUMS.txt release-assets/

ls -la release-assets/

# Remove any stale GitLab release, tag and generic package so the
# package-registry upload does not collide with existing assets and the release
# is recreated at the current commit.
glab release delete "$RELEASE_TAG" -R "$CI_PROJECT_PATH" -y 2>/dev/null || true
PKG_ID=$(glab api "projects/$CI_PROJECT_ID/packages?package_name=release-assets&package_version=$RELEASE_TAG" 2>/dev/null | jq -r '.[0].id // empty')
if [ -n "$PKG_ID" ] && [ "$PKG_ID" != "null" ]; then
  glab api --method DELETE "projects/$CI_PROJECT_ID/packages/$PKG_ID" 2>/dev/null || true
fi

# Move the release tag to the same commit as GitHub using an SSH deploy key.
# The CI job token cannot modify tags, but a deploy key with write access can.
if [ -n "${GITLAB_RELEASE_SSH_KEY:-}" ]; then
  git remote add gitlab-ssh "git@gitlab.com:${CI_PROJECT_PATH}.git" 2>/dev/null || true
  git tag -f "$RELEASE_TAG" "$RELEASE_COMMIT"
  git push -f gitlab-ssh "$RELEASE_TAG"
fi

# Mirror to a GitLab release. The tag is kept the same as GitHub.
# glab in CI will use CI_JOB_TOKEN when GLAB_ENABLE_CI_AUTOLOGIN is set.
glab release create "$RELEASE_TAG" \
  --name "NewTube $RELEASE_TAG" \
  --notes "Mirrored from the GitHub release." \
  --ref "$RELEASE_COMMIT" \
  --use-package-registry \
  "$PROJECT_DIR/release-assets"/*

# Regenerate the AltStore source so it always points at the ipa on this release.
VERSION="${RELEASE_TAG#v}"
IPA_URL="https://gitlab.com/${CI_PROJECT_PATH}/-/releases/${RELEASE_TAG}/downloads/newtube-${VERSION}-ios.ipa"
ICON_URL="https://gitlab.com/${CI_PROJECT_PATH}/-/raw/main/assets/icon/icon.png"
SOURCE_URL="https://gitlab.com/${CI_PROJECT_PATH}/-/raw/main/repos/altstore.json"
mkdir -p repos
python3 - "$VERSION" "$IPA_URL" "$ICON_URL" "$SOURCE_URL" <<'PYEOF'
import json, sys
version, ipa_url, icon_url, source_url = sys.argv[1:5]
source = {
    "name": "NewTube",
    "subtitle": "A privacy-friendly YouTube client",
    "description": "Watch YouTube without the ads, the tracking or the clutter.",
    "iconURL": icon_url,
    "website": "https://gitlab.com/HttpAnimations/newtube",
    "sourceURL": source_url,
    "apps": [{
        "name": "NewTube",
        "bundleIdentifier": "gitlab.httpanimations.newtube",
        "developerName": "HttpAnimations",
        "subtitle": "A privacy-friendly YouTube client",
        "localizedDescription": "Watch YouTube without the ads, the tracking or the clutter.",
        "iconURL": icon_url,
        "tintColor": "#C02026",
        "category": "entertainment",
        "screenshots": [],
        "versions": [{
            "version": version,
            "date": __import__("datetime").datetime.now(
                __import__("datetime").timezone.utc
            ).strftime("%Y-%m-%d"),
            "localizedDescription": "See the release notes for changes.",
            "downloadURL": ipa_url,
            "size": 0,
            "minOSVersion": "14.0",
        }],
        "appPermissions": {
            "entitlements": [],
            "privacy": {},
        },
    }],
    "news": [],
}
ipa_size = 0
try:
    import os
    for f in os.listdir("release-assets"):
        if f.endswith(".ipa"):
            ipa_size = os.path.getsize(os.path.join("release-assets", f))
except Exception:
    pass
source["apps"][0]["versions"][0]["size"] = ipa_size
with open("repos/altstore.json", "w") as f:
    json.dump(source, f, indent=2)
    f.write("\n")
PYEOF

if [ -n "${GITLAB_RELEASE_SSH_KEY:-}" ]; then
  if ! git diff --quiet repos/altstore.json 2>/dev/null; then
    git add repos/altstore.json
    git -c user.name="GitLab CI" -c user.email="ci@gitlab.com"       commit -m "chore: 更新 AltStore 源到 $RELEASE_TAG"
    git push -o ci.skip gitlab-ssh HEAD:main || true
  fi
fi
