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
// push constant 7
@7
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant 8
@8
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
