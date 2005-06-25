#!/bin/sh

builddir=$1
[ "$builddir" -a -d "$builddir/var/adm/cache/" ] || exit 1

getprio() {
	local pkg="$1" prio="999.999"
	local confdir=${2:-$( echo package/*/$pkg/ )}

	if [ -d "$confdir" -a -f "$confdir/$pkg.desc" ]; then
		prio=$( grep '^\[P\]' "$confdir/$pkg.desc" | cut -d' ' -f4)
	fi
	echo ${prio/./}
}

getdeps() {
	local cachefile="$1"
	grep '^\[DEP\]' $cachefile | cut -d' ' -f2- | tr ' ' '\n'
}

{
for repo in package/*; do
	for confdir in $repo/*; do
		pkg=${confdir##*/}
		prio=$( getprio "$pkg" "$confdir" )

		if [ -f "$builddir/var/adm/cache/"$pkg ]; then
			for dep in $( getdeps "$builddir/var/adm/cache/"$pkg ); do
				prio1=$( getprio $dep )
				if [ $prio -le $prio1 ]; then
					echo "$prio $pkg FRESH -> $dep ($prio1)"
				fi
			done
		elif [ -f "$confdir/$pkg.cache" ]; then
			for dep in $( getdeps "$confdir/$pkg.cache" ); do
				prio1=$( getprio $dep )
				if [ $prio -le $prio1 ]; then
					echo "$prio $pkg OFFICIAL -> $dep ($prio1)"
				fi
			done
		else
			echo "$prio $pkg NOCACHE"
		fi
	done
done
} | grep -v -- '-> \(gcc\|sysfiles\|patch\|bzip2\|tar\|sed\|make\|grep\|bash\|binutils\|ccache\|util-linux\|net-tools\|coreutils\|diffutils\|findutils\|autoconf\|automake\|glibc\|gawk\|mktemp\) '

