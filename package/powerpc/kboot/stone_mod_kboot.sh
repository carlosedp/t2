# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../kboot/stone_mod_kboot.sh
# Copyright (C) 2004 - 2020 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
#
# [MAIN] 70 kmoot kBoot Loader Setup
# [SETUP] 90 kboot

create_kernel_list() {
	first=1
	for x in `(cd /boot/; ls vmlinux_* ) | sort -r`; do
		if [ $first = 1 ]; then
			label=t2sde; first=0
		else
			label=t2sde-${x/vmlinux_/}
		fi
		ver=${x/vmlinux_}
		cat << EOT
$label='$bootpath/$x initrd=$bootpath/initrd-${ver}.img root=$rootdev' # video=ps3fb:mode:13
EOT
	done
}

create_kboot_conf() {
	mkdir -p $etcpath/etc/
	create_kernel_list > $etcpath/etc/kboot.conf

	gui_message "This is the new $etcpath/etc/kboot.conf file:

$(< $etcpath/etc/kboot.conf)"
}

device4() {
	local dev="`sed -n "s,\([^ ]*\) $1 .*,\1,p" /proc/mounts | tail -n 1`"
	if [ ! "$dev" ]; then # try the higher dentry
		local try="`dirname $1`"
		dev="`grep \" $try \" /proc/mounts | tail -n 1 | \
		      cut -d ' ' -f 1`"
	fi
	if [ -h "$dev" ]; then
	  echo "/dev/`readlink $dev`"
	else
	  echo $dev
	fi
}

realpath() {
	dir="`dirname $1`"
	file="`basename $1`"
	dir="`dirname $dir`/`readlink $dir`"
	dir="`echo $dir | sed 's,[^/]*/\.\./,,g'`"
	echo $dir/$file
}

main() {
	rootdev="`device4 /`"
	bootdev="`device4 /boot`"

	[ "$rootdev" != "$bootdev" ] && etcpath=/boot || bootpath=/boot

	if [ ! -f /boot/etc/kboot.conf ]; then
	  if gui_yesno "kBoot does not appear to be configured.
Automatically configure kboot now?"; then
	    create_kboot_conf
	  fi
	fi

	while

	gui_menu kboot 'kBoot Loader Setup' \
		"Following settings only for expert use: (default)" ""\
		"Root Device ........... $rootdev" "" \
		"Boot Device ........... $bootdev" "" \
		'' '' \
		"(Re-)Create default $etcpath/etc/kboot.conf" 'create_kboot_conf' \
		'' '' \
		"Edit $etcpath/etc/kboot.conf (Config file)" \
		"gui_edit 'kBoot Configurationp' $etcpath/etc/kboot.conf"
    do : ; done
}
