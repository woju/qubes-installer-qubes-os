# fedora-live-base.ks
#
# Defines the basics for all kickstarts in the fedora-live branch
# Does not include package selection (other then mandatory)
# Does not include localization packages or configuration
#
# Does includes "default" language configuration (kickstarts including
# this template can override these settings)

lang en_US.UTF-8
keyboard us
timezone US/Eastern
auth --useshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=mdns
xconfig --startxonboot
part / --size 16386 --fstype ext4
services --enabled=NetworkManager --disabled=network,sshd

%include qubes-kickstart.cfg

%packages
# This was added a while ago, I think it falls into the category of
# "Diagnosis/recovery tool useful from a Live OS image".  Leaving this untouched
# for now.
memtest86+

# The point of a live image is to install
anaconda

# Without this, initramfs generation during live image creation fails: #1242586
#dracut-live

qubes-live

%end

%post

# enable tmpfs for /tmp
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
varcacheyum /var/cache/yum  tmpfs   mode=0755,context=system_u:object_r:rpm_var_cache_t:s0   0   0
EOF

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
echo "Packages within this LiveCD"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# save a little bit of space at least...
rm -f /boot/initramfs*
# make sure there aren't core files lying around
rm -f /core*

# convince readahead not to collect
# FIXME: for systemd

# forcibly regenerate fontconfig cache (so long as this live image has
# fontconfig) - see #1169979
if [ -x /usr/bin/fc-cache ] ; then
   fc-cache -f
fi

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated


#
# setup Qubes
#

# TODO: appmenus

# we won't do `useradd qubes`, since his creation depends of persistent home
# feature; see /etc/rc.d/init.d/livesys

qvm-create  --offline-mode --force-root --net --label red sys-net
qvm-create  --offline-mode --force-root --proxy --label green sys-firewall

qvm-prefs   --offline-mode --force-root --set sys-firewall netvm sys-net
qubes-prefs --set default-netvm sys-firewall

qvm-create  --offline-mode --force-root work --label green
qvm-create  --offline-mode --force-root banking --label green
qvm-create  --offline-mode --force-root personal --label yellow
qvm-create  --offline-mode --force-root untrusted --label red

chgrp -R qubes /var/lib/qubes
chmod -R g+w /var/lib/qubes

%end


%post --nochroot
cp $INSTALL_ROOT/usr/share/licenses/*-release/* $LIVE_ROOT/

# only works on x86, x86_64
if [ "$(uname -i)" = "i386" -o "$(uname -i)" = "x86_64" ]; then
  if [ ! -d $LIVE_ROOT/LiveOS ]; then mkdir -p $LIVE_ROOT/LiveOS ; fi
  cp /usr/bin/livecd-iso-to-disk $LIVE_ROOT/LiveOS
fi
%end
