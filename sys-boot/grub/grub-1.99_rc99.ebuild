# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-boot/grub/grub-9999.ebuild,v 1.34 2011/06/28 16:33:29 vapier Exp $

# XXX: need to implement a grub.conf migration in pkg_postinst before we ~arch
EAPI="2"

inherit mount-boot eutils flag-o-matic toolchain-funcs autotools
# bzr

# EBZR_REPO_URI="http://bzr.savannah.gnu.org/r/grub/branches/release_1_99/"
# SRC_URI=""

MY_P=${P/_rc99/}
SRC_URI="http://ftp.gnu.org/gnu/${PN}/${MY_P}.tar.gz
				mirror://gentoo/${MY_P}.tar.gz"
S="${WORKDIR}"/${MY_P}

DESCRIPTION="GNU GRUB boot loader"
HOMEPAGE="http://www.gnu.org/software/grub/"

LICENSE="GPL-3"
use multislot && SLOT="2" || SLOT="0"
KEYWORDS=""
IUSE="custom-cflags debug device-mapper multislot static sdl truetype zfs"

RDEPEND=">=sys-libs/ncurses-5.2-r5
	dev-libs/lzo
	debug? (
		sdl? ( media-libs/libsdl )
	)
	device-mapper? ( >=sys-fs/lvm2-2.02.45 )
	truetype? ( media-libs/freetype >=media-fonts/unifont-5 )
	zfs? ( >=sys-fs/zfs-0.6.0_rc5 )"
# We'll dep on zfs only for now.  We need spl too, but there are differently
# named packages on circulation for that, and ZFS requires it anyways.

DEPEND="${RDEPEND}
	>=dev-lang/python-2.5.2 >=sys-devel/autogen-5.10 sys-apps/help2man"

export STRIP_MASK="*/grub/*/*.mod"
QA_EXECSTACK="sbin/grub-probe sbin/grub-setup sbin/grub-mkdevicemap bin/grub-script-check bin/grub-fstest"

src_prepare() {
	epatch "${FILESDIR}"/${MY_P}-010-zfs_packed_la_array.patch
	epatch "${FILESDIR}"/${MY_P}-020-zfs_update.patch
	epatch "${FILESDIR}"/${MY_P}-029-noman.patch
	epatch "${FILESDIR}"/${MY_P}-030-zfs_gentoo_build.patch
	epatch_user

	# autogen.sh does more than just run autotools
	# need to eautomake due to weirdness #296013
	sed -i -e '/^autoreconf/s:^:set +e; e:' autogen.sh || die
	(. ./autogen.sh) || die

	# install into the right dir for eselect #372735
	sed -i \
		-e '/^bashcompletiondir =/s:=.*:= $(datarootdir)/bash-completion:' \
		util/bash-completion.d/Makefile.in || die
}

src_configure() {
	use custom-cflags || unset CFLAGS CPPFLAGS LDFLAGS
	use static && append-ldflags -static

	econf \
		--disable-werror \
		--sbindir=/sbin \
		--bindir=/bin \
		--libdir=/$(get_libdir) \
		--disable-efiemu \
		$(use_enable device-mapper) \
		$(use_enable truetype grub-mkfont) \
		$(use_enable debug mm-debug) \
		$(use sdl && use_enable debug grub-emu-sdl) \
		$(use_enable debug grub-emu-usb)
}

src_compile() {
	emake -j1 || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog NEWS README THANKS TODO

	insinto /etc/defaults
	doins "${FILESDIR}"/defaults || die
	cat <<-EOF >> "${D}"/lib*/grub/grub-mkconfig_lib
	GRUB_DISTRIBUTOR="Gentoo"
	EOF

	if use multislot ; then
		sed -i "s:grub-install:grub2-install:" "${D}"/sbin/grub-install || die
		mv "${D}"/sbin/grub{,2}-install || die
		mv "${D}"/sbin/grub{,2}-set-default || die
		mv "${D}"/usr/share/man/man8/grub{,2}-install.8 || die
		mv "${D}"/usr/share/info/grub{,2}.info || die
	fi
}

setup_boot_dir() {
	local boot_dir=$1
	local dir=${boot_dir}/grub

	if [[ ! -e ${dir}/grub.cfg ]] ; then
		einfo "Running: grub-mkconfig -o '${dir}/grub.cfg'"
		grub-mkconfig -o "${dir}/grub.cfg"
	fi

	#local install=grub-install
	#use multislot && install="grub2-install --grub-setup=/bin/true"
	#einfo "Running: ${install} "
	#${install}
}

pkg_postinst() {
	mount-boot_mount_boot_partition

	if use multislot ; then
		elog "You have installed grub2 with USE=multislot, so to coexist"
		elog "with grub1, the grub2 install binary is named grub2-install."
	fi
	setup_boot_dir "${ROOT}"boot

	# needs to be after we call setup_boot_dir
	mount-boot_pkg_postinst
}
