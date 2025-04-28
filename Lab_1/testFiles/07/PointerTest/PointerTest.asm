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
// push constant3030
@3030
D=A
@SP
AM=M+1
A=A-1
M=D
// pop pointer0
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
// push constant3040
@3040
D=A
@SP
AM=M+1
A=A-1
M=D
// pop pointer1
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
// push constant32
@32
D=A
@SP
AM=M+1
A=A-1
M=D
// pop this2
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
// push constant46
@46
D=A
@SP
AM=M+1
A=A-1
M=D
// pop that6
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
// push pointer0
@THIS
D=M
@SP
AM=M+1
A=A-1
M=D
// push pointer1
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
// push this2
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
// push that6
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
