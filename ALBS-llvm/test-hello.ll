;a.string print called
;a.string print called
;a.float print called
;_ print called
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
  %o = alloca i1
  %p = alloca i1
  store i32 1, i32* %x
  store i32 2, i32* %y
  store i8 97, i8* %c
  store double 1.100000e+00, double* %f
  store double 2.100000e+00, double* %g
  %x1 = load i32* %x
  %y2 = load i32* %y
  %tmp = add i32 %x1, %y2
  store i32 %tmp, i32* %x
  %x3 = load i32* %x
  %tmp4 = add i32 %x3, 1
  store i32 %tmp4, i32* %x
  %x5 = load i32* %x
  %tmp6 = sub i32 0, %x5
  store i32 %tmp6, i32* %x
  %f7 = load double* %f
  %g8 = load double* %g
  %tmp9 = fadd double %f7, %g8
  store double %tmp9, double* %f
  store i1 true, i1* %o
  store i1 true, i1* %p
  %o10 = load i1* %o
  %tmp11 = xor i1 %o10, true
  store i1 %tmp11, i1* %o
  store i1 true, i1* %o
  %f12 = load double* %f
  %tmp13 = fsub double %f12, 1.100000e+00
  store double %tmp13, double* %f
  %f14 = load double* %f
  %tmp15 = fsub double -0.000000e+00, %f14
  store double %tmp15, double* %f
  %o16 = load i1* %o
  %string_printf = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i1 %o16)
  %p17 = load i1* %p
  %string_printf18 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i1 %p17)
  %f19 = load double* %f
  %float_printf = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt, i32 0, i32 0), double %f19)
  %x20 = load i32* %x
  %tmp21 = sub i32 0, %x20
  %abcd = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 %tmp21)
  %f22 = load double* %f
  %float_printf23 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt, i32 0, i32 0), double %f22)
  %abcd24 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @fmt1, i32 0, i32 0), i32 100)
  ret i32 0
}
