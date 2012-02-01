# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit git-2 linux-mod autotools-utils

DESCRIPTION="The Solaris Porting Layer is a Linux kernel module which provides many of the Solaris kernel APIs"
HOMEPAGE="http://zfsonlinux.org/"
SRC_URI=""
EGIT_REPO_URI="git://github.com/zfsonlinux/spl.git"

LICENSE="|| ( GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="!sys-devel/spl"

AT_M4DIR="config"
AUTOTOOLS_AUTORECONF="1"
AUTOTOOLS_IN_SOURCE_BUILD="1"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.6.0-rc6-includedir.patch
	eautoreconf
}

src_configure() {
	set_arch_to_kernel
	local myeconfargs=(
		--with-config=all
		--with-linux="${KV_DIR}"
		--with-linux-obj="${KV_OUT}"
	)
	autotools-utils_src_configure
}

pkg_preinst() {
	# Need to link in the spl_config header or zfs can't find the version.
	find "${D}/usr/include/" -type f -exec chmod a-x "{}" \;
	dosym /usr/include/spl/spl_config.h /usr/include/spl/module/spl_config.h
}
