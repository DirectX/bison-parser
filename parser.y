%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

typedef enum {
    AST_NUMBER,
    AST_ADD,
    AST_SUB,
    AST_MUL,
    AST_DIV
} ASTType;

typedef struct ASTNode {
    ASTType type;
    int value;
    struct ASTNode *left;
    struct ASTNode *right;
} ASTNode;

ASTNode *make_number(int value);
ASTNode *make_op(ASTType type, ASTNode *left, ASTNode *right);
void print_ast(ASTNode *node, int depth);
void free_ast(ASTNode *node);

int yylex(void);
void yyerror(const char *message);
%}

%union {
    int num;
    ASTNode *node;
}

%token <num> NUMBER

%type <node> expr

%left '+' '-'
%left '*' '/'

%%

input:
    expr '\n'
    {
        printf("AST:\n");
        print_ast($1, 0);
        free_ast($1);
    }
    ;

expr:
      NUMBER
      {
          $$ = make_number($1);
      }
    | expr '+' expr
      {
          $$ = make_op(AST_ADD, $1, $3);
      }
    | expr '-' expr
      {
          $$ = make_op(AST_SUB, $1, $3);
      }
    | expr '*' expr
      {
          $$ = make_op(AST_MUL, $1, $3);
      }
    | expr '/' expr
      {
          $$ = make_op(AST_DIV, $1, $3);
      }
    | '(' expr ')'
      {
          $$ = $2;
      }
    ;

%%

ASTNode *make_number(int value)
{
    ASTNode *node = malloc(sizeof(ASTNode));

    if (!node) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }

    node->type = AST_NUMBER;
    node->value = value;
    node->left = NULL;
    node->right = NULL;

    return node;
}

ASTNode *make_op(ASTType type, ASTNode *left, ASTNode *right)
{
    ASTNode *node = malloc(sizeof(ASTNode));

    if (!node) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }

    node->type = type;
    node->value = 0;
    node->left = left;
    node->right = right;

    return node;
}

void print_ast(ASTNode *node, int depth)
{
    if (!node)
        return;

    for (int i = 0; i < depth; ++i)
        printf("  ");

    switch (node->type) {
        case AST_NUMBER:
            printf("NUMBER(%d)\n", node->value);
            break;

        case AST_ADD:
            printf("ADD\n");
            break;

        case AST_SUB:
            printf("SUB\n");
            break;

        case AST_MUL:
            printf("MUL\n");
            break;

        case AST_DIV:
            printf("DIV\n");
            break;
    }

    print_ast(node->left, depth + 1);
    print_ast(node->right, depth + 1);
}

void free_ast(ASTNode *node)
{
    if (!node)
        return;

    free_ast(node->left);
    free_ast(node->right);
    free(node);
}

/* Простейший лексер без Flex. */
int yylex(void)
{
    int c;

    do {
        c = getchar();
    } while (c == ' ' || c == '\t' || c == '\r');

    if (c == EOF)
        return 0;

    if (isdigit((unsigned char)c)) {
        int value = c - '0';

        while ((c = getchar()) != EOF &&
               isdigit((unsigned char)c)) {
            value = value * 10 + (c - '0');
        }

        if (c != EOF)
            ungetc(c, stdin);

        yylval.num = value;
        return NUMBER;
    }

    /* Возвращаем операторы и скобки как символьные токены. */
    return c;
}

void yyerror(const char *message)
{
    fprintf(stderr, "Syntax error: %s\n", message);
}

int main(void)
{
    return yyparse();
}