(* Code generation: translate takes a semantically checked AST and
produces LLVM IR
LLVM tutorial: Make sure to read the OCaml version of the tutorial
http://llvm.org/docs/tutorial/index.html
Detailed documentation on the OCaml LLVM library:
http://llvm.moe/
http://llvm.moe/ocaml/
*)

module L = Llvm
module A = Ast

open Llvm
open Ast

module SymbolsMap = Map.Make(String)
module StringMap = Map.Make(String)
let struct_types:(string, lltype) Hashtbl.t = Hashtbl.create 10
let struct_datatypes:(string, string) Hashtbl.t = Hashtbl.create 10
let struct_field_indexes:(string, int) Hashtbl.t = Hashtbl.create 50

let translate (globals, functions, structs) =
let context = L.global_context () in
let the_module = L.create_module context "ALBS"
and i32_t  = L.i32_type  context
and f_t   = L.double_type   context
and i8_t   = L.i8_type   context
and i1_t   = L.i1_type   context
and void_t = L.void_type context in


let temp_ltype_of_typ (datatype:A.datatype) = match datatype with
Datatype(A.Int) -> i32_t
| Datatype(A.Bool) -> i1_t
| Datatype(A.Float) -> f_t
| Datatype(A.Char) -> i32_t
| Datatype(A.Void) -> void_t
| _ -> void_t in

let find_struct name =
try Hashtbl.find struct_types name
with | Not_found ->  raise (Failure ("Struct not found")) in


let rec get_ptr_type datatype = match datatype with
| Arraytype(t, 0) -> temp_ltype_of_typ (Datatype(t))
| Arraytype(t, 1) -> L.pointer_type (temp_ltype_of_typ (Datatype(t)))
| Arraytype(t, i) -> L.pointer_type (get_ptr_type (Arraytype(t, (i-1))))
|   _ -> void_t in

let ltype_of_typ = function
Datatype(A.Int) -> i32_t
| Datatype(A.Bool) -> i1_t
| Datatype(A.Float) -> f_t
| Datatype(A.Char) -> i32_t
| Datatype(A.Void) -> void_t
| Arraytype(t, i) -> get_ptr_type (Arraytype(t, (i)))
| Datatype(A.Objecttype(struct_name)) -> L.pointer_type(find_struct struct_name) (*gives llvm for this struct type*)

in



(* Declare each global variable; remember its value in a map *)
let global_vars =
let global_var m (t, n) =
let init = L.const_int (ltype_of_typ t) 0
in StringMap.add n (L.define_global n init the_module) m in
List.fold_left global_var StringMap.empty globals in

(* Declare printf(), which the print built-in function will call *)
let printf_t = L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
let printf_func = L.declare_function "printf" printf_t the_module in




(* Define each struct stub (arguments) so we can create it *)
let struct_decl_stub sdecl =

let struct_t = L.named_struct_type context sdecl.A.sname in (*make llvm for this struct type*)


print_endline ";struct_decl_stub called";
Hashtbl.add struct_types sdecl.sname struct_t  (* add to map name vs llvm_stuct_type *)
in


(* Add var_types for each struct so we can create it *)
let struct_decl sdecl =

let struct_t = Hashtbl.find struct_types sdecl.sname in (*get llvm struct_t code for it*)


let type_list = List.map (fun (t,_) -> ltype_of_typ t) sdecl.A.svar_decl_list in (*map the datatypes*)
let name_list = List.map (fun (_,n) -> n) sdecl.A.svar_decl_list in (*map the names*)

(* Add key all fields in the struct *)
let type_list = i32_t :: type_list in
let name_list = ".key" :: name_list in

(* Add key all fields in the struct *)
let type_array = (Array.of_list type_list) in

