/*
 * test.c
 *
 *  Created on: Aug 10, 2014
 *      Author: leeopop
 */


#include <stdio.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <getopt.h>
#include <unistd.h>

#include "click_lex.h"
#include "click_yacc.h"

int main(int argc, char** argv)
{
	char* config_dir = 0;
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
				{"config-dir",	required_argument,	0,	0},
				{0,	0,	0,	0}
		};

		int c = getopt_long(argc, argv, "",
				long_options, &option_index);
		if (c == -1)
			break;

		switch (c) {
		case 0:
			switch(option_index)
			{
			case 0:
			{
				config_dir = optarg;
			}
			}
			break;

		default:
			printf("?? getopt returned character code 0%o ??\n", c);
		}
	}

	struct dirent *entry;
	DIR *dir;

	if ((dir = opendir(config_dir)) == NULL)
	{
		fprintf(stderr, "Can't open %s\n", config_dir);
		return 0;
	}

	char filename[FILENAME_MAX+1];

	while ((entry = readdir(dir)) != NULL)
	{
		if(entry->d_type == DT_REG)
		{
			snprintf(filename, sizeof(filename), "%s/%s", config_dir, entry->d_name);

			FILE* input = fopen(filename, "r");

			yylex_destroy();
			yyset_in(input);
			while(1)
			{
				int lex_ret = yylex();
				if(lex_ret == 0)
					break;
				if(lex_ret == OTHER_VALUE)
				{
					printf("%s ", filename);
					//printf("%d, %d: %s\n",lex_ret, yyget_leng(), yyget_text());
					break;
				}
			}

			fclose(input);
		}
	}

	return 0;
}
