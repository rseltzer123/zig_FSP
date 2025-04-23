

const std = @import("std");

const print = std.debug.print;
const TRUELINE = 8;
const FALSELINE = 2;

pub const CodeWriter = struct {
    //output: []u8,         // or a file handle if writing directly
    file_name: []const u8,  // For naming static variables: "FileName.i"

    pub fn newCodeWriter(fileName: []const u8) CodeWriter {
        return CodeWriter{
            //.output = undefined,
            .file_name = fileName,
        };
    }

    pub fn init(self:CodeWriter) []const u8{
        _=self;
        return \\@14
               \\0;JMP          // jump over the block to line 14 (where real code begins)
               \\@SP
               \\A=M-1
               \\M=0            // set top of stack to false (0)
               \\@R13
               \\A=M
               \\0;JMP          // jump to return address
               \\@SP
               \\A=M-1
               \\M=-1           // set top of stack to true (-1)
               \\@R13
               \\A=M
               \\0;JMP          // jump to return address
               \\
               ;
    }

    // Working:
    //      add
    //      sub
    //      push
    //
    pub fn writeAdd(self: CodeWriter) []const u8 {
        _ = self;
        return \\@SP
               \\AM=M-1
               \\D=M
               \\A=A-1
               \\M=D+M
               \\
               ;
    }

    pub fn writeSub(self: CodeWriter) []const u8 {
        _ = self;
        return \\@SP
               \\AM=M-1
               \\D=M
               \\A=A-1
               \\M=M-D
                \\
               ;
    }

    // when using a function that has an allocator as an arugment you must free it after use
    pub fn writeEq(self: *CodeWriter, allocator: std.mem.Allocator, lineNum: usize) ![]u8 {
        _ = self;
        return std.fmt.allocPrint(
            allocator,
            \\JEQ
            \\@{d}
            \\D=A
            \\@R13
            \\M=D
            \\@SP
            \\AM=M-1
            \\D=M
            \\A=A-1
            \\D=M-D
            \\@{d}
            \\JEQ
            \\@{d}
            \\0;JMP
            \\
            ,
            .{lineNum+14, TRUELINE, FALSELINE}
        );
    }

    // when using a function that has an allocator as an arugment you must free it after use
    pub fn writeGt(self: *CodeWriter, allocator: std.mem.Allocator, lineNum: usize) ![]u8 {
        _ = self;

        return std.fmt.allocPrint(
            allocator,
            \\JGT
            \\@{d}
            \\D=A
            \\@R13
            \\M=D
            \\@SP
            \\AM=M-1
            \\D=M
            \\A=A-1
            \\D=M-D
            \\@{d}
            \\JGT
            \\@{d}
            \\0;JMP
            \\
            ,
            .{lineNum+14, TRUELINE, FALSELINE}
        );
    }

    // when using a function that has an allocator as an arugment you must free it after use
    pub fn writeLt(self: *CodeWriter, allocator: std.mem.Allocator, lineNum: usize) ![]u8 {
        _ = self;

        return std.fmt.allocPrint(
            allocator,
            \\JLT
            \\@{d}
            \\D=A
            \\@R13
            \\M=D
            \\@SP
            \\AM=M-1
            \\D=M
            \\A=A-1
            \\D=M-D
            \\@{d}
            \\JLT
            \\@{d}
            \\0;JMP
            \\
            ,
            .{lineNum+14, TRUELINE, FALSELINE}
        );
    }

    pub fn writeAnd(self: CodeWriter) []const u8 {
        _ = self;
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y (topmost value)
               \\A=A-1
               \\M=M&D      // M = x bitwise and y
               \\
               ;
    }

    pub fn writeOr(self: CodeWriter) []const u8 {
        _ = self;
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y (topmost value)
               \\A=A-1
               \\M=M|D      // M = x bitwaise or y
               \\
               ;
    }

    pub fn writeNot(self: CodeWriter) []const u8 {
        _ = self;
        return \\@SP
               \\A=M-1
               \\M=!M
               \\
               ;
    }

    pub fn writeNeg(self: CodeWriter) []const u8 {
        _ = self;
        return \\@SP
               \\A=M-1
               \\M=-M
               \\
               ;
    }

    pub fn writePushPop(
        self: *CodeWriter,
        pushOrpop: []const u8,
        valueType: []const u8,
        i: i32,
        allocator: std.mem.Allocator,
        filename: []const u8
    ) ![]u8 {
        _ = self;

        const SegmentEndStack = struct {
            segmentEnd: []const u8,
            stack: []const u8,
        };

        const segmentEndStack: SegmentEndStack = blk: {
            if (std.mem.eql(u8, pushOrpop, "push")) {
                break :blk SegmentEndStack{
                    .segmentEnd = "D=M\n",
                    .stack = "@SP\nAM=M+1\nA=A-1\nM=D\n",
                };
            } else if (std.mem.eql(u8, pushOrpop, "pop")) {
                break :blk SegmentEndStack{
                    .segmentEnd = "D=A\n@R13\nM=D\n",
                    .stack = "@SP\nAM=M-1\nD=M\n@R13\nA=M\nM=D\n",
                };
            } else {
                return error.InvalidCommand;
            }
        };

        var asmText = std.ArrayList(u8).init(allocator);
        defer asmText.deinit(); // If we return early, cleanup

        if (std.mem.eql(u8, valueType, "constant")) {
            try asmText.writer().print("@{d}\nD=A\n", .{ i });

        } else if (std.mem.eql(u8, valueType, "local") or
            std.mem.eql(u8, valueType, "argument") or
            std.mem.eql(u8, valueType, "this") or
            std.mem.eql(u8, valueType, "that")) {

            const segSymbol = if (std.mem.eql(u8, valueType, "local")) "LCL"
                else if (std.mem.eql(u8, valueType, "argument")) "ARG"
                    else if (std.mem.eql(u8, valueType, "this")) "THIS"
                        else if (std.mem.eql(u8, valueType, "that")) "THAT"
                            else return error.InvalidSegment;

            try asmText.writer().print("@{s}\nA=M\n", .{ segSymbol });

            if (i == 1) {
                try asmText.writer().writeAll("A=A+1\n");
            } else if (i != 0) {
                try asmText.writer().print("D=A\n@{d}\nA=A+D\n", .{ i });
            }

            try asmText.writer().writeAll(segmentEndStack.segmentEnd);

        } else if (std.mem.eql(u8, valueType, "static")) {
            try asmText.writer().print("@{s}.{d}\n{s}", .{ filename, i, segmentEndStack.segmentEnd });

        } else if (std.mem.eql(u8, valueType, "temp")) {
            try asmText.writer().print("@{d}\n{s}", .{ i + 5, segmentEndStack.segmentEnd });

        } else if (std.mem.eql(u8, valueType, "pointer")) {
            if (i != 0 and i != 1) return error.InvalidPointerIndex;
            const symbol = if (i == 0) "THIS" else "THAT";
            try asmText.writer().print("@{s}\n{s}", .{ symbol, segmentEndStack.segmentEnd });

        } else {
            return error.InvalidSegment;
        }

        try asmText.writer().writeAll(segmentEndStack.stack);
        return asmText.toOwnedSlice(); // Transfer ownership of result
    }
};


    test "writeAdd" {
    const result = CodeWriter.writeAdd();
    try std.testing.expectEqualStrings(
        \\@SP
        \\AM=M-1
        \\D=M        // D = y (topmost value)
        \\A=A-1
        \\M=M+D      // M = x + y
        \\
        ,
        result
    );
}

