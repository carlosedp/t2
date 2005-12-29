# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../rocknet/rocknet_script.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

public_script() {
	local a="$1"; shift
	addcode up   5 5 "$a up   $*"
	addcode down 5 5 "$a down $*"
}

public_run_up() {
	addcode up   5 5 "$*"
}

public_run_down() {
	addcode down 5 5 "$*"
}

public_code() {
	addcode $1 $2 5 "$3"
}

