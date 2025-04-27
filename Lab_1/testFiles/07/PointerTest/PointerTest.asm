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
// push constant 3030
@3030
D=A
@SP
AM=M+1
A=A-1
M=D
// pop pointer 0
@THIS
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push constant 3040
@3040
D=A
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
// push constant 32
@32
D=A
@SP
AM=M+1
A=A-1
M=D
// pop this 2
@THIS
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
// push constant 46
@46
D=A
@SP
AM=M+1
A=A-1
M=D
// pop that 6
@THAT
A=M
D=A
@6
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
// push pointer 0
@THIS
D=M
@SP
AM=M+1
A=A-1
M=D
// push pointer 1
@THAT
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
// push this 2
@THIS
A=M
D=A
@2
A=D+A
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
// push that 6
@THAT
A=M
D=A
@6
A=D+A
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
