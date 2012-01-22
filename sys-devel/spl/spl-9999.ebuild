# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

WANT_AUTOMAKE="1.11"
AT_M4DIR=./config  # for aclocal called by eautoreconf

DESCRIPTION="Solaris Porting Layer - a Linux kernel module providing some Solaris kernel APIs"
HOMEPAGE="http://zfsonlinux.org/"

LICENSE="|| ( GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND=""
RDEPEND=""

if [[ ${PV} == 9999* ]] ; then
	SRC_URI=""
	EGIT_REPO_URI="https://github.com/zfsonlinux/spl.git"
	inherit git-2 linux-info eutils autotools linux-mod
else
	MY_P=${P/_rc/-rc}
	inherit linux-info eutils autotools linux-mod
	SRC_URI="mirror://gentoo/${MY_P}.tar.gz
									https://github.com/downloads/zfsonlinux/spl/${MY_P}.tar.gz"
	S=${WORKDIR}/${MY_P}
fi

src_unpack() {
	if [[ ${PV} == 9999* ]] ; then
		git-2_src_unpack
	else
		unpack ${MY_P}.tar.gz
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
		--exec-prefix=/
}

src_install() {
	emake DESTDIR="${D}" install || die 'emake install failed'
	dosym /usr/include/spl/spl_config.h /usr/include/spl/module/spl_config.h \
		|| die
}
