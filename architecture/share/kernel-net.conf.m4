dnl --- T2-COPYRIGHT-NOTE-BEGIN ---
dnl This copyright note is auto-generated by ./scripts/Create-CopyPatch.
dnl 
dnl T2 SDE: architecture/share/kernel-net.conf.m4
dnl Copyright (C) 2004 - 2005 The T2 SDE Project
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
CONFIG_PACKET_MMAP=y
CONFIG_PACKET=y
CONFIG_NETLINK=y
CONFIG_RTNETLINK=y
CONFIG_IP_MULTICAST=y
CONFIG_FILTER=y
CONFIG_UNIX=y
CONFIG_INET=y

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

dnl Enable ISDN drivers as modules
dnl
CONFIG_ISDN=m
CONFIG_ISDN_I4L=y
CONFIG_ISDN_AUDIO=y
CONFIG_ISDN_BOOL=y
CONFIG_ISDN_CAPI_CAPIFS_BOOL=y
CONFIG_ISDN_CAPI_MIDDLEWARE=y
CONFIG_CAPI_AVM=y
CONFIG_CAPI_EICO=y
CONFIG_CAPI_EICON=y
CONFIG_HISAX_16_0=y
CONFIG_HISAX_16_3=y
CONFIG_HISAX_1TR6=y
CONFIG_HISAX_ASUSCOM=y
CONFIG_HISAX_AVM_A1=y
CONFIG_HISAX_AVM_A1_PCMCIA=y
CONFIG_HISAX_BKM_A4T=y
CONFIG_HISAX_DIEHLDIVA=y
CONFIG_HISAX_ELSA=y
CONFIG_HISAX_EURO=y
CONFIG_HISAX_FRITZPCI=y
CONFIG_HISAX_FRITZ_PCIPNP=m
CONFIG_HISAX_GAZEL=y
CONFIG_HISAX_HFCS=y
CONFIG_HISAX_HFC_SX=y
CONFIG_HISAX_HSTSAPHIR=y
CONFIG_HISAX_ISURF=y
CONFIG_HISAX_IX1MICROR2=y
CONFIG_HISAX_MIC=y
CONFIG_HISAX_NI1=y
CONFIG_HISAX_NICCY=y
CONFIG_HISAX_S0BOX=y
CONFIG_HISAX_SCT_QUADRO=y
CONFIG_HISAX_SEDLBAUER=y
CONFIG_HISAX_SPORTSTER=y
CONFIG_HISAX_TELEINT=y
CONFIG_HISAX_TELESPCI=y
CONFIG_HISAX_W6692=y
CONFIG_IPPP_FILTER=y
CONFIG_ISDN_DIVAS_BRIPCI=y
CONFIG_ISDN_DIVAS_PRIPCI=y
CONFIG_ISDN_DRV_AVMB1_B1PCIV4=y
CONFIG_ISDN_DRV_HISAX=m
CONFIG_ISDN_HISAX=y
CONFIG_ISDN_MPP=y
CONFIG_ISDN_PPP=y
CONFIG_ISDN_PPP_BSDCOMP=m
CONFIG_ISDN_PPP_VJ=y
CONFIG_ISDN_TTY_FAX=y
CONFIG_ISDN_X25=y

dnl Enable fibre channel support
CONFIG_NET_FC=y
