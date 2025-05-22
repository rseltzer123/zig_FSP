// push argument 1
@ARG
A=M
A=A+1
D=M
@SP
AM=M+1
A=A-1
M=D
// pop pointer 1
@THAT
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push constant 0
@0
D=A
@SP
AM=M+1
A=A-1
M=D
// pop that 0
@THAT
A=M
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push constant 1
@1
D=A
@SP
AM=M+1
A=A-1
M=D
// pop that 1
@THAT
A=M
A=A+1
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push argument 0
@ARG
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
// push constant 2
@2
D=A
@SP
AM=M+1
A=A-1
M=D
// sub
@SP
AM=M-1
D=M
A=A-1
M=M-D
// pop argument 0
@ARG
A=M
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// branch label
(boot$MAIN_LOOP_START)
// push argument 0
@ARG
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
// if goto
@SP
AM=M-1
D=M
@boot$COMPUTE_ELEMENT
D;JNE
// goto
@boot$END_PROGRAM
0;JMP
// branch label
(boot$COMPUTE_ELEMENT)
// push that 0
@THAT
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
// push that 1
@THAT
A=M
A=A+1
D=M
@SP
AM=M+1
A=A-1
M=D
// add
@SP
AM=M-1
D=M
A=A-1
M=D+M
// pop that 2
@THAT
A=M
D=A
@2
A=D+A
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push pointer 1
@THAT
D=M
@SP
AM=M+1
A=A-1
M=D
// push constant 1
@1
D=A
@SP
AM=M+1
A=A-1
M=D
// add
@SP
AM=M-1
D=M
A=A-1
M=D+M
// pop pointer 1
@THAT
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push argument 0
@ARG
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
// push constant 1
@1
D=A
@SP
AM=M+1
A=A-1
M=D
// sub
@SP
AM=M-1
D=M
A=A-1
M=M-D
// pop argument 0
@ARG
A=M
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// goto
@boot$MAIN_LOOP_START
0;JMP
// branch label
(boot$END_PROGRAM)
