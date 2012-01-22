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
	epatch "${FILESDIR}"/${PN}-0.6.0-rc6-includedir.patch
	eautoreconf
}

pkg_setup() {
	linux-mod_pkg_setup
	kernel_is gt 2 6 32 || die "Your kernel is too old. ${CATEGORY}/${PN} need 2.6.32 or newer."
	linux_config_exists || die "Your kernel sources are unconfigured."
	if ! linux_chkconfig_present PREEMPT_NONE; then
		eerror "${CATEGORY}/${PN} doesn't currently work with PREEMPT kernel."
		eerror "Please look at bug https://github.com/behlendorf/zfs/issues/83 ."
		die "PREEMPT kernel"
	fi
}

src_configure() {
	set_arch_to_kernel
	econf \
		--with-config=all \
		--with-linux="${KERNEL_DIR}" \
		--with-linux-obj="${KERNEL_DIR}"
}

src_compile()	{
	# Not sure why, but jumping straight to make install seems to leave
	# module/Module.symvers missing.  make, then make install works.
	set_arch_to_kernel
	emake || die 'emake install failed'
}

src_install() {
	set_arch_to_kernel
	emake DESTDIR="${D}" install || die 'emake install failed'
	find "${D}/usr/include/" -type f -exec chmod a-x "{}" \;
	dosym /usr/include/spl/spl_config.h /usr/include/spl/module/spl_config.h \
		|| die
}
