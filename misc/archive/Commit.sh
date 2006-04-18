#!/bin/bash
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: misc/archive/Commit.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

if [ -z "$1" ] ; then
	echo "Usage $0 package/files"
	exit
fi

trap 'echo "Got SIGINT (Crtl-C)." ; rm $$.log ; exit 1' INT

locations=
for x; do
	[ ! -e "$x" -a -e `echo package/*/$x` ] &&
		x=`echo package/*/$x`
	locations="$locations $x"
done	
		
echo "Diff:"
svn diff $locations | tee $$.diff

# the grep -v === is a hack - somehow the svn === lines confuse awk ... ?!?
grep -v === $$.diff | awk "
	BEGIN { FS=\"[ /]\" }

	/^\+\+\+ / { pkg = \$4 }
	{ if (sub(/^\+\[I\]/,\" -\") ) { info = \$0 } }

	/^\-\[V\] / { oldver=\$2 }
	/^\+\[V\] / {
		newver=\$2
		if ( oldver )
		  print \"\t* updated \" pkg \" (\" oldver \" -> \" newver \")\"
		else {
		  print \"\t* added \" pkg \" (\" newver \")\" info
		}
		oldver=\"\" ; newver=\"\" ; info=\"\"
	}

" > $$.log

if [ -s $$.diff ]; then
quit=0
until [ $quit -ne 0 ]; do

	echo -e "\nLog:"
	cat $$.log

	echo -en "\nLog ok (q=quit,e=edit,c=commit)? "
	read in

	case "$in" in
	  c*) svn commit $locations --file $$.log ; quit=1 ;;
	  e*) $EDITOR $$.log ;;
	  q*) quit=1 ;;
	  *) echo "Excuse me?"
	esac
done
else
	echo -e "\nNo changes detected at:$locations"
	svn st $locations
fi

rm $$.log $$.diff

