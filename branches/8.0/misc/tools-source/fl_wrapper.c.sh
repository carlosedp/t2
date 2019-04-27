#!/bin/bash
#
# This shell-script genereates the fl_wrapper.c source file.

cat << EOT
/* ROCK Linux Wrapper for getting a list of created files
 *
 * --- T2-COPYRIGHT-NOTE-BEGIN ---
 * This copyright note is auto-generated by ./scripts/Create-CopyPatch.
 * 
 * T2 SDE: misc/tools-source/fl_wrapper.c.sh
 * Copyright (C) 2004 - 2010 The T2 SDE Project
 * Copyright (C) 1998 - 2003 ROCK Linux Project
 * Copyright (C) 2006 - 2010 Rene Rebe <rene@exactcode.de>
 * 
 * More information can be found in the files COPYING and README.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License. A copy of the
 * GNU General Public License can be found in the file COPYING.
 * --- T2-COPYRIGHT-NOTE-END ---
 *
 * gcc -Wall -O2 -ldl -shared -o fl_wrapper.so fl_wrapper.c
 *
 * !!! THIS FILE IS AUTO-GENERATED BY $0 !!!
 *
 * ELF Dynamic Loading Documentation:
 *  - http://www.linuxdoc.org/HOWTO/GCC-HOWTO-7.html
 *  - http://www.educ.umu.se/~bjorn/mhonarc-files/linux-gcc/msg00576.html
 *  - /usr/include/dlfcn.h
 */


/* Headers and prototypes */

#define DEBUG 0
#define DLOPEN_LIBC 1
#ifndef FLWRAPPER_LIBC
#  define FLWRAPPER_LIBC "libc.so.6"
#endif

#define _GNU_SOURCE
#define _REENTRANT

#define open   xxx_open
#define open64 xxx_open64
#define openat xxx_openat
#define openat64 xxx_openat64
#define mkfifo xxx_mkfifo
#define mknod  xxx_mknod
#define __xmknod xxx___xmknod

#define _LARGEFILE_SOURCE
#define _LARGEFILE64_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <utime.h>
#include <stdarg.h>
#include <limits.h>
/* somehow it can happen that PATH_MAX does not get defined...? -- jsaw */
#ifndef PATH_MAX
#include <linux/limits.h>
#endif
#ifndef PATH_MAX
#warning "PATH_MAX was not defined - BUG in your system headers?"
#define PATH_MAX 4095
#endif
#include <libgen.h>

#undef _LARGEFILE64_SOURCE
#undef _LARGEFILE_SOURCE

#undef __xmknod
#undef mknod
#undef mkfifo
#undef open
#undef open64
#undef openat
#undef openat64

static void * get_dl_symbol(char *);

struct status_t {
	ino_t   inode;
	off_t   size;
	time_t  mtime;
	time_t  ctime;
};

#ifdef FLWRAPPER_BASEDIR
static void check_write_access(const char * , const char * );
#endif
static void handle_file_access_before(const char *, const char *, struct status_t *);
static void handle_file_access_after(const char *, const char *, struct status_t *);

char filterdir[PATH_MAX], wlog[PATH_MAX], rlog[PATH_MAX], *cmdname = "unkown";

/* Wrapper Functions */
EOT

# This has been made with cpp-macros before until they turned to be absolutely
# unreadable ...
#
add_wrapper()
{
	line="$( echo "$*" | sed 's/ *, */,/g' )"
	old_ifs="$IFS" ; IFS="," ; set $line ; IFS="$old_ifs"

	ret_type=$1 ; shift ; function=$1 ; shift
	p1="" ; p2="" ; for x ; do p1="$p1$x, " ; done
	for x ; do x="${x%%\[\]}" ; p2="$p2${x##* }, " ; done
	p1="${p1%, }" ; p2="${p2%, }"

	case ${function} in
	open*)
		# remove varg from $p2
		p2=${p2%, ...}
		echo ; cat << EOT
extern $ret_type $function($p1);
$ret_type (*orig_$function)($p1) = 0;

