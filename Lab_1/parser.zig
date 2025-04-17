// This module provides functionality for parsing VM commands from a file. It includes a parser that reads a
// VM file, processes it line by line, and classifies each command into one of the predefined command types.
//
// The `Parser` structure holds the source lines, the current command index, and the current command in a parsed format.
// The parser can process VM commands such as arithmetic operations, push/pop commands, and unary operations.
//
// Key Functions:
// - `newParser`: Initializes a parser by reading a VM file, removing comments and whitespace, and splitting the file into lines.
// - `hasMoreCommands`: Checks if there are more commands to process.
// - `advance`: Advances to the next command and parses it.
// - `commandType`: Identifies the type of a given command string (e.g., "add", "sub", "push", "pop").
// - `arg1Arithmetic`, `arg2Arithmetic`: Retrieves the arguments for arithmetic commands.
// - `valueType`: Returns the type of value for push/pop commands.
// - `argPushPop`: Returns the argument value for push/pop commands.
//
// `CommandType` is an enum representing the different types of commands in the VM language:
// - Arithmetic commands: `add`, `sub`, `eq`, `gt`, `lt`, `and`, `or`, `neg`, `not`.
// - Push/Pop commands: `push`, `pop`.
// - Placeholder commands for future implementation: `start`, `eof`, `placeholder`.
//
// The module uses an array of strings to represent each line in the VM file, and it utilizes the `std` library for
// memory management, string manipulation, and file I/O.



const std = @import("std");
const print = std.debug.print;

pub fn trimComments(line: []const u8) []const u8{
    const comment_index = std.mem.indexOf(u8, line, "//") orelse line.len;
    return line[0..comment_index];
}
pub const CommandType = enum {
    start,  //placeholder for starting the program
    eof,        // eof
    placeholder,        //placeholder for all the commands that will be implemented later
                        //
    // Arithmetic Commands
    add,
    sub,
    eq,
    gt,
    lt,
    andCommand,
    orCommand,

    // Arithmetic Unary commands
    neg,
    not,

    // Push/Pop
    push,       // push segment i
    pop,        // pop segment i

    // To Implement later
    // label,
    // goto,
    // ifGoto,
    // function,
    // call,
    // returnCommand,
};

