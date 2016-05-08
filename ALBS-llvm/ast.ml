(* Abstract Syntax Tree and functions for printing it *)

type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or

type uop = Neg | Not

type typ = Int | Bool | Void | Float | Char | Objecttype of string
type datatype = Arraytype of typ * int | Datatype of typ  

type bind = datatype * string

type expr =
    Literal of int
  | BoolLit of bool
  | FloatLit of float
  | Id of string
  | StringLit of string
  | CharLit of char
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of expr * expr
  | Call of string * expr list
  | Noexpr
  | ArrayCreate of datatype * expr list
  | ArrayAccess of expr * expr list
  | StructAccess of string * string  (*struct_var_name, struct_field_name*)
  | StructCreate of string (*struct name, variable name*)

type stmt =
    Block of stmt list
  | Expr of expr
  | Return of expr
  | If of expr * stmt * stmt
  | For of expr * expr * expr * stmt
  | While of expr * stmt

type func_decl = {
    datatype : datatype;
    fname : string;
    formals : bind list;
    locals : bind list;
    body : stmt list;
  }

type s_decl = {
    sname : string;
    svar_decl_list : bind list;
  }

type program = bind list * func_decl list * s_decl list

(* Pretty-printing functions *)

let string_of_op = function
  | Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Equal -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "&&"
  | Or -> "||"

let string_of_uop = function
  | Neg -> "-"
  | Not -> "!"


  let rec string_of_datatype = function
    | Datatype(Int) -> "int"
    | Datatype(Bool) -> "bln"
    | Datatype(Void) -> "void"
    | Datatype(Char) -> "chr"
    | Datatype(Float) -> "flt"
    | Datatype(Objecttype(name)) -> name
    | Arraytype(t,_) -> string_of_datatype (Datatype(t))

  let string_of_typ = function
    | Int -> "int"
    | Bool -> "bln"
    | Void -> "void"
    | Float -> "flt"
    | Char -> "chr"
    | Objecttype(name) -> name

let rec string_of_expr = function
  | Literal(l) -> string_of_int l
  | FloatLit(f) -> string_of_float f
  | CharLit(c) -> String.make 1 c
  | StringLit(s) -> "\"" ^ s ^ "\""
  | BoolLit(true) -> "true"
  | BoolLit(false) -> "false"
  | ArrayCreate(d,el) -> string_of_datatype d ^ "[" ^ String.concat ", " (List.map string_of_expr el) ^ "]"
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> string_of_expr v ^ " = " ^ string_of_expr e
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Noexpr -> ""
  | _ -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | For(e1, e2, e3, s) ->
      "for (" ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^
      string_of_expr e3  ^ ") " ^ string_of_stmt s
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s

let string_of_vdecl (t, id) = string_of_datatype t ^ " " ^ id ^ ";\n"

let string_of_fdecl fdecl =

  let x = fdecl.datatype in
  string_of_datatype x  ^ " " ^

  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.formals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.locals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_program (vars, funcs, structs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs)
