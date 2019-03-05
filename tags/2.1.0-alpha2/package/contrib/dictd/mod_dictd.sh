# --- ROCK-COPYRIGHT-NOTE-BEGIN ---
# 
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# Please add additional copyright information _after_ the line containing
# the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
# the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
# 
# ROCK Linux: rock-src/package/*/dictd/mod_dictd.sh
# Copyright (C) 1998 - 2004 ROCK Linux Project
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

#
# [MAIN] 80 dictd Configuration for dictionary server 


conf=/etc/dictd.conf

list_dictionaries () {
    ds=""
    for i in $( ls /usr/share/dictd/*.index )
    do
        ds="$ds `basename $i .index`"
    done
}

select_dict() {
        if grep "database[[:space:]]\+\"$1\"" $conf 2>&1 >/dev/null
        then
                # delete entry if it is not for select all
                if [ "$2" != "1" ] ; then  
                perl -i -00 -p -e"s/database\s+\"$1\"\s+\{.+\}//s" $conf
                fi
        else 
                # set entry if it is not in unselect all mode
                if [ "$2" != "0" ] ; then 
                cat <<MSG >>$conf
database "$1"
{
      data "/usr/share/dictd/$1.dict.dz"
      index "/usr/share/dictd/$1.index"
}
MSG
                fi
	fi 
}

select_dictionaries() {
	while
		cmd="gui_menu dictd 'Select the dictionaries which"
		cmd="$cmd will be served by dictd.'"
		
		list_dictionaries
		if [ -z "$ds" ] ; then gui_message \
		"Stone can not find any dictionary. Please install one!"
		return; fi

		for dic in $ds 
		do
                        if grep "database[[:space:]]\+\"$dic\"" $conf 2>&1 >/dev/null
                        then
                             dics=$(printf "%-10sOK" "$dic")
                        else
                             dics=$(printf "%-10s--" "$dic")
                        fi 
                	cmd="$cmd '$dics' 'select_dict \"$dic\"'"			
		done
		eval $cmd
	do : ; done
}

all_dictionaries() {
        list_dictionaries
	for dic in $ds
        do
                select_dict "$dic" 1
        done
}

deselect_all() {
        list_dictionaries
        for dic in $ds
        do
                select_dict "$dic" 0
        done
}

main() {
        while
        
                cmd="gui_menu dictd 'Configuration for dictionary server' "
	        list_dictionaries
                if [ -z "$ds" ] ; then gui_message \
                "There is no dictionary installed. Please install one."
                return ; fi
  
                cmd="$cmd 'Select dictionaries' 'select_dictionaries'"
                cmd="$cmd 'Select all installed dictionaries' 'all_dictionaries'"
                cmd="$cmd 'Deselect all dictionaries' 'deselect_all'"
                cmd="$cmd 'Edit $conf' 'gui_edit DICTD $conf'"
                eval $cmd
	do : ; done
}
