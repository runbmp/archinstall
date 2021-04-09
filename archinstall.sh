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

statusprint "ip info"
ip link
ip a

statusprint "ping check"
ping google.com -c 1

statusprint "reflector update for pacman mirrors"
reflector --verbose --country US --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

statusprint "timedatectl set ntp"
timedatectl set-ntp true

statusprint "lsblk info"
fdisk -l
lsblk

statusprint "enter the disk you wish to blow away and install arch to" "1;33"
read -r DISKDEV

statusprint "gdisking to create efi and root partitions"
sgdisk -og "$DISKDEV"
sgdisk -n 1:0:+500M -t 1:ef00 "$DISKDEV"
sgdisk -n 2:0:0 "$DISKDEV"
sgdisk -p "$DISKDEV"

statusprint "mkfs on new partitions"
mkfs.fat -f -F32 "$DISKDEV"p1
mkfs.btrfs -f "$DISKDEV"p2

statusprint "mount root to /mnt"
mount "$DISKDEV"p2 /mnt
cd /mnt || (echo "couldn't cd into /mnt" && return)

statusprint "create btrfs subvolumes"
btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @snapshots
btrfs subvolume create @var_log
btrfs subvolume create @swap
cd || (echo "couldn't cd into /" && return)

statusprint "create directories and mount btrfs subvolumes"
umount /mnt
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@ "$DISKDEV"p2 /mnt
mkdir -p /mnt/efi
mkdir /mnt/home
mkdir /mnt/.snapshots
mkdir -p /mnt/var/log
mkdir /mnt/swap
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@home "$DISKDEV"p2 /mnt/home
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@snapshots "$DISKDEV"p2 /mnt/.snapshots
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@var_log "$DISKDEV"p2 /mnt/var/log
mount -o defaults,noatime,subvol=@swap "$DISKDEV"p2 /mnt/swap
mount "$DISKDEV"p1 /mnt/efi

cd /mnt/swap
truncate -s 0 ./swapfile
chattr +C ./swapfile
btrfs property set ./swapfile compression none
cd

statusprint "pacstrap base packages"
pacstrap /mnt base base-devel linux linux-firmware linux-lts btrfs-progs grub os-prober efibootmgr git networkmanager reflector iwd vi

statusprint "genfstab"
genfstab -U /mnt >> /mnt/etc/fstab

statusprint "curl next script for use in new arch-chroot environment"
curl https://raw.githubusercontent.com/runbmp/archinstall/main/archchrootinstall.sh -o archchrootinstall.sh
chmod +x archchrootinstall.sh
cp archchrootinstall.sh /mnt/
arch-chroot /mnt ./archchrootinstall.sh "$DISKDEV"
