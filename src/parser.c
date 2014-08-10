/*
 * parser.c
 *
 *  Created on: Aug 10, 2014
 *      Author: leeopop
 */


#include "node.h"
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/ether.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <memory.h>
#include <assert.h>

Node* makeData(enum NodeType type, const char* string)
{
	switch(type)
	{
	case Node_IPv4_ADDR:
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(struct in_addr));
		ret->type = type;
		if(!inet_aton(string, (struct in_addr*)ret->payload))
		{
			free(ret);
			return 0;
		}
		return ret;
	}
	case Node_IPv6_ADDR:
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(struct in6_addr));
		ret->type = type;
		if(!inet_pton(AF_INET6, string, (struct in6_addr*)ret->payload))
		{
			free(ret);
			return 0;
		}
		return ret;
	}
	case Node_DEC_INTEGER:
	case Node_HEX_INTEGER:
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(uint32_t));
		ret->type = type;
		long value = strtol(string, 0, 0);
		uint32_t* payload = (uint32_t*)ret->payload;
		*payload = (uint32_t)value;

		return ret;
	}
	case Node_ETHER_ADDR:
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(struct ether_addr));
		ret->type = type;
		if(!ether_aton_r(string, (struct ether_addr*)ret->payload))
		{
			free(ret);
			return 0;
		}
		return ret;
	}
	case Node_STRING:
	{
		const char* start, *end;
		start = string+1;
		end = string+strlen(string)-1;
		Node* ret = (Node*)malloc(sizeof(Node) + (end-start)+1);
		ret->type = type;
		strncpy(ret->payload, start, end-start);
		ret->payload[end-start] = 0;
		return ret;
	}
	case Node_IDENTIFIER:
	{
		const char* start, *end;
		start = string;
		end = string+strlen(string);
		Node* ret = (Node*)malloc(sizeof(Node) + (end-start)+1);
		ret->type = type;
		strncpy(ret->payload, start, end-start);
		ret->payload[end-start] = 0;
		return ret;
	}
	default:
		return 0;
	}
}

void init_list(List* list)
{
	list->list = malloc(sizeof(void*));
	list->capacity = 1;
	list->len = 0;
}
void add_list(List* list, void* item)
{
	list->list[list->len++] = item;
	if(list->len == list->capacity)
	{
		list->capacity = list->capacity*2;
		void** new_list = (void**)malloc(sizeof(void*) * list->capacity);
		memcpy(new_list, list->list, sizeof(void*)*list->len);
		free(list->list);
		list->list = new_list;
	}
}

void init_map(Map* map)
{
	map->key_list = malloc(sizeof(List));
	map->val_list = malloc(sizeof(List));

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
	Key* new_key = malloc(sizeof(Key) + keylen);
	memcpy(new_key->data, key, keylen);
	new_key->keylen = keylen;

	add_list(map->key_list, new_key);
	add_list(map->val_list, item);
}
