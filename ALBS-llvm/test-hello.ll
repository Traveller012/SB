;struct_decl_stub called
;struct_decl_stub called
;struct_decl called!!
;struct_decl called!!
;field
;field
;field
;struct print called
;field
;field
;_ print called
;_ print called
; ModuleID = 'ALBS'

%location = type <{ i32, i32, double, i1 }>
%loc = type <{ i32, i32, double, i1 }>

@fmt = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt1 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt2 = private unnamed_addr constant [4 x i8] c"%c\0A\00"

declare i32 @printf(i8*, ...)

define i32 @main() {
entry:
  %l = alloca %location
  %l1 = alloca %loc
  %a = alloca i32*
  %malloccall = tail call i8* @malloc(i32 mul (i32 add (i32 mul (i32 ptrtoint (i32* getelementptr (i32* null, i32 1) to i32), i32 5), i32 1), i32 ptrtoint (i32* getelementptr (i32* null, i32 1) to i32)))
  %tmp = bitcast i8* %malloccall to i32*
  store i32 add (i32 mul (i32 ptrtoint (i32* getelementptr (i32* null, i32 1) to i32), i32 5), i32 1), i32* %tmp
  br label %array.cond

array.cond:                                       ; preds = %array.init, %entry
  %counter = phi i32 [ 0, %entry ], [ %tmp1, %array.init ]
  %tmp1 = add i32 %counter, 1
  %tmp2 = icmp slt i32 %counter, add (i32 mul (i32 ptrtoint (i32* getelementptr (i32* null, i32 1) to i32), i32 5), i32 1)
  br i1 %tmp2, label %array.init, label %array.done

array.init:                                       ; preds = %array.cond
  %tmp3 = getelementptr i32* %tmp, i32 %counter
  store i32 0, i32* %tmp3
  br label %array.cond

array.done:                                       ; preds = %array.cond
  store i32* %tmp, i32** %a
  %x = getelementptr inbounds %location* %l, i32 0, i32 1
  store i32 123, i32* %x
  %y = getelementptr inbounds %location* %l, i32 0, i32 2
  store double 5.300000e+00, double* %y
  %x4 = getelementptr inbounds %location* %l, i32 0, i32 1
  %abcd = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32* %x4)
  %a5 = load i32** %a
  %tmp6 = getelementptr i32* %a5, i32 1
  store i32 10, i32* %tmp6
  %a7 = load i32** %a
  %tmp8 = getelementptr i32* %a7, i32 3
  store i32 4, i32* %tmp8
  %a9 = load i32** %a
  %tmp10 = getelementptr i32* %a9, i32 3
  %tmp11 = load i32* %tmp10
  %abcd12 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 %tmp11)
  %a13 = load i32** %a
  %tmp14 = getelementptr i32* %a13, i32 1
  %tmp15 = load i32* %tmp14
  %abcd16 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 %tmp15)
  ret i32 0
}

declare noalias i8* @malloc(i32)