// The Parser structure holds the source lines, the current command index, and the current command in a parsed format.
pub const Parser = struct {
    lines: []const [3][]const u8, // dynamically sized array of 3-element arrays
    current_index: usize,
    current_command: CommandType, // Will be set when advance() is called

    // Reads the .vm file content, splits it into lines, and removes comments/whitespace.
    pub fn newParser(file: std.fs.File) !Parser {
        const allocator = std.heap.page_allocator;

        var reader = std.io.bufferedReader(file.reader());
        var stream = reader.reader();

        var lines_list = std.ArrayList([3][]const u8).init(allocator);

        while (true){
            const line = stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024) catch |err|{
                print("ERROR: {}\n", .{err});
                break;
            };
            if (line == null) break; // EOF
            defer allocator.free(line.?);

            const trimmed = std.mem.trim(u8, line.?, " \r\t\n");

            // Skip empty lines or comments
            if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "//")) continue;

            // Get rid of inline comments
            const line_no_comment = trimComments(trimmed);

            // Split into words
            var it = std.mem.tokenizeAny(u8, line_no_comment, " \n");
            var row: [3][]const u8 = undefined;
            var j: usize = 0;
            while (it.next()) |word|{

                if (j == 3){
                    print("ERROR: One of the lines in the VM file was too long.", .{});
                    break;
                }
                // the splitter always returns null at the end
                print("{s} ", .{word});
                const word_copy = try allocator.alloc(u8, word.len);
                @memcpy(word_copy, word);
                row[j] = word_copy;
                j +=1;

            }
            // Fill remaining unused slots with empty slices
            while (j < 3) : (j += 1) {
                row[j] = "";
            }

            try lines_list.append(row);
            print("\n", .{});
        }

        return Parser{
            .lines = try lines_list.toOwnedSlice(),
            .current_index = 0,
            .current_command = CommandType.start,
        };
    }

    // Returns whether there are additional commands to process.
    pub fn hasMoreCommands(self: *Parser) bool{
        // checks cuurent command and returns false if current command is the last command
        return self.current_index < (self.lines.len - 1);
    }

    // Reads the next command, parses it, and sets current_command.
    pub fn advance(self: *Parser) void{
        // if the number of rows in the lines array is the same as the current index then the code is completed
        if (self.current_index == (self.lines.len - 1)){
            self.current_command = CommandType.eof;
            return;
        }
        // if we've just started reading the file
        if (self.current_command == CommandType.start){
            self.current_command = commandType(self.lines[self.current_index][0]);
            return;
        }

        self.current_index += 1;
        self.current_command = commandType(self.lines[self.current_index][0]);
    }

    // Returns the type of the current command.
    pub fn commandType(command: []const u8) CommandType{
        // Had to do this with a bunch of ifs because you can't switch on strings in zig

        // Arithmetic Commands
        if (std.mem.eql(u8, command, "add")){ return CommandType.add;}
        if (std.mem.eql(u8, command, "sub")){ return CommandType.sub;}

        if (std.mem.eql(u8, command, "eq")){ return CommandType.eq;}
        if (std.mem.eql(u8, command, "gt")){ return CommandType.gt;}
        if (std.mem.eql(u8, command, "lt")){ return CommandType.lt;}
        if (std.mem.eql(u8, command, "and")){ return CommandType.andCommand;}
        if (std.mem.eql(u8, command, "or")){ return CommandType.orCommand;}

        // Arithmetic Unary Commands
        if (std.mem.eql(u8, command, "not")){ return CommandType.not;}
        if (std.mem.eql(u8, command, "neg")){ return CommandType.neg;}

        // Push
        if (std.mem.eql(u8, command, "push")){ return CommandType.push;}

        // Pop
        if (std.mem.eql(u8, command, "pop")){ return CommandType.pop;}

        return CommandType.placeholder;
    }

    // I DONT THINK WE NEED THESE FUNCTIONS
    // // Returns the first argument of an arithmetic current command.
    // pub fn arg1Arithmetic(self: *Parser) i32{
    //     // checks if the current command is an arithmetic command
    //     switch (self.current_command) {
    //         .add, .sub, .eq, .gt, .lt, .andCommand, .orCommand, .not, .neg => {
    //             // return CodeWriter.pop();
    //         },
    //         else => {
    //             print("ERROR: command is not an arithmetic command.", .{});
    //             return undefined;
    //         }
    //     }
    // }
    //
    // // Returns the integer value of the second argument for an Arithmetic command
    // pub fn arg2Arithmetic(self: *Parser) i32 {
    //     // checks if the current command is an arithmetic command
    //     switch (self.current_command) {
    //         .add, .sub, .eq, .gt, .lt, .andCommand, .orCommand => {
    //             // return CodeWriter.pop();
    //         },
    //         else => {
    //             print("ERROR: command is not an arithmetic command with 2 arguments.", .{});
    //             return undefined;
    //         }
    //     }
    // }
    // // Returns the integer for a push/pop
    //     pub fn argPushPop(self: *Parser) !i32{
    //         if (self.current_command == CommandType.push or self.current_command == CommandType.pop){
    //             const input: []const u8 = self.lines[self.current_index][2];
    //             const parsed_value = try std.fmt.parseInt(i32, input, 10);
    //             return parsed_value;
    //         }
    //         else {
    //             print("ERROR: command is not a push/pop.", .{});
    //             return undefined;
    //         }
    //     }

    // Returns the type of push/pop value type
    pub fn valueType(self: *Parser) []const u8{
        if (self.current_command == CommandType.push or self.current_command == CommandType.pop){
            // no error check here to see if ther is in fact a type-- need to do that on Codewriter side
            return self.lines[self.current_index][1];
        }
        else {
            print("ERROR: command is not a push/pop.", .{});
            return undefined;
        }
    }


};

test "Parser.newParser"{
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

    // Call newParser
    const file = try std.fs.Dir.openFile(tmp_dir.dir, file_name, .{}); // fixed this line
    defer file.close();
    const parser = try Parser.newParser(file);

    // Expected output:
    // [
    //   ["push", "constant", "10"],
    //   ["add"],
    //   ["pop", "local", "0"],
    //   ["label", "LOOP_START"]
    // ]

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

test "Parser functionality: hasMoreCommands, advance, commandType, arg1Arithmetic, arg2Arithmetic, valueType, argPushPop" {
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

    // hasMoreCommands should be true initially
    try testing.expect(parser.hasMoreCommands());

    // advance to the first command: push constant 7
    parser.advance();
    try testing.expectEqual(@as(CommandType, .push), parser.current_command);
    //print("\n{s}\n", .{parser.valueType()});
    try testing.expectEqualStrings("constant", parser.valueType());
    try testing.expectEqual(7, parser.argPushPop());

    // advance to second command: add
    parser.advance();
    try testing.expectEqual(@as(CommandType, .add), parser.current_command);
    // Assuming it's fixed for testability:
    // try testing.expectEqualStrings("add", parser.arg1Arithmetic());

    // advance to third command: pop local 2
    parser.advance();
    try testing.expectEqual(@as(CommandType, .pop), parser.current_command);
    try testing.expectEqualStrings("local", parser.valueType());
    try testing.expectEqual(2, parser.argPushPop());

    // advance to fourth command: neg
    parser.advance();
    try testing.expectEqual(@as(CommandType, .neg), parser.current_command);

    // advance to end
    parser.advance();
    try testing.expect(!parser.hasMoreCommands());
}

