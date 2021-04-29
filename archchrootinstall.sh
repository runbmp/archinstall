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

#DISKDEV="$1"
#if [ -z "$DISKDEV" ]; then
#  statusprint "lsblk info"
#  fdisk -l
#  lsblk

#  statusprint "disk device was not passed, please reconfirm" "1;33"
#  read -r DISKDEV
#fi

cd /swap
truncate -s 0 ./swapfile
chattr +C ./swapfile
btrfs property set ./swapfile compression none
dd if=/dev/zero of=/swap/swapfile bs=1M count=16384 status=progress
chmod 600 swapfile
mkswap swapfile
swapon swapfile

echo "/n" > /etc/fstab
echo "# /dev/nvme0n1p5/n" > /etc/fstab
echo "/swap/swapfile none swap defaults 0 0" > /etc/fstab
cat /etc/fstab

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
" >> /etc/hosts

statusprint "run mkinitcpio for all installed kernels"
# sed add resume between fssystems and fsck
mkinitcpio -P

statusprint "install grub bootloader"
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

statusprint "setup root password" "1;33"
passwd

statusprint "setup new user ben password and add wheel as sudoer" "1;33"
useradd -mG wheel ben
usermod -a -G video ben
passwd ben
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

statusprint "grab dotfiles and bootstrap them"
sudo -u ben sh -c 'cd "$HOME" && echo ".dotfiles" >> .gitignore'
sudo -u ben sh -c 'cd "$HOME" && git clone --bare https://github.com/runbmp/dotfiles.git "$HOME"/.dotfiles'
sudo -u ben sh -c 'cd "$HOME" && /usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" checkout'

sudo -u ben sh -c 'cd "$HOME" && chmod +x "$HOME"/.bootstrap.sh'
sudo -u ben sh -c 'cd "$HOME" && "$HOME"/.bootstrap.sh'
