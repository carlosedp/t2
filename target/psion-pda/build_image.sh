#!/bin/bash

set -e

arlo_ver="`sed -e 's,.*arlo-\(.*\).zip .*,\1,' \
           $base/target/psion-pda/download.txt`"

rm -rf $imagedir
mkdir -p $imagedir/initrd ; cd $imagedir/initrd

find $build_root -printf "%P\n" | sed '

# stuff we never need

/^TOOLCHAIN/	d;
/^var\/adm/	d;

/\/include/	d;
/\/src/		d;
/\.a$/		d;
/\.o$/		d;

/\/games/	d;
/\/local/	d;
/^boot/		d;

# stuff that would be nice - but is huge and only documentation
/\/man/		d;
/\/doc/		d;

# /etc noise
/^etc\/stone.d/	d;
/^etc\/cron.d/	d;
/^etc\/network/	d;
/^etc\/init.d/	d;
/^etc\/profile.d/	d;

/^etc\/sysconfig/	d;
/^etc\/iproute2/	d;

/^etc\/skel/	d;
/^etc\/opt/	d;
/^etc\/conf/	d;
/^etc\/rc.d/	d;

/^home/		d;
/^mnt/		d;
/^opt/		d;

/^\/man\//	d;

/terminfo\/a\/ansi$/	{ p; d; }
/terminfo\/l\/linux$/	{ p; d; }
/terminfo\/x\/xterm$/	{ p; d; }
/terminfo\/n\/nxterm$/	{ p; d; }
/terminfo\/x\/xterm-color$/	{ p; d; }
/terminfo\/x\/xterm-8bit$/	{ p; d; }
/terminfo\/x\/screen$/	{ p; d; }
/terminfo\/v\/vt100$/	{ p; d; }
/terminfo\/v\/vt200$/	{ p; d; }
/terminfo\/v\/vt220$/	{ p; d; }
/terminfo/	d;

# some big ncurses stuff
/\/tack$/	d;
/\/tic$/	d;
/\/toe$/	d;
/\/tput$/	d;
/\/tset$/	d;
/\/captoinfo$/	d;
/\/input$/	d;

' | while read file ; do
	[ "$file" ] || continue
	mkdir -p `dirname $file`
	if [ -f $build_root/$file ] ; then
		cp -p $build_root/$file $file
	else
		mkdir $file
	fi
done

echo "Creating links for identical files."
while read ck fn ; do      
        if [ "$oldck" = "$ck" ] ; then
                echo "\"$fn -> $oldfn\""
                rm $fn ; ln $oldfn $fn
        else    
                oldck=$ck ; oldfn=$fn
        fi
done < <( find -type f | xargs md5sum | sort )
echo

while read target name ; do
	ln -s $target $name
done < <(cat <<-EOT
kcore dev/core
/proc/self/fd dev/fd
fd/0 dev/stdin
fd/1 dev/stdout
fd/2 dev/stderr
vcs0 dev/vcs
EOT
)

while read type major minor name ; do
	if [ "$name" ] ; then
		mknod dev/$name $type $major $minor
	else
		echo "defect rule!"
	fi
done < <(cat <<-EOT
c 10 3 atibm
c 14 4 audio
c 14 20 audio1
c 14 36 audio2
c 14 52 audio3
c 14 7 audioctl
c 5 1 console
c 14 3 dsp
c 14 19 dsp1
c 29 0 fb0
c 1 7 full
c 10 2 inportbm
c 161 0 ircomm0
c 161 1 ircomm1
c 161 16 irlpt0
c 161 17 irlpt1
c 10 4 jbm
c 1 2 kmem
c 10 0 logibm
b 7 0 loop0
b 7 1 loop1
b 7 2 loop2
b 7 3 loop3
c 6 0 lp0
c 6 1 lp1
c 6 2 lp2
c 1 1 mem
c 14 0 mixer
c 14 16 mixer1
c 1 3 null
c 1 4 port
c 5 2 ptmx
c 2 0 ptyp0
c 2 1 ptyp1
c 2 2 ptyp2
c 2 3 ptyp3
c 2 4 ptyp4
c 2 5 ptyp5
c 2 6 ptyp6
c 2 7 ptyp7
c 2 8 ptyp8
c 2 9 ptyp9
c 2 10 ptypa
c 2 11 ptypb
c 2 12 ptypc
c 2 13 ptypd
c 2 14 ptype
c 2 15 ptypf
b 1 0 ram0
b 1 1 ram1
b 1 2 ram2
b 1 3 ram3
c 1 8 random
c 14 6 sndstat
c 10 11 tpanel
c 5 0 tty
c 4 0 tty0
c 4 1 tty1
c 4 10 tty10
c 4 2 tty2
c 4 3 tty3
c 4 4 tty4
c 4 5 tty5
c 4 6 tty6
c 4 7 tty7
c 4 8 tty8
c 4 9 tty9
c 204 16 ttyAM0
c 204 17 ttyAM1
c 204 16 ttyS0
c 204 17 ttyS1
c 1 9 urandom
c 7 0 vcs0
c 7 1 vcs1
c 7 2 vcs2
c 7 3 vcs3
c 7 4 vcs4
c 7 5 vcs5
c 7 6 vcs6
c 7 7 vcs7
c 7 8 vcs8
c 7 9 vcs9
c 1 5 zero
EOT
)

echo "Injecting some more stuff ..."
ln -s ash bin/sh
cp -f $base/target/psion-pda/{passwd,group,fstab,issue,profile} etc/

# image size estimation ...
s="`du -s -B 1 . | cut -f 1`"
s="$(( (s + 128000) / 1024 ))"
s="$(( s * 1024 ))"

echo "Writing initrd image file ($s bytes)."

tmpdir="`mktemp`" ; rm $tmpdir ; mkdir $tmpdir
tmpfile="`mktemp`"

dd if=/dev/zero of=$tmpfile bs=$s count=1 > $tmpfile

mke2fs -m 0 -N 512 -qF $tmpfile
mount -t ext2 $tmpfile $tmpdir -o loop
rmdir $tmpdir/lost+found/

tar cSp . | (cd $tmpdir ; tar xSp)

umount $tmpdir
gzip -9 -c $tmpfile > ../initrd.gz
rmdir $tmpdir ; rm -f $tmpfile

cd $imagedir
cp $build_root/boot/Image_* Image
unzip $base/download/mirror/a/arlo-$arlo_ver.zip
rm arlo/{copying,readme.html,example.cfg}

cp $base/target/psion-pda/arlo.cfg arlo/

