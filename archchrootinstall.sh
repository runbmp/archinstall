#!/bin/sh

ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

locale-gen

echo LANG=en_US.UTF-8 >> /etc/locale.conf

MYHOST=4700u

echo "$MYHOST" >> /etc/hostname

echo "\
# Static tabl lookup for hostnames.
# See hosts(5) for details
127.0.0.1	localhost
::1		localhost
127.0.1.1	$MYHOST.localdomain	$MYHOST
"

sed -i 's/^MODULES()/MODULES(btrfs)/' /etc/mkinitcpio.conf

mkinitcpio -P

refind-install

echo "enter root password"
passwd

useradd -mG wheel ben
"echo enter password for ben"
passwd ben

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

sudo -u ben sh -c 'cd "$HOME" && echo ".dotfiles" >> .gitignore'
sudo -u ben sh -c 'cd "$HOME" && git clone https://github.com/runbmp/dotfiles.git "$HOME/.dotfiles"'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" config --local status.showUntrackedFiles no'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" checkout master'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" pull'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" restore .'

sudo -u ben sh -c 'cd "$HOME" && chmod +x "$HOME"/.bootstrap.sh'
sudo -u ben sh -c 'cd "$HOME" && "$HOME"/.bootstrap.sh'
