#!/usr/bin/env bash

# Start
colors=(31 33 32 36 34 35)

text="Hello!"

for ((i=0; i<${#text}; i++)); do
  color=${colors[i % ${#colors[@]}]}
  char="${text:$i:1}"
  echo -ne "\e[1;${color}m$char\e[0m"
done

echo

#Packages install by Pacman
packagesToInstallPacman=(
    git
    base-devel
    gnome-browser-connector
    gnome-terminal
    exfatprogs
    bash-completion
    ttf-dejavu 
    ttf-liberation 
    noto-fonts 
    noto-fonts-emoji 
    noto-fonts-cjk 
    noto-fonts-extra
    steam
    adw-gtk-theme
)
sudo pacman -S --noconfirm "${packagesToInstallPacman[@]}"

fc-cache -fv

#Build AUR packages
cd Downloads
git clone https://aur.archlinux.org/google-chrome.git
cd google-chrome
makepkg -si --noconfirm
cd ..

git clone https://aur.archlinux.org/menulibre.git
cd menulibre
makepkg -si --noconfirm
cd ..

git clone https://aur.archlinux.org/neofetch.git
cd neofetch
gpg --recv-keys 46D62DD9F1DE636E
makepkg -si --noconfirm
cd ..

git clone https://aur.archlinux.org/mission-center.git
cd mission-center
makepkg -si --noconfirm
cd ..

#GNOME Shekk Extensions
git clone https://aur.archlinux.org/gnome-shell-extension-dash-to-dock.git
cd gnome-shell-extension-dash-to-dock
makepkg -si --noconfirm
gnome-extensions enable dash-to-dock@micxgx.gmail.com
cd ..

#To remove:
echo "Removing: ${packagesToRemovePacman[*]}"
packagesToRemovePacman=(
    vim
    epiphany
    simple-scan 
    snapshot
    papers
    evince
    malcontent
    yelp 
    sushi
    nm-connection-editor
    network-manager-applet
    gnome-disk-utility
    gnome-user-docs
    gnome-contacts 
    gnome-clocks
    gnome-weather
    gnome-maps 
    gnome-music
    gnome-software
    gnome-calendar
    gnome-connections
    gnome-tour
    gnome-logs
    gnome-system-monitor
    gnome-console
)

#Remove /usr/bin software
sudo rm -f /usr/bin/bssh
sudo rm -f /usr/bin/bvnc
sudo rm -f /usr/bin/avahi-discover
sudo rm -f /usr/bin/qv4l2
sudo rm -f /usr/bin/qvidcap

#Remove menu Gnome menu entries
sudo rm -f /usr/share/applications/bssh.desktop
sudo rm -f /usr/share/applications/bvnc.desktop
sudo rm -f /usr/share/applications/avahi-discover.desktopsu
sudo rm -f /usr/share/applications/qv4l2.desktop
sudo rm -f /usr/share/applications/qvidcap.desktop
sudo rm -f /usr/share/applications/htop.desktop
sudo rm -f /usr/share/applications/nvtop.desktop

# Filter only installed packages
installed=()
for pkg in "${packagesToRemovePacman[@]}"; do
  if pacman -Q "$pkg" &>/dev/null; then
    installed+=("$pkg")
  fi
done

# Remove only if something is installed
if [ ${#installed[@]} -gt 0 ]; then
  echo "Removing: ${installed[*]}"
  sudo pacman -R --noconfirm "${installed[@]}"
else
  echo "No matching packages installed."
fi

#Removing usr
sudo pacman -Syu --noconfirm && sudo pacman -Sc --noconfirm && sudo pacman -Rs $(pacman -Qdtq) --noconfirm

#Adding UA language in system
set -e

echo "🔧 Adding Ukrainian locale and GNOME language support..."

# 1. Enable Ukrainian locale in /etc/locale.gen
sudo sed -i '/^# *uk_UA.UTF-8 UTF-8/s/^# *//' /etc/locale.gen

# 2. Generate locales
sudo locale-gen

# 3. Set system-wide locale
echo 'LANG=uk_UA.UTF-8' | sudo tee /etc/locale.conf

# 4. Set GNOME interface language
gsettings set org.gnome.system.locale region 'uk_UA.UTF-8'

echo "✅ Ukrainian language added!"

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

#Finish
colors=(31 33 32 36 34 35)

text="That's all!"

for ((i=0; i<${#text}; i++)); do
  color=${colors[i % ${#colors[@]}]}
  char="${text:$i:1}"
  echo -ne "\e[1;${color}m$char\e[0m"
done

echo
