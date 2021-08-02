/*
 * --- T2-COPYRIGHT-NOTE-BEGIN ---
 * This copyright note is auto-generated by scripts/Create-CopyPatch.
 * 
 * T2 SDE: misc/tools-source/cmd_wrapper.c
 * Copyright (C) 2004 - 2021 The T2 SDE Project
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
 *	prefix_WRAPPER_OTHERS_DONE	Internal use only.
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
#include <errno.h>

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
 * Evaluate conditional argument in the form:
 * "condition?matched-value:unmatched-value"
 */
char* eval_cond_arg (char * arg, int argc, char ** argv) {
	char * c = arg;
	char * lhs = NULL, * rhs = NULL;

	/* look for '?' */
	while (*c && *c != '?') c++;

	if (*c != '?') {
		return arg;
	}
#if VERBOSE_DEBUG
	if (debug) fprintf(stderr, "Conditonal arg: '%s'\n", arg);
#endif

	/* split conditional (arg), left hand and right hand statement */
	*c++ = 0;
	lhs = c;

	/* look for ':' */
	while (*c && *c != ':') c++;
	if (*c == ':')
		*c++ = 0;
	rhs = c;

	if (debug) fprintf(stderr, "Conditonal: '%s', lhs: '%s', rhs: '%s'\n", arg, lhs, rhs);

	/* match arguments against conditional */
	while (argc--)
	{
		if (!fnmatch(arg, *argv, 0)) {
#if VERBOSE_DEBUG
			if (debug) fprintf(stderr, "Conditonal: '%s', matched: '%s'\n", arg, *argv);
#endif
			return lhs;
		}
		argv++;
	}

	return rhs;
}

/* newargv memory management, realloc if newargv is filled */
static inline char** realloc_if_needed(int c1, int* newargc, char** newargv) {
	if (c1 + 1 >= *newargc) { /* +1 for NULL-sentinel */
		*newargc *= 2;
		newargv = realloc (newargv, sizeof(char*) * *newargc);
	}
	return newargv;
}

/*
 *  Main function.
 */
int main(int argc, char ** argv) {
	int newargc = 64; /* initial newargv size, anyhting >3 (name, other, NULL) */
	char **newargv;
	char *other, *other_done;
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
		if (getenv(ENVPREFIX "_WRAPPER_OTHERS_DONE"))
		fprintf(stderr, "OTHERS DONE = '%s'\n",
				getenv(ENVPREFIX "_WRAPPER_OTHERS_DONE"));
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
	other = getenv(ENVPREFIX "_WRAPPER_OTHERS");
	other_done = getenv(ENVPREFIX "_WRAPPER_OTHERS_DONE");
	
	if (other && strlen(other) > 0) {
		other = strdup(other);
		char *newother_done;
		
		if (other_done) {
			char *str = strstr(other, other_done);
			if (str != other) {
				fprintf(stderr, "OTHERS_DONE set but does not match.\n");
				return 249;
			}

			other += strlen(other_done);
			if (*other == 0) {
			  other = 0;
			}
			else {
			  if (*other == ':') 
			    other++;
			
			  newother_done = (char *) malloc(strlen(getenv(ENVPREFIX "_WRAPPER_OTHERS")));
			  strcpy(newother_done, other_done);
			  strcat(newother_done, ":");
			  strcat(newother_done, other);

			  setenv(ENVPREFIX "_WRAPPER_OTHERS_DONE", newother_done, 1);
			}
		}
		else {
			other = strtok(other, ":");
			setenv(ENVPREFIX "_WRAPPER_OTHERS_DONE", other, 1);
		}
	}

	/*
	 *  Main work.
	 */
	
	newargv = malloc( sizeof(char*) * newargc );
	
	/* init newargv[], c1 and c2 */
	c1 = c2 = 0;
	if (other && strlen(other) > 0)
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
			delim = eval_cond_arg (delim, argc, argv);

			if (delim[0]) {
#if VERBOSE_DEBUG
			    if (debug) fprintf(stderr, "Insert: %s\n", delim);
#endif
			    newargv = realloc_if_needed(c1, &newargc, newargv);
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
				delim = eval_cond_arg (delim, argc, argv);
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

		    newargv = realloc_if_needed(c1, &newargc, newargv);
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
			delim = eval_cond_arg (delim, argc, argv);
			if (delim[0]) {
#if VERBOSE_DEBUG
			    if (debug) fprintf(stderr, "Append: %s\n", delim);
#endif

			    newargv = realloc_if_needed(c1, &newargc, newargv);
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
		int pid, status;
	
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
		pid = fork();
		if (!pid) {
			dup2(infd,  0);  close(infd);
			dup2(outfd, 1);  close(outfd);
			execlp("sh", "sh", "-c", delim, NULL);
			return 1;
		} else if (pid == -1) {
			fprintf(stderr, "Fork failed: %d: %s\n", errno, strerror(errno));
		} else {
			/* We don't expect any signals and have no other child processes. */
			wait(&status);
			if (WEXITSTATUS(status) != 0) {
				fprintf(stderr, "Filter failed: %d\n", WEXITSTATUS(status));
			}
		}
	
		/* Re-read parameter list. */
		{
		  size_t argvsize = lseek(outfd, 0, SEEK_END);
		  char* argvmem = malloc (argvsize + 1); /* might not have trailing \n */
		  lseek(outfd, 0, SEEK_SET);
		  read(outfd, argvmem, argvsize);

		  if (argvsize == 0) {
			  fprintf(stderr, "Filter produced no output!\n");
			  return 248;
		  }

		  for (c1 = c2 = 0; c2 < argvsize; ++c2) {
			newargv = realloc_if_needed(c1, &newargc, newargv);
			newargv[c1++] = argvmem + c2;

			/* scan for newlines, terminate, next */
			while (c2 < argvsize && argvmem[c2] != '\n')
				++c2;
			argvmem[c2] = 0;
		  }
		}
	
		/* Close and remove temp files */
		close(outfd); unlink(outfn);
		close(infd);  unlink(infn);
	}

	/*
	 * Run other wrappers first. They will re-start us.
	 */

	if (other && strlen(other) > 0) {

#if VERBOSE_DEBUG
		if (debug) {
		  fprintf(stderr, "Running external wrapper: %s\n", newargv[0]);
		  for (c3=0; c3<c1; c3++)
		    fprintf(stderr, " %s", newargv[c3]);
		  fprintf(stderr, "\n");
		}
#endif

		if (logfile) {
			fprintf(logfile, "+");
			for (c3=0; c3<c1; c3++)
					fprintf(logfile, " %s", newargv[c3]);
			fprintf(logfile, "\n");
			fclose(logfile);
		}

		newargv[c1] = NULL;
		execvp(newargv[0], newargv);
		fprintf(stderr, "cmd_wrapper: execvp(%s,...) - %s\n", 
			newargv[0], strerror(errno));

		return 253;
	}

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
		return 252;
	}

	/*
	 *  Detect loops
	 */
	
	if ( (delim=getenv(ENVPREFIX "_WRAPPER_NOLOOP")) != NULL &&
					delim[0] && delim[0] != '0') {
		return 251;
	}
	setenv(ENVPREFIX "_WRAPPER_NOLOOP", "1", 1);

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
	fprintf(stderr, "cmd_wrapper: execvp(%s,...) - %s\n", 
		newargv[0], strerror(errno));
	
	return 254;
}