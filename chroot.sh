#!/bin/bash
# this is a very strange way ive decided to do this
# i hope it works!
# see install.sh if you dont understand
partdisk=!!PLACEHOLDER!!

mount ${partdisk}1 /boot

# configuring Portage
emerge-webrsync
echo "USE=\"-gnome -dvd -cdr pulseaudio networkmanager\"" >> /etc/portage/make.conf

# sigma pipewire
rm -rf /etc/portage/package.use
echo "# making pipewire work
media-video/pipewire sound-server
media-sound/pulseaudio -daemon
media-video/wireplumber elogind" > /etc/portage/package.use
emerge --verbose --update --deep --newuse @world

# CPU_FLAGS_*
emerge --ask app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" >> /etc/portage/package.use
echo "VIDEO_CARDS=\"nvidia\"" >> /etc/portage/make.conf
echo "ACCEPT_LICENSE=\"*\"" >> /etc/portage/make.conf
echo "INPUT_DEVICES=$(portageq envvar INPUT_DEVICES)" >> /etc/portage/make.conf

# locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

# firmware things

emerge sys-kernel/linux-firmware sys-firmware/intel-microcode
emerge sys-kernel/installkernel-gentoo

# using binary kernel for now...
# will make a custom kernel later!
emerge sys-kernel/gentoo-kernel-bin
emerge --depclean
emerge @module-rebuild
emerge --config sys-kernel/gentoo-kernel-bin

# i do not want to make an fstab file
emerge sys-fs/genfstab

# network setup
sed -i "s/localhost/gentoo/g" /etc/conf.d/hostname
echo "127.0.0.1     gentoo.homenetwork gentoo localhost" >> /etc/hosts
emerge net-misc/networkmanager net-vpn/networkmanager-openvpn
rc-update add NetworkManager default

echo "please type a root password!"
passwd

sed -i "s/clock=\"UTC\"/clock=\"local\"/g" etc/conf.d/hwclock

# almost done !
emerge app-admin/sysklogd # logging service
rc-update add sysklogd default
emerge sys-process/cronie # cron daemon
rc-update add cronie default
emerge sys-apps/mlocate # file indexing
emerge net-misc/chrony # time sync
rc-update add chronyd default

# bootloada
echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
emerge sys-boot/grub
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg

echo "media-libs/libsndfile minimal" >> /etc/portage/package.use
emerge media-video/wireplumber media-video/pipewire x11-drivers/nvidia-drivers
