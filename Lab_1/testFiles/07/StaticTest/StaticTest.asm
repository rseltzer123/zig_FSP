@14
0;JMP          // Jump over helper block to actual program start
@SP
A=M-1
M=0            // false value (0) setup
@R13
A=M
0;JMP          // return to caller
@SP
A=M-1
M=-1           // true value (-1) setup
@R13
A=M
0;JMP          // return to caller
// push constant 111
@111
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant 333
@333
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant 888
@888
D=A
@SP
AM=M+1
A=A-1
M=D
// pop static 8
@StaticTestVME.8
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// pop static 3
@StaticTestVME.3
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// pop static 1
@StaticTestVME.1
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push static 3
@StaticTestVME.3
D=M
@SP
AM=M+1
A=A-1
M=D
// push static 1
@StaticTestVME.1
D=M
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
// push static 8
@StaticTestVME.8
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
