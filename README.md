Gentoo ZFS Overlay
==================

This project provides a Gentoo overlay to provide ebuilds for packages necessary to support ZFS on Gentoo from Brian Behlendorf's ZFSonLinux port.  This fork tracks work done to better integrate ZFS with Gentoo's filesystem structure and to match work done to genkernel to get a working Root on ZFS.

Note that at this time, this overly doesn't actually provide ebuilds for the spl or zfs packages themselves.  Both of those are now available from the main Portage tree.  This overly does provide builds for modified versions of Grub, Genkernel, and Dracut necessary to boot from a ZFS root device.

Using this overlay
------------------

Please be aware that the following instructions assume a certain level of expertise using Portage and Genkernel.  Before running these commands, you should at a bare minimum backup your existing kernel & initramfs and create failsafe entries in your grub.conf to use those backups for when things fail miserably.

> This is (at best) experimental code, and it can easily leave your system in an unbootable state.  Have a LiveCD standing by...

Add the ZFS overlay:

	layman -o https://raw.github.com/pendor/gentoo-zfs-overlay/master/overlay.xml -f -a zfs

Keep the overlay up to date from git:

	layman -s zfs

You'll probably need to unmask packages and make numerous other system changes to get things working at this point.  For semi-complete instructions, please see:

    https://github.com/pendor/gentoo-zfs-install

"Branching" Out
===============

This falls under general Gentoo knowledge, but if the need ever arises to run these ebuilds against a custom branch of the repo, it's possible to do so without hacking the ebuild files themselves using Portage's env folder combined with ebuild phase hooks.  For example, to build from Brian's private udev branch:

```
$ mkdir -p /etc/portage/env/sys-fs
$ cat > /etc/portage/env/sys-fs/zfs <<EOF
#!/bin/bash
pre_pkg_setup() {
  # Override to use Brian's testing repo
  EGIT_REPO_URI="https://github.com/behlendorf/zfs"
  EGIT_BRANCH="udev"
}
EOF
```

To go back to normal, just `rm /etc/portage/env/sys-fs/zfs`.

References:

* http://sergiosdj.wordpress.com/2008/06/24/how-to-personalize-a-packages-cflags-in-gentoo/
* http://dev.gentoo.org/~zmedico/portage/doc/portage.html#config-bashrc-ebuild-phase-hooks 
