# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/package/base/iproute2/stone_mod_network.sh
# ROCK Linux is Copyright (C) 1998 - 2003 Clifford Wolf
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
# [MAIN] 20 network Network (TCP/IP v4) Configuration

HOSTNAME="`hostname`"
DOMAINNAME="`hostname -d 2> /dev/null`"

DHCP="X" ; IF="X" ; IPADDR="X" ; GATEWAY="X" ; tmp="`mktemp`"
egrep '^(DHCP|IF|IPADDR|GATEWAY)=' /etc/conf/network > $tmp ; . $tmp

grep '^nameserver ' /etc/resolv.conf | tr '\t' ' ' | tr -s ' ' | \
    sed 's,^nameserver *\([^ ]*\),DNSSRV="$DNSSRV \1",' > $tmp
DNSSRV='' ; . $tmp ; DNSSRV="`echo $DNSSRV`"
[ -z "$DNSSRV" ] && DNSSRV="none" ; rm -f $tmp

set_name() {
	old1="$HOSTNAME" old2="$HOSTNAME.$DOMAINNAME" old3="$DOMAINNAME"
	if [ $1 = HOSTNAME ] ; then
		gui_input "Set a new hostname (without domain part)" \
		          "${!1}" "$1"
	else
		gui_input "Set a new domainname (without host part)" \
		          "${!1}" "$1"
	fi
	new="$HOSTNAME.$DOMAINNAME $HOSTNAME"

	echo "$HOSTNAME" > /etc/HOSTNAME ; hostname "$HOSTNAME"

	ip="`echo $IPADDR | sed 's,[/ ].*,,'`"
	if grep -q "^$ip\\b" /etc/hosts ; then
		tmp="`mktemp`"
		sed -e "/^$ip\\b/ s,\\b$old2\\b[ 	]*,,g" \
		    -e "/^$ip\\b/ s,\\b$old1\\b[ 	]*,,g" \
		    -e "/^$ip\\b/ s,[ 	]\\+,&$new ," < /etc/hosts > $tmp
		cat $tmp > /etc/hosts ; rm -f $tmp
	else
		echo -e "$ip\\t$new" >> /etc/hosts
	fi

	if [ $1 = DOMAINNAME ] ; then
		tmp="`mktemp`"
		grep -vx "search $old3" /etc/resolv.conf > $tmp
		[ -n "$DOMAINNAME" ] && echo "search $DOMAINNAME" >> $tmp
		cat $tmp > /etc/resolv.conf
		rm -f $tmp
	fi
}

set_dns() {
	gui_input "Set a new (space seperated) list of DNS Servers" "$DNSSRV" "DNSSRV"
	DNSSRV="`echo $DNSSRV`" ; [ -z "$DNSSRV" ] && DNSSRV="none"

	tmp="`mktemp`" ; grep -v '^nameserver\b' /etc/resolv.conf > $tmp
	for x in $DNSSRV ; do
		[ "$x" != "none" ] && echo "nameserver $x" >> $tmp
	done
	cat $tmp > /etc/resolv.conf
	rm -f $tmp
}

set_dhcp() {
	DHCP=$1 ; tmp="`mktemp`"
	sed "s,^DHCP=.*,DHCP=\"$1\"," < /etc/conf/network > $tmp
	cat $tmp > /etc/conf/network ; rm -f $tmp
}

set_if() {
	gui_input "Set a new network interface" "$IF" IF ; tmp="`mktemp`"
	sed "s,^IF=.*,IF=\"$IF\"," < /etc/conf/network > $tmp
	cat $tmp > /etc/conf/network ; rm -f $tmp
}

set_ip() {
	oldip="`echo $IPADDR | sed 's,[/ ].*,,'`"
	if [ $1 = IPADDR ] ; then
		gui_input "Set a new IP address or a whitespace seperated list
of IP addresses in the format A.B.C.D/NM (e.g. 192.168.20.17/24)" "$IPADDR" IPADDR
	else
		gui_input "Set a new gateway IP address (e.g. 192.168.20.1)" \
				"$GATEWAY" GATEWAY
	fi
	newip="`echo $IPADDR | sed 's,[/ ].*,,'`"

	sed -e "s,^IPADDR=.*,IPADDR=\"$IPADDR\"," \
	    -e "s,^GATEWAY=.*,GATEWAY=\"$GATEWAY\"," \
		< /etc/conf/network > $tmp
	cat $tmp > /etc/conf/network ; rm -f $tmp

	if [ "$newip" != "$oldip" ] ; then
		tmp="`mktemp`"
		sed -e "s,^$oldip\\b,$newip," < /etc/hosts > $tmp
		cat $tmp > /etc/hosts ; rm -f $tmp
	fi
}

edit() {
	gui_edit "Edit file $1" "$1"
	exec $STONE network
}

main() {
    while
	cmd="gui_menu network 'Network Configuration - Select an item to"
	cmd="$cmd change the value

WARNING: This script tries to adopt /etc/conf/network, /etc/hosts,
/etc/resolv.conf and /etc/HOSTNAME according to your changes. You
better be carefull if you also change this files by hand.'"

	cmd="$cmd 'Hostname:    $HOSTNAME'   'set_name HOSTNAME'"
	cmd="$cmd 'Domainname:  $DOMAINNAME' 'set_name DOMAINNAME'"
	cmd="$cmd 'DNS-Server:  $DNSSRV'     'set_dns' '' ''"

	if [ "$DHCP" = "X" ] ; then
		cmd="$cmd 'File /etc/conf/network has been changed.' ''"
		cmd="$cmd 'So no IP configuration is available here.' ''"
	elif [ "$DHCP" = "on" ] ; then
		cmd="$cmd '[*] Use DHCP for IP configuration' 'set_dhcp off'"
		cmd="$cmd 'Network Interface:  $IF' 'set_if'"
	else
		cmd="$cmd '[ ] Use DHCP for IP configuration' 'set_dhcp on'"
		cmd="$cmd 'Network Interface:  $IF' 'set_if'"
		cmd="$cmd 'Host IP Addresses:  $IPADDR'  'set_ip IPADDR'"
		cmd="$cmd 'Gateway IP Address: $GATEWAY' 'set_ip GATEWAY'"
	fi

	cmd="$cmd '' '' 'Configure runlevels for network service'"
	cmd="$cmd '$STONE runlevel edit_srv network'"
	cmd="$cmd '(Re-)Start network init script'"
	cmd="$cmd '$STONE runlevel restart network'"
	cmd="$cmd '' ''"

	cmd="$cmd 'View/Edit /etc/conf/network file' 'edit /etc/conf/network'"
	cmd="$cmd 'View/Edit /etc/hosts file'        'edit /etc/hosts'"
	cmd="$cmd 'View/Edit /etc/resolv.conf file'  'edit /etc/resolv.conf'"

	eval "$cmd"
    do : ; done
}

