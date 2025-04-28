/// Rachamim Seltzer: 662215912
/// Efrem Mincer: 3246291982
/// Fundamentals of Software Programming Lab 1

const std = @import("std");
const parserModule = @import("parser.zig");
const codeWriterModule = @import("codeWriter.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;

const print = std.debug.print;

/// Main entry point for the VM Translator.
/// Asks the user for a directory path, parses `.vm` files, translates VM commands to Hack assembly,
/// and writes the output to `.asm` files with the same name as the input files.
pub fn main() !void {

    // Setup input and output streams
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var parser: parserModule.Parser = undefined;
    var parserErrorUnion: anyerror!parserModule.Parser = undefined;

    var inputFileName: []const u8 = undefined;
    var outputFileName: []const u8 = undefined;
    var wFile: std.fs.File = undefined;

    // Prompt the user for a directory path
    try stdout.print("Enter path: ", .{});

    var isGoodPath = false;
    while (!isGoodPath) {
        var buffer: [1024]u8 = undefined; // fresh buffer for each input attempt

        // Read user input
        const path = stdin.readUntilDelimiterOrEof(buffer[0..], '\r') catch |err| {
            print("ERROR while reading input: {}\n", .{err});
            return;
        };

        if (path) |value| {
            const path_val = std.mem.trim(u8, value, " \r\n");

            // Try to open the provided directory
            var dir = std.fs.openDirAbsolute(path_val,  .{.iterate = true}) catch |err| {
                print("ERROR: {}\n", .{err});
                continue;
            };
            defer dir.close();

            isGoodPath = true;

            // Iterate over the files in the directory
            var dir_it = dir.iterate();

            while(try dir_it.next()) |entry| {
                // Only process files that are .vm files
                if (entry.kind == DIR_FILE_TYPE and std.mem.endsWith(u8,  entry.name, ".vm")){
                    const file = try std.fs.Dir.openFile(dir, entry.name, .{});
                    defer file.close();

                    // Attempt to create a parser for the .vm file
                    parserErrorUnion = parserModule.Parser.newParser(file);
                    if (parserErrorUnion) |val|{
                        parser = val;
                    }
                    else |err| {
                        print("Error: {}\n", .{err});
                        return;
                    }

                    inputFileName = entry.name;
                    // Generate the output filename by replacing `.vm` with `.asm`
                    outputFileName = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.asm", .{entry.name[0..entry.name.len-3]});

                    // Create a new (empty) output file, overwriting if it already exists
                    wFile = try dir.createFile(outputFileName, .{.read = false, .truncate = true});
                }
            }
        } else {
            print("NO INPUT FOUND!\n", .{});
        }
    }

    // Initialize a CodeWriter to generate assembly code
    var writer = codeWriterModule.CodeWriter.newCodeWriter(outputFileName);

    // Write the initial bootstrap code (if necessary)
    const initBytesWritten = wFile.write(writer.init()) catch |err|{
        print("ERROR while writing initialization: {}\n", .{err});
        return;
    };
    _ = initBytesWritten; // Ignore the actual number of bytes written

    var lineNum: usize = 13; // Line number used for label generation (especially for comparisons)

    // Process each command in the input file
    while (parser.hasMoreCommands()){
        parser.advance(); // Advance to the next command

        const cmdType = parser.current_command;
        const allocator = std.heap.page_allocator;

        var newLines: []const u8 = undefined; // Assembly instructions for the current command
        var shouldFree: bool = false;         // Whether we should free the allocated memory later

        // Determine which code generation function to call based on the command type
        switch (cmdType) {
        // Arithmetic Binary Operations
            .add => {
            newLines = writer.writeAdd();
        },
            .sub => {
                newLines = writer.writeSub();
            },
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

            // Arithmetic Unary Operations
            .not => {
                newLines = writer.writeNot();
            },
            .neg => {
                newLines = writer.writeNeg();
            },

            // Push operation
            .push => {
                const arg = parser.argPushPop() catch |err|{
                    print("arg failed, error: {}", .{err});
                    return;
                };
                newLines = writer.writePushPop("push", parser.valueType(), arg, allocator, inputFileName) catch @panic("writePush failed");
                shouldFree = true;
            },

            // Pop operation
            .pop => {
                const arg = parser.argPushPop() catch |err|{
                    print("arg failed, error: {}", .{err});
                    return;
                };
                newLines = writer.writePushPop("pop", parser.valueType(), arg, allocator, inputFileName) catch @panic("writePop failed");
                shouldFree = true;
            },

            else => {
                print("Unsupported command type encountered.\n", .{});
            }
        }

        // Write generated assembly code to the output file
        const bytesWritten = wFile.write(newLines) catch |err|{
            print("ERROR: {}\n", .{err});
            return;
        };
        _ = bytesWritten; // Ignore the actual number of bytes written

        // Update line counter based on how many assembly lines were generated
        const lineCount = std.mem.count(u8, newLines, "\n");
        lineNum += lineCount - 1;  // subtract 1 because one "line" might just be a comment or blank

        // Free dynamically allocated memory if needed
        if (shouldFree){
            allocator.free(newLines);
        }
    }

    // Success message
    print("\nWrote successfully to file.\n", .{});
    wFile.close(); // Explicitly close the output file
}
