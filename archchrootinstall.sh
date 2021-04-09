#!/bin/sh

statusprint() {
  printf "\n"
  printf "\033[%sm**********\033[0m\n" "${2:-1;34}"
  printf "\033[%sm*\033[0m\n" "${2:-1;34}"
  printf "\033[%sm* %s\033[0m\n" "${2:-1;34}" "$1"
  printf "\033[%sm*\033[0m\n" "${2:-1;34}"
  printf "\033[%sm**********\033[0m\n" "${2:-1;34}"
  printf "\n"
}

DISKDEV="$1"
if [ -z "$DISKDEV" ]; then
  statusprint "lsblk info"
  lsblk

  statusprint "disk device was not passed, please reconfirm" "1;33"
  read -r DISKDEV
fi

statusprint "set timezone in /etc/localtime"
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

statusprint "turn on hwclock"
hwclock --systohc

statusprint "enable en_US.UTF-8 UTF-8 locale"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf

statusprint "set hostname 4700u"
MYHOST=4700u
echo "$MYHOST" >> /etc/hostname
echo "\
# Static tabl lookup for hostnames.
# See hosts(5) for details
127.0.0.1	localhost
::1		localhost
127.0.1.1	$MYHOST.localdomain	$MYHOST
"

statusprint "run mkinitcpio for all installed kernels"
#todo this is only for partitionless install?
#sed -i 's/^MODULES()/MODULES(btrfs)/' /etc/mkinitcpio.conf
mkinitcpio -P

statusprint "install refind bootloader to 'DISKDEV'1"
refind-install --usedefault "$DISKDEV"1

statusprint "setup root password" "1;33"
passwd

statusprint "setup new user ben password and add wheel as sudoer" "1;33"
useradd -mG wheel ben
passwd ben
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

statusprint "grab dotfiles and bootstrap them"
sudo -u ben sh -c 'cd "$HOME" && echo ".dotfiles" >> .gitignore'
sudo -u ben sh -c 'cd "$HOME" && git clone https://github.com/runbmp/dotfiles.git "$HOME/.dotfiles"'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" config --local status.showUntrackedFiles no'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" checkout master'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" pull'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" restore .'

sudo -u ben sh -c 'cd "$HOME" && chmod +x "$HOME"/.bootstrap.sh'
sudo -u ben sh -c 'cd "$HOME" && "$HOME"/.bootstrap.sh'