$ret_type $function($p1)
{
	struct status_t status;
	int old_errno=errno;
	$ret_type rc;
	mode_t b = 0;

#ifdef FLWRAPPER_BASEDIR
	if (a & (O_WRONLY|O_CREAT|O_APPEND))
		check_write_access("$function", f);
#endif

	handle_file_access_before("$function", f, &status);
	if (!orig_$function) orig_$function = get_dl_symbol("$function");
	errno=old_errno;

#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: going to run original $function() at %p (wrapper is at %p).\n",
		getpid(), orig_$function, $function);
#endif

	if (a & O_CREAT) {
	  va_list ap;

	  va_start(ap, a);
	  b = va_arg(ap, mode_t);
	  va_end(ap);

	  rc = orig_$function($p2, b);
	}
	else
	  rc = orig_$function($p2);

	old_errno=errno;
	handle_file_access_after("$function", f, &status);
	errno=old_errno;

	return rc;
}
EOT
		;;
	exec*)
		echo ; cat << EOT
extern $ret_type $function($p1);
$ret_type (*orig_$function)($p1) = 0;

$ret_type $function($p1)
{
	int old_errno=errno;

	handle_file_access_after("$function", f, 0);
	if (!orig_$function) orig_$function = get_dl_symbol("$function");
	errno=old_errno;

	return orig_$function($p2);
}
EOT
		;;
	*)
		echo ; cat << EOT
extern $ret_type $function($p1);
$ret_type (*orig_$function)($p1) = 0;

$ret_type $function($p1)
{
	struct status_t status;
	int old_errno=errno;
	$ret_type rc;

	handle_file_access_before("$function", f, &status);
	if (!orig_$function) orig_$function = get_dl_symbol("$function");
	errno=old_errno;

#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: going to run original $function() at %p (wrapper is at %p).\n",
		getpid(), orig_$function, $function);
#endif
	rc = orig_$function($p2);

	old_errno=errno;
	handle_file_access_after("$function", f, &status);
	errno=old_errno;

	return rc;
}
EOT
		;;
	esac
}

add_wrapper 'int,   open,    const char* f, int a, ...'
add_wrapper 'int,   open64,  const char* f, int a, ...'
add_wrapper 'int,   openat,  int dirfd, const char* f, int a, ...'
add_wrapper 'int,   openat64,int dirfd, const char* f, int a, ...'

add_wrapper 'FILE*, fopen,   const char* f, const char* g'
add_wrapper 'FILE*, fopen64, const char* f, const char* g'

add_wrapper 'int,   creat,   const char* f, mode_t m'
add_wrapper 'int,   creat64, const char* f, mode_t m'

add_wrapper 'int,   mkdir,   const char* f, mode_t m'
add_wrapper 'int,   mkfifo,  const char* f, mode_t m'
add_wrapper 'int,   mknod,   const char* f, mode_t m, dev_t d'
add_wrapper 'int,   __xmknod, int ver, const char* f, mode_t m, dev_t* d'

add_wrapper 'int,   link,    const char* s, const char* f'
add_wrapper 'int,   linkat,  int sfd, const char* s, int ffd, const char* f, int flags'

add_wrapper 'int,   symlink, const char* s, const char* f'
add_wrapper 'int,   rename,  const char* s, const char* f'

add_wrapper 'int,   utime,   const char* f, const struct utimbuf* t'
add_wrapper 'int,   utimes,  const char* f, struct timeval* t'

add_wrapper 'int,   execv,   const char* f, char* const a[]'
add_wrapper 'int,   execve,  const char* f, char* const a[], char* const e[]'

echo
cat misc/tools-source/fl_wrapper_execl.c

echo ; cat << "EOT"
/* Internal Functions */

static void * get_dl_symbol(char * symname)
{
	void * rc;
#if DLOPEN_LIBC
	static void * libc_handle = 0;

	if (!libc_handle) libc_handle=dlopen(FLWRAPPER_LIBC, RTLD_LAZY);
	if (!libc_handle) {
		fprintf(stderr, "fl_wrapper.so: Can't dlopen libc: %s\n", dlerror()); fflush(stderr);
		abort();
	}

        rc = dlsym(libc_handle, symname);
#  if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: Symbol '%s' in libc (%p) has been resolved to %p.\n",
		getpid(), symname, libc_handle, rc);
#  endif
#else
        rc = dlsym(RTLD_NEXT, symname);
#  if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: Symbol '%s' (RTLD_NEXT) has been resolved to %p.\n",
		getpid(), symname, rc);
