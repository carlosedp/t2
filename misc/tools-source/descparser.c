/*
 * --- ROCK-COPYRIGHT-NOTE-BEGIN ---
 *
 * This copyright note is auto-generated by ./scripts/Create-CopyPatch.
 * Please add additional copyright information _after_ the line containing
 * the ROCK-COPYRIGHT-NOTE-END tag. Otherwise it might get removed by
 * the ./scripts/Create-CopyPatch script. Do not edit this copyright text!
 *
 * ROCK Linux: rock-src/misc/tools-source/descparser.c
 * ROCK Linux is Copyright (C) 1998 - 2004 Clifford Wolf
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
 */

/* this is a 1st proof-of-concept implementation */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <regex.h>

int check_condition(const char *cond)
{
	char *t = strdup(cond);
	char *left  = strtok(t, " \t\n");
	char *op    = strtok(0, " \t\n");
	char *right = strtok(0, " \t\n");
	int retcode = 0;

	if ( !strcmp(op, "==") ) {
		char regex[strlen(right)+3];
		char *text = getenv(left);
		regex_t re;

		sprintf(regex, "^%s$", right);
		if ( !text ) text = "_undef_";

		if ( regcomp(&re, regex, REG_EXTENDED|REG_NOSUB) ) {
			fprintf(stderr, "failed to compile regex: '%s'.\n", right);
			exit(1);
		}
		if ( !regexec(&re, text, 0, 0, 0) ) retcode = 1;
		regfree(&re);
	} else {
		fprintf(stderr, "Unknown operator: '%s'.\n", op);
		exit(1);
	}
	
	free(t);
	return retcode;
}

int main()
{
	char line[4096];
	int condstack[128];
	int condcount = -1;
	int falselevel = 0;

	while ( fgets(line, 4096, stdin) ) {
		if (line[0] == '#') {
			if ( !strncmp(line, "#if ", 4) ) {
				condstack[++condcount] = check_condition(line+4);
				if ( !condstack[condcount] ) falselevel++;
			} else
			if ( !strncmp(line, "#else", 5) ) {
				falselevel += condstack[condcount] ? +1 : -1;
				condstack[condcount] = !condstack[condcount];
			} else
			if ( !strncmp(line, "#elsif ", 7) ) {
				if ( !condstack[condcount] ) {
					condstack[condcount] = check_condition(line+7);
					if ( condstack[condcount] ) falselevel--;
				} else
					falselevel++;
			} else
			if ( !strncmp(line, "#endif", 6) ) {
				if ( !condstack[condcount--] ) falselevel--;
			}
		} else
			if ( !falselevel )
				fputs(line, stdout);
	}

	return 0;
}

