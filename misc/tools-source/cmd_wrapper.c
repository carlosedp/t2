/*
 * --- ROCK-COPYRIGHT-NOTE-BEGIN ---
 * 
 * This copyright note is auto-generated by ./scripts/Create-CopyPatch.
 * Please add additional copyright information _after_ the line containing
 * the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
 * the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
 * 
 * ROCK Linux: rock-src/misc/tools-source/cmd_wrapper.c
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
 *  Generic command wrapper.
 *
 *  Recognised Variables:
 *
 *      prefix_WRAPPER_MYPATH		"/path/to/binary"
 *	prefix_WRAPPER_LOGFILE		".cmd_wrapper_log"
 *
 *      prefix_WRAPPER_DEBUG		0
 *      prefix_WRAPPER_BYPASS		0
 *
 *	prefix_WRAPPER_OTHERS		"other_cmd"
 *
 *	prefix_WRAPPER_INSERT		"-1st-opt -2nd-opt"
 *	prefix_WRAPPER_REMOVE		"-del-this-opt -this-also [!-]*"
 *	prefix_WRAPPER_APPEND		"-last-opt"
 *
 *      prefix_WRAPPER_FILTER		"sed '...' | awk '...' | foobar"
 *
 *	prefix_WRAPPER_NOLOOP		Internal use only.
 *
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/wait.h>
#include <libgen.h>
#include <fnmatch.h>

#ifndef ENVPREFIX
#    error You must use -DENVPREFIX=".." when compiling this tool.
#endif

#ifndef MYNAME
#    error You must use -DMYNAME=".." when compiling this tool.
#endif

#define VERBOSE_DEBUG 1
int debug=1;

/*
 *  Clean config vars before using them
 */
void cleanenv(const char * name, const char ch) {
	int pos1=0, pos2=0, delim=1;
	char *tmp1, *tmp2;

	setenv(name, "", 0); /* no overwrite - make sure it is defined */
	tmp1 = getenv(name);
	tmp2 = malloc(strlen(tmp1)+1);

	while ( tmp1[pos1] ) {
		if ( tmp1[pos1]  == ch ) {
			if ( ! delim ) {
				tmp2[pos2++] = ch;
				delim = 1;
			}
		} else {
			tmp2[pos2++] = tmp1[pos1];
			delim = 0;
		}
		pos1++;
	}
	if (pos2 > 0 && tmp2[pos2-1] == ch) pos2--;
	tmp2[pos2] = 0; setenv(name, tmp2, 1);
}

/*
 *  Main function.
 */
