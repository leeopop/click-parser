%{
#include "click_lex.h"
#include "node.h"
#include "resource.h"

#define YYSTYPE Node*
extern List* __click_modules;
extern Map* __click_symbol_table;
extern List* __click_edges;
%}


%token IDENTIFIER DEFINE ARROW_TAIL ARROW_HEAD 
%token TOKEN INTEGER STRING

%start program

%%
program:
	statement_list
	;

statement_list:
	statement_list statement
	|
	statement
	;

identifier:
	IDENTIFIER
	{
		Node* ret = makeData(Node_IDENTIFIER, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	;

integer:
	INTEGER
	{
		Node* ret = makeData(Node_INTEGER, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	;

value:
	integer
	{
		$$ = $1;
	}
	|
	string
	{
		$$ = $1;
	}
	|
	identifier
	{
		$$ = $1;
	}
	;

string:
	STRING
	{
		Node* ret = makeData(Node_STRING, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	|
	TOKEN
	{
		Node* ret = makeData(Node_TOKEN, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	;

value_set:
	value_set value
	{
		if($1->type != Node_VALUE_LIST)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		ValueList* vlist = (ValueList*)$1->payload;
		add_list(vlist, $2);
		$$ = $1;
	}
	|
	value
	{
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(ValueList));
		ValueList* vlist = (ValueList*)ret->payload;
		init_list(vlist);
		
		ret->type = Node_VALUE_LIST;
		add_list(vlist, $1);
		$$ = ret;
	}
	;
arg_list:
	arg_list ',' value_set
	{
		if($1->type != Node_ARG_LIST)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		ArgList* alist = (ArgList*)$1->payload;
		
		add_list(alist, $3);
		$$ = $1;
	}
	|
	arg_list ',' ARROW_TAIL
	{
		if($1->type != Node_ARG_LIST)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		ArgList* alist = (ArgList*)$1->payload;
		add_list(alist, 0);
		$$ = $1;
	}
	|
	value_set
	{
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(ArgList));
		ArgList* alist = (ArgList*)ret->payload;
		init_list(alist);
		ret->type = Node_ARG_LIST;
		add_list(alist, $1);
		$$ = ret;
	}
	|
	ARROW_TAIL
	{
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(ArgList));
		ArgList* alist = (ArgList*)ret->payload;
		init_list(alist);
		ret->type = Node_ARG_LIST;
		add_list(alist, 0);
		$$ = ret;
	}
	;

module:
	identifier '(' arg_list ')'
	{
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Module));
		ret->type = Node_MODULE;
		Module* module = (Module*)ret->payload;
		module->name = $1;
		module->args = $3;
		module->index = __click_modules->len;
		add_list(__click_modules, ret);
		$$ = ret;
	}
	|
	identifier '(' ')'
	{
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Module));
		ret->type = Node_MODULE;
		Module* module = (Module*)ret->payload;
		module->name = $1;
		Node* ret2 = (Node*)alloc_resource(sizeof(Node) + sizeof(ArgList));
		ArgList* alist = (ArgList*)ret2->payload;
		init_list(alist);
		ret2->type = Node_ARG_LIST;
		
		module->args = ret2;
		module->index = __click_modules->len;
		add_list(__click_modules, ret);
		$$ = ret;
	}

chain_element:
	module
	{
		$$ = $1;
	}
	|
	identifier
	{
		if($1->type != Node_IDENTIFIER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* iter = 0;
		const char* key = ($1->payload);
		iter = find_map(__click_symbol_table, key, strlen(key));
		if(iter == 0)
		{
			Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Module));
			ret->type = Node_MODULE;
			Module* module = (Module*)ret->payload;
			module->name = $1;
			module->index = __click_modules->len;
			
			Node* ret2 = (Node*)alloc_resource(sizeof(Node) + sizeof(ArgList));
			ArgList* alist = (ArgList*)ret2->payload;
			init_list(alist);
			ret2->type = Node_ARG_LIST;
			
			module->args = ret2;
			
			
			add_list(__click_modules, ret);
			$$ = ret;
		}
		else
			$$ = iter;
	}
	|
	identifier DEFINE module
	{
		if($1->type != Node_IDENTIFIER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* iter = 0;
		const char* key = ($1->payload);
		iter = find_map(__click_symbol_table, key, strlen(key));
		if(iter != 0)
		{
			printf("%d ",__LINE__);printf("Redefinition of module %s\n", $1->payload);
			YYABORT;
		}
		
		add_map(__click_symbol_table, key, strlen(key), $3);
		$$ = $3;
	}
	|
	identifier DEFINE identifier
	{
		if(($1->type != Node_IDENTIFIER)
		|
		($3->type != Node_IDENTIFIER))
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* iter = 0;
		const char* key = ($1->payload);
		iter = find_map(__click_symbol_table, key, strlen(key));
		if(iter != 0)
		{
			printf("%d ",__LINE__);printf("Redefinition of module %s\n", $1->payload);
			YYABORT;
		}
		
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Module));
		ret->type = Node_MODULE;
		Module* module = (Module*)ret->payload;
		module->name = $3;
		module->index = __click_modules->len;
		
		Node* ret2 = (Node*)alloc_resource(sizeof(Node) + sizeof(ArgList));
		ArgList* alist = (ArgList*)ret2->payload;
		init_list(alist);
		ret2->type = Node_ARG_LIST;
		
		module->args = ret2;
		add_list(__click_modules, ret);
		add_map(__click_symbol_table, key, strlen(key), ret);
		$$ = ret;
	}
	;

