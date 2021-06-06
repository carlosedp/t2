# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by scripts/Create-CopyPatch.
# 
# T2 SDE: target/share/initrd/build.sh
# Copyright (C) 2004 - 2021 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
#
#Description: Initial RAM disk (initrd) / RAM FS (initramfs)

# TODO: share code with livecd imager

set -e
imagelocation="$build_toolchain/rootfs"	# where the roofs is prepared

. $base/misc/target/functions.in

mkdir -p $imagelocation ; cd $imagelocation
# just in case it is still there from the last run
(umount proc ; umount dev) 2>/dev/null || true

echo "Creating root file-system file lists ..."
f=" $pkg_filter "
for pkg in `grep '^X ' $base/config/$config/packages | cut -d ' ' -f 5`; do
	# include the package?
	if [ "${f/ $pkg /}" == "$f" ] ; then
		cut -d ' ' -f 2 $build_root/var/adm/flists/$pkg 2>/dev/null || true
	fi
done > ../files-wanted
unset f
[ "$filter_hook" ] && "$filter_hook" ../files-wanted
sort -u ../files-wanted > x ; mv -f x ../files-wanted

# for rsync with --delete we can not use file lists, since rsync does not
# delete in that mode - instead we need to generate a negative list
time find $build_root -mount -wholename $build_root/TOOLCHAIN -prune -o -printf '%P\n' |
	sort -u > ../files-all
# the difference
diff -u ../files-all ../files-wanted |
sed -n -e '/var\/adm\/olist/d' -e '/var\/adm\/logs/d' \
       -e '/var\/adm\/dep-debug/d' -e '/var\/adm\/cache/d' -e 's/^-//p' > ../files-exclude
echo "TOOLCHAIN
proc/*
dev/*
*/share/doc/*
var/adm/olist
var/adm/logs
var/adm/dep-debug
var/adm/cache" >> ../files-exclude

echo "Syncing root file-system (this may take some time) ..."
[ -e $imagelocation/bin ] && v="-v" || v=""
time rsync -artH $v --devices --specials --delete --delete-excluded \
     --exclude-from ../files-exclude $build_root/ $imagelocation/
rm ../files-{wanted,all,exclude}

echo "Overlaying root file-system with target defined files ..."
copy_and_parse_from_source $base/target/share/initrd/rootfs $imagelocation
[ -e $base/target/$target/rootfs ] &&
	copy_and_parse_from_source $base/target/$target/rootfs $imagelocation

[ "$inject_hook" ] && "$inject_hook"

if false; then
echo "Running ldconfig and other postinstall scripts ..."
mount /dev dev --bind
mount none proc -t proc
for x in sbin/ldconfig etc/postinstall.d/*; do
	cat > $$.sh <<-EOT
		. /etc/profile
		$x
EOT
	chmod +x $$.sh
	case $x in
		*/scrollkeeper) echo "$x left out" ;;
		*) chroot . /bin/sh -c ". /etc/profile; /$x" && true ;;
	esac
	rm $$.sh
done
umount proc
umount dev
fi

echo "Compression root file-system (this may take some time) ..."
time find . | cpio -o -H newc | gzip -c9 > $imagelocation/../initrd
du -sh $imagelocation/../initrd

# For each available kernel:
#
mkdir -p $imagelocation/../boot/
for x in `egrep 'X .* KERNEL .*' $base/config/$config/packages |
          cut -d ' ' -f 5`; do
 kernel=${x/_*/}
 for moduledir in `grep lib/modules $build_root/var/adm/flists/$kernel |
                   cut -d ' ' -f 2 | cut -d / -f 1-3 | uniq`; do
  kernelver=${moduledir/*\/}
  initrd="initrd-$kernelver"
  kernelimg=`ls $build_root/boot/vmlinu?-$kernelver`
  kernelimg=${kernelimg##*/}

  cp $build_root/boot/vmlinu?-$kernelver $imagelocation/../boot/
  cp $imagelocation/../initrd $imagelocation/../boot/$initrd
 done
done