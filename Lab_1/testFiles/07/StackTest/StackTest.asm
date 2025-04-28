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
// push constant17
@17
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant17
@17
D=A
@SP
AM=M+1
A=A-1
M=D
// eq
@39
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JEQ
@2
0;JMP
// push constant17
@17
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant16
@16
D=A
@SP
AM=M+1
A=A-1
M=D
// eq
@64
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JEQ
@2
0;JMP
// push constant16
@16
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant17
@17
D=A
@SP
AM=M+1
A=A-1
M=D
// eq
@89
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JEQ
@2
0;JMP
// push constant892
@892
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant891
@891
D=A
@SP
AM=M+1
A=A-1
M=D
// lt
@114
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JLT
@2
0;JMP
// push constant891
@891
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant892
@892
D=A
@SP
AM=M+1
A=A-1
M=D
// lt
@139
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JLT
@2
0;JMP
// push constant891
@891
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant891
@891
D=A
@SP
AM=M+1
A=A-1
M=D
// lt
@164
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JLT
@2
0;JMP
// push constant32767
@32767
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant32766
@32766
D=A
@SP
AM=M+1
A=A-1
M=D
// gt
@189
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JGT
@2
0;JMP
// push constant32766
@32766
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant32767
@32767
D=A
@SP
AM=M+1
A=A-1
M=D
// gt
@214
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JGT
@2
0;JMP
// push constant32766
@32766
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant32766
@32766
D=A
@SP
AM=M+1
A=A-1
M=D
// gt
@239
D=A
@R13
M=D
@SP
AM=M-1
D=M
A=A-1
D=M-D
@8
D;JGT
@2
0;JMP
// push constant57
@57
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant31
@31
D=A
@SP
AM=M+1
A=A-1
M=D
// push constant53
@53
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
// push constant112
@112
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
// neg
@SP
A=M-1
M=-M
// and
@SP
AM=M-1
D=M
A=A-1
M=D&M
// push constant82
@82
D=A
@SP
AM=M+1
A=A-1
M=D
// or
@SP
AM=M-1
D=M
A=A-1
M=D|M
// not
@SP
A=M-1
M=!M
