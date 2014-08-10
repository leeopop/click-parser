%{
#include "click_lex.h"
%}


%token IDENTIFIER DEFINE ARROW_TAIL ARROW_HEAD
%token IPv4_ADDR IPv6_ADDR IPv4_MASK IPv6_MASK DEC_INTEGER HEX_INTEGER ETHER_ADDR STRING OTHER_VALUE

%start program

%%
program:
	;

%%


int yyerror(const char* val)
{
	printf("%d ",__LINE__);printf("Error occuered: %s\n", val);
	return 1;
}
