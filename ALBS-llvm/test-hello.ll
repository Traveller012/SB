;a.literial print called
;a.float print called
;_ print called
; ModuleID = 'ALBS'

@fmt = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@fmt1 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@fmt2 = private unnamed_addr constant [4 x i8] c"%c\0A\00"

declare i32 @printf(i8*, ...)

define i32 @main() {
entry:
  %x = alloca i32
  %y = alloca i32
  %f = alloca double
  %c = alloca i8
  %g = alloca double
  store i32 4, i32* %x
  store i32 8, i32* %y
  store i8 97, i8* %c
  store double 4.100000e+00, double* %f
  store double 5.500000e+00, double* %g
  %x1 = load i32* %x
  %y2 = load i32* %y
  %tmp = add i32 %x1, %y2
  store i32 %tmp, i32* %x
  %x3 = load i32* %x
  %tmp4 = add i32 %x3, 3
  store i32 %tmp4, i32* %x
  %f5 = load double* %f
  %g6 = load double* %g
  %tmp7 = fadd double %f5, %g6
  store double %tmp7, double* %f
  %f8 = load double* %f
  %tmp9 = fsub double %f8, 1.200000e+00
  store double %tmp9, double* %f
  %x10 = load i32* %x
  %int_printf = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 %x10)
  %f11 = load double* %f
  %float_printf = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt, i32 0, i32 0), double %f11)
  %abcd = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 100)
  ret i32 0
}
