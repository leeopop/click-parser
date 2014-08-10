CC = gcc
LEX = flex
YACC = bison

SRC_DIR = src
GRAMMAR_DIR = grammar
OUTPUT_DIR = build

GRAMMAR = $(GRAMMAR_DIR)/click.l  $(GRAMMAR_DIR)/click.y
GRAMMAR_SRC = $(SRC_DIR)/click_lex.c $(SRC_DIR)/click_yacc.c

SRCS = $(wildcard $$(SRC_DIR)/*.c) $(GRAMMAR_SRC)
OBJS = $(SRCS:.c=.o)
HEADERS = $(wildcard $$(SRC_DIR)/*.h)
EXEC = test_parser



LIBS = 
LDFLAGS = 
CFLAGS = -g -O0 -I$(SRC_DIR)

DEPS = .make.dep

.PHONY: all clean

all: $(DEPS) $(EXEC)

$(GRAMMAR_SRC): $(GRAMMAR)
	$(LEX) --header-file=$(SRC_DIR)/click_lex.h --outfile=$(SRC_DIR)/click_lex.c -Cr $(GRAMMAR_DIR)/click.l
	$(YACC) --defines=$(SRC_DIR)/click_yacc.h --output=$(SRC_DIR)/click_yacc.c $(GRAMMAR_DIR)/click.y
	
nslex.cc nslex.hh: nshader.l
	flex -o nslex.cc --header-file=nslex.hh -Cr nshader.l


$(EXEC): $(OBJS) test/test.o
	$(CC) $(OBJS) test/test.o -o $(OUTPUT_DIR)/$@ $(LDFLAGS) $(LIBS)

clean:
	rm -f $(EXEC) test/*.o $(SRC_DIR)/*.o $(DEPS)

$(DEPS): $(SRCS) $(HEADERS)
	@$(CC) $(CFLAGS) -MM $(SRCS) > $(DEPS);