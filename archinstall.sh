#!/bin/sh

ip link

ping google.com -c 1

reflector --verbose --country US --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

timedatectl set-ntp true

fdisk -l

echo "enter the disk you wish to blow away and install arch to"
read -r DISKDEV

sgdisk -og "$DISKDEV"
sgdisk -n 1:0:+500M -t 1:ef00 "$DISKDEV"
sgdisk -n 2:0:0 "$DISKDEV"
sgdisk -p "$DISKDEV"

mkfs.fat -f -F32 "$DISKDEV"1
mkfs.btrfs -f "$DISKDEV"2

mount "$DISKDEV"2 /mnt
cd /mnt || (echo "couldn't cd into /mnt" && return)

btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @snapshots
btrfs subvolume create @var_log
btrfs subvolume create @swapfile
cd || (echo "couldn't cd into /" && return)

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
mount -o defaults,noatime,subvol=@swap /dev/sda1 /swap
mount "$DISKDEV"1 /mnt/boot/efi

pacstrap /mnt base base-devel linux linux-firmware linux-lts vi btrfs-progs grub efibootmgr git

genfstab -U /mnt >> /mnt/etc/fstab

curl https://raw.githubusercontent.com/runbmp/archinstall/main/archchrootinstall.sh -o archchrootinstall.sh

chmod +x archchrootinstall.sh

cp archchrootinstall.sh /mnt/

arch-chroot /mnt ./archchrootinstall.sh