#  endif
#endif
	if (!rc) {
		fprintf(stderr, "fl_wrapper.so: Can't resolve %s: %s\n",
		       symname, dlerror()); fflush(stderr);
		abort();
	}

        return rc;
}

static pid_t pid2ppid(pid_t pid)
{
	char buffer[100];
	int fd, rc;
	pid_t ppid = 0;

	sprintf(buffer, "/proc/%d/stat", pid);
	if ( (fd = open(buffer, O_RDONLY, 0)) < 0 ) return 0;
	if ( (rc = read(fd, buffer, 99)) > 0) {
		buffer[rc] = 0;
		/* format: 27910 (bash) S 27315 ... */
		sscanf(buffer, "%*[^ ] %*[^ ] %*[^ ] %d", &ppid);
	}
	close(fd);

	return ppid;
}

/* this is only called from fl_wrapper_init(). so it doesn't need to be
 * reentrant. */
static char *getpname(int pid)
{
	static char p[512];
	char buffer[100]="";
	char *arg=0, *b;
	int i, fd, rc;

	sprintf(buffer, "/proc/%d/cmdline", pid);
	if ( (fd = open(buffer, O_RDONLY, 0)) < 0 ) return "unkown";
	if ( (rc = read(fd, buffer, 99)) > 0) {
		buffer[rc--] = 0;
		for (i=0; i<rc; i++)
			if (!buffer[i]) { arg = buffer+i+1; break; }
	}
	close(fd);

	b = basename(buffer);
	snprintf(p, 512, "%s", b);

	if ( !strcmp(b, "bash") || !strcmp(b, "sh") || !strcmp(b, "perl") )
		if (arg && *arg && *arg != '-')
			snprintf(p, 512, "%s(%s)", b, basename(arg));

	return p;
}

/* invert the order by recursion. there will be only one recursion tree
 * so we can use a static var for managing the last ent */
static void addptree(int *txtpos, char *cmdtxt, int pid, int basepid)
{
	static char l[512] = "";
	char *p;

	if (!pid || pid == basepid) return;

	addptree(txtpos, cmdtxt, pid2ppid(pid), basepid);

	p = getpname(pid);

	if ( strcmp(l, p) )
		*txtpos += snprintf(cmdtxt+*txtpos, 4096-*txtpos, "%s%s",
				*txtpos ? "." : "", getpname(pid));
	else
		*txtpos += snprintf(cmdtxt+*txtpos, 4096-*txtpos, "*");

	strcpy(l, p);
}

void copy_getenv (char* var, const char* name)
{
	char *c = getenv(name);
	if (c) strcpy (var, c);
	else var[0]=0;
}

void __attribute__ ((constructor)) fl_wrapper_init()
{
	char cmdtxt[4096] = "";
	char *basepid_txt = getenv("FLWRAPPER_BASEPID");
	int basepid = 0, txtpos=0;

	if (basepid_txt)
		basepid = atoi(basepid_txt);

	addptree(&txtpos, cmdtxt, getpid(), basepid);
	cmdname = strdup(cmdtxt);

	/* we copy the vars, so evil code can not unset them ... e.g.
	   the perl/spamassassin build ... -ReneR */
	copy_getenv(filterdir, "FLWRAPPER_FILTERDIR");
	copy_getenv(wlog, "FLWRAPPER_WLOG");
	copy_getenv(rlog, "FLWRAPPER_RLOG");
}

#ifdef FLWRAPPER_BASEDIR
static void check_write_access(const char * func, const char * file)
{
	if (*file == '/') { /* do only check rooted paths */
		while (file[1] == '/') file++;

		if (!strcmp(file, "/dev/null") || !strncmp(file, "/tmp", 4)) {
		}
		else if (strncmp(file, FLWRAPPER_BASEDIR, sizeof(FLWRAPPER_BASEDIR)-1)) {
			fprintf(stderr, "fl_wrapper.so: write outside basedir (%s): %s\n", FLWRAPPER_BASEDIR, file);
			fflush(stderr);
			exit(-1);
		}
	}
}
#endif

static void handle_file_access_before(const char * func, const char * file,
                               struct status_t * status)
{
	struct stat st;
#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: begin of handle_file_access_before(\"%s\", \"%s\", xxx)\n",
		getpid(), func, file);
