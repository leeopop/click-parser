CC = gcc
LEX = flex
YACC = bison

SRC_DIR = src
GRAMMAR_DIR = grammar
OUTPUT_DIR = build

GRAMMAR = $(GRAMMAR_DIR)/click.l  $(GRAMMAR_DIR)/click.y
GRAMMAR_SRC = $(GRAMMAR_DIR)/click_lex.c $(GRAMMAR_DIR)/click_yacc.c $(GRAMMAR_DIR)/click_lex.h $(GRAMMAR_DIR)/click_yacc.h

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(SRCS:.c=.o) $(GRAMMAR_SRC:.c=.o)
HEADERS = $(wildcard $(SRC_DIR)/*.h)
EXEC = test_parser



LIBS = 
LDFLAGS = 
CFLAGS = -g -O0 -I$(SRC_DIR) -I$(GRAMMAR_DIR) -Iinclude

DEPS = .make.dep

.PHONY: all clean

all: $(GRAMMAR_SRC) $(DEPS) $(EXEC)

$(GRAMMAR_SRC): $(GRAMMAR)
	$(YACC) --defines=$(GRAMMAR_DIR)/click_yacc.h --output=$(GRAMMAR_DIR)/click_yacc.c $(GRAMMAR_DIR)/click.y
	$(LEX) --header-file=$(GRAMMAR_DIR)/click_lex.h --outfile=$(GRAMMAR_DIR)/click_lex.c -Cr $(GRAMMAR_DIR)/click.l
	
nslex.cc nslex.hh: nshader.l
	flex -o nslex.cc --header-file=nslex.hh -Cr nshader.l


$(EXEC): $(OBJS) test/test.o $(GRAMMAR_SRC)
	$(CC) $(OBJS) test/test.o -o $(OUTPUT_DIR)/$@ $(LDFLAGS) $(LIBS)

clean:
	rm -f $(EXEC) test/*.o $(SRC_DIR)/*.o $(DEPS) $(GRAMMAR_DIR)/*.o $(GRAMMAR_DIR)/*.c $(GRAMMAR_DIR)/*.h

$(DEPS): $(GRAMMAR_SRC) $(SRCS) $(HEADERS)
	@$(CC) $(CFLAGS) -MM $(SRCS) > $(DEPS);