test "writeSub" {
    const result = CodeWriter.writeSub();
    try std.testing.expectEqualStrings(
        \\@SP
        \\AM=M-1
        \\D=M        // D = y
        \\A=A-1
        \\M=M-D      // M = x - y
        \\
        ,
        result
    );
}

test "writeAnd" {
    const result = CodeWriter.writeAnd();
    try std.testing.expectEqualStrings(
        \\@SP
        \\AM=M-1
        \\D=M        // D = y (topmost value)
        \\A=A-1
        \\M=M&D      // M = x bitwise and y
        \\
        ,
        result
    );
}

test "writeOr" {
    const result = CodeWriter.writeOr();
    try std.testing.expectEqualStrings(
        \\@SP
        \\AM=M-1
        \\D=M        // D = y (topmost value)
        \\A=A-1
        \\M=M|D      // M = x bitwaise or y
        \\
        ,
        result
    );
}

test "writeNot" {
    const result = CodeWriter.writeNot();
    try std.testing.expectEqualStrings(
        \\@SP
        \\A=M-1
        \\M=!M
        \\
        ,
        result
    );
}

test "writeNeg" {
    const result: []const u8 = CodeWriter.writeNeg();
    try std.testing.expectEqualStrings(
        \\@SP
        \\A=M-1
        \\M=-M
        \\D=M
        \\
        ,
        result
    );
}

