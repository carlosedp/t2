# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/package/*/grub/stone_mod_grub.sh
# Copyright (C) 1998 - 2003 ROCK Linux Project
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. A copy of the GNU General Public
# License can be found at Documentation/COPYING.
# 
# Many people helped and are helping developing ROCK Linux. Please
# have a look at http://www.rocklinux.org/ and the Documentation/TEAM
# file for details.
# 
# --- ROCK-COPYRIGHT-NOTE-END ---
#
# [MAIN] 70 grub GRUB Boot Loader Setup

create_kernel_list() {
	first=1
	for x in `(cd /boot/ ; ls vmlinuz_* ) | sort -r` ; do
		ver=${x/vmlinuz_/}
		if [ $first = 1 ] ; then
			label=linux ; first=0
		else
			label=linux-$ver
		fi

		cat << EOT

title  $label
kernel $bootdrive$bootpath/$x root=$rootdev ro
initrd $bootdrive$bootpath/initrd-${ver}.img
EOT
	done
}

create_device_map() {
	gui_cmd '(Re-)Create GRUB Device Map' "$( cat << "EOT"
rm -vf /boot/grub/device.map
echo quit | grub --batch --device-map=/boot/grub/device.map
EOT
	)"
}

convert_device () {
    device="$1"

    # extract device type (block) and major number for root drive
    user_drive_maj=`ls -Ll $device |
    awk '{if ($6 < 64) printf("%c%d0", $1, $5); else printf("%c%d1", $1, $5)}'`

    # does your bios know about the above drive?
    for bios_drive in `grep -v '^#' /boot/grub/device.map|awk '{print $2}'`; do
    bios_drive_maj=`ls -l $bios_drive |
    awk '{if ($6 < 64) printf("%c%d0", $1, $5); else printf("%c%d1", $1, $5)}'`

    if [ "$user_drive_maj" = "$bios_drive_maj" ]; then
	# yupi ya yeh! we found your drive!
	root_drive=`grep $bios_drive /boot/grub/device.map | awk '{print $1}'`
	    tmp_part=`ls -Ll $device | awk '{print $6}'`
	break
    fi
    done

    # convert the partition number to GRUB style
    if [ $tmp_part -gt 64 ]; then
	# hd[bdfh]
	# this doesn't handle the disk itself correctly - just the partitions
	root_part=$[$tmp_part-65]
    else
    root_part=$[$tmp_part-1]
    fi 
    unset tmp_part

    drive=`echo $root_drive | sed "s:)$:,$root_part):"`
    # Do we need some user confirmation to this result???
    # ...
    unset device
    echo $drive
}

create_boot_menu() {
	cat << EOT > /boot/grub/menu.lst
timeout 8
default 0
fallback 1
EOT
	create_kernel_list >> /boot/grub/menu.lst

	cat << EOT >> /boot/grub/menu.lst

title  MemTest86 (memory tester)
kernel $bootdrive$bootpath/memtest86.bin
EOT

	gui_message "This is the new /boot/grub/menu.lst file:

$( cat /boot/grub/menu.lst )"
}

grub_install() {
	gui_cmd 'Installing GRUB' "echo -e 'root $bootdrive\\nsetup (hd0)\\nquit' | grub --batch --device-map=/boot/grub/device.map"
}

main() {
    while
	rootdev="`grep ' / ' /proc/mounts | tail -n 1 | \
				awk '/\/dev\// { print $1; }'`"
	bootdev="`grep ' /boot ' /proc/mounts | tail -n 1 | \
				awk '/\/dev\// { print $1; }'`"
	[ -z "$bootdev" ] && bootdev="$rootdev"

	i=0
	rootdev="$( cd `dirname $rootdev` ; pwd -P )/$( basename $rootdev )"
	while [ -L $rootdev ] ; do
		directory="$( cd `dirname $rootdev` ; pwd -P )"
		rootdev="$( ls -l $rootdev | sed 's,.* -> ,,' )"
		[ "${rootdev##/*}" ] && rootdev="$directory/$rootdev"
		i=$(( $i + 1 )) ; [ $i -gt 20 ] && rootdev="Not found!"
	done

	i=0
	bootdev="$( cd `dirname $bootdev` ; pwd -P )/$( basename $bootdev )"
	while [ -L $bootdev ] ; do
		directory="$( cd `dirname $bootdev` ; pwd -P )"
		bootdev="$( ls -l $bootdev | sed 's,.* -> ,,' )"
		[ "${bootdev##/*}" ] && bootdev="$directory/$bootdev"
		i=$(( $i + 1 )) ; [ $i -gt 20 ] && bootdev="Not found!"
	done

	if [ -s /boot/grub/device.map ] ; then
		rootdrive=`convert_device $rootdev`
		bootdrive=`convert_device $bootdev`
	else
		rootdrive='No Device Map found!'
		bootdrive='No Device Map found!'
	fi

	if [ "$rootdrive" = "$bootdrive" ]
	then bootpath="/boot" ; else bootpath="" ; fi

        gui_menu grub 'GRUB Boot Loader Setup' \
		'(Re-)Create GRUB Device Map' 'create_device_map' \
		"Root Device ... $rootdev" "" \
		"Boot Drive .... $bootdrive$boot_path" "" \
		'' '' \
		'(Re-)Create default boot menu' 'create_boot_menu' \
		'(Re-)Install GRUB in MBR of (hd0)' 'grub_install' \
		'' '' \
		"Edit /boot/grub/device.map (Device Map)" \
			"gui_edit 'GRUB Device Map' /boot/grub/device.map" \
		"Edit /boot/grub/menu.lst (Boot Menu)" \
			"gui_edit 'GRUB Boot Menu' /boot/grub/menu.lst"
    do : ; done
}

