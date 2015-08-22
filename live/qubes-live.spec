%if 0%{?qubes_builder}
%define _builddir %(pwd)/live
%endif

Name:       qubes-live
Version:    1.0
Release:    1%{?dist}
Summary:    Various fixes for Qubes Live edition

Group:      System
License:    GPL
URL:        https://qubes-os.org

%description
Various fixes for Qubes Live edition

%prep

%build

%install


install -d -m 0755 $RPM_BUILD_ROOT/etc/rc.d/init.d/
install -m 0755 -t $RPM_BUILD_ROOT/etc/rc.d/init.d/ \
    livesys \
    livesys-late

install -D -m 0644 lightdm-qubes-live.conf \
            $RPM_BUILD_ROOT/etc/lightdm/lightdm.conf.d/50-qubes-live.conf


install -D -m 0644 default-appmenus $RPM_BUILD_ROOT/usr/share/qubes/live-default-appmenus

install -d -m 0755 $RPM_BUILD_ROOT/etc/skel
cp -r skel/* $RPM_BUILD_ROOT/etc/skel/

%post

/sbin/restorecon /etc/rc.d/init.d/livesys
/sbin/chkconfig --add livesys

/sbin/restorecon /etc/rc.d/init.d/livesys-late
/sbin/chkconfig --add livesys-late

# livecd-tools expects strange xen.gz name
xen=$(ls -1 /boot/xen-*gz | tail -n 1)
for kernel in /boot/vmlinuz-*; do
    # see __copy_kernel_and_initramfs function in imgcreate/live.py
    version=$(echo ${kernel} | cut -f 2- -d -)
    short_version=$(echo -n ${version} | head -c -3)
    ln -s $(basename ${xen}) /boot/xen.gz-${short_version}
done


%files
/etc/rc.d/init.d/livesys
/etc/rc.d/init.d/livesys-late
/etc/lightdm/lightdm.conf.d/50-qubes-live.conf
/usr/share/qubes/live-default-appmenus
/etc/skel/*

%changelog


