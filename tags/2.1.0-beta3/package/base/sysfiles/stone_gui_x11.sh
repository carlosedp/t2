# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/package/*/sysfiles/stone_gui_x11.sh
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

if ! Xdialog --infobox 'Test' 0 0 1 ; then
	echo
	echo "Fatal ERROR: Can't display Xdialog windows!"
	echo
	echo "Maybe the \$DISPLAY variable is not set or you don't have"
	echo "permissions to connect to the X-Server."
	exit 1
fi

. ${SETUPD}/gui_dialog.sh

gui_dialog() {
        Xdialog --stdout --title 'STONE - Setup Tool ONE - T2 System Configuration' "$@"
}

gui_edit() {
	# find editor
	for x in $EDITOR vi nvi emacs xemacs pico ; do
		if which $x > /dev/null
		then xx=$x ; break ; fi
	done
	if [ "$xx" ] ; then
		xterm -T "STONE - $1" -n "STONE" -e bash -c "$xx $2"
	else
		gui_message "Cannot find any editor. Make sure \$EDITOR is set."
	fi
}

gui_cmd() {
	title="$1" ; shift
	xterm -T "STONE - $title" -n "STONE" -e bash -c "$@
			read -p 'Press ENTER to continue'"
}
