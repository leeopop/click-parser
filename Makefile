SRC_DIR = src
GRAMMAR_DIR = grammar
OUTPUT_DIR = build

GRAMMAR = $(GRAMMAR_DIR)/click.l  $(GRAMMAR_DIR)/click.y
GRAMMAR_SRC = $(GRAMMAR_DIR)/click_lex.c $(GRAMMAR_DIR)/click_yacc.c $(GRAMMAR_DIR)/click_lex.h $(GRAMMAR_DIR)/click_yacc.h

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(SRCS:.c=.o) $(GRAMMAR_SRC:.c=.o)
HEADERS = $(wildcard $(SRC_DIR)/*.h)
TEST = test_parser
LIB = libclickparser.a

LIBS = 
LDFLAGS = 
CFLAGS = -g -O0 -I$(SRC_DIR) -I$(GRAMMAR_DIR) -Iinclude

DEPS = .make.dep

.PHONY: all clean

all: $(DEPS) $(OUTPUT_DIR)/$(LIB) $(OUTPUT_DIR)/$(TEST)

test: $(GRAMMAR_SRC) $(DEPS) $(TEST)

lib: $(GRAMMAR_SRC) $(DEPS) $(LIB)

$(GRAMMAR_SRC): $(GRAMMAR)
	$(YACC) --defines=$(GRAMMAR_DIR)/click_yacc.h --output=$(GRAMMAR_DIR)/click_yacc.c $(GRAMMAR_DIR)/click.y
	$(LEX) --header-file=$(GRAMMAR_DIR)/click_lex.h --outfile=$(GRAMMAR_DIR)/click_lex.c -Cr $(GRAMMAR_DIR)/click.l

$(OUTPUT_DIR)/$(LIB): $(OBJS)
	$(AR) r $@ $(OBJS)

$(OUTPUT_DIR)/$(TEST): $(OUTPUT_DIR)/$(LIB) test/test.o
	$(CC) $(OBJS) test/test.o $(LDFLAGS) $(LIBS) -L$(OUTPUT_DIR) -lclickparser -o $@

clean:
	rm -f $(OUTPUT_DIR)/$(LIB) $(OUTPUT_DIR)/$(TEST) test/*.o $(SRC_DIR)/*.o $(DEPS) $(GRAMMAR_DIR)/*.o $(GRAMMAR_DIR)/*.c $(GRAMMAR_DIR)/*.h

$(DEPS): $(GRAMMAR_SRC) $(SRCS) $(HEADERS)
	@$(CC) $(CFLAGS) -MM $(SRCS) > $(DEPS);

-include .make.dep

