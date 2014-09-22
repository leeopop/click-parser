/*
 * parser.c
 *
 *  Created on: Aug 10, 2014
 *      Author: leeopop
 */

#include "click_lex.h"
#include "click_yacc.h"
#include "node.h"
#include "resource.h"
#include "click_parser.h"
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <memory.h>
#include <assert.h>
#include <stdio.h>
#include <stdbool.h>

List* __click_modules = 0;
Map* __click_symbol_table = 0;
List* __click_edges = 0;

Node* makeData(enum NodeType type, const char* string)
{
	switch(type)
	{
	case Node_STRING:
	{
		const char* start, *end;
		start = string+1;
		end = string+strlen(string)-1;
		Node* ret = (Node*)alloc_resource(sizeof(Node) + (end-start)+1);
		ret->type = type;
		strncpy(ret->payload, start, end-start);
		ret->payload[end-start] = 0;
		return ret;
	}
	case Node_INTEGER:
	case Node_TOKEN:
	case Node_IDENTIFIER:
	{
		const char* start, *end;
		start = string;
		end = string+strlen(string);
		Node* ret = (Node*)alloc_resource(sizeof(Node) + (end-start)+1);
		ret->type = type;
		strncpy(ret->payload, start, end-start);
		ret->payload[end-start] = 0;
		return ret;
	}
	default:
		printf("Node fail: %d\n", type);
		return 0;
	}
}

void init_list(List* list)
{
	list->list = alloc_resource(sizeof(void*));
	list->capacity = 1;
	list->len = 0;
}
void add_list(List* list, void* item)
{
	list->list[list->len++] = item;
	if(list->len == list->capacity)
	{
		list->capacity = list->capacity*2;
		void** new_list = (void**)alloc_resource(sizeof(void*) * list->capacity);
		memcpy(new_list, list->list, sizeof(void*)*list->len);
		//free(list->list);
		list->list = new_list;
	}
}

void init_map(Map* map)
{
	map->key_list = alloc_resource(sizeof(List));
	map->val_list = alloc_resource(sizeof(List));

	init_list(map->key_list);
	init_list(map->val_list);
}
void* find_map(Map* map, const void* key, int keylen)
{
	int k;
	for(k=0; k<map->key_list->len; k++)
	{
		Key* target = (Key*)map->key_list->list[k];
		if(target->keylen == keylen)
		{
			if(0 == memcmp(target->data, key, keylen))
				return map->val_list->list[k];
		}
	}
	return 0;
}
void add_map(Map* map, const void* key, int keylen, void* item)
{
	assert(0 == find_map(map, key, keylen));
	Key* new_key = alloc_resource(sizeof(Key) + keylen);
	memcpy(new_key->data, key, keylen);
	new_key->keylen = keylen;

	add_list(map->key_list, new_key);
	add_list(map->val_list, item);
}

int create_graph(FILE* input)
{
	yylex_destroy();
	__click_modules = alloc_resource(sizeof(List));
	__click_symbol_table = alloc_resource(sizeof(Map));
	__click_edges = alloc_resource(sizeof(List));
	init_list(__click_modules);
	init_map(__click_symbol_table);
	init_list(__click_edges);

	yyset_in(input);
	int ret = yyparse();
	yylex_destroy();

	int k;
	for(k=0; k<__click_modules->len; k++)
	{
		Node* node = (Node*)__click_modules->list[k];
		assert(node->type == Node_MODULE);
		Module* module = (Module*)node->payload;
		printf("%s::\t", module->name->payload);
		ArgList* arglist = (ArgList*)module->args->payload;
		int j;
		for(j=0; j<arglist->len; j++)
		{
			Node* eacharg = (Node*)arglist->list[j];
			if(eacharg == NULL)
			{
				printf("NULL ");
			}
			else if(eacharg->type == Node_VALUE_LIST)
			{
				ValueList* valuelist = (ValueList*)eacharg->payload;
				int i;
				for(i=0; i<valuelist->len; i++)
				{
					Node* eachval = (Node*)valuelist->list[i];
					printf("%s ", eachval->payload);
				}
				printf(", ");
			}
			else
			{
				assert(0);
			}

		}
		printf("\n");
	}

	clear_resource();
	__click_modules = 0;
	__click_symbol_table = 0;
	__click_edges = 0;

	return ret;
}

struct click_parseinfo
{
	void** all_modules;
	int no_modules;
	void** root_modules;
	int no_root;
	void** leaf_modules;
	int no_leaf;
};

