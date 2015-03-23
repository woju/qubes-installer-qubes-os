ifeq ($(PACKAGE_SET),dom0)
RPM_SPEC_FILES := \
	pykickstart/pykickstart.spec \
	anaconda/anaconda.spec \
	firstboot/firstboot.spec \
	qubes-release/qubes-release.spec \
	lorax-templates-qubes/lorax-templates-qubes.spec \
	pungi/pungi.spec \
	qubes-release/qubes-dom0-dist-upgrade.spec
endif
