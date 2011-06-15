Gentoo ZFS Overlay
==================

This project provides a Gentoo overlay to provide ebuilds for SPL and ZFS from Brian Behlendorf's ZFSonLinux port.  This ebuilds are forked from those provided in the Gentoo Science overlay.  This fork tracks work done to better integrate ZFS with Gentoo's filesystem structure and to match work done to genkernel to get a working Root on ZFS.

Currently these ebuilds pull from Pendor's fork of ZFS on github.  This fork currently exists to track build changes to make ZFS FHS compliant.  These ebuilds track the fork rather than following the taking usual Gentoo path of providing patches against upstream as the goal is to quickly submit the relevant patches to upstream and end this forked overlay as soon as practical.