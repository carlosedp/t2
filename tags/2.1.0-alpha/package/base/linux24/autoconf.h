/*
 * Manualy created by Clifford to keep common things alive ...
 *
 * --- ROCK-COPYRIGHT-NOTE-BEGIN ---
 * 
 * This copyright note is auto-generated by ./scripts/Create-CopyPatch.
 * Please add additional copyright information _after_ the line containing
 * the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
 * the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
 * 
 * ROCK Linux: rock-src/package/*/linux24/autoconf.h
 * Copyright (C) 1998 - 2003 ROCK Linux Project
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version. A copy of the GNU General Public
 * License can be found at Documentation/COPYING.
 * 
 * Many people helped and are helping developing ROCK Linux. Please
 * have a look at http://www.rocklinux.org/ and the Documentation/TEAM
 * file for details.
 * 
 * --- ROCK-COPYRIGHT-NOTE-END ---
 *
 */

/*
 * Code maturity level options
 */
#define CONFIG_EXPERIMENTAL 0

/*
 * Loadable module support
 */
#define CONFIG_MODULES 1
#undef  CONFIG_MODVERSIONS 1
#define CONFIG_KMOD 1

/*
 * General setup
 */
#define CONFIG_NET 1
#define CONFIG_SYSVIPC 1
#define CONFIG_BINFMT_ELF 1

/*
 * Networking options
 */
#define CONFIG_UNIX 1
#define CONFIG_INET 1

/*
 * Network device support
 */
#define CONFIG_NETDEVICES 1
#define CONFIG_DUMMY 1

/*
 * Filesystems
 */
#define CONFIG_QUOTA 1
#define CONFIG_EXT2_FS 1
#define CONFIG_PROC_FS 1