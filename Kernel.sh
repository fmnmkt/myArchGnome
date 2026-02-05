#!/usr/bin/env bash
# repair-mkinitcpio.sh
set -euo pipefail

CONF="/etc/mkinitcpio.conf"
BACKUP="${CONF}.bak.$(date +%Y%m%d-%H%M%S)"

echo "[INFO] Backing up $CONF to $BACKUP"
sudo cp "$CONF" "$BACKUP"

echo "[INFO] Removing any HOOKS= line..."
sudo sed -i '/^HOOKS=/d' "$CONF"

echo "[INFO] Appending clean HOOKS line..."
cat <<'EOF' | sudo tee -a "$CONF" >/dev/null
HOOKS=(base udev autodetect modconf block plymouth filesystems keyboard fsck)
EOF

echo "[INFO] Rebuilding initramfs..."
sudo mkinitcpio -P

echo "[INFO] Done. If something goes wrong, restore backup: sudo cp $BACKUP $CONF && sudo mkinitcpio -P"


#!/usr/bin/env bash
# fix-mkinitcpio-hooks.sh
# Repair mkinitcpio.conf HOOKS line if broken by stray quotes and add plymouth safely.

set -euo pipefail

CONF="/etc/mkinitcpio.conf"
BACKUP="${CONF}.bak.$(date +%Y%m%d-%H%M%S)"

echo "[INFO] Backing up $CONF to $BACKUP"
sudo cp "$CONF" "$BACKUP"

echo "[INFO] Fixing HOOKS line..."
# Remove any stray quotes and rebuild HOOKS line
sudo sed -i '/^HOOKS=/d' "$CONF"

cat <<'EOF' | sudo tee -a "$CONF" >/dev/null
HOOKS=(base udev autodetect modconf block plymouth filesystems keyboard fsck)
EOF

echo "[INFO] Rebuilding initramfs..."
sudo mkinitcpio -P

echo "[INFO] Done. mkinitcpio.conf repaired and initramfs rebuilt."
echo "If something goes wrong, restore backup: sudo cp $BACKUP $CONF && sudo mkinitcpio -P"




#!/usr/bin/env bash
# setup-plymouth.sh
# Configure Arch Linux to show a custom splash screen at boot using Plymouth.
# This version generates a default Arch logo image if you don't provide one.

set -euo pipefail

THEME_NAME="archsplash"
WORKDIR="/usr/share/plymouth/themes/${THEME_NAME}"
IMAGE_PATH="${WORKDIR}/background.png"

log() { echo "[INFO] $*"; }
require_root() { [[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }; }

require_root

log "Installing plymouth and dependencies..."
pacman -S --needed plymouth imagemagick

log "Creating theme directory: $WORKDIR"
mkdir -p "$WORKDIR"

log "Generating default Arch splash image..."
# Create a 1920x1080 black background with Arch logo text
convert -size 1920x1080 xc:black \
  -fill cyan -pointsize 200 -gravity center \
  -annotate +0+0 "Arch Linux" "$IMAGE_PATH"

log "Creating plymouth theme file..."
cat > "$WORKDIR/${THEME_NAME}.plymouth" <<EOF
[Plymouth Theme]
Name=${THEME_NAME}
Description=Arch splash with background image
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/${THEME_NAME}
ScriptFile=${WORKDIR}/${THEME_NAME}.script
EOF

cat > "$WORKDIR/${THEME_NAME}.script" <<'EOF'
wallpaper_image = Image("background.png");
wallpaper_sprite = Sprite(wallpaper_image);
wallpaper_sprite.SetZ(-1000);
wallpaper_sprite.SetPosition(ScreenWidth/2, ScreenHeight/2);
EOF

log "Setting default plymouth theme..."
plymouth-set-default-theme -R "$THEME_NAME"

log "Adding plymouth to initramfs hooks..."
sed -i 's/^HOOKS=(\(.*\)filesystems\(.*\))$/HOOKS=(\1plymouth filesystems\2)/' /etc/mkinitcpio.conf

log "Rebuilding initramfs..."
mkinitcpio -P

log "Updating bootloader..."
if [[ -f /etc/default/grub ]]; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub
  grub-mkconfig -o /boot/grub/grub.cfg
elif [[ -d /boot/loader/entries ]]; then
  for entry in /boot/loader/entries/*.conf; do
    sed -i 's/^options .*/& quiet splash/' "$entry"
  done
  bootctl update
fi

log "Done! Reboot to see your Arch splash screen."
