(* Semantic checking for the ALBS compiler *)

open Ast

module StringMap = Map.Make(String)

(* Semantic checking of a program. Returns void if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check (globals, functions, structs) =

  (* Raise an exception if the given list has a duplicate *)
  let report_duplicate exceptf list =
    let rec helper = function
	n1 :: n2 :: _ when n1 = n2 -> raise (Failure (exceptf n1))
      | _ :: t -> helper t
      | [] -> ()
    in helper (List.sort compare list)
  in

  (* Raise an exception if a given binding is to a void type *)
  let check_not_void exceptf = function
      (Datatype(Void), n) -> raise (Failure (exceptf n))
    | _ -> ()
  in

  (* Raise an exception of the given rvalue type cannot be assigned to
     the given lvalue type *)
  let check_assign lvaluet rvaluet err =
    (* print_endline lvaluet; *)
     if string_of_datatype( lvaluet) = string_of_datatype( rvaluet) then lvaluet 
   else  raise err
  in

  (**** Checking Global Variables ****)

  List.iter (check_not_void (fun n -> "illegal void global " ^ n)) globals;

  report_duplicate (fun n -> "duplicate global " ^ n) (List.map snd globals);

  (**** Checking Functions ****)

  if List.mem "print" (List.map (fun fd -> fd.fname) functions)
  then raise (Failure ("function print may not be defined")) else ();

  report_duplicate (fun n -> "duplicate function " ^ n)
    (List.map (fun fd -> fd.fname) functions);

  (* Function declaration for a named function *)
  let built_in_decls =  

  StringMap.add "print" { 
                datatype = Datatype(Void); fname = "print"; formals = [(Datatype(Float), "x")];
                locals = []; body = [] } 

  (StringMap.singleton "getchar"  { 
              datatype = Datatype(Char); fname = "getchar"; formals = [];
              locals = []; body = [] }
            ) in

  let  function_decls = List.fold_left (fun m fd -> StringMap.add fd.fname fd m)
                         built_in_decls functions
  in
  let function_decl s = try StringMap.find s function_decls
       with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = function_decl "main" in (* Ensure "main" is defined *)

  let check_function func =

    List.iter (check_not_void (fun n -> "illegal void formal " ^ n ^
      " in " ^ func.fname)) func.formals;

    report_duplicate (fun n -> "duplicate formal " ^ n ^ " in " ^ func.fname)
      (List.map snd func.formals);

    List.iter (check_not_void (fun n -> "illegal void local " ^ n ^
      " in " ^ func.fname)) func.locals;

    report_duplicate (fun n -> "duplicate local " ^ n ^ " in " ^ func.fname)
      (List.map snd func.locals);

    (* Type of each variable (global, formal, or local *)
    let symbols = List.fold_left (fun m (t, n) -> StringMap.add n t m)
	StringMap.empty (globals @ func.formals @ func.locals )
    in

    let type_of_identifier s =
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in

    (* Return the type of an expression or throw an exception *)
    let rec expr = function
	    | Literal _ -> Datatype(Int)
      | FloatLit _ -> Datatype(Float)
      | CharLit _ -> Datatype(Char)
      | StringLit _ -> Datatype(Int) (* ADDED *)
      | BoolLit _ -> Datatype(Bool)
      | Id s -> type_of_identifier s

      | ArrayCreate (t, n) -> t
      | ArrayAccess (e , el) -> expr(e)

      | StructAccess (n, f) -> Datatype(Objecttype(""))  (*struct_var_name, struct_field_name*)
      | StructCreate (n) ->  Datatype(Objecttype(""))(*struct name*)

      | Binop(e1, op, e2) as e -> let t1 = expr e1 and t2 = expr e2 in
    
      if compare (string_of_datatype t1) "struct" = 0 (*don't compare structs*)
      then  t1
      else if compare (string_of_datatype t2) "struct" = 0 (*don't compare structs*)                          
    	then t2
      else (match op with

        | Add | Sub | Mult | Div when t1 = Datatype(Int) && t2 = Datatype(Int) -> Datatype(Int)
        | Add | Sub | Mult | Div when t1 = Datatype(Int) && t2 = Datatype(Char) -> Datatype(Int)
        | Add | Sub | Mult | Div when t1 = Datatype(Char) && t2 = Datatype(Char) -> Datatype(Char)

	      | And | Or | Equal | Neq | Less | Leq | Greater | Geq when t1 = Datatype(Int) && t2 = Datatype(Int) -> Datatype(Bool)
        | And | Or | Equal | Neq | Less | Leq | Greater | Geq when t1 = Datatype(Char) && t2 = Datatype(Char) -> Datatype(Bool)

        | Equal | Neq when t1 = t2 -> Datatype(Bool)
	      | And | Or when t1 = Datatype(Bool) && t2 = Datatype(Bool) -> Datatype(Bool)

        | Add | Sub | Mult | Div when t1 = Datatype(Float) && t2 = Datatype(Float) -> Datatype(Float)
        | Less | Leq | Greater | Geq when t1 = Datatype(Float) && t2 = Datatype(Float) -> Datatype(Bool)


        | _ -> raise (Failure ("illegal binary operator " ^
              string_of_datatype t1 ^ " " ^ string_of_op op ^ " " ^
              string_of_datatype t2 ^ " in " ^ string_of_expr e))
        )
      | Unop(op, e) as ex -> let t = expr e in

       if compare (string_of_datatype t) "struct" = 0 (*don't compare structs*)
      then  t
      else 
	 (match op with
	   Neg when t = Datatype(Int) -> Datatype(Int)
   | Neg when t = Datatype(Float) -> Datatype(Float)
	 | Not when t = Datatype(Bool) -> Datatype(Bool)
         | _ -> raise (Failure ("illegal unary operator " ^ string_of_uop op ^
	  		   string_of_datatype t ^ " in " ^ string_of_expr ex)))
      | Noexpr -> Datatype(Void)
      | Assign(var, e) as ex -> let lt = expr var
                                and rt = expr e in

                                if compare (string_of_datatype lt) "struct" != 0 (*don't compare structs*)
                                then if compare (string_of_datatype rt) "struct" != 0 (*don't compare structs*)
                                   then ignore (check_assign lt rt
                                  (Failure ("illegal assignment: types dont match left: " ^ string_of_datatype lt ^ " right: " ^ string_of_datatype rt )));
        lt;

        (* check_assign lt rt (Failure ("illegal assignment " ^ string_of_typ lt ^
				     " = " ^ string_of_typ rt ^ " in " ^
				     string_of_expr ex)) *)
      | Call(fname, actuals) as call -> let fd = function_decl fname in
         if List.length actuals != List.length fd.formals then
           raise (Failure ("expecting " ^ string_of_int
             (List.length fd.formals) ^ " arguments in " ^ string_of_expr call))
         else

           if fname <> "print"
           then List.iter2 (fun (ft, _) e -> let et = expr e in
              ignore (check_assign ft et
                (Failure ("illegal actual argument found of type " ^ string_of_datatype et ^ " for variable/literal " ^ string_of_expr e ^
              ", function " ^ fname ^ " expected " ^ string_of_datatype ft ^ "."))))


             fd.formals actuals;

           fd.datatype
    in

    let check_bool_expr e =
    (*ignore(print_endline (string_of_datatype ( e)) ;); *)
    (*    ignore(print_endline (string_of_datatype (Datatype(Bool)));)*)
    if (string_of_datatype (expr e)) <> "bln"
     then raise (Failure ("expected Boolean expression as type of " ^ string_of_expr e ^
     " it was " ^ string_of_datatype (expr e)))
     else () in

    (* Verify a statement or throw an exception *)
    let rec stmt = function
	Block sl -> let rec check_block = function
           [Return _ as s] -> stmt s
         | Return _ :: _ -> raise (Failure "nothing may follow a return")
         | Block sl :: ss -> check_block (sl @ ss)
         | s :: ss -> stmt s ; check_block ss
         | [] -> ()
        in check_block sl
      | Expr e -> ignore (expr e)
      | Return e -> let t = expr e in if t = func.datatype then () else
         raise (Failure ("return gives " ^ string_of_datatype t ^ " expected " ^
                         string_of_datatype func.datatype ^ " as type for " ^ string_of_expr e))

      | If(p, b1, b2) -> check_bool_expr p; stmt b1; stmt b2
      | For(e1, e2, e3, st) -> ignore (expr e1); check_bool_expr e2;
                               ignore (expr e3); stmt st
      | While(p, s) -> check_bool_expr p; stmt s
    in

    stmt (Block func.body)

  in
  List.iter check_function functions
