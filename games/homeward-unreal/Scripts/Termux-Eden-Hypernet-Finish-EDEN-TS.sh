#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Canonical Ghost Atlas Hypernet endpoint map.
# EDEN_TS is the Windows EDEN target over Tailscale.
# ARK1 is the Android/Termux field node endpoint.
export EDEN_USER="${EDEN_USER:-Raymond}"
export EDEN_HOST="${EDEN_HOST:-100.83.241.3}"
export EDEN_PORT="${EDEN_PORT:-22}"
export ARK1_HOST="${ARK1_HOST:-100.69.77.85}"
export ARK1_PORT="${ARK1_PORT:-8022}"
export EDEN_DNS="${EDEN_DNS:-eden.tail685c07.ts.net}"

printf '\n🜂 Ghost Atlas HOMEWARD Canonical EDEN_TS Launcher\n'
printf 'EDEN_TS: %s@%s:%s\n' "$EDEN_USER" "$EDEN_HOST" "$EDEN_PORT"
printf 'ARK1:    %s:%s\n' "$ARK1_HOST" "$ARK1_PORT"
printf 'EDEN_DNS fallback: %s:22\n\n' "$EDEN_DNS"

BASE_URL='https://raw.githubusercontent.com/Atlas-Ascend/GARI-/build/new-atlantis-homeward-unreal-5.8/games/homeward-unreal/Scripts/Termux-Eden-Hypernet-Finish.sh'
TARGET_SCRIPT="${HOME}/ga-homeward-finish-inner.sh"

curl -fsSL "$BASE_URL" -o "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
exec bash "$TARGET_SCRIPT"
