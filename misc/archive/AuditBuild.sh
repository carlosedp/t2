#!/bin/sh
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: misc/archive/AuditBuild.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

config=default
enabled='X'
repositories=
VERBOSE=
HTMLDIR=
root=

show_usage() {
	cat<<-EOT
	usage: $0 [-v] [-cfg <config>] [--no-enabled-too] [-repository <repositories>]
	EOT
}

while [ $# -gt 0 ]; do
	case "$1" in
		-cfg)	config="$2"; shift	;;
		-v)	VERBOSE=1		;;
		-w)	HTMLDIR="$2"; shift	;;
		--help)	show_usage; exit 1	;;
		-R)	root="$2"; shift	;;
		--no-enabled-too)
			enabled=.		;;
		-repository)
			shift; repositories="$*"
			break ;;
		*)	show_usage; exit 2	;;
	esac
	shift
done

if [ ! -f config/$config/packages ]; then
	echo "ERROR: '$config' is not a valid config"
	exit 1
fi

eval `grep 'ROCKCFG_ID=' config/$config/config 2> /dev/null`
if [ "$root" ]; then
	LOGSDIR=$root/var/adm/logs
else
	LOGSDIR=build/$ROCKCFG_ID/var/adm/logs
fi
if [ -z "$ROCKCFG_ID" -o ! -d $LOGSDIR ]; then
	echo "ERROR: 'build/$ROCKCFG_ID/' is not a valid build root (sandbox)"
	exit 1
fi

if [ "$HTMLDIR" ]; then
	mkdir -p $HTMLDIR/$config.$$/{diff,log}
fi

expand_stages() {
	local array="$1" stage=
	while [ "$array" ]; do
		stage=${array:0:1}
		array=${array:1}
		if [ "$stage" != "-" ]; then
			echo -n "$stage "
		fi
	done
}

audit_package() {
	local pkg="$1" repo="$2" ver="$3" enabled="$4"
	local stages= svndiff= oldver= newver= lchanges= stage=
	local svnst= lstatus= lbuild= file=
	shift 4; stages="$*"

	svnst=`svn st package/$repo/$pkg`
	if [ "$svnst" ]; then
		svndiff=`svn diff package/$repo/$pkg`
		if [ "$svndiff" ]; then
			lchanges="CHANGED"
			oldver=`echo "$svndiff" | grep '^-\[V\]' | cut -d' ' -f2`
			newver=`echo "$svndiff" | grep '^+\[V\]' | cut -d' ' -f2`

			if [ "$oldver" ]; then
				ver="$oldver -> $ver"
				lchanges="UPDATED"
			elif [ "$newver" ]; then
				lchanges="ADDED"
			fi
		fi
		if [ "$HTMLDIR" ]; then
			{
			echo "$svnst"
			echo ""
			echo "$svndiff"
			} > $HTMLDIR/$config.$$/diff/$pkg.diff
			lchanges="<a href=\"diff/$pkg.diff\">$lchanges</a>"
		fi
	fi

	if [ "$enabled" == "O" ]; then
		for stage in $stages; do
			lbuild="$lbuild NO($stage)"
		done
		lstatus=3
	else
		for stage in $stages; do
		file=`ls -1 $LOGSDIR/$stage-$pkg.{err,log,out} 2> /dev/null`
		lstatus=
		if [ "$file" ]; then
			case "$file" in
				*.log)	[ "$lstatus" ] || lstatus=1
					lbuild="$lbuild OK($stage)"	;;
				*.out)	[ "$lstatus" != "2" ] || lstatus=0
					lbuild="$lbuild NO($stage)"	;;
				*)	lstatus=2
					if [ "$HTMLDIR" ]; then
						lbuild="$lbuild <a href=\"log/$stage-$pkg.err\">ERR($stage)</a>"
						cp $file $HTMLDIR/$config.$$/log/$stage-$pkg.err
					else
						lbuild="$lbuild ERR($stage)"
					fi	;;
			esac
		else
			lbuild="$lbuild NO($stage)"
			[ "$lstatus" ] || lstatus=0
		fi
		done
	fi
	case "$lstatus" in
		3)	lstatus=NOQUEUED	;;
		2)	lstatus=FAILED		;;
		1)	lstatus=SUCCESSFUL	;;
		*)	lstatus=PENDING		;;
	esac
	if [ "$HTMLDIR" ]; then
		cat <<EOT
<tr><td>package/$repo/$pkg</td><td>$lchanges</td><td>(${ver//>/&gt;})</td><td>$lbuild</td><td>$lstatus</td></tr>
EOT
	else
		echo -e "package/$repo/$pkg\t$lchanges\t($ver)\t$lbuild\t$lstatus"
	fi
}

if [ "$HTMLDIR" ]; then
	cat <<EOT
<html>
<head><title>Audit Build $config over revision $( svn info | grep Revision | cut -d' ' -f2 )</title>
<body>
$( [ "$repositories" ] && echo "<h3>$repositories</h3>" )
<table><tr>
	<th>Package</th>
	<th>SVN Status</th>
	<th>Version</th>
	<th>Build Status</th>
	<th>Result</th>
</tr>
EOT

fi
if [ "$repositories" ]; then
	for repo in $repositories; do
		repo=${repo#package/}; repo=${repo%/}
		if [ -d package/$repo/ ]; then
			grep -e "^$enabled.* $repo " config/$config/packages | while \
				read e stages x repo pkg ver x; do
					audit_package $pkg $repo $ver $e `expand_stages $stages`
			done
		fi
	done
else
	grep -e "^$enabled" config/$config/packages | while \
		read e stages x repo pkg ver x; do
			audit_package $pkg $repo $ver $e `expand_stages $stages`
	done
fi

if [ "$HTMLDIR" ]; then
	echo "<body><html>"

	if [ -d "$HTMLDIR/$config" ]; then
		mv $HTMLDIR/$config $HTMLDIR/$config.$$-old
	fi
	mv $HTMLDIR/$config.$$ $HTMLDIR/$config/
fi
