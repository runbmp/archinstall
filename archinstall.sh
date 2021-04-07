#!/bin/sh

ip link

ping google.com -c 1

reflector --country US --latest 100 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

timedatectl set-ntp true

fdisk -l

echo "enter the disk you wish to blow away and install arch to"
read -r DISKDEV

sgdisk -og "$DISKDEV"
sgdisk -n 1:0:+500M -t 1:ef00 "$DISKDEV"
sgdisk -n 2:0:0 "$DISKDEV"
sgdisk -p "$DISKDEV"

mkfs.fat -F32 "$DISKDEV"1
mkfs.btrfs "$DISKDEV"2

mount "$DISKDEV"2 /mnt
cd /mnt || echo "couldn't cd into /mnt" && return

btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @snapshots
btrfs subvolume create @var_log
cd || echo "couldn't cd into /" && return

umount /mnt
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@ "$DISKDEV"2 /mnt
mkdir -p /mnt/boot/efi
mkdir /mnt/home
mkdir /mnt/.snapshots
mkdir -p /mnt/var/log
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@home "$DISKDEV"2 /mnt/home
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@snapshots "$DISKDEV"2 /mnt/.snapshots
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@var_log "$DISKDEV"2 /mnt/var/log
mount "$DISKDEV"1 /mnt/boot/efi

pacstrap /mnt base base-devel linux linux-firmware linux-lts vi btrfs-progs grub efibootmgr git

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

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

passwd

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

sed -i 's/^GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/^#GRUB_SAVE_DEFAULT=true/GRUB_SAVE_DEFAULT=true/' /etc/default/grub
sed -i 's/^#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

useradd -mG wheel ben
passwd ben

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

su ben
cd "$HOME" || echo "home does not exist" && return

echo ".cfg" >> .gitignore
git clone https://github.com/runbmp/dotfiles.git "$HOME/.dotfiles"
/usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" config --local status.showUntrackedFiles no
/usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" checkout master
/usr/bin/git --git-dir="$HOME/.dotfiles/.git" --work-tree="$HOME" pull

chmod +x ./.bootstrap.sh
./.bootstrap.sh
