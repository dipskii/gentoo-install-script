#!/bin/bash
# nice formatting
RED='\033[0;31m'
NC='\033[0m' # No Color

# drive partitioning
lsblk # lists disks
echo "select disk for installation (type ${RED}entirety${NC} of name field from lsblk result)"
read partdisk

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${partdisk}
  g # create gpt disklabel
  n # new partition
  1 # partition number 1
    # start at default
  +256M # 256 MB boot parttion
  t # select partition
  1 # mark as efi system partition
  n # new swap partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +5G # 5gb swap file
  t # select partition
  2 # select swap partition
  19 # mark as linux swap
  n # make root partition
  3 # partition number 3
    # default, start immediately after preceding partition
    # default, fill rest of disk
  w # write partition table
EOF

# creating filesystems

mkfs.vfat -F 32 ${partdisk}1
mkswap ${partdisk}2
swapon ${partdisk}2
mkfs.ext4 ${partdisk}3

# mounting and installing stage3 tarball

mount ${partdisk}3 /mnt/gentoo
cd /mnt/gentoo

echo "Please select \"Stage 3 desktop profile | openrc\" (this is manual to keep the script up to date!)"
while [ true ] ; do
read -t 3 -n 1
if [ $? = 0 ] ; then
exit ;
else
fi
done

links gentoo.org/downloads
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

# make.conf tomfoolery
# change this to match your cpu architecture and thread count!

sed -i 's/-O2 -pipe/-O2 -march=skylake -pipe/' /mnt/gentoo/etc/portage/make.conf
echo "MAKEOPTS=\"-j16\"" >> make.conf

# mirrors
# i tried to automate this but i kept getting errors

mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# chroot setup

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run 

wget https://raw.githubusercontent.com/dipskii/gentoo-install-script/main/chroot.sh
chmod +x chroot.sh
sed -i "s|\!\!PLACEHOLDER\!\!|$partdisk|g" chroot.sh

echo "Please chroot into your Gentoo install, then run 'chroot.sh'
# chroot /mnt/gentoo /bin/bash
# source /etc/profile
# export PS1=\"(chroot) ${PS1}\"
# ./chroot.sh
"
