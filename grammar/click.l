
%{
#include "click_yacc.h"
%}

FIRST_WORD [A-Za-z_]
WORD [A-Za-z_0-9]
HEX [0-9A-Fa-f]
HEX2 {HEX}{1,2}
HEX4 {HEX}{1,4}
DIGIT [0-9]
IPv4 {DIGIT}+"."{DIGIT}+"."{DIGIT}+"."{DIGIT}+
IPv6 (([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))
ETHERNET {HEX2}":"{HEX2}":"{HEX2}":"{HEX2}":"{HEX2}":"{HEX2}
SPACES [ \t\n\r\f]
IPv4_MASK {IPv4}[/]{DIGIT}+
IPv6_MASK {IPv6}[/]{DIGIT}+
%%

"//"[^\n]*"\n" {  }
L?\"(\\.|[^\\"])*\"	{ return(STRING); }

{IPv4_MASK} { return IPv4_MASK; }
{IPv6_MASK} { return IPv6_MASK; }
"(" { return '('; }
")" { return ')'; }
"[" { return '['; }
"]" { return ']'; }
"," { return ','; }
";" { return ';'; }
"/" { return '/'; }
"::" { return DEFINE; }
"-" { return ARROW_TAIL; }
">" { return ARROW_HEAD; }
{FIRST_WORD}{WORD}* { return IDENTIFIER; }
{IPv4} { return IPv4_ADDR; }
{IPv6} { return IPv6_ADDR; }
{DIGIT}+ { return DEC_INTEGER; }
("0x"|"0X"){HEX}+ { return HEX_INTEGER; }
{ETHERNET} { return ETHER_ADDR; }
{SPACES}+ {}
. { return OTHER_VALUE; }
%%

int yywrap()
{
	return 1;
}

