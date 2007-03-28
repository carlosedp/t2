#!/bin/bash
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: target/livecd/build_image.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

. $base/misc/target/functions.in

set -e

mkdir -p $imagelocation ; cd $imagelocation
# just in case it is still there from the last run
(umount proc ; umount dev) 2>/dev/null

echo "Creating root file-system file lists ..."

pkg_skip=" ccache distcc "
for pkg in `grep '^X ' $base/config/$config/packages | cut -d ' ' -f 5`; do
	# include the package?
	if [ "${pkg_skip/ $pkg /}" == "$pkg_skip" ] ; then
		cut -d ' ' -f 2 $build_root/var/adm/flists/$pkg || true
	fi
done | (
	# quick and dirty filter
	grep  -v -e 'lib/[^/]*\.a$'
) | sort -u > ../files-wanted

# for rsync with --delete we can not use file lists, since rsync does not
# delete in that mode - instead we need to generate a negative list

time find $build_root -mount -wholename $build_root/TOOLCHAIN -prune -o -printf '%P\n' |
	sort -u > ../files-all
# the difference
diff -u ../files-all ../files-wanted |
sed -n -e '/var\/adm\/olist/d' -e '/var\/adm\/logs/d' \
       -e '/var\/adm\/dep-debug/d' -e '/var\/adm\/cache/d' -e 's/^-//p' > ../files-exclude
echo "proc/*
dev/*
*/share/doc/*
var/adm/olist
var/adm/logs
var/adm/dep-debug
var/adm/cache" >> ../files-exclude

echo "Syncing root file-system (this may take some time) ..."
[ -e $imagelocation/bin ] && v="-v" || v=""
time rsync -artH $v --delete --exclude-from ../files-exclude \
      --exclude TOOLCHAIN --delete-excluded $build_root/ $imagelocation/
rm ../files-{wanted,all,exclude}

echo "Overlaying root file-system with target defined files ..."
copy_and_parse_from_source $base/target/share/livecd/rootfs $imagelocation
copy_and_parse_from_source $base/target/$target/rootfs $imagelocation

[ "$inject_hook" ] && "$inject_hook"

echo "Running ldconfig and other postinstall scripts ..."
mount /dev dev --bind
mount none proc -t proc
for x in sbin/ldconfig etc/postinstall.d/*; do
	case $x in
		*/scrollkeeper) echo "$x left out" ;;
		*) chroot . /$x && true
	esac
done
umount proc
umount dev

echo "Squashing root file-system (this may take some time) ..."
time mksquashfs * $isofsdir/live.squash -noappend
du -sh $isofsdir/live.squash