test "writePush constant 7" {
    const allocator = std.testing.allocator;
    var writer = CodeWriter{
        //.output = undefined,
        .file_name = "TestFile",
        .label_counter = 0,
    };

    const result:[]u8 = try writer.writePush("constant", 7, allocator);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(
        \\@7
        \\D=A
        \\@SP
        \\A=M
        \\M=D
        \\@SP
        \\M=M+1
        \\
        ,
        result
    );
}

test "writePop static 2" {
    const allocator = std.testing.allocator;
    var writer = CodeWriter{
        //.output = undefined,
        .file_name = "TestFile",
        .label_counter = 0,
    };

    const result: []u8 = try writer.writePop("static", 2, allocator);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(
        \\@SP
        \\AM=M-1
        \\D=M
        \\@TestFile.2
        \\M=D
        \\
        ,
        result
    );
}

test "CodeWriter.newCodeWriter initializes fields correctly" {
    const writer = CodeWriter.newCodeWriter("TestFile");

    try std.testing.expectEqualStrings("TestFile", writer.file_name);
    try std.testing.expectEqual(@as(usize, 0), writer.label_counter);
}






// pub fn writePush(self: *CodeWriter, valueType: []const u8, i: i32,  allocator: std.mem.Allocator) ![]u8{
//     // if statements checking which type of push it is
//     if (std.mem.eql(u8, valueType, "constant")) {
//
//         return std.fmt.allocPrint(
//         allocator,
//         \\@{d}
//                      \\D=A
//                      \\@SP
//                      \\AM=M+1
//                      \\A=A-1
//                      \\M=D
//                      \\
//                      ,
//         .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "local")) {
//
//         if (i == 1){
//             return std.fmt.allocPrint(
//             allocator,
//             \\@LCL
//             \\A=M
//             \\D=M
//             \\@SP
//             \\A=M
//             \\A=A+1
//             \\D=M
//             \\
//              ,
//             .{});
//         }
//
//         else if (i != 0){
//             return std.fmt.allocPrint(
//             allocator,
//             \\@LCL
//             \\A=M
//             \\D=A
//             \\@{d}
//             \\A=M
//             \\M=D
//             \\@SP
//             \\M=M+1
//             \\
//             ,
//             .{i});
//         }
//
//     }
//
//     if (std.mem.eql(u8, valueType, "argument")) {
//
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@ARG
//             \\A=M+D
//             \\D=M
//             \\@SP
//             \\A=M
//             \\M=D
//             \\@SP
//             \\M=M+1
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "this")) {
//
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@THIS
//             \\A=M+D
//             \\D=M
//             \\@SP
//             \\A=M
//             \\M=D
//             \\@SP
//             \\M=M+1
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "that")) {
//
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@THAT
//             \\A=M+D
//             \\D=M
//             \\@SP
//             \\A=M
//             \\M=D
//             \\@SP
//             \\M=M+1
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "pointer")) {
//         if (i == 0){
//             return std.fmt.allocPrint(
//                 allocator,
//             \\@THIS
//                    \\D=M
//                    \\@SP
//                    \\A=M
//                    \\M=d
//                    \\@SP
//                    \\M=M+1
//             \\
//             ,
//                 .{});
//         }
//         if (i == 1){
//             return std.fmt.allocPrint(
//                 allocator,
//             \\@THAT
//                    \\D=M
//                    \\@SP
//                    \\A=M
//                    \\M=d
//                    \\@SP
//                    \\M=M+1
//             \\
//             ,
//                 .{});
//         }
//
//         // if they didn't specify 1 or 0
//         print("ERROR: there was no 1 or 0 specified.", .{});
//
//     }
//
//     // temp values are stored in ram locations 5 - 12
//     // writing the command "push temp 3" is asking for the temp in RAM location 8
//     if (std.mem.eql(u8, valueType, "temp")) {
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@5
//             \\A=D+A     // A = 5 + i
//             \\D=M
//             \\@SP
//             \\A=M
//             \\M=D
//             \\@SP
//             \\M=M+1
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "static")) {
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{s}.{d}
//             \\D=M
//             \\@SP
//             \\A=M
//             \\M=D
//             \\@SP
//             \\M=M+1
//             \\
//              ,
//             .{self.file_name,i});
//     }
//
//     return undefined;
// }
//
//
// pub fn writePop(self: *CodeWriter, valueType: []const u8, i: i32,  allocator: std.mem.Allocator) ![]u8{
//     // if statements checking which type of pop it is
//
//     if (std.mem.eql(u8, valueType, "local")) {
//
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@LCL
//             \\D=M+D
//             \\@R13
//             \\M=D       //R13 = target address
//             \\@SP
//             \\AM=M-1
//             \\D=M
//             \\@R13
//             \\A=M
//             \\M=D
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "argument")) {
//
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@ARG
//             \\D=M+D
//             \\@R13
//             \\M=D
//             \\@SP
//             \\AM=M-1
//             \\D=M
//             \\@R13
//             \\A=M
//             \\M=D
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "this")) {
//
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@THIS
//             \\D=M+D
//             \\@R13
//             \\M=D
//             \\@SP
//             \\AM=M-1
//             \\D=M
//             \\@R13
//             \\A=M
//             \\M=D
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "that")) {
//
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@THAT
//             \\D=M+D
//             \\@R13
//             \\M=D
//             \\@SP
//             \\AM=M-1
//             \\D=M
//             \\@R13
//             \\A=M
//             \\M=D
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "pointer")) {
//         if (i == 0){
//             return std.fmt.allocPrint(
//                 allocator,
//             \\@SP
//                    \\AM=M-1
//                    \\D=M
//                    \\@THIS
//                    \\M=D
//             \\
//             ,
//                 .{});
//         }
//         if (i == 1){
//             return std.fmt.allocPrint(
//                 allocator,
//             \\@SP
//                    \\AM=M-1
//                    \\D=M
//                    \\@THAT
//                    \\M=D
//             \\
//             ,
//                 .{});
//         }
//
//         // if they didn't specify 1 or 0
//         print("ERROR: there was no 1 or 0 specified.", .{});
//
//     }
//
//     // temp values are stored in ram locations 5 - 12
//     // writing the command "push temp 3" is asking for the temp in RAM location 8
//     if (std.mem.eql(u8, valueType, "temp")) {
//         return std.fmt.allocPrint(
//             allocator,
//             \\@{d}
//             \\D=A
//             \\@5
//             \\D=A+D     // D = 5 + i
//             \\@R13
//             \\M=D
//             \\@SP
//             \\AM=M-1
//             \\D=M
//             \\@R13
//             \\A=M
//             \\M=D
//             \\
//              ,
//             .{i});
//     }
//
//     if (std.mem.eql(u8, valueType, "static")) {
//         return std.fmt.allocPrint(
//             allocator,
//             \\@SP
//             \\AM=M-1
//             \\D=M
//             \\@{s}.{d}
//             \\M=D
//             \\
//              ,
//             .{self.file_name,i});
//     }
//
//     return undefined;
// }

