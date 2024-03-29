/* Ocamlyacc parser for ALBS */

%{
open Ast

let unescape s =
  Scanf.sscanf ("\"" ^ s ^ "\"") "%S%!" (fun x -> x)

%}

%token SEMI LPAREN RPAREN LSBRACE RSBRACE LBRACE RBRACE COMMA COLON NEW STRUCT DOT
%token PLUS MINUS TIMES DIVIDE ASSIGN NOT
%token EQ NEQ LT LEQ GT GEQ AND OR
%token RETURN IF ELSE FOR WHILE INT FLOAT BOOL VOID CHAR
%token <int> LITERAL
%token <bool> BOOLEAN_LITERAL
%token <float> FLOAT_LITERAL
%token <char> CHAR_LITERAL
%token <string> STRING_LITERAL
%token <string> ID
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE
%right NOT NEG

%start program
%type <Ast.program> program

%%

program:
  decls EOF { $1 }

decls:
 | vdecl_list fdecl_list sdecl_list { $1, $2, $3}
 | /* nothing */ { [], [], [] }


sdecl_list:
    /* nothing */    { [] }
  | sdecl_list sdecl { $2 :: $1 }

sdecl:
  STRUCT ID LSBRACE vdecl_list RSBRACE
  { {
   sname = $2;
   svar_decl_list = List.rev $4;
  } }

fdecl_list:
    /* nothing */    { [] }
  | fdecl_list fdecl { $2 :: $1 }

fdecl:
   LBRACE param_types_list COLON datatype RBRACE ID ASSIGN param_ids_list LSBRACE vdecl_list stmt_list RSBRACE
     { { datatype = $4;
	 fname = $6;
   formals = List.combine $2 $8;
	 locals = List.rev $10;
	 body = List.rev $11 } }

param_types_list:
    /* nothing */ { [] }
  | param_types_list_r   { List.rev $1 }

param_types_list_r:
    datatype                   { [($1)] }
  | param_types_list_r datatype { ($2) :: $1 }

param_ids_list:
    /* nothing */ { [] }
  | param_ids_list_r   { List.rev $1 }

param_ids_list_r:
    ID                   { [($1)] }
  | param_ids_list_r ID { ($2) :: $1 }

typ:
  | INT { Int }
  | BOOL { Bool }
  | VOID { Void }
  | FLOAT { Float }
  | CHAR { Char }

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
  datatype ID SEMI { ($1, $2) }

obj_type:
  | STRUCT ID { Objecttype($2) }

singular_type:
  | typ {$1}
  | obj_type {$1}

array_type:
  typ LSBRACE brackets RSBRACE { Arraytype($1, $3) }

datatype:
  | singular_type { Datatype($1) }
  | array_type { $1 }

brackets:
	|	/* nothing */ 			   { 1 }
	| 	brackets RSBRACE LSBRACE { $1 + 1 }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI { Expr $1 }
  | RETURN SEMI { Return Noexpr }
  | RETURN expr SEMI { Return $2 }
  | LBRACE stmt_list RBRACE { Block(List.rev $2) }
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7) }
  | FOR LPAREN expr_opt SEMI expr SEMI expr_opt RPAREN stmt
     { For($3, $5, $7, $9) }
  | WHILE LPAREN expr RPAREN stmt { While($3, $5) }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
  | STRING_LITERAL   { StringLit(unescape $1) }
  | LITERAL          { Literal($1) }
  | FLOAT_LITERAL    { FloatLit($1) }
  | CHAR_LITERAL		 { CharLit($1) }
  | BOOLEAN_LITERAL  { BoolLit($1) }
  | ID               { Id($1) }
  | expr PLUS   expr { Binop($1, Add,   $3) }
  | expr MINUS  expr { Binop($1, Sub,   $3) }
  | expr TIMES  expr { Binop($1, Mult,  $3) }
  | expr DIVIDE expr { Binop($1, Div,   $3) }
  | expr EQ     expr { Binop($1, Equal, $3) }
  | expr NEQ    expr { Binop($1, Neq,   $3) }
  | expr LT     expr { Binop($1, Less,  $3) }
  | expr LEQ    expr { Binop($1, Leq,   $3) }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3) }
  | expr AND    expr { Binop($1, And,   $3) }
  | expr OR     expr { Binop($1, Or,    $3) }
  | MINUS expr %prec NEG { Unop(Neg, $2) }
  | NOT expr         { Unop(Not, $2) }
  | expr ASSIGN expr { Assign($1, $3) }
  | ID DOT ID { StructAccess($1,$3) }
  | ID LPAREN actuals_opt RPAREN { Call($1, $3) }
  | LPAREN expr RPAREN { $2 }
  | NEW typ bracket_args RSBRACE  { ArrayCreate(Datatype($2), List.rev $3) }
  | NEW ID { StructCreate($2) } /*stuct_name*/
  | expr bracket_args RSBRACE    { ArrayAccess($1, List.rev $2) }

bracket_args:
  |   LSBRACE expr            { [$2] }
  |   bracket_args RSBRACE LSBRACE expr { $4 :: $1 }

actuals_opt:
    /* nothing */ { [] }
  | actuals_list  { List.rev $1 }

actuals_list:
    expr                    { [$1] }
  | actuals_list COMMA expr { $3 :: $1 }
