#!/bin/sh
#
# Convert an Old-Style ROCK Linux Extension to the standard package format.
#
# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/misc/archive/extconv.sh
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

if [ -z "$1" -o ! -f "$1.ext" ] ; then
	[ ! -f "$1.ext" ] && echo "No such file: $1.ext"
	echo "Usage: $0 <ext-name>"
	exit 1
fi

egrep '^# +\[' $1.ext | sed 's,^# *,,' | \
egrep -v '^\[(P|PRI|PRIORITY)\]' > $1.desc

pri=`{ egrep '^# +\[(P|PRI|PRIORITY)\] +' $1.ext ; echo ". . 5" ; } | head -1 | tr -s ' ' | cut -f3 -d' '`
echo "[P] X ------6--9 300.$pri" >> $1.desc

{
echo "#"
echo "# Converted from $name.ext by <rock-base>/misc/archive/extconv.sh"
echo "#"
echo
echo 'if [ "$prefix" != "opt/$pkg" ] ; then'
echo '	abort "!! This package is converted from an old-style .ext file and'
echo '!! might only compile fine when built with the Build-Pkg'
echo '!! option \"-prefix /opt/$pkg\"."'
echo 'fi'
echo
echo "main() {"
egrep -v '^# +\[' $1.ext
echo "}"
echo
echo "autoextract=0"
echo "custmain=main"
echo
} > $1.conf