#endif
	if ( lstat(file,&st) ) {
		status->inode=0;  status->size=0;
		status->mtime=0;  status->ctime=0;
	} else {
		status->inode=st.st_ino;    status->size=st.st_size;
		status->mtime=st.st_mtime;  status->ctime=st.st_ctime;
	}
#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: end   of handle_file_access_before(\"%s\", \"%s\", xxx)\n",
		getpid(), func, file);
#endif
}

/* sort of, private realpath, mostly not readlink() */
static void sort_of_realpath (const char *file, char *absfile)
{
	/* make sure the filename is absolute */
	if (file[0] != '/') {
		char cwd[PATH_MAX];
		getcwd(cwd, PATH_MAX);
		snprintf(absfile, PATH_MAX, "%s/%s", cwd, file);
		file = absfile;
	}

	const char* src = file; char* dst = absfile;
	/* till the end, remove ./ and ../ parts */
	while (dst < absfile + PATH_MAX && *src) {
		if (*src == '/' && src[1] == '/')
			while (src[1] == '/') src++;
		else if (*src == '.') {
			if (src[1] == '.' && (src[2] == '/' || src[2] == 0)) {
				if (dst > absfile+1) --dst; /* jump to last '/' */
				while (dst > absfile+1 && dst[-1] != '/')
					--dst;
				src += 2; if (*src) src++;
				while (*src == '/') src++;
				continue;
			}
			else if (src[1] == '/' || src[1] == 0) {
				src += 1; if (*src) src++;
				while (*src == '/') src++;
				continue;
			}
		}
		*dst++ = *src++;
	}
	*dst = 0;
	/* remove trailing slashes */
	while (--dst, dst > absfile+1 && *dst == '/')
		*dst = 0;
}

static void handle_file_access_after(const char * func, const char * file,
                              struct status_t * status)
{
	char buf[PATH_MAX], *logfile, filterdir2 [PATH_MAX], *tfilterdir;
	char absfile [PATH_MAX];
	int fd; struct stat st;

#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: begin of handle_file_access_after(\"%s\", \"%s\", xxx)\n",
		getpid(), func, file);
#endif
	if ( !strcmp(file, wlog) ) return;
	if ( !strcmp(file, rlog) ) return;
	if ( lstat(file, &st) ) return;

	if ( (status != 0) && (status->inode != st.st_ino ||
	     status->size  != st.st_size || status->mtime != st.st_mtime ||
	     status->ctime != st.st_ctime) ) { logfile = wlog; }
	else { logfile = rlog; }
        if ( logfile == 0 ) return;

	/* make sure the filename is "canonical" */
	sort_of_realpath (file, absfile);

	/* We ignore access inside the collon seperated directory list
	   $FLWRAPPER_BASE, to keep the log smaller and reduce post
	   processing time. -ReneR */
	strcpy (filterdir2, filterdir); /* due to strtok - sigh */
	tfilterdir = strtok(filterdir2, ":");
	for ( ; tfilterdir ; tfilterdir = strtok(NULL, ":") )
	{
		if ( !strncmp(absfile, tfilterdir, strlen(tfilterdir)) ) {
#if DEBUG == 1
		  fprintf(stderr,
		          "fl_wrapper.so debug [%d]: \"%s\" dropped due to filterdir \"%s\"\n",
		          getpid(), absfile, tfilterdir);
#endif
		  return;
		}
	}

#ifdef __USE_LARGEFILE
	fd=open64(logfile,O_APPEND|O_WRONLY|O_LARGEFILE,0);
#else
#warning "The wrapper library will not work properly for large logs!"
	fd=open(logfile,O_APPEND|O_WRONLY,0);
#endif
	if (fd == -1) return;

    flock(fd, LOCK_EX);
    lseek(fd, 0, SEEK_END);

    sprintf(buf,"%s.%s:\t%s\n", cmdname, func, absfile);
    write(fd,buf,strlen(buf));

	close(fd);
#if DEBUG == 1
	fprintf(stderr, "fl_wrapper.so debug [%d]: end   of handle_file_access_after(\"%s\", \"%s\", xxx)\n",
		getpid(), func, file);
#endif
}
EOT
