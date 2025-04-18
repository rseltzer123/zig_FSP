

const std = @import("std");

const print = std.debug.print;

pub const CodeWriter = struct {
    //output: []u8,         // or a file handle if writing directly
    file_name: []const u8,  // For naming static variables: "FileName.i"
    label_counter: usize, // To generate unique labels in comparisons

    pub fn newCodeWriter(fileName: []const u8) CodeWriter {
        return CodeWriter{
            //.output = undefined,
            .file_name = fileName,
            .label_counter = 0,
        };
    }

    pub fn writeAdd() []const u8 {
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y (topmost value)
               \\A=A-1
               \\M=M+D      // M = x + y
               \\
               ;
    }

    pub fn writeSub() []const u8 {
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y
               \\A=A-1
               \\M=M-D      // M = x - y
               \\
               ;
    }

    // when using a function that has an allocator as an arugment you must free it after use
    pub fn writeEq(self: *CodeWriter, allocator: std.mem.Allocator) ![]u8 {
        const label_id = self.label_counter;
        self.label_counter += 1;

        return std.fmt.allocPrint(
            allocator,
            \\@SP
            \\AM=M-1
            \\D=M
            \\A=A-1
            \\D=M-D
            \\@EQ_TRUE{d}
            \\D;JEQ
            \\@SP
            \\A=M-1
            \\M=0    // false
            \\@EQ_END{d}
            \\0;JMP
            \\(EQ_TRUE{d})
            \\@SP
            \\A=M-1
            \\M=-1  // true
            \\(EQ_END{d})
            \\
            ,
            .{label_id, label_id, label_id, label_id}
        );
    }

    // when using a function that has an allocator as an arugment you must free it after use
    pub fn writeGt(self: *CodeWriter, allocator: std.mem.Allocator) ![]u8 {
        const label_id = self.label_counter;
        self.label_counter += 1;

        return std.fmt.allocPrint(
            allocator,
            \\@SP
            \\AM=M-1
            \\D=M
            \\A=A-1
            \\D=M-D
            \\@GT_TRUE{d}
            \\D;JGT
            \\@SP
            \\A=M-1
            \\M=0
            \\@GT_END{d}
            \\0;JMP
            \\(GT_TRUE{d})
            \\@SP
            \\A=M-1
            \\M=-1  // true
            \\(GT_END{d})
            \\
            ,
            .{label_id, label_id, label_id, label_id}
        );
    }

    // when using a function that has an allocator as an arugment you must free it after use
    pub fn writeLt(self: *CodeWriter, allocator: std.mem.Allocator) ![]u8 {
        const label_id = self.label_counter;
        self.label_counter += 1;

        return std.fmt.allocPrint(
            allocator,
            \\@SP
            \\AM=M-1
            \\D=M
            \\A=A-1
            \\D=M-D
            \\@LT_TRUE{d}
            \\D;JLT
            \\@SP
            \\A=M-1
            \\M=0
            \\@LT_END{d}
            \\0;JMP
            \\(LT_TRUE{d})
            \\@SP
            \\A=M-1
            \\M=-1  // true
            \\(LT_END{d})
            \\
            ,
            .{label_id, label_id, label_id, label_id}
        );
    }

    pub fn writeAnd() []const u8 {
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y (topmost value)
               \\A=A-1
               \\M=M&D      // M = x bitwise and y
               \\
               ;
    }

    pub fn writeOr() []const u8 {
        return \\@SP
               \\AM=M-1
               \\D=M        // D = y (topmost value)
               \\A=A-1
               \\M=M|D      // M = x bitwaise or y
               \\
               ;
    }

    pub fn writeNot() []const u8 {
        return \\@SP
               \\A=M-1
               \\M=!M
               \\
               ;
    }

    pub fn writeNeg() []const u8 {
        return \\@SP
               \\A=M-1
               \\M=-M
               \\
               ;
    }

    pub fn writePush(self: *CodeWriter, valueType: []const u8, i: i32,  allocator: std.mem.Allocator) ![]u8{
        // if statements checking which type of push it is
        if (std.mem.eql(u8, valueType, "constant")) {

            return std.fmt.allocPrint(
                allocator,
                 \\@{d}
                 \\D=A
                 \\@SP
                 \\A=M
                 \\M=D
                 \\@SP
                 \\M=M+1
                 \\
                 ,
                .{i});
        }
        if (std.mem.eql(u8, valueType, "local")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@LCL
                \\A=M+D
                \\D=M
                \\@SP
                \\A=M
                \\M=D
                \\@SP
                \\M=M+1
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "argument")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@ARG
                \\A=M+D
                \\D=M
                \\@SP
                \\A=M
                \\M=D
                \\@SP
                \\M=M+1
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "this")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@THIS
                \\A=M+D
                \\D=M
                \\@SP
                \\A=M
                \\M=D
                \\@SP
                \\M=M+1
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "that")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@THAT
                \\A=M+D
                \\D=M
                \\@SP
                \\A=M
                \\M=D
                \\@SP
                \\M=M+1
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "pointer")) {
            if (i == 0){
                return std.fmt.allocPrint(
                    allocator,
                \\@THIS
                       \\D=M
                       \\@SP
                       \\A=M
                       \\M=d
                       \\@SP
                       \\M=M+1
                \\
                ,
                    .{});
            }
            if (i == 1){
                return std.fmt.allocPrint(
                    allocator,
                \\@THAT
                       \\D=M
                       \\@SP
                       \\A=M
                       \\M=d
                       \\@SP
                       \\M=M+1
                \\
                ,
                    .{});
            }

            // if they didn't specify 1 or 0
            print("ERROR: there was no 1 or 0 specified.", .{});

        }

        // temp values are stored in ram locations 5 - 12
        // writing the command "push temp 3" is asking for the temp in RAM location 8
        if (std.mem.eql(u8, valueType, "temp")) {
            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@5
                \\A=D+A     // A = 5 + i
                \\D=M
                \\@SP
                \\A=M
                \\M=D
                \\@SP
                \\M=M+1
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "static")) {
            return std.fmt.allocPrint(
                allocator,
                \\@{s}.{d}
                \\D=M
                \\@SP
                \\A=M
                \\M=D
                \\@SP
                \\M=M+1
                \\
                 ,
                .{self.file_name,i});
        }

        return undefined;
    }

    pub fn writePop(self: *CodeWriter, valueType: []const u8, i: i32,  allocator: std.mem.Allocator) ![]u8{
        // if statements checking which type of pop it is

        if (std.mem.eql(u8, valueType, "local")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@LCL
                \\D=M+D
                \\@R13
                \\M=D       //R13 = target address
                \\@SP
                \\AM=M-1
                \\D=M
                \\@R13
                \\A=M
                \\M=D
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "argument")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@ARG
                \\D=M+D
                \\@R13
                \\M=D
                \\@SP
                \\AM=M-1
                \\D=M
                \\@R13
                \\A=M
                \\M=D
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "this")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@THIS
                \\D=M+D
                \\@R13
                \\M=D
                \\@SP
                \\AM=M-1
                \\D=M
                \\@R13
                \\A=M
                \\M=D
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "that")) {

            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@THAT
                \\D=M+D
                \\@R13
                \\M=D
                \\@SP
                \\AM=M-1
                \\D=M
                \\@R13
                \\A=M
                \\M=D
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "pointer")) {
            if (i == 0){
                return std.fmt.allocPrint(
                    allocator,
                \\@SP
                       \\AM=M-1
                       \\D=M
                       \\@THIS
                       \\M=D
                \\
                ,
                    .{});
            }
            if (i == 1){
                return std.fmt.allocPrint(
                    allocator,
                \\@SP
                       \\AM=M-1
                       \\D=M
                       \\@THAT
                       \\M=D
                \\
                ,
                    .{});
            }

            // if they didn't specify 1 or 0
            print("ERROR: there was no 1 or 0 specified.", .{});

        }

        // temp values are stored in ram locations 5 - 12
        // writing the command "push temp 3" is asking for the temp in RAM location 8
        if (std.mem.eql(u8, valueType, "temp")) {
            return std.fmt.allocPrint(
                allocator,
                \\@{d}
                \\D=A
                \\@5
                \\D=A+D     // D = 5 + i
                \\@R13
                \\M=D
                \\@SP
                \\AM=M-1
                \\D=M
                \\@R13
                \\A=M
                \\M=D
                \\
                 ,
                .{i});
        }

        if (std.mem.eql(u8, valueType, "static")) {
            return std.fmt.allocPrint(
                allocator,
                \\@SP
                \\AM=M-1
                \\D=M
                \\@{s}.{d}
                \\M=D
                \\
                 ,
                .{self.file_name,i});
        }

        return undefined;
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



