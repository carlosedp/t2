# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../bdb/bdb_config.sh
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

includedir=$includedir/db${ver:0:1}

# oficial patches
bdb_autopatch() {
	local x=
	for x in `match_source_file -p patch` ; do
		patch -p0 < $x
	done
}
hook_add prepatch 5 'bdb_autopatch'

hook_add preconf 2 'cd build_unix'
configscript="../dist/configure"

var_append confopt ' ' '--enable-compat185'
var_append confopt ' ' '--enable-cxx'

# we need the install-sh here, since our gnu-install does not
# handle the transform-name ...
var_append confopt ' ' "--program-transform-name='s/db/db${ver:0:1}/'"

# bdb doesn't like some of our make options
makeopt="docdir=$docdir all" ; makeinstopt="docdir=$docdir install"

# create yet another alternative library name some programs use
# this will crate a symlink in the form libdb-4.1.so -> libdb41.so
hook_add postinstall 9 'ln -sfv libdb-${ver:0:3}.so $libdir/libdb${ver:0:1}.so'

# bdb does copy the docs itself ...
createdocs=0
