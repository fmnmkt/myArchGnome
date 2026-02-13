#!/usr/bin/env bash


#Silence GRUB and Remove Timeout
set -e

echo "🔧 Updating GRUB to remove timeout and hide boot messages..."

# 1. Backup original config
sudo cp /etc/default/grub /etc/default/grub.bak

# 2. Apply silent boot settings
sudo sed -i \
  -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' \
  -e 's/^#GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' \
  -e 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' \
  -e 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 nowatchdog"/' \
  /etc/default/grub

# 3. Regenerate GRUB config
if [[ -d /boot/grub ]]; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg
elif [[ -d /boot/grub2 ]]; then
  sudo grub-mkconfig -o /boot/grub2/grub.cfg
else
  echo "❌ Could not find GRUB directory. Please check your boot setup."
  exit 1
fi

echo "✅ GRUB updated: no timeout, hidden menu, quiet boot."
