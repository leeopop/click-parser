
%{
#include "click_yacc.h"
%}

FIRST_WORD [A-Za-z_]
WORD [A-Za-z_0-9]
HEX [0-9A-Fa-f]
HEX2 {HEX}{2}
HEX4 {HEX}{1,4}
DIGIT [0-9]
IPv4 {DIGIT}+"."{DIGIT}+"."{DIGIT}+"."{DIGIT}+
IPv6 {HEX4}":"{HEX4}":"{HEX4}":"{HEX4}":"{HEX4}":"{HEX4}":"{HEX4}":"{HEX4}
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
"-" { return ARROW_BODY; }
">" { return ARROW_HEAD; }
{FIRST_WORD}{WORD}* { return IDENTIFIER; }
{IPv4} { return IPv4_ADDR; }
{IPv6} { return IPv6_ADDR; }
{DIGIT}+ { return DEC_INTEGER; }
("0x"|"0X"){HEX}+ { return HEX_INTEGER; }
{ETHERNET} { return ETHER_ADDR; }
{SPACES}+ {}
%%

int yywrap()
{
	return 1;
}

