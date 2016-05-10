(* Ocamllex scanner for MicroC *)

{ open Parser
    let unescape s =
    	Scanf.sscanf ("\"" ^ s ^ "\"") "%S%!" (fun x -> x)
}

let digit = ['0'-'9']
let float = '-'?(digit+) ['.'] digit+
let bool = "true" | "false"
let escaped_char = '\\' ['\\' ''' '"' 'n' 'r' 't']
let ascii = ([' '-'!' '#'-'[' ']'-'~'])
let char = ''' (ascii | digit) '''
let string = '"' ( (ascii | escaped_char)* as s) '"'

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "/*"     { comment lexbuf }           (* Comments *)
| '('      { LPAREN }
| ')'      { RPAREN }
| '{'      { LBRACE }
| '}'      { RBRACE }
| '['      { LSBRACE }
| ']'      { RSBRACE }
| ';'      { SEMI }
| ','      { COMMA }
| '+'      { PLUS }
| float as lxm { FLOAT_LITERAL(float_of_string lxm) }
| '-'      { MINUS }
| '*'      { TIMES }
| '/'      { DIVIDE }
| '='      { ASSIGN }
| ':'      { COLON }
| "while"  { WHILE }
| "=="     { EQ }
| "!="     { NEQ }
| '<'      { LT }
| "<="     { LEQ }
| ">"      { GT }
| ">="     { GEQ }
| "&"      { AND }
| "|"      { OR }
| "!"      { NOT }
| "if"     { IF }
| "else"   { ELSE }
| "rtn"    { RETURN }
| "int"    { INT }
| "flt"    { FLOAT }
| "bln"    { BOOL }
| "chr"    { CHAR }
| "void"   { VOID }
| "new"    { NEW }
| "struct" { STRUCT }
| "." { DOT }
| bool as lxm { BOOLEAN_LITERAL (bool_of_string lxm) }
| char as lxm  { CHAR_LITERAL( String.get lxm 1 ) }
| ['0'-'9']+ as lxm { LITERAL(int_of_string lxm) }
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof       { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }
| string    { STRING_LITERAL(unescape s) }
and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }
