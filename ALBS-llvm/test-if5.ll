;_ print called
;_ print called
; ModuleID = 'ALBS'

@fmt = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt1 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt2 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt3 = private unnamed_addr constant [4 x i8] c"%d\0A\00"

declare i32 @printf(i8*, ...)

define i32 @cond(i1 %blaahhhh) {
entry:
  %blaahhhh1 = alloca i1
  store i1 %blaahhhh, i1* %blaahhhh1
  %x = alloca i32
  %blaahhhh2 = load i1* %blaahhhh1
  br i1 %blaahhhh2, label %then, label %else

merge:                                            ; preds = %else, %then
  %x3 = load i32* %x
  ret i32 %x3

then:                                             ; preds = %entry
  store i32 42, i32* %x
  br label %merge

else:                                             ; preds = %entry
  store i32 17, i32* %x
  br label %merge
}

define i32 @main() {
entry:
  %cond_result = call i32 @cond(i1 true)
  %abcd = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt2, i32 0, i32 0), i32 %cond_result)
  %cond_result1 = call i32 @cond(i1 false)
  %abcd2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt2, i32 0, i32 0), i32 %cond_result1)
  ret i32 0
}
