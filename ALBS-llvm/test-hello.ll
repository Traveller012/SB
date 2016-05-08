;struct_decl_stub called
;struct_decl called!!
;_ print called
;_ print called
; ModuleID = 'ALBS'

@fmt = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt.1 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt.2 = private unnamed_addr constant [4 x i8] c"%c\0A\00"

declare i32 @printf(i8*, ...)

define i32 @main() {
entry:
  %a = alloca i32*
  %malloccall = tail call i8* @malloc(i32 mul (i32 add (i32 mul (i32 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i32), i32 5), i32 1), i32 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i32)))
  %tmp = bitcast i8* %malloccall to i32*
  store i32 add (i32 mul (i32 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i32), i32 5), i32 1), i32* %tmp
  br label %array.cond

array.cond:                                       ; preds = %array.init, %entry
  %counter = phi i32 [ 0, %entry ], [ %tmp1, %array.init ]
  %tmp1 = add i32 %counter, 1
  %tmp2 = icmp slt i32 %counter, add (i32 mul (i32 ptrtoint (i32* getelementptr (i32, i32* null, i32 1) to i32), i32 5), i32 1)
  br i1 %tmp2, label %array.init, label %array.done

array.init:                                       ; preds = %array.cond
  %tmp3 = getelementptr i32, i32* %tmp, i32 %counter
  store i32 0, i32* %tmp3
  br label %array.cond

array.done:                                       ; preds = %array.cond
  store i32* %tmp, i32** %a
  %a4 = load i32*, i32** %a
  %tmp5 = getelementptr i32, i32* %a4, i32 1
  store i32 10, i32* %tmp5
  %a6 = load i32*, i32** %a
  %tmp7 = getelementptr i32, i32* %a6, i32 3
  store i32 4, i32* %tmp7
  %a8 = load i32*, i32** %a
  %tmp9 = getelementptr i32, i32* %a8, i32 3
  %tmp10 = load i32, i32* %tmp9
  %abcd = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @fmt.1, i32 0, i32 0), i32 %tmp10)
  %a11 = load i32*, i32** %a
  %tmp12 = getelementptr i32, i32* %a11, i32 1
  %tmp13 = load i32, i32* %tmp12
  %abcd14 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @fmt.1, i32 0, i32 0), i32 %tmp13)
  ret i32 0
}

declare noalias i8* @malloc(i32)
