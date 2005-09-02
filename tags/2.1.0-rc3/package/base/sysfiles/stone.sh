#!/bin/bash
#
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../sysfiles/stone.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# Copyright (C) 1998 - 2003 ROCK Linux Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

export SETUPD="${SETUPD:-/etc/stone.d}"
if type -p dialog > /dev/null ; then 
	export SETUPG="${SETUPG:-dialog}"
else
	export SETUPG="${SETUPG:-text}"
fi
export STONE="`type -p $0`"

if [ "$1" = "-text"   ] ; then SETUPG="text"   ; shift ; fi
if [ "$1" = "-dialog" ] ; then SETUPG="dialog" ; shift ; fi
if [ "$1" = "-x11"    ] ; then SETUPG="x11"    ; shift ; fi

. ${SETUPD}/gui_${SETUPG}.sh

if [ "$1" -a -f "${SETUPD}/mod_$1.sh" ]
then
	. ${SETUPD}/mod_$1.sh ; shift
	if [ -z "$*" ] ; then
		main
	else
		eval "$*"
	fi
elif [ "$#" = 0 -a -f ${SETUPD}/default.sh ]
then
	. ${SETUPD}/default.sh
elif [ "$#" = 0 ]
then
	while
		command="gui_menu main 'Main Menu - Select the Subsystem you want to configure'"
		while read a b c cmd name ; do
			x="'" ; cmd="${cmd//,/ }"
			command="$command '${name//$x/$x\\$x$x}'"
			command="$command '$STONE ${cmd//$x/$x\\$x$x}'"
		done < <( grep -h '^# \[MAIN\] [0-9][0-9] ' \
						$SETUPD/mod_*.sh | sort )
		eval "$command"
	do : ; done
else
	echo
	echo "STONE - Setup Tool ONE - System Configuration"
	echo
	echo "Usage: $0 [ -text | -dialog | -x11 ] [ module [ command ] ]"
	echo
fi

