
%{
#include "click_yacc.h"
%}

FIRST_WORD [A-Za-z_]
WORD [A-Za-z_0-9]
HEX [0-9A-Fa-f]
HEX2 {HEX}{1,2}
HEX4 {HEX}{1,4}
DIGIT [0-9]
SPACES [ \t\n\r\f]
%%

"//"[^\n]*"\n" {  }
L?\"(\\.|[^\\"])*\"	{ return(STRING); }

"(" { return '('; }
")" { return ')'; }
"[" { return '['; }
"]" { return ']'; }
"," { return ','; }
";" { return ';'; }
"::" { return DEFINE; }
"-" { return ARROW_TAIL; }
">" { return ARROW_HEAD; }
{FIRST_WORD}{WORD}* { return IDENTIFIER; }
{DIGIT}+ { return INTEGER; }
[^ \t\n\r\f\(\)\[\]\,\;\-\>]+ { return TOKEN; }
{SPACES}+ {}
%%

int yywrap()
{
	return 1;
}

