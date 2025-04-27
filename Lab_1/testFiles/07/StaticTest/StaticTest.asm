@14
0;JMP          // jump over the block to line 14 (where real code begins)
@SP
A=M-1
M=0            // set top of stack to false (0)
@R13
A=M
0;JMP          // jump to return address
@SP
A=M-1
M=-1           // set top of stack to true (-1)
@R13
A=M
0;JMP          // jump to return address
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
