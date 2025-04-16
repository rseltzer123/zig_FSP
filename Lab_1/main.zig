/// Rachamim Seltzer: 662215912
/// Efrem Mincer: 3246291982
/// Fundamentals of Software Programming Lab 1



const std = @import("std");
const parserFile = @import("parser.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;

const print = std.debug.print;


pub const CodeWriter = struct {
    output: []u8,         // or a file handle if writing directly
    file_name: []const u8,  // For naming static variables: "FileName.i"
    label_counter: usize, // To generate unique labels in comparisons
};

// code from Lab 0 to get the output file name
fn getOutputFileName(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "{s}.asm", .{std.fs.path.basename(path)}) catch | err | {
        return err;
    };
    return res;
}

pub fn main() !void {

    // Directory input from user taken from Lab 0
    const stdin = std.io.getStdIn().reader();
    var parser: parserFile.Parser = undefined;
    var buffer : [256]u8 = undefined;
    print("Please write a valid file path: \n", .{});
    var isGoodPath = false;
    while (!isGoodPath) {
        // get path from the user
        const path =  try stdin.readUntilDelimiterOrEof(buffer[0..], '\n');
        // convert path from ?[]u8 to []const u8
        if (path) |value| {
            const path_val = std.mem.trim(u8, value, " \r\n");

            var dir = std.fs.cwd().openDir(path_val,  .{.iterate = true}) catch |err| {
                print("ERROR: {}\n", .{err});
                continue;
            };
            defer dir.close();

            isGoodPath = true;

            const fileName = try getOutputFileName(path_val, std.heap.page_allocator);

            const wFile = try dir.createFile(fileName, .{.read = false});
            defer wFile.close();

            // iterate over directory and get file names
            var dir_it = dir.iterate();
            while(try dir_it.next()) |entry| {

                if (entry.kind == DIR_FILE_TYPE and std.mem.endsWith(u8,  entry.name, ".vm")){
                    const file = try std.fs.Dir.openFile(dir, entry.name, .{});
                    defer file.close();
                    parser = parserFile.Parser.newParser(file);

                }
            }
        } else {
            print("NO INPUT FOUND!\n", .{});
        }
    }

    while (parser.hasMoreCommands()){
        // first advance and if it's at the start it'll read the first command and doesn't increment the counter (although we could change that)
        parser.advance();
        const cmdType = parser.current_command;

        //put proper instructions in each one, just not sure how we're implememtning codewriter
        switch (cmdType) {
            .arithmetic => {
                return 0;
            },

            .arithmeticUnary => {
                return 0;
            },

            .push => {
                return 0;
            },

            .pop => {
                return 0;
            },

            else => {
                print("else.", .{});
            }

        }
    }

}

