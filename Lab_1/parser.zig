const std = @import("std");
const print = std.debug.print;

/// Removes any comments (//) from a given line, returning only the code part.
pub fn trimComments(line: []const u8) []const u8 {
    const comment_index = std.mem.indexOf(u8, line, "//") orelse line.len;
    const trimmed = std.mem.trim(u8, line[0..comment_index], " \r\t\n");
    return trimmed;
}

/// Enum representing all possible command types a VM file can contain.
pub const CommandType = enum {
    start,       // Placeholder for starting the program (before any commands processed)
    eof,         // End-of-file marker
    placeholder, // Placeholder for commands not yet implemented

    // Arithmetic Commands
    add,
    sub,
    eq,
    gt,
    lt,
    andCommand,
    orCommand,

    //added for test in class
    subNum2,

    // Arithmetic Unary Commands
    neg,
    not,

    // Memory Access Commands
    push,       // push segment i
    pop,        // pop segment i

    // Branching
    label,
    goto,
    ifGoto,

    // Function Calls
    function,
    call,
    returnCommand,
};

/// `Parser` reads and processes VM commands from a file.
pub const Parser = struct {
    lines: []const [4][]const u8,    // Array of parsed lines: each with up to 3 parts (command, arg1, arg2)
    current_index: usize,            // Current line index being processed
    current_command: CommandType,    // Type of current command (updated via advance)

    pub fn newParser(files: []std.fs.File, fileNames: [][]const u8) !Parser {
        const allocator = std.heap.page_allocator;
        var lines_list = std.ArrayList([4][]const u8).init(allocator);

        var i: usize = 0;

        for (files) |file| {
            var reader = std.io.bufferedReader(file.reader());
            var stream = reader.reader();

            while (true) {
                const line = stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024) catch |err| {
                    print("ERROR reading file: {}\n", .{err});
                    break;
                };
                if (line == null) break; // End of file
                defer allocator.free(line.?);

                const trimmed = std.mem.trim(u8, line.?, " \r\t\n");
                if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "//")) continue;

                const line_no_comment = trimComments(trimmed);
                var it = std.mem.tokenizeAny(u8, line_no_comment, " \n");
                var row: [4][]const u8 = undefined;
                var j: usize = 0;

                while (it.next()) |word| {
                    if (j == 3) {
                        print("ERROR: One of the lines in a VM file was too long.\n", .{});
                        break;
                    }
                    const word_copy = try allocator.alloc(u8, word.len);
                    @memcpy(word_copy, word);
                    row[j] = word_copy;
                    j += 1;
                }

                while (j < 3) : (j += 1) {
                    row[j] = "";
                }
                row[3] = fileNames[i];

                try lines_list.append(row);
            }
            i += 1;
        }

        return Parser{
            .lines = try lines_list.toOwnedSlice(),
            .current_index = 0,
            .current_command = CommandType.start,
        };
    }

    /// Returns true if there are more commands to process.
    pub fn hasMoreCommands(self: *Parser) bool {
        if (self.lines.len == 0) return false;
        return self.current_index < (self.lines.len - 1);
    }

    /// Advances the parser to the next command and updates the current_command field.
    pub fn advance(self: *Parser) void {
        if (self.current_index == (self.lines.len - 1)) {
            self.current_command = CommandType.eof;
            return;
        }
        if (self.current_command == CommandType.start) {
            self.current_command = commandType(self.lines[self.current_index][0]);
            return;
        }

        self.current_index += 1;
        self.current_command = commandType(self.lines[self.current_index][0]);
    }

    /// Returns the CommandType corresponding to the given command string.
    pub fn commandType(command: []const u8) CommandType {
        // Match command strings manually (no switch for strings in Zig)
    if (std.mem.eql(u8, command, "add")) {
            return CommandType.add;
        } else if (std.mem.eql(u8, command, "sub")) {
            return CommandType.sub;
        } else if (std.mem.eql(u8, command, "eq")) {
            return CommandType.eq;
        } else if (std.mem.eql(u8, command, "gt")) {
            return CommandType.gt;
        } else if (std.mem.eql(u8, command, "lt")) {
            return CommandType.lt;
        } else if (std.mem.eql(u8, command, "and")) {
            return CommandType.andCommand;
        } else if (std.mem.eql(u8, command, "or")) {
            return CommandType.orCommand;
        } else if (std.mem.eql(u8, command, "not")) {
            return CommandType.not;
        } else if (std.mem.eql(u8, command, "neg")) {
            return CommandType.neg;
        } else if (std.mem.eql(u8, command, "push")) {
            return CommandType.push;
        } else if (std.mem.eql(u8, command, "pop")) {
            return CommandType.pop;
        } else if (std.mem.eql(u8, command, "sub#2")) {
            return CommandType.subNum2;
        } else if (std.mem.eql(u8, command, "label")) {
            return CommandType.label;
        } else if (std.mem.eql(u8, command, "goto")) {
            return CommandType.goto;
        } else if (std.mem.eql(u8, command, "if-goto")) {
            return CommandType.ifGoto;
        } else if (std.mem.eql(u8, command, "call")) {
            return CommandType.call;
        } else if (std.mem.eql(u8, command, "function")) {
            return CommandType.function;
        } else if (std.mem.eql(u8, command, "return")) {
            return CommandType.returnCommand;
        } else {
            return CommandType.placeholder;
        }
    }

    pub fn getCurrentLine(self: *Parser) *const [4][]const u8 {
        return &self.lines[self.current_index];
    }

};



