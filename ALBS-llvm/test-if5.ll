;field
;field
;a.string print called
;a.literial print called
;field
;_ print called
;_ print called
; ModuleID = 'ALBS'

@fmt = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt1 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt2 = private unnamed_addr constant [4 x i8] c"%c\0A\00"
@fmt3 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt4 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt5 = private unnamed_addr constant [4 x i8] c"%c\0A\00"

declare i32 @printf(i8*, ...)

define i32 @cond(i1 %blaahhhh) {
entry:
  %blaahhhh1 = alloca i1
  store i1 %blaahhhh, i1* %blaahhhh1
  %x = alloca i32
  %test = alloca i1
  store i1 false, i1* %test
  store i32 10, i32* %x
  %test2 = load i1* %test
  %string_printf = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i1 %test2)
  %x3 = load i32* %x
  %int_printf = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 %x3)
  store i32 10, i32* %x
  %x4 = load i32* %x
  ret i32 %x4
}

define i32 @main() {
entry:
  %cond_result = call i32 @cond(i1 true)
  %abcd = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt4, i32 0, i32 0), i32 %cond_result)
  %cond_result1 = call i32 @cond(i1 false)
  %abcd2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt4, i32 0, i32 0), i32 %cond_result1)
  ret i32 0
}