List.iteri (fun i f ->
let n = sdecl.sname ^ "." ^ f in

  Hashtbl.add struct_field_indexes n i; (*add to name struct_field_indices*)
  ) name_list;


  print_endline ";struct_decl called!!";
  L.struct_set_body struct_t type_array true

  in



  let _ = List.map (fun s -> struct_decl_stub s) structs in
  let _ = List.map (fun s -> struct_decl s) structs in



  (* Define each function (arguments and return type) so we can call it *)
  let function_decls =
  let function_decl m fdecl =
  let name = fdecl.A.fname
  and formal_types =
  Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.A.formals)
  in let fdecl_datatype = fdecl.A.datatype (*return type*)
  in let llvm_fdecl = (ltype_of_typ fdecl_datatype)
  in let ftype = L.function_type llvm_fdecl formal_types in
  StringMap.add name (L.define_function name ftype the_module, fdecl) m in
  List.fold_left function_decl StringMap.empty functions in

  (* Fill in the body of the given function *)
  let build_function_body fdecl =
  let (the_function, _) = StringMap.find fdecl.A.fname function_decls in
  let builder = L.builder_at_end context (L.entry_block the_function) in
  let float_format_str = L.build_global_stringptr "%f\n" "fmt" builder in
  let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder in
  let char_format_str = L.build_global_stringptr "%c\n" "fmt" builder in

  (* Construct the function's "locals": formal arguments and locally
  declared variables.  Allocate each on the stack, initialize their
  value, if appropriate, and remember their values in the "locals" map *)
  let local_vars =

  let add_formal m (t, n) p = L.set_value_name n p;
  let local = L.build_alloca (ltype_of_typ t) n builder in
  ignore (L.build_store p local builder);
  StringMap.add n local m in

  let add_local m (var_type, var_name) = (* map, datatype, name *)

  let t = match var_type with
  Datatype(Objecttype(n)) ->

  ignore(Hashtbl.add struct_datatypes var_name n);  (* add to map name vs type *)

  find_struct n
  |   _ -> ltype_of_typ var_type
  in

  let llvm_for_allocation = L.build_alloca t var_name builder in


  StringMap.add var_name llvm_for_allocation m;


  in


  let formals = List.fold_left2 add_formal StringMap.empty fdecl.A.formals
  (Array.to_list (L.params the_function)) in

  List.fold_left add_local formals fdecl.A.locals in



  (*name vs type*)
  let symbol_vars =

  let add_to_symbol_table m (t, n) =
  SymbolsMap.add n t m in

  let symbolmap = List.fold_left add_to_symbol_table SymbolsMap.empty fdecl.A.formals in

  List.fold_left add_to_symbol_table symbolmap fdecl.A.locals in



  (* Return the value for a variable or formal argument *)
  let print_map_pair key value =
  print_endline (key ^ " " ^ value ^ "\n") in
  let lookup n = try StringMap.find n local_vars
  (* ignore(StringMap.iter print_map_pair local_vars); *)
  with Not_found -> StringMap.find n global_vars
  in


  (* Return the type for a variable or formal argument *)
  let lookup_datatype n = try SymbolsMap.find n symbol_vars
  with Not_found -> SymbolsMap.find n symbol_vars
  in




  (*Array functions*)
  let initialise_array arr arr_len init_val start_pos builder =
  let new_block label =
  let f = block_parent (insertion_block builder) in
  append_block (global_context ()) label f
  in
  let bbcurr = insertion_block builder in
  let bbcond = new_block "array.cond" in
  let bbbody = new_block "array.init" in
  let bbdone = new_block "array.done" in
  ignore (build_br bbcond builder);
  position_at_end bbcond builder;

  (* Counter into the length of the array *)
  let counter = build_phi [const_int i32_t start_pos, bbcurr] "counter" builder in
  add_incoming ((build_add counter (const_int i32_t 1) "tmp" builder), bbbody) counter;
  let cmp = build_icmp Icmp.Slt counter arr_len "tmp" builder in
  ignore (build_cond_br cmp bbbody bbdone builder);
  position_at_end bbbody builder;

  (* Assign array position to init_val *)
  let arr_ptr = build_gep arr [| counter |] "tmp" builder in
  ignore (build_store init_val arr_ptr builder);
  ignore (build_br bbcond builder);
  position_at_end bbdone builder in



  (*Array functions*)
  let struct_access lhs rhs isAssign builder =


  let lhs_type = Hashtbl.find struct_datatypes lhs in

  let search_term = ( lhs_type ^ "." ^ rhs) in


  let field_index = Hashtbl.find struct_field_indexes search_term in

  let _val = L.build_struct_gep (lookup lhs) field_index rhs builder in

  let _val = (* match d with
    Datatype(Objecttype(_)) ->
    if not isAssign then _val
    else build_load _val field builder

    | _ -> *)
    if not isAssign then
    _val
    else
    build_load _val rhs builder


    in
    _val



    in




    (* Construct code for an expression; return its value *)
    let rec expr builder = function
    | A.FloatLit f  -> L.const_float f_t f
    | A.StringLit s -> L.build_global_stringptr s "" builder
    | A.CharLit c   -> L.const_int i8_t (Char.code c)
    | A.Literal i   -> L.const_int i32_t i
    | A.BoolLit b   -> L.const_int i1_t (if b then 1 else 0)
    | A.Noexpr      -> L.const_int i32_t 0



    | A.StructAccess(lhs,rhs) -> (

      struct_access lhs rhs false builder
      )

      | A.StructCreate(struct_name)  ->
      (


        raise (Failure ("Structs still in progress 2"))


        )

        (*integer literals*)
        | A.Call ("print", [e]) ->

        (match List.hd [e] with

          | A.StringLit s ->
          let head = expr builder (List.hd [e]) in
          let llvm_val = L.build_in_bounds_gep head [| L.const_int i32_t 0 |] "string_printf" builder in

          print_endline ";a.string print called";
          L.build_call printf_func [| llvm_val |] "string_printf" builder

          | A.FloatLit f -> print_endline ";a.floatlit print called"; L.build_call printf_func [| float_format_str ; (expr builder e) |] "float_printf" builder


          | A.Id my_id ->
          (
            let my_typ = lookup_datatype my_id in
            ignore(print_endline("; my_typ: " ^ string_of_datatype my_typ));
            (match my_typ with

              | Datatype(A.Int) ->
              print_endline ";a.literial print called";L.build_call printf_func [| int_format_str ; (expr builder e) |] "int_printf" builder

              | Datatype(A.Float) ->
              print_endline ";a.float print called";L.build_call printf_func [| float_format_str ; (expr builder e) |] "float_printf" builder

              | Datatype(A.Char) ->
              print_endline ";a.char print called";L.build_call printf_func [| char_format_str ; (expr builder e) |] "int_printf" builder

              | _ ->
              print_endline ";a.string print called";L.build_call printf_func [| int_format_str ; (expr builder e) |] "string_printf" builder

              )

              )

              | A.StructAccess(var,field) ->
              (
                print_endline ";struct print called"; L.build_call printf_func [| int_format_str ; (expr builder e) |] "abcd" builder
                )
          | A.ArrayAccess(e2,i2) -> (match e2 with
            | A.FloatLit f -> print_endline ";ArrayAccess float lit print called"; L.build_call printf_func [| int_format_str ; (expr builder e) |] "abcd" builder
            | A.Id my_id -> ignore(print_endline(";my_id: " ^ my_id));
            (
              let my_typ = lookup_datatype my_id in
              ignore(print_endline(";typ: "^ (string_of_datatype my_typ)));

              (match (string_of_datatype my_typ) with

                | "int" ->
                print_endline ";mytype int_ print called";L.build_call printf_func [| int_format_str ; (expr builder e) |] "int_printf" builder

                | "flt" ->
                print_endline ";mytype float_ print called";L.build_call printf_func [| float_format_str ; (expr builder e) |] "float_printf" builder

                | "chr" ->
                print_endline ";mytpe char_ print called"; L.build_call printf_func [| char_format_str ; (expr builder e) |] "char_printf" builder

                | _ ->
                print_endline (";a._ in mytype match print called" ^ (string_of_datatype my_typ));L.build_call printf_func [| int_format_str ; (expr builder e) |] "string_printf" builder

                )

                )
            | _ -> print_endline (";ArrayAccess print called " ^ (string_of_expr e)); L.build_call printf_func [| int_format_str ; (expr builder e) |] "abcd" builder
            )
          | _ -> print_endline ";_ print called"; L.build_call printf_func [| int_format_str ; (expr builder e) |] "abcd" builder

                )




                (*Arrays*)
                |  A.ArrayCreate(t, el)      ->
                (
                  if(List.length el > 1) (*list of dimension sizes*)
                  then raise (Failure ("Only 1D arrays are allowed")) (*should throw an exception, not return*)
                  else
                  match t with

                  |   _ ->

                  let e = List.hd el in
                  let t = ltype_of_typ t in

                  let size = (expr builder e) in
                  let size_t = build_intcast (size_of t) i32_t "tmp" builder in
                  let size = build_mul size_t size "tmp" builder in
                  let size_real = build_add size (const_int i32_t 1) "arr_size" builder in

                  let arr = build_array_malloc t size_real "tmp" builder in
                  let arr = build_pointercast arr (pointer_type t) "tmp" builder in

                  let arr_len_ptr = build_pointercast arr (pointer_type i32_t) "tmp" builder in

                  (* Store length at this position *)
                  ignore(build_store size_real arr_len_ptr builder);
                  initialise_array arr_len_ptr size_real (const_int i32_t 0) 0 builder;
                  arr
                  )


                  (*ID and index*)
                  | A.ArrayAccess(e, el)   ->
                  (
                    let index = expr builder (List.hd el) in
                    let index = (match e with
                      | A.FloatLit f ->   build_add
                      index (
                          const_float f_t
                          1.0)
                          "tmp" builder
                      | _ ->   build_add index (const_int i32_t 1) "tmp" builder
                      )

                    in
                    let arr = expr builder e in
                    let _val = build_gep arr [| index |] "tmp" builder in

                    if false
                    then _val
                    else build_load _val "tmp" builder
                    )

                    (*printing functions*)
                    | A.Call (f, act) ->
                    let (fdef, fdecl) = StringMap.find f function_decls in

                    let actuals = List.rev (List.map (expr builder) (List.rev act)) in
                    let result = (match fdecl.A.datatype with
                      Datatype(Void) -> ""
                      | _ -> f ^ "_result") in
                      L.build_call fdef (Array.of_list actuals) result builder

                      | A.Id s -> L.build_load (lookup s) s builder
                      | A.Binop (e1, op, e2) ->
                      let e1' = expr builder e1
                      and e2' = expr builder e2 in

                      (match e1 with

                        | A.BoolLit b ->
                        (match op with
                          | A.And     -> L.build_and
                          | A.Or      -> L.build_or
                          | A.Equal   -> L.build_icmp L.Icmp.Eq
                          | A.Neq     -> L.build_icmp L.Icmp.Ne
                          | _ -> raise (Failure "Unsupported BoolLit binop")
                          ) e1' e2' "tmp" builder
                        | A.Bool b ->
                          (match op with
                            | A.And     -> L.build_and
                            | A.Or      -> L.build_or
                            | A.Equal   -> L.build_icmp L.Icmp.Eq
                            | A.Neq     -> L.build_icmp L.Icmp.Ne
                            | _ -> raise (Failure "Unsupported Bool (not lit) binop")
                            ) e1' e2' "tmp" builder

                            | A.FloatLit f ->
                            (match op with
                              A.Add     -> L.build_fadd
                              | A.Sub     -> L.build_fsub
                              | A.Mult    -> L.build_fmul
                              | A.Div     -> L.build_fdiv
                              | A.Equal   -> L.build_fcmp L.Fcmp.Oeq
                              | A.Neq     -> L.build_fcmp L.Fcmp.One
                              | A.Less    -> L.build_fcmp L.Fcmp.Ult
                              | A.Leq     -> L.build_fcmp L.Fcmp.Ole
                              | A.Greater -> L.build_fcmp L.Fcmp.Ogt
                              | A.Geq     -> L.build_fcmp L.Fcmp.Oge
                              | _ -> raise (Failure "Invalid")

                              ) e1' e2' "tmp" builder

                              | A.Literal i ->
                              (match op with
                                A.Add     -> L.build_add
                                | A.Sub     -> L.build_sub
                                | A.Mult    -> L.build_mul
                                | A.Div     -> L.build_sdiv
                                | A.And     -> L.build_and
                                | A.Or      -> L.build_or
                                | A.Equal   -> L.build_icmp L.Icmp.Eq
                                | A.Neq     -> L.build_icmp L.Icmp.Ne
                                | A.Less    -> L.build_icmp L.Icmp.Slt
                                | A.Leq     -> L.build_icmp L.Icmp.Sle
                                | A.Greater -> L.build_icmp L.Icmp.Sgt
                                | A.Geq     -> L.build_icmp L.Icmp.Sge
                                ) e1' e2' "tmp" builder

                                | A.Id my_id ->
                                (
                                  let my_typ = lookup_datatype my_id in
                                  (match my_typ with
                                    | Datatype(A.Int) ->
                                    (
                                      (match op with
                                        A.Add     -> L.build_add
                                        | A.Sub     -> L.build_sub
                                        | A.Mult    -> L.build_mul
                                        | A.Div     -> L.build_sdiv
                                        | A.And     -> L.build_and
                                        | A.Or      -> L.build_or
                                        | A.Equal   -> L.build_icmp L.Icmp.Eq
                                        | A.Neq     -> L.build_icmp L.Icmp.Ne
                                        | A.Less    -> L.build_icmp L.Icmp.Slt
                                        | A.Leq     -> L.build_icmp L.Icmp.Sle
                                        | A.Greater -> L.build_icmp L.Icmp.Sgt
                                        | A.Geq     -> L.build_icmp L.Icmp.Sge
                                        | _ -> raise (Failure "Invalid Int Binop")
                                        ) e1' e2' "tmp" builder
                                        )

                                        | Datatype(A.Bool) ->
                                        (
                                          (match op with
                                            | A.And     -> L.build_and
                                            | A.Or      -> L.build_or
                                            | A.Equal   -> L.build_icmp L.Icmp.Eq
                                            | A.Neq     -> L.build_icmp L.Icmp.Ne
                                            | _ -> raise (Failure "Unsupported Bool (not lit) binop")
                                            ) e1' e2' "tmp" builder
                                            )

                                      | Datatype(A.Float) ->
                                        ((match op with
                                          A.Add     -> L.build_fadd
                                          | A.Sub     -> L.build_fsub
                                          | A.Mult    -> L.build_fmul
                                          | A.Div     -> L.build_fdiv
                                          | A.Equal   -> L.build_fcmp L.Fcmp.Oeq
                                          | A.Neq     -> L.build_fcmp L.Fcmp.One
                                          | A.Less    -> L.build_fcmp L.Fcmp.Ult
                                          | A.Leq     -> L.build_fcmp L.Fcmp.Ole
                                          | A.Greater -> L.build_fcmp L.Fcmp.Ogt
                                          | A.Geq     -> L.build_fcmp L.Fcmp.Oge
                                          | _ -> raise (Failure "Invalid")

                                          ) e1' e2' "tmp" builder
                                          )
                                          | _ -> raise (Failure "Invalid Types")

                                          )
                                          )

                                          | _ ->  raise (Failure "Invalid")

                                          )
                                          | A.Unop(op, e) ->
                                          let e' = expr builder e in
                                          (match op with
                                            | A.Neg     ->

                                            (match e with

                                              | A.FloatLit f ->
                                              L.build_fneg

                                              | A.Literal i ->
                                              L.build_neg

                                              | A.Id my_id ->
                                              (
                                                let my_typ = lookup_datatype my_id in
                                                (match my_typ with
                                                  | Datatype(A.Int) ->
                                                  L.build_neg
                                                  | Datatype(A.Float) ->
                                                  L.build_fneg
                                                  | _ -> raise (Failure "Invalid")
                                                  )
                                                  )
                                                  | _ ->  raise (Failure "Invalid")

                                                  )

                                                  | A.Not     -> L.build_not) e' "tmp" builder

                                                  | A.Assign (lhs_id, rhs) ->
                                                  (
                                                    let lhs =
                                                    (
                                                      print_endline ";field";
                                                      match (lhs_id) with

                                                      | 	A.Id id ->
                                                      lookup id


                                                      (*ID and index*)
                                                      | A.ArrayAccess(e, el)   ->
                                                      (
                                                        let my_val =
                                                        match (e) with
                                                        | A.Id myaid ->
                                                        lookup myaid
                                                        | _ -> raise (Failure "Invalid2") in


                                                        let index = expr builder (List.hd el) in

                                                        let index = build_add index (const_int i32_t 1) "tmp" builder in
                                                        (
                                                          match (e) with
                                                          | A.Id myaid ->
                                                          (
                                                            let name = List.hd [e] in
                                                            let arr = L.build_load my_val myaid builder in
                                                            let _val = build_gep arr [| index |] "tmp" builder in
                                                            _val
                                                            )
                                                            | _ -> raise (Failure "Invalid3")
                                                            )
                                                            )


                                                            | A.StructAccess(lhs,rhs) -> (

                                                              struct_access lhs rhs false builder
                                                              )

                                                              )

                                                              in

                                                              let rhs = match rhs with
                                                              | A.Id id -> lookup id

                                                              | _ -> expr builder rhs

                                                              in
                                                              ignore (L.build_store rhs lhs builder);
                                                              rhs
                                                              )

                                                              in
                                                              (* Invoke "f builder" if the current block doesn't already
                                                              have a terminal (e.g., a branch). *)
                                                              let add_terminal builder f =
                                                              match L.block_terminator (L.insertion_block builder) with
                                                              Some _ -> ()
                                                              | None -> ignore (f builder) in

                                                              (* Build the code for the given statement; return the builder for
                                                              the statement's successor *)
                                                              let rec stmt builder = function
                                                              A.Block sl -> List.fold_left stmt builder sl
                                                              | A.Expr e -> ignore (expr builder e); builder
                                                              | A.Return e -> ignore (match fdecl.A.datatype with
                                                                Datatype(Void) -> L.build_ret_void builder
                                                                | _ -> L.build_ret (expr builder e) builder); builder
                                                                | A.If (predicate, then_stmt, else_stmt) ->
                                                                let bool_val = expr builder predicate in
                                                                let merge_bb = L.append_block context "merge" the_function in

                                                                let then_bb = L.append_block context "then" the_function in
                                                                add_terminal (stmt (L.builder_at_end context then_bb) then_stmt)
                                                                (L.build_br merge_bb);

                                                                let else_bb = L.append_block context "else" the_function in
                                                                add_terminal (stmt (L.builder_at_end context else_bb) else_stmt)
                                                                (L.build_br merge_bb);

                                                                ignore (L.build_cond_br bool_val then_bb else_bb builder);
                                                                L.builder_at_end context merge_bb

                                                                | A.While (predicate, body) ->
                                                                let pred_bb = L.append_block context "while" the_function in
                                                                ignore (L.build_br pred_bb builder);

                                                                let body_bb = L.append_block context "while_body" the_function in
                                                                add_terminal (stmt (L.builder_at_end context body_bb) body)
                                                                (L.build_br pred_bb);

                                                                let pred_builder = L.builder_at_end context pred_bb in
                                                                let bool_val = expr pred_builder predicate in

                                                                let merge_bb = L.append_block context "merge" the_function in
                                                                ignore (L.build_cond_br bool_val body_bb merge_bb pred_builder);
                                                                L.builder_at_end context merge_bb

                                                                | A.For (e1, e2, e3, body) -> stmt builder
                                                                ( A.Block [A.Expr e1 ; A.While (e2, A.Block [body ; A.Expr e3]) ] )
                                                                in

                                                                (* Build the code for each statement in the function *)
                                                                let builder = stmt builder (A.Block fdecl.A.body) in

                                                                (* Add a return if the last block falls off the end *)
                                                                add_terminal builder (match fdecl.A.datatype with
                                                                  Datatype(A.Void) -> L.build_ret_void
                                                                  | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
                                                                  in

                                                                  List.iter build_function_body functions;
                                                                  the_module
