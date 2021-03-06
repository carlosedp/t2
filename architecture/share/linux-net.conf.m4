dnl --- T2-COPYRIGHT-NOTE-BEGIN ---
dnl This copyright note is auto-generated by scripts/Create-CopyPatch.
dnl 
dnl T2 SDE: architecture/share/linux-net.conf.m4
dnl Copyright (C) 2004 - 2021 The T2 SDE Project
dnl 
dnl More information can be found in the files COPYING and README.
dnl 
dnl This program is free software; you can redistribute it and/or modify
dnl it under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; version 2 of the License. A copy of the
dnl GNU General Public License can be found in the file COPYING.
dnl --- T2-COPYRIGHT-NOTE-END ---

dnl the basic sections
dnl
CONFIG_NET=y
CONFIG_PACKET=y
CONFIG_PACKET_MMAP=y
CONFIG_UNIX=y
CONFIG_INET=y
CONFIG_NETLINK=y
CONFIG_RTNETLINK=y

CONFIG_NETDEVICES=y
CONFIG_NET_ETHERNET=y

CONFIG_NET_ISA=y
CONFIG_NET_EISA=y
CONFIG_NET_PCI=y
CONFIG_NET_POCKET=y

dnl Enable some vendor sections
dnl
CONFIG_NET_VENDOR_3COM=y
CONFIG_NET_VENDOR_SMC=y
CONFIG_NET_VENDOR_RACAL=y

dnl make sure those are modular (built-in by default)
dnl
CONFIG_8139TOO=m
CONFIG_FORCEDETH=m
CONFIG_E1000=m

dnl Enable some categories so drivers are enabled as modules
dnl
CONFIG_NET_RADIO=y
CONFIG_NET_PCMCIA=y
CONFIG_NET_TULIP=y

dnl Misc network device support
dnl
CONFIG_PPP=y
CONFIG_PPP_FILTER=y

dnl Enable IP autoconfiguration
dnl
CONFIG_IP_PNP=y
CONFIG_IP_PNP_BOOTP=y
CONFIG_IP_PNP_DHCP=y

dnl Enable some nice networking features
dnl
CONFIG_IP_ADVANCED_ROUTER=y
CONFIG_IP_MULTIPLE_TABLES=y
CONFIG_IP_MULTICAST=y
CONFIG_FILTER=y

dnl Enable QoS and IP-Tables (drivers themself are modules)
dnl 
CONFIG_NET_SCHED=y
CONFIG_NETFILTER=y
CONFIG_NET_QOS=y
CONFIG_NET_CLS=y

dnl Disable dangerous packet generator
dnl
# CONFIG_NET_PKTGEN is not set

dnl Important BT settings, RFCOM_TTY that is
dnl
CONFIG_BT=y
CONFIG_BT_L2CAP=m
CONFIG_BT_RFCOMM=m
CONFIG_BT_RFCOMM_TTY=y

dnl Enable fibre channel support
CONFIG_NET_FC=y

dnl Wireless Fidelity
CONFIG_WLAN_PRE80211=y
CONFIG_WLAN_80211=y

dnl some more vendor options
CONFIG_BRCMFMAC_USB=y
CONFIG_BRCMFMAC_PCIE=y

dnl rare / obsolete stuff
# CONFIG_ISDN is not set
# CONFIG_WIMAX is not set
# CONFIG_DECNET is not set
