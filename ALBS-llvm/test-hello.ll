;a.float print called
;_ print called
; ModuleID = 'ALBS'

@fmt = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt1 = private unnamed_addr constant [4 x i8] c"%d\0A\00"

declare i32 @printf(i8*, ...)

define i32 @main() {
entry:
  %x = alloca i32
  %f = alloca double
  store i32 4, i32* %x
  store double 4.100000e+00, double* %f
  %f1 = load double* %f
  %float_printf = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt, i32 0, i32 0), double %f1)
  %abcd = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 5)
  ret i32 0
}
