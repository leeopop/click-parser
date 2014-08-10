%{
#include "click_lex.h"
#include "node.h"

#define YYSTYPE Node*

static List* modules = 0;
static Map* symbol_table = 0;
static List* edges = 0;
%}


%token IDENTIFIER DEFINE ARROW_TAIL ARROW_HEAD
%token IPv4_ADDR IPv6_ADDR IPv4_MASK IPv6_MASK DEC_INTEGER HEX_INTEGER ETHER_ADDR STRING OTHER_VALUE

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
	DEC_INTEGER
	{
		Node* ret = makeData(Node_DEC_INTEGER, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	|
	HEX_INTEGER
	{
		Node* ret = makeData(Node_HEX_INTEGER, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	;

value:
	IPv4_ADDR
	{
		Node* ret = makeData(Node_IPv4_ADDR, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	|
	IPv6_ADDR
	{
		Node* ret = makeData(Node_IPv6_ADDR, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	|
	integer
	{
		$$ = $1;
	}
	|
	ETHER_ADDR
	{
		Node* ret = makeData(Node_ETHER_ADDR, yytext);
		if(!ret)
		{
			printf("%d ",__LINE__);printf("Node creation failed\n");
			YYABORT;
		}
		$$ = ret;
	}
	;

value_pair:
	value '/' value
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Pair));
		Pair* pair = (Pair*)ret->payload;
		pair->left = $1;
		pair->right = $3;
		ret->type = Node_PAIR;
		$$ = ret;
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
	;	

value2:
	string
	|
	value_pair
	{
		$$ = $1;
	}
	|
	value
	{
		$$ = $1;
	}
	|
	identifier
	{
		$$ = $1;
	}
	;
value_set:
	value_set value2
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
	value2
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(ValueList));
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
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(ArgList));
		ArgList* alist = (ArgList*)ret->payload;
		init_list(alist);
		ret->type = Node_ARG_LIST;
		add_list(alist, $1);
		$$ = ret;
	}
	|
	ARROW_TAIL
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(ArgList));
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
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Module));
		ret->type = Node_MODULE;
		Module* module = (Module*)ret->payload;
		module->name = $1;
		module->args = $3;
		module->index = modules->len;
		add_list(modules, ret);
		$$ = ret;
	}
	|
	identifier '(' ')'
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Module));
		ret->type = Node_MODULE;
		Module* module = (Module*)ret->payload;
		module->name = $1;
		Node* ret2 = (Node*)malloc(sizeof(Node) + sizeof(ArgList));
		ArgList* alist = (ArgList*)ret2->payload;
		init_list(alist);
		ret2->type = Node_ARG_LIST;
		
		module->args = ret2;
		module->index = modules->len;
		add_list(modules, ret);
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
		iter = find_map(symbol_table, key, strlen(key));
		if(iter == 0)
		{
			Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Module));
			ret->type = Node_MODULE;
			Module* module = (Module*)ret->payload;
			module->name = $1;
			module->index = modules->len;
			
			Node* ret2 = (Node*)malloc(sizeof(Node) + sizeof(ArgList));
			ArgList* alist = (ArgList*)ret2->payload;
			init_list(alist);
			ret2->type = Node_ARG_LIST;
			
			module->args = ret2;
			
			
			add_list(modules, ret);
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
		iter = find_map(symbol_table, key, strlen(key));
		if(iter != 0)
		{
			printf("%d ",__LINE__);printf("Redefinition of module %s\n", $1->payload);
			YYABORT;
		}
		
		add_map(symbol_table, key, strlen(key), $3);
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
		iter = find_map(symbol_table, key, strlen(key));
		if(iter != 0)
		{
			printf("%d ",__LINE__);printf("Redefinition of module %s\n", $1->payload);
			YYABORT;
		}
		
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Module));
		ret->type = Node_MODULE;
		Module* module = (Module*)ret->payload;
		module->name = $3;
		module->index = modules->len;
		
		Node* ret2 = (Node*)malloc(sizeof(Node) + sizeof(ArgList));
		ArgList* alist = (ArgList*)ret2->payload;
		init_list(alist);
		ret2->type = Node_ARG_LIST;
		
		module->args = ret2;
		add_list(modules, ret);
		add_map(symbol_table, key, strlen(key), ret);
		$$ = ret;
	}
	;

arrow:
	ARROW_TAIL ARROW_HEAD
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Arrow));
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
		if(num1->type != Node_DEC_INTEGER && num1->type != Node_HEX_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Arrow));
		ret->type = Node_ARROW;
		Arrow* arrow = (Arrow*)ret->payload;
		arrow->head_outport = (int)(*((int*)$2->payload));
		arrow->tail_inport = 0;
		
		$$ = ret;
	}
	|
	ARROW_TAIL ARROW_HEAD '[' integer ']'
	{
		Node* num2 = $4;
		if(num2->type != Node_DEC_INTEGER && num2->type != Node_HEX_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Arrow));
		ret->type = Node_ARROW;
		Arrow* arrow = (Arrow*)ret->payload;
		arrow->head_outport = 0;
		arrow->tail_inport = (int)(*((int*)$4->payload));
		
		$$ = ret;
	}
	|
	'[' integer ']' ARROW_TAIL ARROW_HEAD '[' integer ']'
	{
		Node* num1 = $2;
		if(num1->type != Node_DEC_INTEGER && num1->type != Node_HEX_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* num2 = $7;
		if(num2->type != Node_DEC_INTEGER && num2->type != Node_HEX_INTEGER)
		{
			printf("%d ",__LINE__);printf("Type checking failed\n");
			YYABORT;
		}
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(Arrow));
		ret->type = Node_ARROW;
		Arrow* arrow = (Arrow*)ret->payload;
		arrow->head_outport = (int)(*((int*)$2->payload));
		arrow->tail_inport = (int)(*((int*)$7->payload));
		
		$$ = ret;
	}
	;

chain_element2:
	chain_element
	{
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(ChainElement));
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
		
		Node* ret = (Node*)malloc(sizeof(Node) + sizeof(ChainElement));
		ret->type = Node_CHAIN_ELEMENT;
		ChainElement* chain = (ChainElement*)ret->payload;
		chain->head = ((ChainElement*)$1->payload)->head;
		chain->tail = ((ChainElement*)$3->payload)->tail;
		
		$$ = ret;
		
		Chain* edge = (Chain*)malloc(sizeof(Chain));
		edge->head = ((ChainElement*)$1->payload)->tail;
		edge->head_outport = arrow->head_outport;
		edge->tail_inport = arrow->tail_inport;
		edge->tail = ((ChainElement*)$3->payload)->head;
		
		add_list(edges, edge);
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
	printf("%d ",__LINE__);printf("Error occuered: %s\n", val);
	return 1;
}
