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
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/ether.h>
#include <sys/socket.h>
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


	clear_resource();

	return ret;
}
