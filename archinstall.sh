#!/bin/sh

statusprint() {
  printf "\n"
  printf "\033[${2:-1;34}m**********\033[0m\n"
  printf "\033[${2:-1;34}m*\033[0m\n"
  printf "\033[${2:-1;34}m* $1\033[0m\n"
  printf "\033[${2:-1;34}m*\033[0m\n"
  printf "\033[${2:-1;34}m**********\033[0m\n"
  printf "\n"
}

statusprint "ip info"
ip link
ip a

statusprint "ping check"
ping google.com -c 1

statusprint "reflector update for pacman mirrors"
reflector --verbose --country US --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

statusprint "timedatectl set ntp"
timedatectl set-ntp true

statusprint "fdisk info"
fdisk -l

statusprint "enter the disk you wish to blow away and install arch to" "1;33"
read -r DISKDEV

statusprint "gdisking to create efi and root partitions"
sgdisk -og "$DISKDEV"
sgdisk -n 1:0:+500M -t 1:ef00 "$DISKDEV"
sgdisk -n 2:0:0 "$DISKDEV"
sgdisk -p "$DISKDEV"

statusprint "mkfs on new partitions"
mkfs.fat -f -F32 "$DISKDEV"1
mkfs.btrfs -f "$DISKDEV"2

statusprint "mount root to /mnt"
mount "$DISKDEV"2 /mnt
cd /mnt || (echo "couldn't cd into /mnt" && return)

statusprint "create btrfs subvolumes"
btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @snapshots
btrfs subvolume create @var_log
btrfs subvolume create @swapfile
cd || (echo "couldn't cd into /" && return)

statusprint "create directories and mount btrfs subvolumes"
umount /mnt
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@ "$DISKDEV"2 /mnt
mkdir -p /mnt/boot/efi
mkdir /mnt/home
mkdir /mnt/.snapshots
mkdir -p /mnt/var/log
mkdir /mnt/swap
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@home "$DISKDEV"2 /mnt/home
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@snapshots "$DISKDEV"2 /mnt/.snapshots
mount -o noatime,compress=lzo,space_cache=v2,discard=async,subvol=@var_log "$DISKDEV"2 /mnt/var/log
mount -o defaults,noatime,subvol=@swap "$DISKDEV"2 /swap
mount "$DISKDEV"1 /mnt/boot/efi

statusprint "pacstrap base packages"
pacstrap /mnt base base-devel linux linux-firmware linux-lts btrfs-progs refind efibootmgr git

statusprint "genfstab"
genfstab -U /mnt >> /mnt/etc/fstab

statusprint "curl next script for use in new arch-chroot environment"
curl https://raw.githubusercontent.com/runbmp/archinstall/main/archchrootinstall.sh -o archchrootinstall.sh
chmod +x archchrootinstall.sh
cp archchrootinstall.sh /mnt/
arch-chroot /mnt ./archchrootinstall.sh
