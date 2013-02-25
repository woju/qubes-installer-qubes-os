#!/bin/sh

set -e

FILESPATH=/usr/share/qubes-upgrade
YUM_OPTS="-y -q"
export LC_ALL=C

echo "--> Installing packages required for upgrade"
qubes-dom0-update --disablerepo=* --enablerepo=qubes-upgrade $YUM_OPTS qubes-dom0-upgrade-packages-placeholder
yum -y remove PackageKit-yum
qubes-dom0-update --disablerepo=* --enablerepo=qubes-upgrade $YUM_OPTS rpm libdb-utils
rm -f /var/lib/rpm/__*
rpm --rebuilddb

echo "--> Applying misc fixes"
sed -i 's@find /var/lock /var/run@\0 -mindepth 1@' /etc/rc.d/rc.sysinit

echo "--> Preparing filesystem layout upgrade"

# prepare boot into runlevel 3
for srv in `chkconfig --list |grep 5:on|awk '{print $1}'`; do
    chkconfig --level 3 $srv on
done
for srv in `chkconfig --list |grep 5:off|awk '{print $1}'`; do
    chkconfig --level 3 $srv off
done

KVER=`uname -r`
KPATH=/boot/vmlinuz-$KVER

if ! [ -r $KPATH ]; then
    echo "Kernel image $KPATH does not exists!"
    echo 1
fi

INITRDPATH="/boot/upgrade-initramfs-$KVER.img"
dracut --force -a convertfs "$INITRDPATH" $KVER

KCMDLINE="`cat /proc/cmdline | sed 's/^ro /3 rw /'` rd.convertfs"
grubby --title="Qubes upgrade" \
    --add-multiboot=/boot/xen.gz \
    --mbargs="console=none" \
    --add-kernel=$KPATH \
    --args="$KCMDLINE" \
    --initrd="$INITRDPATH" \
    --make-default

echo "--> Now you need to reboot the system. Make sure you boot into \"Qubes upgrade\" boot option"
echo "--> After reboot login into system (in text mode) and start this tool again"
