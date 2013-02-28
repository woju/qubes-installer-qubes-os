#!/bin/bash

set -e

YUM_OPTS="-q -y"

if [ -r /var/lib/qubes-dist-upgrade/grub ]; then
    . /var/lib/qubes-dist-upgrade/grub
fi
if [ -z "$GRUB_DEVICE" ]; then
    if [ -r /etc/sysconfig/grub ]; then
	GRUB_DEVICE="`grep ^boot= /etc/sysconfig/grub |cut -d= -f2`"
    fi
fi

if [ -n "$GRUB_DEVICE" ]; then
    echo "GRUB_DEVICE=$GRUB_DEVICE" > /var/lib/qubes-dist-upgrade/grub
fi

if rpm -q kdelibs | grep -q fc13; then
    echo "--> Removing old KDE packages"
    yum $YUM_OPTS remove kdelibs kde-settings kde-filesystem kde-settings-kdm \
	ksysguardd oxygen-icon-theme oxygen-cursor-themes
fi

if rpm -q pyxf86config > /dev/null; then
    echo "--> Removing other old packages"
    yum $YUM_OPTS remove pyxf86config
fi

echo "--> Switching to new release"
qubes-dom0-update --releasever=2 $YUM_OPTS qubes-release

echo "--> Updating base system packages"
qubes-dom0-update $YUM_OPTS yum kbd.x86_64 kbd-misc groff.x86_64 groff-base.x86_64 \
    dbus-glib.x86_64 dbus-libs.x86_64 dbus.x86_64 dbus-x11.x86_64
rpm --rebuilddb

echo "--> Updating all installed packages"
qubes-dom0-update --clean $YUM_OPTS

echo "--> Installing new packages"
# Group "qubes", "sound-basic"
qubes-dom0-update $YUM_OPTS gnome-packagekit.x86_64 pulseaudio-utils.x86_64 \
    linux-firmware \
    paman.x86_64 paprefs.x86_64 pavucontrol.x86_64

echo "--> Installing KDE packages"
# Group "kde-desktop-qubes"
qubes-dom0-update $YUM_OPTS kcm_touchpad.x86_64 ksnapshot.x86_64 kdm.x86_64 \
    mesa-libEGL.x86_64 oxygen-icon-theme qubes-kde-dom0 xsettings-kde kmix.x86_64

echo "--> Removing placeholder package"
yum remove $YUM_OPTS qubes-dom0-upgrade-packages-placeholder

echo "--> Removing no longer required packages"
yum remove $YUM_OPTS hal hal-libs hal-filesystem eggdbus avahi

echo "--> Updating config files"
for f in /etc/pam.d/*.rpmnew /etc/inittab.rpmnew /etc/xml/catalog.rpmnew /etc/sysctl.conf.rpmnew; do
    mv -f $f ${f/.rpmnew/}
done
rm -f /etc/yum.rpmnew

rm -f /etc/dracut.conf.d/firmware*.conf

#Services
systemctl enable rsyslog.service
chkconfig xencommons off
chkconfig xen-watchdog off
chkconfig xend off

# Grub
cat <<EOF > /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="\$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_CMDLINE_LINUX="quiet rhgb"
GRUB_DISABLE_RECOVERY="true"
GRUB_THEME="/boot/grub2/themes/system/theme.txt"
GRUB_CMDLINE_XEN_DEFAULT="console=none"
EOF

#Regenerate initramfs to include new software, new dracut modules and firmware
dracut --force

echo "--> Switching to new bootloader"
# Disable non-xen boot
chmod -x /etc/grub.d/10_linux
grub2-mkconfig > /boot/grub2/grub.cfg
if [ -n "$GRUB_DEVICE" ]; then
    echo "---> Grub2 bootloader will be installed to $GRUB_DEVICE"
    echo -n "Do you want to continue? [Y/n] "
    read response
    if [ "x$response" == "xn" -o "x$response" == "xN" ]; then
	GRUB_DEVICE=
    fi
fi
if [ -z "$GRUB_DEVICE" ]; then
    echo "---> You must manually install bootloader by following command:"
    echo "      grub2-install YOUR_BOOT_DEVICE"
    echo "---> Until you do so your system is UNBOOTABLE!"
    echo ""
else
    grub2-install $GRUB_DEVICE
fi

echo "--> Done."

if [ -n "$GRUB_DEVICE" ]; then
    echo "--> You must reboot system to complete update"
    echo "Press ENTER to do it now, press Ctrl-C to do it later"
    read x
    reboot
else
    echo "--> Reboot your system as soon as you install bootloader"
fi