int main(int argc, char ** argv) {
	char **newargv;
	char *other;
	int c1,c2,c3;
	char *delim, *optbuf, *wrdir;
	FILE *logfile = NULL;

	/* Calling the wrapper with an absolute path results in an
	   endless-loop. Use basename only to force a $PATH lookup. */
	argv[0] = basename(argv[0]);
	if ( !strcmp(argv[0], MYNAME) ) {
		if ( argc > 1 ) {
			argv++; argc--;
			argv[0] = basename(argv[0]);
		} else {
			exit(250);
		}
	}

	/* Open logfile (if any) */
	delim = getenv(ENVPREFIX "_WRAPPER_LOGFILE");
	if (delim && delim[0]) {
		logfile = fopen(delim, "a");
	}
	if (logfile) {
		delim = malloc(FILENAME_MAX);
		if ( getcwd(delim, FILENAME_MAX) == NULL ) delim[0]=0;
		fprintf(logfile, "\n%s:\n-", delim);
		for (c3=0; c3<argc; c3++) fprintf(logfile, " %s", argv[c3]);
		fprintf(logfile, "\n");
		free(delim);
	}

	/*
	 *  Read prefix_WRAPPER_DEBUG and prefix_WRAPPER_BYPASS
	 */

	if ( (delim=getenv(ENVPREFIX "_WRAPPER_DEBUG")) != NULL &&
					delim[0] ) debug = atoi(delim);

	if ( (delim=getenv(ENVPREFIX "_WRAPPER_BYPASS")) != NULL &&
					delim[0] && atoi(delim)) {
#if VERBOSE_DEBUG
		if (debug) fprintf(stderr, "Bypassing cmd_wrapper by "
		                           "clearing all config variables.\n");
#endif
		setenv(ENVPREFIX "_WRAPPER_OTHERS", "", 1);
		setenv(ENVPREFIX "_WRAPPER_INSERT", "", 1);
		setenv(ENVPREFIX "_WRAPPER_REMOVE", "", 1);
		setenv(ENVPREFIX "_WRAPPER_APPEND", "", 1);
		setenv(ENVPREFIX "_WRAPPER_FILTER", "", 1);
	}

	cleanenv(ENVPREFIX "_WRAPPER_OTHERS", ':');
	cleanenv(ENVPREFIX "_WRAPPER_INSERT", ' ');
	cleanenv(ENVPREFIX "_WRAPPER_REMOVE", ' ');
	cleanenv(ENVPREFIX "_WRAPPER_APPEND", ' ');
	cleanenv(ENVPREFIX "_WRAPPER_FILTER", '|');

#if VERBOSE_DEBUG
	if (debug) {
		fprintf(stderr, "Old Command:");
		for (c3=0; c3<argc; c3++) fprintf(stderr, " %s", argv[c3]);
		fprintf(stderr, "\n");
		fprintf(stderr, "ENVPREFIX = '%s'\n", ENVPREFIX);
		fprintf(stderr, "OTHERS = '%s'\n",
				getenv(ENVPREFIX "_WRAPPER_OTHERS"));
		fprintf(stderr, "INSERT = '%s'\n",
				getenv(ENVPREFIX "_WRAPPER_INSERT"));
		fprintf(stderr, "REMOVE = '%s'\n",
				getenv(ENVPREFIX "_WRAPPER_REMOVE"));
		fprintf(stderr, "APPEND = '%s'\n",
				getenv(ENVPREFIX "_WRAPPER_APPEND"));
		fprintf(stderr, "FILTER = '%s'\n",
				getenv(ENVPREFIX "_WRAPPER_FILTER"));
	}
#endif

	/* extract the next other wrapper */
	other = strdup(getenv(ENVPREFIX "_WRAPPER_OTHERS"));
	other = strtok(other, ":");

	if (other != NULL) {
		/* if we have other wrappers remove the current one from the list */
		char *newothers = getenv(ENVPREFIX "_WRAPPER_OTHERS");
		newothers += strlen (other);
		if (*newothers == ':')
			newothers++;
		setenv (ENVPREFIX "_WRAPPER_OTHERS", newothers, 1);
	}

	/*
	 *  Make sure that newargv[] is big enough
	 */
	
	/* start with argc */
	c1 = argc;

	/* other wrapper */
	if (other)
		c1++;

	/* add numbers of blanks in prefix_WRAPPER_INSERT */
	if ( (delim=getenv(ENVPREFIX  "_WRAPPER_INSERT")) != NULL )
		while (*delim) { if (*delim==' ') c1++; delim++; }

	/* add numbers of blanks in prefix_WRAPPER_APPEND */
	if ( (delim=getenv(ENVPREFIX  "_WRAPPER_APPEND")) != NULL )
		while (*delim) { if (*delim==' ') c1++; delim++; }

	/* add 10 to be sure (3 should be enough) */
	newargv=malloc( sizeof(char*) * (c1+10) );
	
	/* init newargv[], c1 and c2 */
	c1 = c2 = 0;
	if (other)
		newargv[c1++] = other;
	newargv[c1++] = argv[c2++];

	/*
	 *  Copy options from prefix_WRAPPER_INSERT to newargv[]
	 */

	if ( (delim=getenv(ENVPREFIX  "_WRAPPER_INSERT")) != NULL ) {
		optbuf = malloc( strlen(delim) + 1 );
		strcpy(optbuf, delim);

		delim = strtok(optbuf, " ");
		while (delim != NULL) {
			if (delim[0]) {
#if VERBOSE_DEBUG
			    if (debug) fprintf(stderr, "Insert: %s\n", delim);
#endif
			    newargv[c1++] = delim;
			}
			delim = strtok(NULL, " ");
		}
	}


	/*
	 *  Copy options from argv[] to newargv[] if they are not listed
	 *  in prefix_WRAPPER_REMOVE
	 */

	for (; c2<argc; c2++) {
		if ( (delim=getenv(ENVPREFIX  "_WRAPPER_REMOVE")) != NULL ) {
			optbuf = malloc( strlen(delim) + 1 );
			strcpy(optbuf, delim);

			delim = strtok(optbuf, " ");
			while (delim != NULL) {
				if ( delim[0] &&
				     !fnmatch(delim, argv[c2], 0) ) break;
				delim = strtok(NULL, " ");
			}
			free(optbuf);
		}
		if (delim == NULL) {
#if VERBOSE_DEBUG
		    if (debug) fprintf(stderr, "Copy:   %s\n", argv[c2]);
#endif
		    newargv[c1++] = argv[c2];
#if VERBOSE_DEBUG
		} else {
		    if (debug) fprintf(stderr, "Remove: %s\n", argv[c2]);
#endif
		}
	}


	/*
	 *  Copy options from prefix_WRAPPER_APPEND to newargv[]
	 */

	if ( (delim=getenv(ENVPREFIX  "_WRAPPER_APPEND")) != NULL ) {
		optbuf = malloc( strlen(delim) + 1 );
		strcpy(optbuf, delim);

		delim = strtok(optbuf, " ");
		while (delim != NULL) {
			if (delim[0]) {
#if VERBOSE_DEBUG
			    if (debug) fprintf(stderr, "Append: %s\n", delim);
#endif
			    newargv[c1++] = delim;
			}
			delim = strtok(NULL, " ");
		}
	}
	

	/*
	 *  Use prefix_WRAPPER_FILTER if set and not ""
	 *
	 *  (Maybe we make a nice re-write of this code-block later.)
	 */

	if ( (delim=getenv(ENVPREFIX "_WRAPPER_FILTER")) != NULL && delim[0] ) {
	
		/* Open temp files. */
		char outfn[] = "/tmp/gccfilter_out.XXXXXX";
		char infn[] = "/tmp/gccfilter_in.XXXXXX";
		int outfd = mkstemp(outfn);
		int infd = mkstemp(infn);
	
		/* Create content of input file */
		for (c3=0; c3<c1; c3++) {
			write(infd, newargv[c3], strlen(newargv[c3]));
			write(infd, "\n", 1);
		}
		lseek(infd, 0, SEEK_SET);
	
		/* Run filter command with shell (sh -c xxx) */
#if VERBOSE_DEBUG
		if (debug) fprintf(stderr, "Run Filter: %s\n", delim);
#endif
		if (!fork()) {
			dup2(infd,  0);  close(infd);
			dup2(outfd, 1);  close(outfd);
			execlp("sh", "sh", "-c", delim, NULL);
			return 1;
		}
		wait(NULL);  /* We don't expect any signals and have no */
		             /* other child processes. */
	
		/* Re-read parameter list. Don't free old stuff, we do an
		   exec() anyway ... */
		lseek(outfd, 0, SEEK_SET);
		/* Maximum on 1023 parameters, 1023 chars each. */
		newargv = malloc( sizeof(char*) * 1024 );
		for (c1=0; c1<1023; c1++) {
			newargv[c1] = malloc(1024);
			for (c2=0; c2<1023; c2++) {
				if (read(outfd, newargv[c1]+c2, 1) != 1)
						goto reread_file_finished;
				if (newargv[c1][c2] == '\n')
						{ newargv[c1][c2] = 0; break; }
			}
			newargv[c1] = realloc(newargv[c1],
			                      strlen(newargv[c1])+1);
		}
reread_file_finished:
	
		/* Close and remove temp files */
		close(outfd); unlink(outfn);
		close(infd);  unlink(infn);
	}

	/*
	 *  Detect loops
	 */
	
	if ( (delim=getenv(ENVPREFIX "_WRAPPER_NOLOOP")) != NULL &&
					delim[0] && delim[0] != '0') {
		return 250;
	}
	setenv(ENVPREFIX "_WRAPPER_NOLOOP", "1", 1);

	/*
	 *  Remove the wrapper dir from PATH
	 */

	if ( (delim=getenv("PATH")) != NULL && delim[0] &&
	     (wrdir=getenv(ENVPREFIX "_WRAPPER_MYPATH")) != NULL &&
								wrdir[0] ) {
		optbuf = malloc( strlen(delim) + 1 );
		optbuf[0] = 0;
	
#if VERBOSE_DEBUG
		if (debug)
			fprintf(stderr, "Old PATH: %s\n", delim);
#endif
	
		delim = strtok(delim, ":");
		while ( delim != NULL ) {
			if (strcmp(delim, wrdir)) {
				if (optbuf[0]) strcat(optbuf, ":");
				strcat(optbuf, delim);
			}
			delim = strtok(NULL, ":");
		}
		setenv("PATH", optbuf, 1);

#if VERBOSE_DEBUG
		if (debug) fprintf(stderr, "New PATH: %s\n", optbuf);
#endif
	} else {
		return 250;
	}

	/*
	 * Run other wrappers first. They will re-start us.
	 */

	if (other != NULL) {

#if VERBOSE_DEBUG
		if (debug) {
		  fprintf(stderr,
			  "Running external wrapper: %s\n", newargv[0]);
		  for (c3=0; c3<c1; c3++)
		    fprintf(stderr, " %s", newargv[c3]);
		  fprintf(stderr, "\n");
		}
#endif

		if (logfile) {
			fprintf(logfile, "+");
			for (c3=0; c3<=c1; c3++)
					fprintf(logfile, " %s", newargv[c3]);
			fprintf(logfile, "\n");
			fclose(logfile);
		}
		execvp(newargv[0], newargv);
		return 250;
	}

	/*
	 *  Run the new command
	 */
	
#if VERBOSE_DEBUG
	if (debug) {
		fprintf(stderr, "New Command:");
		for (c3=0; c3<c1; c3++) fprintf(stderr, " %s", newargv[c3]);
		fprintf(stderr, "\n");
	}
#endif

	if (logfile) {
		fprintf(logfile, "+");
		for (c3=0; c3<c1; c3++) fprintf(logfile, " %s", newargv[c3]);
		fprintf(logfile, "\n");
		fclose(logfile);
	}

	newargv[c1]=NULL;
	execvp(newargv[0], newargv);
	
	return 250;
}
