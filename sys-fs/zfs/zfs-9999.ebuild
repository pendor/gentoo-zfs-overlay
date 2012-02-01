# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit git-2 linux-mod autotools-utils

DESCRIPTION="Native ZFS for Linux"
HOMEPAGE="http://zfsonlinux.org/"
SRC_URI=""
EGIT_REPO_URI="git://github.com/zfsonlinux/zfs.git"

LICENSE="CDDL GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="static-libs"

DEPEND=">=sys-kernel/spl-${PV}"
RDEPEND="${DEPEND}
	!sys-fs/zfs-fuse"

AT_M4DIR="config"
AUTOTOOLS_AUTORECONF="1"
AUTOTOOLS_IN_SOURCE_BUILD="1"

pkg_setup() {
	linux-mod_pkg_setup
	kernel_is ge 2 6 32 || die "Your kernel is too old. ${CATEGORY}/${PN} need 2.6.32 or newer."
	linux_config_exists || die "Your kernel sources are unconfigured."
	CONFIG_CHECK="!PREEMPT !DEBUG_LOCK_ALLOC KALLSYMS"
	check_extra_config
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.6.0-rc6-includedir.patch

	# Fix install dir for Dracut modules
	sed -i "s:\\\$(datadir)/dracut/:${EPREFIX}/usr/lib/dracut/:" \
		"${S}"/dracut/90zfs/Makefile.am || die
	eautoreconf
}

src_configure() {
	set_arch_to_kernel
	local myeconfargs=(
		--with-config=all
		--with-linux="${KV_DIR}"
		--with-linux-obj="${KV_OUT}"
		--with-spl=/usr/include/spl
		--with-spl-obj=/usr/include/spl/module
		--libexecdir=/usr/libexec
		--with-udevdir=/lib/udev
	)
	autotools-utils_src_configure
}

#src_compile() {
#	set_arch_to_kernel
#	default # _not_ the one from linux-mod
#}

#src_install() {
#	emake DESTDIR="${D}" install || die 'emake install failed'
#	# Drop unwanted files
#	rm -rf "${D}/usr/src" || die "removing unwanted files die"
#
#	# Can't install static libs or libtool files
#	find "${D}" -name \*.la -delete
#	find "${D}" -name \*.a -delete
#}

pkg_postinst() {
	linux-mod_pkg_postinst
	
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