arrow:
	ARROW_TAIL ARROW_HEAD
	{
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Arrow));
		ret->type = Node_ARROW;
		Arrow* arrow = (Arrow*)ret->payload;
		arrow->head_outport = 0;
		arrow->tail_inport = 0;
		
		$$ = ret;
	}
	|
	'[' integer ']' ARROW_TAIL ARROW_HEAD
	{
		Node* num1 = $2;
		if(num1->type != Node_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Arrow));
		ret->type = Node_ARROW;
		Arrow* arrow = (Arrow*)ret->payload;
		arrow->head_outport = atoi($2->payload);
		arrow->tail_inport = 0;
		
		$$ = ret;
	}
	|
	ARROW_TAIL ARROW_HEAD '[' integer ']'
	{
		Node* num2 = $4;
		if(num2->type != Node_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Arrow));
		ret->type = Node_ARROW;
		Arrow* arrow = (Arrow*)ret->payload;
		arrow->head_outport = 0;
		arrow->tail_inport = atoi($4->payload);
		
		$$ = ret;
	}
	|
	'[' integer ']' ARROW_TAIL ARROW_HEAD '[' integer ']'
	{
		Node* num1 = $2;
		if(num1->type != Node_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* num2 = $7;
		if(num2->type != Node_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(Arrow));
		ret->type = Node_ARROW;
		Arrow* arrow = (Arrow*)ret->payload;
		arrow->head_outport = atoi($2->payload);
		arrow->tail_inport = atoi($7->payload);
		
		$$ = ret;
	}
	;

chain_element2:
	chain_element
	{
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(ChainElement));
		ret->type = Node_CHAIN_ELEMENT;
		ChainElement* chain = (ChainElement*)ret->payload;
		chain->head = $1;
		chain->tail = $1;
		
		$$ = ret;
	}
	;

chain:
	chain arrow chain_element2
	{
		if($1->type != Node_CHAIN_ELEMENT)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		if($2->type != Node_ARROW)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		if($3->type != Node_CHAIN_ELEMENT)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Arrow* arrow = (Arrow*)$2->payload;
		
		Node* ret = (Node*)alloc_resource(sizeof(Node) + sizeof(ChainElement));
		ret->type = Node_CHAIN_ELEMENT;
		ChainElement* chain = (ChainElement*)ret->payload;
		chain->head = ((ChainElement*)$1->payload)->head;
		chain->tail = ((ChainElement*)$3->payload)->tail;
		
		$$ = ret;
		
		Chain* edge = (Chain*)alloc_resource(sizeof(Chain));
		edge->head = ((ChainElement*)$1->payload)->tail;
		edge->head_outport = arrow->head_outport;
		edge->tail_inport = arrow->tail_inport;
		edge->tail = ((ChainElement*)$3->payload)->head;
		
		add_list(__click_edges, edge);
	}
	|
	chain_element2
	{		
		$$ = $1;
	}
	;

statement:
	chain ';'
	;
%%


int yyerror(const char* val)
{
	printf("%d ",yyget_lineno());printf("Error occuered: %s, %s\n", val, yytext);
	return 1;
}
