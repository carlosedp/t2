#!/bin/sh
# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../sendmail/setmailer.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

for x in sendmail mailq newaliases; do
	echo "$0: Re-creating /usr/bin/$x -> ${x}_@mailer@ ..."
	echo -e "#!/bin/sh\nexec -a $x ${x}_@mailer@ \"\$@\"" > /usr/bin/$x
	chmod +x /usr/bin/$x
done

# add compatibility symlink
ln -sf /usr/bin/sendmail /usr/sbin/sendmail

exit 0
