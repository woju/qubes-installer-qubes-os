Name:		qubes-dist-upgrade
Version:	1.0
Release:	1%{?dist}
Summary:	Upgrade tool for Qubes dom0

Group:		System
License:	GPL
URL:		http://www.qubes.org/
Source0:	qubes-dist-upgrade-%{version}.tar.bz2

%description
Tool to preform update Qubes dom0 from R1 to R2.


%prep
%setup -q

%build


%install
mkdir -p $RPM_BUILD_ROOT/usr/share/dracut/modules.d
cp -a 30convertfs $RPM_BUILD_ROOT/usr/share/dracut/modules.d/

mkdir -p $RPM_BUILD_ROOT/usr/sbin
install qubes-dist-upgrade $RPM_BUILD_ROOT/usr/sbin/
mkdir -p $RPM_BUILD_ROOT/usr/libexec/qubes-dist-upgrade
install upgrade-stage1.sh $RPM_BUILD_ROOT/usr/libexec/qubes-dist-upgrade/
install upgrade-stage2.sh $RPM_BUILD_ROOT/usr/libexec/qubes-dist-upgrade/
mkdir -p $RPM_BUILD_ROOT/etc/yum.repos.d
install -m 644 qubes-upgrade.repo $RPM_BUILD_ROOT/etc/yum.repos.d/

mkdir -p $RPM_BUILD_ROOT/var/lib/qubes-dist-upgrade

%files
%defattr(-,root,root,-)
/usr/share/dracut/modules.d/30convertfs
/usr/sbin/qubes-dist-upgrade
/usr/libexec/qubes-dist-upgrade/upgrade-stage1.sh
/usr/libexec/qubes-dist-upgrade/upgrade-stage2.sh
/etc/yum.repos.d/qubes-upgrade.repo
%dir /var/lib/qubes-dist-upgrade

%changelog

