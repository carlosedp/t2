#!/bin/sh
#
# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/misc/archive/getdefs.sh
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

for x in unix linux i386 alpha powerpc ppc gnuc \
         intel_compiler ; do
	for y in $x __${x}__ _${x}_ __$x _$x ; do
		for z in $y $( echo $y | tr a-z A-Z ) ; do
			echo "X$z $z" >> /tmp/$$.c
		done
	done
done

echo "== ${1:-cc} -E =="
${1:-cc} -E /tmp/$$.c | egrep -xv '(X(.*) \2|#.*)' | \
	cut -c2- | sed 's, ,	,' | expand -20
rm -f /tmp/$$.c

