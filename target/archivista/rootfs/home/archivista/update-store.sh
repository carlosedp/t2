#!/bin/bash

from="$1" ; shift
to="$1" ; shift

if [ -z "$from" -o -z "$to" ]; then
	echo "Usage: $0 from-dir to-dir"
	exit
fi

# include shared code
. ${0%/*}/Global.pm.in
. ${0%/*}/perl-var.in


cd $from

# passwords
update_root_hash=`grep '^root:' etc/shadow | cut -d : -f 2`
update_archivista_hash=`grep '^archivista:' etc/shadow | cut -d : -f 2`
update_ftp_hash=`grep '^ftp:' etc/shadow | cut -d : -f 2`

# mysql does not need to be saved - it is in /home/data/

# perl class
update_root_perl_passwd=`grep 'MYSQL_PWD' \
                         home/cvs/archivista/apcl/Archivista/Config.pm | cut -d \" -f 2`

# gnupg key
cp -rfv home/archivista/.gnupg $to/ 2>/dev/null

# ssh key
cp -fv etc/ssh/ssh_*key* $to/ 2>/dev/null

# network
cp etc/conf/network $to/

# https
grep -q '\-DSSL' sbin/init.d/apache && update_apache_https=1
mkdir -p $to/https/
cp -rfv etc/opt/apache/ssl.{crt,key} $to/https/ 2>/dev/null

# cups
if grep -q '^<DefaultPrinter' etc/cups/printers.conf; then
	# this is all we need for setup right now
	mkdir -p $to/cups
	update_cups_allow=`sed -n '/<Location \/>/{n;n;n;n;s/Allow From //p}' \
	                   etc/cups/cupsd.conf`
	cp -fv etc/cups/printers.conf $to/cups/
	cp -rv etc/cups/ppd/*.ppd $to/cups/
fi

# exim
grep -q '^# *local_interface' etc/exim/configure && update_incoming_mail=1

# admin mail
[ -f etc/mail.conf ] && . etc/mail.conf
[ "$To" ] && update_mail_to="$To"

# backup
update_backup=`grep archivista/backup.sh etc/crontab | cut -d ' ' -f 1-5`

# network backup
update_net_backup=`grep archivista/net-backup.sh etc/crontab |
                   cut -d ' ' -f 1-5`
cp -fv etc/net-backup.conf $to/ 2>/dev/null

# rsync backup
update_rsync_backup=`grep archivista/rsync-backup.sh etc/crontab |
                     cut -d ' ' -f 1-5`
cp -fv etc/rsync-backup.conf $to/ 2>/dev/null
mkdir -p $to/rsync-backup/
cp -fv root/.ssh/id_rsa* $to/rsync-backup/

# usb backup
update_usb_backup=`grep archivista/usb-backup.sh etc/crontab |
                   cut -d ' ' -f 1-5`

# ftp
grep -q '^ftp' etc/inetd.conf && update_ftp_enabled=1

# OCR reg key
cp -fv "home/archivista/.wine/drive_c/Programs/Av5e/av5.con" $to/ 2>/dev/null


# other, fine grained cnfiguration values
root=$from
update_onlyLocalhost=`get_Global.pm_var onlyLocalhost`
update_onlyDefaultDb=`get_Global.pm_var onlyDefaultDb`
update_defaultLoginHost=`get_Global.pm_string defaultLoginHost`
update_defaultLoginDb=`get_Global.pm_string defaultLoginDb`
update_defaultLoginUser=`get_Global.pm_string defaultLoginUser`

cp -fv etc/av-button.conf $to/
update_button_host=`get_perl_var '\$val{host1}' $from/home/cvs/archivista/jobs/sane-button.pl`
update_button_db=`get_perl_var '\$val{db1}' $from/home/cvs/archivista/jobs/sane-button.pl`
update_button_user=`get_perl_var '\$val{user1}' $from/home/cvs/archivista/jobs/sane-button.pl`
update_button_pw=`get_perl_var '\$val{pw1}' $from/home/cvs/archivista/jobs/sane-button.pl`

# store all update variables
for var in ${!update_*}; do
	declare -p $var
done > $to/config