static char* vlist_to_string(ValueList* vlist)
{
	int i;
	int total_len = 0;
	for(i=0; i<vlist->len; i++)
	{
		Node* eachval = (Node*)vlist->list[i];
		total_len += strlen(eachval->payload) + 1;
	}

	char* ret = (char*)alloc_resource(total_len);
	*ret = 0;

	for(i=0; i<vlist->len; i++)
	{
		Node* eachval = (Node*)vlist->list[i];
		strcat(ret, eachval->payload);

		if((i+1) != vlist->len)
			strcat(ret, " ");
	}
	return ret;
}

ParseInfo* click_parse_configuration(FILE* input, ClickAllocator alloc, ClickLinker link, void* obj)
{
	ParseInfo* ret = 0;
	yylex_destroy();
	__click_modules = alloc_resource(sizeof(List));
	__click_symbol_table = alloc_resource(sizeof(Map));
	__click_edges = alloc_resource(sizeof(List));
	init_list(__click_modules);
	init_map(__click_symbol_table);
	init_list(__click_edges);

	yyset_in(input);
	int parse_result = yyparse();
	yylex_destroy();

	if(parse_result == 0)
	{
		int no_modules = __click_modules->len;
		ret = malloc(sizeof(ParseInfo));
		ret->all_modules = malloc(sizeof(void*)*no_modules);
		ret->root_modules = malloc(sizeof(void*)*no_modules);
		ret->leaf_modules = malloc(sizeof(void*)*no_modules);
		ret->no_modules = no_modules;
		ret->no_root = 0;
		ret->no_leaf = 0;

		int k;
		for(k=0; k<no_modules; k++)
		{
			Node* node = (Node*)__click_modules->list[k];
			assert(node->type == Node_MODULE);
			Module* module = (Module*)node->payload;
			char* module_name = module->name->payload;
			assert(module->args->type == Node_ARG_LIST);
			ArgList* arglist = (ArgList*)module->args->payload;
			char** argv = alloc_resource(sizeof(char*) * (arglist->len + 1));
			argv[arglist->len] = 0;
			int argc = arglist->len;
			int j;
			for(j=0; j<arglist->len; j++)
			{
				Node* eacharg = (Node*)arglist->list[j];
				char* value_str = 0;
				if(eacharg == NULL)
				{
				}
				else if(eacharg->type == Node_VALUE_LIST)
				{
					ValueList* valuelist = (ValueList*)eacharg->payload;
					value_str = vlist_to_string(valuelist);
				}
				else
				{
					assert(0);
				}
				argv[j] = value_str;
			}

			void* user_module = 0;
			if(alloc)
				user_module = alloc(k, module_name, argc, argv, obj);
			ret->all_modules[k] = user_module;
		}

		int* inward = alloc_resource(sizeof(int)*no_modules);
		int* outward = alloc_resource(sizeof(int)*no_modules);

		for(k=0; k<no_modules; k++)
		{
			inward[k] = 0;
			outward[k] = 0;
		}

		for(k=0; k<__click_edges->len; k++)
		{
			Chain* edge = (Chain*)__click_edges->list[k];
			assert(edge->head->type == Node_MODULE);
			assert(edge->tail->type == Node_MODULE);

			Module* head = (Module*)edge->head->payload;
			Module* tail = (Module*)edge->tail->payload;

			if(link)
				link(ret->all_modules[head->index], edge->head_outport, ret->all_modules[tail->index], edge->tail_inport, obj);

			inward[tail->index]++;
			outward[head->index]++;
		}

		for(k=0; k<no_modules; k++)
		{
			if(inward[k] == 0)
			{
				ret->root_modules[ret->no_root++] = ret->all_modules[k];
			}
			if(outward[k] == 0)
			{
				ret->leaf_modules[ret->no_leaf++] = ret->all_modules[k];
			}
		}
	}
	clear_resource();
	__click_modules = 0;
	__click_symbol_table = 0;
	__click_edges = 0;

	return ret;
}

void click_destroy_configuration(ParseInfo* info)
{
	free(info->all_modules);
	free(info->leaf_modules);
	free(info->root_modules);
	free(info);
}

int click_num_module(ParseInfo* info)
{
	return info->no_modules;
}
int click_num_leaf(ParseInfo* info)
{
	return info->no_leaf;
}
int click_num_root(ParseInfo* info)
{
	return info->no_root;
}
void* click_get_module(ParseInfo* info,int index)
{
	assert(index >= 0 && index < info->no_modules);
	return info->all_modules[index];
}
void* click_get_leaf(ParseInfo* info, int index)
{
	assert(index >= 0 && index < info->no_leaf);
	return info->leaf_modules[index];
}
void* click_get_root(ParseInfo* info, int index)
{
	assert(index >= 0 && index < info->no_root);
	return info->root_modules[index];
}
