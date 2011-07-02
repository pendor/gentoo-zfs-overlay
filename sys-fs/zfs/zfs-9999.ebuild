# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

WANT_AUTOMAKE="1.11"
AT_M4DIR=./config  # for aclocal called by eautoreconf

EGIT_REPO_URI="http://github.com/pendor/zfs.git"

inherit autotools eutils git-2 linux-mod

DESCRIPTION="Native ZFS for Linux"
HOMEPAGE="http://wiki.github.com/behlendorf/zfs/"
SRC_URI=""

LICENSE="CDDL GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND="
		>=sys-devel/spl-${PV}
		>=virtual/linux-sources-2.6
		"
RDEPEND="
		!sys-fs/zfs-fuse
		"

RESTRICT="bindist"

pkg_setup() {
	linux-mod_pkg_setup
	kernel_is gt 2 6 32 || die "Your kernel is too old. ${CATEGORY}/${PN} need 2.6.32 or newer."
	linux_config_exists || die "Your kernel sources are unconfigured."
	if linux_chkconfig_present PREEMPT; then
		eerror "${CATEGORY}/${PN} doesn't currently work with PREEMPT kernel."
		eerror "Please look at bug https://github.com/behlendorf/zfs/issues/83"
		die "PREEMPT kernel"
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.6.0-includedir.patch
	eautoreconf
}

src_configure() {
	set_arch_to_kernel
	econf \
		--with-config=all \
		--with-linux="${KERNEL_DIR}" \
		--with-linux-obj="${KERNEL_DIR}" \
		--with-spl=/usr/include/spl \
		--with-spl-obj=/usr/include/spl/module \
		--exec-prefix=/ --libexecdir=/usr/libexec
}

src_compile() {
	set_arch_to_kernel
	default # _not_ the one from linux-mod
}

src_install() {
	emake DESTDIR="${D}" install || die 'emake install failed'
	# Drop unwanted files
	rm -rf "${D}/usr/src" || die "removing unwanted files die"
	
	# This is kind of messy, but we have our dracut modules, and genkernel
	# will need them later.
	insinto /usr/share/genkernel/modules
	doins -r dracut/90zfs
	
	# Can't install static libs or libtool files
	find "${D}" -name \*.la -delete
	find "${D}" -name \*.a -delete
}

pkg_postinst() {
  # Create write the hostid only if it doesn't exist.
  # This is done outside of packaging since we don't want it
  # deleted on remerge/upgrades.
  if [ ! -f /etc/hostid ] ; then
    hostid > /etc/hostid
    
    elog "A new /etc/hostid file has been created.  This file provides the hostid"
    elog "used by ZFS to determine if a pool being considered for import was last"
    elog "used by the current host.  Non-exported pools can only be imported if"
    elog "the pool's last hostid matches that of the current host."
    ewarn " "
    ewarn "Changing or deleting /etc/hostid after creating ZFS pools may leave"
    ewarn "pools un-importable or cause the system to fail to boot."
    ewarn " "
  fi
}

