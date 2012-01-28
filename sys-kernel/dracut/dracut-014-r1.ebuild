# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/dracut/dracut-014-r1.ebuild,v 1.2 2012/01/12 16:41:30 aidecoe Exp $

EAPI=4

inherit eutils

DESCRIPTION="Generic initramfs generation tool"
HOMEPAGE="http://dracut.wiki.kernel.org"
SRC_URI="mirror://kernel/linux/utils/boot/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
REQUIRED_USE="dracut_modules_livenet? ( dracut_modules_dmsquash-live )
	dracut_modules_crypt-gpg? ( dracut_modules_crypt )
	"

COMMON_MODULES="
	dracut_modules_biosdevname
	dracut_modules_btrfs
	dracut_modules_caps
	dracut_modules_crypt-gpg
	dracut_modules_gensplash
	dracut_modules_mdraid
	dracut_modules_multipath
	dracut_modules_plymouth
	dracut_modules_syslog
	"
NETWORK_MODULES="
	dracut_modules_iscsi
	dracut_modules_livenet
	dracut_modules_nbd
	dracut_modules_nfs
	"
DM_MODULES="
	dracut_modules_crypt
	dracut_modules_dmraid
	dracut_modules_dmsquash-live
	dracut_modules_livenet
	dracut_modules_lvm
	"
IUSE_DRACUT_MODULES="${COMMON_MODULES} ${DM_MODULES} ${NETWORK_MODULES}"
IUSE="debug selinux ${IUSE_DRACUT_MODULES}"
RESTRICT="test"

NETWORK_DEPS=">=net-misc/dhcp-4.2.1-r1 sys-apps/iproute2"
DM_DEPS="|| ( sys-fs/device-mapper >=sys-fs/lvm2-2.02.33 )"

RDEPEND="
	>=app-shells/bash-4.0
	>=app-shells/dash-0.5.4.11
	>=sys-apps/baselayout-1.12.14-r1
	>=sys-apps/module-init-tools-3.8
	>=sys-apps/sysvinit-2.87-r3
	>=sys-apps/util-linux-2.16
	>=sys-fs/udev-164
	app-arch/cpio

	debug? ( dev-util/strace )
	selinux? ( sys-libs/libselinux sys-libs/libsepol )
	dracut_modules_biosdevname? ( sys-apps/biosdevname )
	dracut_modules_btrfs? ( sys-fs/btrfs-progs )
	dracut_modules_caps? ( sys-libs/libcap )
	dracut_modules_crypt? ( sys-fs/cryptsetup ${DM_DEPS} )
	dracut_modules_crypt-gpg? ( app-crypt/gnupg )
	dracut_modules_dmraid? ( sys-fs/dmraid sys-fs/multipath-tools ${DM_DEPS} )
	dracut_modules_dmsquash-live? ( ${DM_DEPS} )
	dracut_modules_gensplash? ( media-gfx/splashutils )
	dracut_modules_iscsi? ( >=sys-block/open-iscsi-2.0.871.3 ${NETWORK_DEPS} )
	dracut_modules_lvm? ( >=sys-fs/lvm2-2.02.33 )
	dracut_modules_mdraid? ( sys-fs/mdadm )
	dracut_modules_multipath? ( sys-fs/multipath-tools )
	dracut_modules_nbd? ( sys-block/nbd ${NETWORK_DEPS} )
	dracut_modules_nfs? ( net-fs/nfs-utils net-nds/rpcbind ${NETWORK_DEPS} )
	dracut_modules_plymouth? ( >=sys-boot/plymouth-0.8.3-r1 )
	dracut_modules_syslog? ( || ( app-admin/syslog-ng app-admin/rsyslog ) )
	"
DEPEND="
	>=dev-libs/libxslt-1.1.26
	app-text/docbook-xml-dtd:4.5
	>=app-text/docbook-xsl-stylesheets-1.75.2
	"

#
# Helper functions
#

