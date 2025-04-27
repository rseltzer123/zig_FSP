/// Rachamim Seltzer: 662215912
/// Efrem Mincer: 3246291982
/// Fundamentals of Software Programming Lab 1

const std = @import("std");
const parserModule = @import("parser.zig");
const codeWriterModule = @import("codeWriter.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;

const print = std.debug.print;

pub fn main() !void {

    // Directory input from user taken from Lab 0
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var parser: parserModule.Parser = undefined;
    var parserErrorUnion: anyerror!parserModule.Parser = undefined;

    var inputFileName: []const u8 = undefined;
    var outputFileName: []const u8 = undefined;
    var wFile: std.fs.File = undefined;

    try stdout.print("Enter path: ", .{});

    var isGoodPath = false;
    while (!isGoodPath) {
        var buffer: [1024]u8 = undefined; // moved inside the loop, so fresh every time

        const path = stdin.readUntilDelimiterOrEof(buffer[0..], '\r') catch |err| {
            print("ERROR while reading input: {}\n", .{err});
            return;
        };

        if (path) |value| {
            const path_val = std.mem.trim(u8, value, " \r\n");

            //example is C:\Users\effie\IdeaProjects\zig_FSP\Lab_1\testFiles\07\BasicTest
            var dir = std.fs.openDirAbsolute(path_val,  .{.iterate = true}) catch |err| {
                print("ERROR: {}\n", .{err});
                continue;
            };
            defer dir.close();

            isGoodPath = true;

            // iterate over directory and get file names
            var dir_it = dir.iterate();

            while(try dir_it.next()) |entry| {
                if (entry.kind == DIR_FILE_TYPE and std.mem.endsWith(u8,  entry.name, ".vm")){
                    const file = try std.fs.Dir.openFile(dir, entry.name, .{});
                    defer file.close();

                    parserErrorUnion = parserModule.Parser.newParser(file);
                    if (parserErrorUnion) |val|{
                        parser = val;
                    }
                    else |err| {
                        print("Error: {}\n", .{err});
                        return;
                    }

                    inputFileName = entry.name;
                    outputFileName = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.asm", .{entry.name[0..entry.name.len-3]});
                    wFile = try dir.createFile(outputFileName, .{.read = false, .truncate = true});     //.truncate == if file exists erase it's contents
                }
            }
        } else {
            print("NO INPUT FOUND!\n", .{});
        }
    }
    var writer = codeWriterModule.CodeWriter.newCodeWriter(outputFileName);
    const initBytesWritten = wFile.write(writer.init()) catch |err|{
        print("ERROR while writing initialization: {}\n", .{err});
        return;
    };
    _ = initBytesWritten;
    var lineNum: usize = 13;

    // DEBUGGING: print("Parser self.lines.len: {d}\nParser current index: {d}\n", .{parser.lines.len, parser.current_index});
    while (parser.hasMoreCommands()){
        // first advance and if it's at the start it'll read the first command and doesn't increment the counter (although we could change that)
        parser.advance();
        const cmdType = parser.current_command;

        const allocator = std.heap.page_allocator;

        var newLines: []const u8 = undefined;
        var shouldFree: bool = false;

        //put proper instructions in each one, just not sure how we're implememtning codewriter
        switch (cmdType) {
            // Arithmetic Commands
            .add => {
                newLines = writer.writeAdd();
            },
            .sub => {
                newLines = writer.writeSub();
            },
            //have to add error handling
            .eq => {
                newLines = writer.writeEq(allocator, lineNum) catch @panic("writeEq failed");
                shouldFree = true;
            },
            .gt => {
                newLines = writer.writeGt(allocator, lineNum) catch @panic("writeGt failed");
                shouldFree = true;
            },
            .lt => {
                newLines = writer.writeLt(allocator, lineNum) catch @panic("writeLt failed");
                shouldFree = true;
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
                const arg = parser.argPushPop() catch |err|{
                    print("arg failed, error: {}", .{err});
                    return;
                };
                newLines = writer.writePushPop("push",parser.valueType(), arg, allocator, inputFileName) catch @panic("writePush failed");
                shouldFree = true;
            },
            // Pop
            .pop => {
                const arg = parser.argPushPop() catch |err|{
                    print("arg failed, error: {}", .{err});
                    return;
                };
                newLines = writer.writePushPop("pop",parser.valueType(), arg, allocator, inputFileName) catch @panic("writePop failed");
                shouldFree = true;
            },

            else => {
                print("else.", .{});
            }

        }

        const bytesWritten = wFile.write(newLines) catch |err|{
            print("ERROR: {}\n", .{err});
            return;
        };

        // Count the number of lines
        const lineCount = std.mem.count(u8, newLines, "\n");
        lineNum += lineCount - 1;  // minus 1 for the comment
                                   //
        // DBUGGING: print("Bytes written: {d}\n", .{bytesWritten});
        _ = bytesWritten;

        if (shouldFree){
            allocator.free(newLines);
        }

    }

    print("\nWrote successfully to file.\n", .{});
    wFile.close();

}

