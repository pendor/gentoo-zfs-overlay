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

DEPEND="
		>=virtual/linux-sources-2.6
		"
RDEPEND=""

if [[ ${PV} == 9999* ]] ; then
  SRC_URI=""
  EGIT_REPO_URI="https://github.com/zfsonlinux/spl.git"
  inherit git-2 linux-info eutils autotools
else
  inherit linux-info eutils autotools
  SRC_URI="mirror://gentoo/${P/_rc/-rc}.tar.gz
                  https://github.com/downloads/zfsonlinux/spl/${P/_rc/-rc}.tar.gz"
fi

src_unpack() {
  if [[ ${PV} == 9999* ]] ; then
    git_src_unpack
  else
    unpack ${P/_rc/-rc}.tar.gz
    cd ${WORKDIR}
    mv ${P/_rc/-rc} ${P}
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
