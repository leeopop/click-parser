/*
 * click_parser.h
 *
 *  Created on: Aug 10, 2014
 *      Author: leeopop
 */

#ifndef CLICK_PARSER_H_
#define CLICK_PARSER_H_

#include <stdio.h>
struct click_parseinfo;

typedef struct click_parseinfo ParseInfo;

typedef void* (*ClickAllocator)(int global_index, const char* module_name, int argc, char** argv, void* obj);
typedef void (*ClickLinker)(void* from_module, int from_output, void* to_module, int to_input, void* obj);

ParseInfo* click_parse_configuration(FILE* input, ClickAllocator alloc, ClickLinker link, void* obj);
void click_destroy_configuration(ParseInfo* info);

int click_num_module(ParseInfo* info);
int click_num_leaf(ParseInfo* info);
int click_num_root(ParseInfo* info);
void* click_get_module(ParseInfo* info,int index);
void* click_get_leaf(ParseInfo* info, int index);
void* click_get_root(ParseInfo* info, int index);

#endif /* CLICK_PARSER_H_ */