/////////////////////
//      TESTS      //
/////////////////////

test "Parser.newParser" {
    const testing = std.testing;

    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const file_name = "test_input.vm";
    const file_path = try tmp_dir.dir.createFile(file_name, .{});
    defer file_path.close();

    const input_text =
        \\// This is a comment
        \\push constant 10
        \\add // inline comment
        \\   pop   local 0
        \\// another comment
        \\label LOOP_START
    ;

    try file_path.writer().writeAll(input_text);

    const file = try std.fs.Dir.openFile(tmp_dir.dir, file_name, .{});
    defer file.close();

    const parser = try Parser.newParser(file);

    try testing.expectEqual(@as(usize, 4), parser.lines.len);
    try testing.expectEqualStrings("push", parser.lines[0][0]);
    try testing.expectEqualStrings("constant", parser.lines[0][1]);
    try testing.expectEqualStrings("10", parser.lines[0][2]);
    try testing.expectEqualStrings("add", parser.lines[1][0]);
    try testing.expectEqualStrings("pop", parser.lines[2][0]);
    try testing.expectEqualStrings("local", parser.lines[2][1]);
    try testing.expectEqualStrings("0", parser.lines[2][2]);
    try testing.expectEqualStrings("label", parser.lines[3][0]);
    try testing.expectEqualStrings("LOOP_START", parser.lines[3][1]);
}

test "Parser functionality: hasMoreCommands, advance, commandType, valueType, argPushPop" {
    const testing = std.testing;

    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const file_name = "test_input.vm";
    const file_path = try tmp_dir.dir.createFile(file_name, .{});
    defer file_path.close();

    const input_text =
        \\push constant 7
        \\add
        \\pop local 2
        \\neg
    ;

    try file_path.writer().writeAll(input_text);

    const file = try std.fs.Dir.openFile(tmp_dir.dir, file_name, .{});
    defer file.close();
    var parser = try Parser.newParser(file);

    try testing.expect(parser.hasMoreCommands());

    parser.advance();
    try testing.expectEqual(@as(CommandType, .push), parser.current_command);
    try testing.expectEqualStrings("constant", parser.valueType());
    try testing.expectEqual(7, parser.argPushPop());

    parser.advance();
    try testing.expectEqual(@as(CommandType, .add), parser.current_command);

    parser.advance();
    try testing.expectEqual(@as(CommandType, .pop), parser.current_command);
    try testing.expectEqualStrings("local", parser.valueType());
    try testing.expectEqual(2, parser.argPushPop());

    parser.advance();
    try testing.expectEqual(@as(CommandType, .neg), parser.current_command);

    parser.advance();
    try testing.expect(!parser.hasMoreCommands());
}