# Returns true if any of specified modules is enabled by USE flag and false
# otherwise.
# $1 = list of modules (which have corresponding USE flags of the same name)
any_module() {
	local m modules=" $@ "

	for m in ${modules}; do
		! use $m && modules=${modules/ $m / }
	done

	shopt -s extglob
	modules=${modules%%+( )}
	shopt -u extglob

	[[ ${modules} ]]
}

# Removes module from modules.d.
# $1 = module name
# Module name can be specified without number prefix.
rm_module() {
	local m

	for m in $@; do
		if [[ $m =~ ^[0-9][0-9][^\ ]*$ ]]; then
			rm -rf "${modules_dir}"/$m
		else
			rm -rf "${modules_dir}"/[0-9][0-9]$m
		fi
	done
}

# Displays Gentoo Base System major release number
base_sys_maj_ver() {
	local line

	read line < /etc/gentoo-release
	line=${line##* }
	echo "${line%%.*}"
}

#
# ebuild functions
#

src_prepare() {
	epatch "${FILESDIR}/${P}-multipath-udev-rules.patch"
	epatch "${FILESDIR}/${P}-usrmount-fsck-fix.patch"
	epatch "${FILESDIR}/${P}-zfs-hostonly-hang.patch"
}

src_compile() {
	emake WITH_SWITCH_ROOT=0
}

src_install() {
	emake WITH_SWITCH_ROOT=0 \
		prefix=/usr sysconfdir=/etc DESTDIR="${D}" \
		install

	local gen2conf

	dodir /var/lib/dracut/overlay
	dodoc HACKING TODO AUTHORS NEWS README*

	case "$(base_sys_maj_ver)" in
		1) gen2conf=gentoo.conf ;;
		2) gen2conf=gentoo-openrc.conf ;;
		*) die "Expected ver. 1 or 2 of Gentoo Base System (/etc/gentoo-release)."
	esac

	insinto /etc/dracut.conf.d
	newins dracut.conf.d/${gen2conf}.example ${gen2conf}

	insinto /etc/logrotate.d
	newins dracut.logrotate dracut

	#
	# Modules
	#
	local module
	modules_dir="${D}/usr/lib/dracut/modules.d"

	echo "${PF}" > "${modules_dir}"/10rpmversion/dracut-version \
		|| die 'dracut-version failed'

	# Remove modules not enabled by USE flags
	for module in ${IUSE_DRACUT_MODULES} ; do
		! use ${module} && rm_module ${module#dracut_modules_}
	done

	# Those flags are specific, and even are corresponding to modules, they need
	# to be declared as regular USE flags.
	use debug || rm_module 95debug
	use selinux || rm_module 98selinux

	! any_module ${DM_MODULES} && rm_module 90dm
	! any_module ${NETWORK_MODULES} && rm_module 45ifcfg 40network

	# Remove S/390 modules which are not tested at all
	rm_module 95dasd 95dasd_mod 95zfcp 95znet

	# Remove modules which won't work for sure
	rm_module 95fcoe # no tools
	# fips module depends on masked app-crypt/hmaccalc
	rm_module 01fips 02fips-aesni

	# Remove extra modules which go to future dracut-extras
	rm_module 00bootchart 05busybox 97masterkey 98ecryptfs 98integrity
}

pkg_postinst() {
	elog 'To generate the initramfs:'
	elog '    # mount /boot (if necessary)'
	elog '    # dracut "" <kernel-version>'
	elog ''
	elog 'For command line documentation see dracut.kernel(7).'
	elog ''
	elog 'Simple example to select root and resume partition:'
	elog '    root=/dev/sda1 resume=/dev/sda2'
	elog ''
	elog 'The default config (in /etc/dracut.conf) is very minimal and is highly'
	elog 'recommended you adjust based on your needs. To include only dracut'
	elog 'modules and kernel drivers for this system, use the "-H" option.'
	elog 'Some modules need to be explicitly added with "-a" option even if'
	elog 'required tools are installed.'
	echo
	elog 'Options (documented in dracut.kernel(7)) have new format since'
	elog 'version 008. Old format is preserved, but will be removed in future.'
	elog 'Please migrate to the new one.'
	echo
	elog 'Some dependencies were removed, because they are optional. dracut'
	elog "will inform you with a warning when you're lacking something optional."
}
