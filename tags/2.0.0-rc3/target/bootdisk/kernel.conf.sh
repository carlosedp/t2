# here we disable driver we'll most probably not need on the bootdisk

echo "bootdisk target -> disabling some modules ..."

sed -e "s/CONFIG_SOUND\(.*\)=./# CONFIG_SOUND\1 is not set/" \
    -e "s/CONFIG_VIDEO\(.*\)=./# CONFIG_VIDEO\1 is not set/" \
    -e "s/CONFIG_PHONE\(.*\)=./# CONFIG_PHONE\1 is not set/" \
    -e "s/CONFIG_RADIO\(.*\)=./# CONFIG_RADIO\1 is not set/" \
    -e "s/CONFIG_HAMRADIO\(.*\)=./# CONFIG_HAMRADIO\1 is not set/" \
    -e "s/CONFIG_ATM\(.*\)=./# CONFIG_ATM\1 is not set/" \
    $1 > .config.server

mv .config.server $1

