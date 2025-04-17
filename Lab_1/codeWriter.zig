

const std = @import("std");

const print = std.debug.print;

pub const CodeWriter = struct {
    output: []u8,         // or a file handle if writing directly
    file_name: []const u8,  // For naming static variables: "FileName.i"
    label_counter: usize, // To generate unique labels in comparisons

    pub fn newCodeWriter(fileName: []const u8) CodeWriter{
        _ = fileName;
        return CodeWriter;
    }

    pub fn writeAdd() []const u8 {
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y (topmost value)
               \\A=A-1
               \\M=M+D      // M = x + y
               ;
    }

    pub fn writeSub() []const u8 {
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y
               \\A=A-1
               \\M=M-D      // M = x - y
               ;
    }

    pub fn writEq(self: *CodeWriter) []const u8 {
        self.label_counter;
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y
               \\A=A-1
               \\D=M-D      // D = x - y
               \\@EQ_TRUE<n>
               \\D;JEQ
               \\@SP
               \\A=M-1
               \\M=0        // false
               \\@EQ_END<n>
               \\0;JMP
               \\(EQ_TRUE<n>)
               \\@SP
               \\A=M-1
               \\M=-1 // true
               \\(EQ_END<n>)
               ;
    }

    pub fn writeGt() []const u8 {
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y
               \\A=A-1
               \\M=M-D      // M = x - y
               ;
    }


};

