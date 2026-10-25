#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix
# Bumps sources.json to the latest stable Axolotl Launcher release.
set -euo pipefail
cd "$(dirname "$0")"

repo="Axolotl-Launcher/Axolotl"
auth=()
[[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")

latest=$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
latest=${latest#v}
current=$(jq -r .version sources.json)

if [[ "$latest" == "$current" ]]; then
  echo "axolotl-launcher is up to date ($current)"
  exit 0
fi
echo "Updating axolotl-launcher $current -> $latest"

hash_for() {
  local url="https://github.com/$repo/releases/download/v$latest/Axolotl.Launcher_${latest}_$1.deb"
  nix store prefetch-file --json "$url" | jq -r .hash
}

amd64=$(hash_for amd64)
arm64=$(hash_for arm64)

jq -n --arg v "$latest" --arg a "$amd64" --arg b "$arm64" \
  '{version: $v, hashes: {amd64: $a, arm64: $b}}' > sources.json
