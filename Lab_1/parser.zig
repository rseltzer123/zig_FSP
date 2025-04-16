// Parser class
// goes through VM file
// isolating the commands and passing them to CodeWriter to Code into Hack

const std = @import("std");
const print = std.debug.print;

pub fn trimComments(line: []const u8) []const u8{
    const comment_index = std.mem.indexOf(u8, line, "//") orelse line.len;
    return line[0..comment_index];
}
pub const CommandType = enum {
    arithmetic, // e.g. add, sub, neg, eq, gt, lt, and, or, not
    push,       // push segment i
    pop        // pop segment i
};

pub const Command = struct {
    command_type: CommandType,
    arg1: []const u8, // For arithmetic, this holds the operation (e.g. "add")
    arg2: ?i32,      // For push/pop, holds the index; null for arithmetic commands
};


pub const Parser = struct {
    lines: []const [3][]const u8, // dynamically sized array of 3-element arrays
    current_index: usize,
    current_command: ?Command, // Will be set when advance() is called

    pub fn newParser(file: std.fs.File) !Parser {
        const allocator = std.heap.page_allocator;

        var reader = std.io.bufferedReader(file.reader());
        var stream = reader.reader();

        // var lines: [100][3] []const u8 = undefined;
        var lines_list = std.ArrayList([3][]const u8).init(allocator);

        // var i: usize = 0;
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
            //i +=1;
            print("\n", .{});
        }

        return Parser{
            .lines = try lines_list.toOwnedSlice(),
            .current_index = 0,
            .current_command = null,
        };
    }

    pub fn hasMoreCommands() bool{
        // checks cuurent command and returns false if current command is the last command
        return true;
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
