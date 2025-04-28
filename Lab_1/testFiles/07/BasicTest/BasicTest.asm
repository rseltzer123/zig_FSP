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
// push constant10
@10
D=A
@SP
AM=M+1
A=A-1
M=D
// pop local0
@LCL
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
// push constant21
@21
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant22
@22
D=A
@SP
AM=M+1
A=A-1
M=D
// pop argument2
@ARG
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
// pop argument1
@ARG
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
// push constant36
@36
D=A
@SP
AM=M+1
A=A-1
M=D
// pop this6
@THIS
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
// push constant42
@42
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant45
@45
D=A
@SP
AM=M+1
A=A-1
M=D
// pop that5
@THAT
A=M
D=A
@5
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
// pop that2
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
// push constant510
@510
D=A
@SP
AM=M+1
A=A-1
M=D
// pop temp6
@11
D=A
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// push local0
@LCL
A=M
D=M
@SP
AM=M+1
A=A-1
M=D
// push that5
@THAT
A=M
D=A
@5
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
// push argument1
@ARG
A=M
A=A+1
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
// push this6
@THIS
A=M
D=A
@6
A=D+A
D=M
@SP
AM=M+1
A=A-1
M=D
// push this6
@THIS
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
// sub
@SP
AM=M-1
D=M
A=A-1
M=M-D
// push temp6
@11
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
