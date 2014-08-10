/*
 * resource.c
 *
 *  Created on: Aug 11, 2014
 *      Author: leeopop
 */


#include "resource.h"
#include <stdlib.h>

typedef struct resource
{
	void* ptr;
	struct resource* next;
}Resource;

static Resource* total_resource = 0;

void* alloc_resource(int size)
{
	Resource* cur = malloc(sizeof(Resource));
	cur->next = total_resource;
	cur->ptr = malloc(size);
	total_resource = cur;
	return cur->ptr;
}
void clear_resource(void)
{
	while(total_resource)
	{
		Resource* next = total_resource->next;
		free(total_resource->ptr);
		free(total_resource);
		total_resource = next;
	}
}
