Gentoo ZFS Overlay
==================

This project provides a Gentoo overlay to provide ebuilds for SPL and ZFS from Brian Behlendorf's ZFSonLinux port.  This ebuilds are forked from those provided in the Gentoo Science overlay.  This fork tracks work done to better integrate ZFS with Gentoo's filesystem structure and to match work done to genkernel to get a working Root on ZFS.

Currently these ebuilds pull from Pendor's fork of ZFS on github.  This fork currently exists to track build changes to make ZFS FHS compliant.  These ebuilds track the fork rather than following the taking usual Gentoo path of providing patches against upstream as the goal is to quickly submit the relevant patches to upstream and end this forked overlay as soon as practical.

Using this overlay
------------------

Please be aware that the following instructions assume a certain level of expertise using Portage and Genkernel.  Before running these commands, you should at a bare minimum backup your existing kernel & initramfs and create failsafe entries in your grub.conf to use those backups for when things fail miserably.

> This is (at best) experimental code, and it can easily leave your system in an unbootable state.  Have a LiveCD standing by...

Edit /etc/layman/layman.cfg.  Add under the overlays line:

	https://raw.github.com/pendor/gentoo-zfs-overlay/master/overlay.xml

Fetch remote overlays:

	layman -f

Add the ZFS overlay:

	layman -a zfs

Keep the overlay up to date from git:

	layman -s zfs

Unmask packages:

	echo "sys-devel/spl **" >> /etc/portage/package.keywords
	echo "sys-fs/zfs **" >> /etc/portage/package.keywords
	echo "sys-kernel/genkernel **" >> /etc/portage/package.keywords

Install:

	emerge -vp =sys-devel/spl-9999 =sys-fs/zfs-9999 =sys-kernel-genkernel-9999

Enable ZFS support in genkernel:

	echo 'ZFS="yes"' >> /etc/genkernel.conf

Build it:

	genkernel all

Enable ZFS at boot:

	Add 'dozfs' to your kernel command line in grub.conf

The first discovered zpool with a bootfs attribute set will have that FS mounted as root.  You should omit the real_root parameter to allow auto-detection.

If manual configuration of root is preferred over auto based on zpool properties, then set something like:

	real_root=ZFS=rpool/ROOT
