/*
 * node.h
 *
 *  Created on: Aug 10, 2014
 *      Author: leeopop
 */

#ifndef NODE_H_
#define NODE_H_

enum NodeType
{
	Node_IPv4_ADDR,
	Node_IPv6_ADDR,
	Node_DEC_INTEGER,
	Node_HEX_INTEGER,
	Node_ETHER_ADDR,
	Node_STRING,
	Node_PAIR,
	Node_IDENTIFIER,
	Node_VALUE_LIST,
	Node_ARG_LIST,
	Node_CHAIN_ELEMENT,
	Node_MODULE,
	Node_ARROW,
};



typedef struct {
	enum NodeType type;
	char payload[0];
}Node;

typedef struct  {
	Node* left;
	Node* right;
}Pair;

typedef struct  {
	void** list;
	int len;
	int capacity;
}List;

typedef struct  {
	Node* name;
	Node* args;
	int index;
}Module;

typedef struct  {
	Node* head;
	int head_outport;
	Node* tail;
	int tail_inport;
}Chain;

typedef struct  {
	Node* head;
	Node* tail;
}ChainElement;

typedef struct  {
	int head_outport;
	int tail_inport;
}Arrow;

typedef List ValueList;
typedef List ArgList;

typedef struct
{
	int keylen;
	char data[0];
}Key;

typedef struct {
	List* key_list;
	List* val_list;
}Map;

void init_list(List* list);
void add_list(List* list, void* item);
Node* makeData(enum NodeType type, const char* string);

void init_map(Map* map);
void* find_map(Map* map, const void* key, int keylen);
void add_map(Map* map, const void* key, int keylen, void* item);
#endif /* NODE_H_ */
