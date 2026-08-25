#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

printf '\n🜂 Ghost Atlas EDEN KeyAuth Fix\n'
printf 'Purpose: install ARK1 public key trust on EDEN, then run HOMEWARD finish key-only.\n\n'

pkg update -y >/dev/null || true
pkg install -y openssh curl coreutils >/dev/null || true

EDEN_USER="${EDEN_USER:-Raymond}"
EDEN_HOST="${EDEN_HOST:-100.83.241.3}"
EDEN_PORT="${EDEN_PORT:-22}"
EDEN_SSH_KEY="${EDEN_SSH_KEY:-$HOME/.ssh/id_ed25519}"
PUBKEY="${EDEN_SSH_KEY}.pub"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh" >/dev/null 2>&1 || true

if [ ! -f "$EDEN_SSH_KEY" ]; then
  ssh-keygen -t ed25519 -f "$EDEN_SSH_KEY" -N "" -C "ARK1-to-EDEN-HOMEWARD"
fi
chmod 600 "$EDEN_SSH_KEY" >/dev/null 2>&1 || true

if [ ! -f "$PUBKEY" ]; then
  ssh-keygen -y -f "$EDEN_SSH_KEY" > "$PUBKEY"
fi

ARK_PUBLIC_KEY="$(cat "$PUBKEY")"
TARGET="${EDEN_USER}@${EDEN_HOST}"
KEY_SSH_OPTS=(-p "$EDEN_PORT" -i "$EDEN_SSH_KEY" -o IdentitiesOnly=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new)

printf 'EDEN target: %s:%s\n' "$TARGET" "$EDEN_PORT"
printf 'Testing key-only SSH. No password fallback.\n\n'

if ssh "${KEY_SSH_OPTS[@]}" "$TARGET" 'powershell -NoProfile -Command "Write-Output EDEN_KEY_AUTH_PASS"'; then
  printf '\nEDEN_KEY_AUTH_PASS\n'
else
  printf '\nEDEN_KEY_AUTH_NOT_INSTALLED\n'
  printf 'Your ARK1 public key is:\n\n%s\n\n' "$ARK_PUBLIC_KEY"
  printf 'Run this ON EDEN in PowerShell as Raymond or Administrator, then rerun this Termux command:\n\n'
  cat <<EOF
\$k = @'
$ARK_PUBLIC_KEY
'@; \$d = 'C:\Users\Raymond\.ssh'; New-Item -ItemType Directory -Force -Path \$d | Out-Null; Add-Content -Path (Join-Path \$d 'authorized_keys') -Value \$k; icacls \$d /inheritance:r /grant 'Raymond:(OI)(CI)F' /grant 'SYSTEM:(OI)(CI)F' | Out-Null; icacls (Join-Path \$d 'authorized_keys') /inheritance:r /grant 'Raymond:F' /grant 'SYSTEM:F' | Out-Null; Restart-Service sshd
EOF
  printf '\nNo password guessing. Install the key once, then EDEN runs key-only.\n'
  exit 23
fi

printf '\nDownloading HOMEWARD finish launcher...\n'
curl -fsSL https://raw.githubusercontent.com/Atlas-Ascend/GARI-/build/new-atlantis-homeward-unreal-5.8/games/homeward-unreal/Scripts/Termux-Eden-Hypernet-Finish.sh -o "$HOME/ga-homeward-finish.sh"
chmod +x "$HOME/ga-homeward-finish.sh"

exec env EDEN_USER="$EDEN_USER" EDEN_HOST="$EDEN_HOST" EDEN_PORT="$EDEN_PORT" EDEN_SSH_KEY="$EDEN_SSH_KEY" bash "$HOME/ga-homeward-finish.sh"
