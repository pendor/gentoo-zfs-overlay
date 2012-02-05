# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit git-2 linux-mod autotools-utils multilib

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
	# Makefiles contain numerous cases of writing header files
	# to /usr/src, but they should probably live in /usr/include.
	einfo "Replacing /usr/src with /usr/include"
	sed -i "s:usr/src/zfs-\\\$\\\$release/\\\$(LINUX_VERSION):\\\${includedir}/zfs-linux/:g" \
		${S}/Makefile.am
		
	find ${S} -name Makefile.am -exec \
		sed -i "s:/usr/src/zfs-\\\$(ZFS_META_VERSION)-\\\$(ZFS_META_RELEASE)/\\\$(LINUX_VERSION):\\\${includedir}/zfs-linux/:g" "{}" \;
	
	# Detect install dir for Dracut modules
	epatch "${FILESDIR}"/${PN}-9999-dracut-location.patch
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
		--libdir=/$(get_libdir)
		--bindir=/bin
		--sbindir=/sbin
	)
	autotools-utils_src_configure
}

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
