(* Ocamllex scanner for MicroC *)

{ open Parser
    let unescape s =
    	Scanf.sscanf ("\"" ^ s ^ "\"") "%S%!" (fun x -> x)
}

let digit = ['0'-'9']
let float = (digit+) ['.'] digit+
let escaped_char = '\\' ['\\' ''' '"' 'n' 'r' 't']
let ascii = ([' '-'!' '#'-'[' ']'-'~'])
let string = '"' ( (ascii | escaped_char)* as s) '"'
let escape_single_char = ''' (escaped_char) '''

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
| '-'      { MINUS }
| '*'      { TIMES }
| '/'      { DIVIDE }
| '='      { ASSIGN }
| ':'      { COLON }
| "=="     { EQ }
| "!="     { NEQ }
| '<'      { LT }
| "<="     { LEQ }
| ">"      { GT }
| ">="     { GEQ }
| "&"     { AND }
| "|"     { OR }
| "!"      { NOT }
| "if"     { IF }
| "else"   { ELSE }
| "rtn" { RETURN }
| "int"    { INT }
| "flt"    { FLOAT }
| "bln"   { BOOL }
| "chr"    { CHAR }
| "void"   { VOID }
| "true"   { TRUE }
| "false"  { FALSE }
| float as lxm { FLOAT_LITERAL(float_of_string lxm) }
| ['0'-'9']+ as lxm { LITERAL(int_of_string lxm) }
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }
| string       		{ STRING_LITERAL(unescape s) }
and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }
