/// Rachamim Seltzer: 662215912
/// Efrem Mincer: 3246291982
/// Fundamentals of Software Programming Lab 1



const std = @import("std");
const parserModule = @import("parser.zig");
const codeWriterModule = @import("codeWriter.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;

const print = std.debug.print;

// code from Lab 0 to get the output file name
fn getInputFileName(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "{s}.asm", .{std.fs.path.basename(path)}) catch | err | {
        return err;
    };
    return res;
}

pub fn main() !void {

    // Directory input from user taken from Lab 0
    const stdin = std.io.getStdIn().reader();
    var parser: parserModule.Parser = undefined;

    const fileName = undefined;
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

            fileName = try getInputFileName(path_val, std.heap.page_allocator);
            // add error handling

            const wFile = try dir.createFile(fileName, .{.read = false});
            defer wFile.close();

            // iterate over directory and get file names
            var dir_it = dir.iterate();
            while(try dir_it.next()) |entry| {

                if (entry.kind == DIR_FILE_TYPE and std.mem.endsWith(u8,  entry.name, ".vm")){
                    const file = try std.fs.Dir.openFile(dir, entry.name, .{});
                    defer file.close();
                    parser = parserModule.Parser.newParser(file);

                }
            }
        } else {
            print("NO INPUT FOUND!\n", .{});
        }
    }

    const outputFileName = fileName[0..fileName.len-3] ++ ".asm";
    const outputFile = try std.fs.cwd().createFile(outputFileName, .{ .truncate = true });
    defer outputFile.close();

    while (parser.hasMoreCommands()){
        // first advance and if it's at the start it'll read the first command and doesn't increment the counter (although we could change that)
        parser.advance();
        const cmdType = parser.current_command;

        var writer = codeWriterModule.CodeWriter.newCodeWriter(fileName);


        const allocator = std.heap.page_allocator;

        const newLines: []const u8 = undefined;

        //put proper instructions in each one, just not sure how we're implememtning codewriter
        switch (cmdType) {
            // Arithmetic Commands
            .add => {
                newLines = writer.writeAdd();
            },
            .sub => {
                newLines = writer.writeSub();
            },
            .eq => {
                newLines = writer.writeEq(allocator) catch @panic("writeEq failed");
            },
            .gt => {
                newLines = writer.writeGt(allocator);
            },
            .lt => {
                newLines = writer.writeLt(allocator);
            },
            .andCommand => {
                newLines = writer.writeAnd();
            },
            .orCommand => {
                newLines = writer.writeOr();
            },
            // Arithmetic Unary Commands
            .not => {
                newLines = writer.writeNot();
            },
            .neg => {
                newLines = writer.writeNeg();
            },
            // Push
            .push => {
                newLines = writer.writePush(parser.valueType(), parser.argPushPop(), allocator);
            },
            // Pop
            .pop => {
                newLines = writer.writePop(parser.valueType(), parser.argPushPop(), allocator);
            },

            else => {
                print("else.", .{});
            }

        }

        outputFile.write(newLines);
        allocator.free(newLines);

    }

}

