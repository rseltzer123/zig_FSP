/// Rachamim Seltzer: 662215912
/// Efrem Mincer: 3246291982
/// Fundamentals of Software Programming Lab 1

const std = @import("std");
const parserModule = @import("parser.zig");
const codeWriterModule = @import("codeWriter.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;

const print = std.debug.print;

/// Reads user input and trims it.
pub fn readAndCleanUserInput() ![]const u8 {
    const stdin = std.io.getStdIn().reader();

    var buffer: [1024]u8 = undefined; // fresh buffer for each input attempt

    var i: usize = 0;

    while (i < buffer.len) {
        const byte = stdin.readByte() catch |err| {
            std.debug.print("ERROR while reading input: {}\n", .{err});
            return error.InvalidInput;
        };

        if (byte == '\n' or byte == '\r') {
            break;
        }

        buffer[i] = byte;
        i += 1;
    }

    const path = buffer[0..i];

    return std.mem.trim(u8, path, " \r\n");
}

/// Scans the given directory for a `.vm` file, parses it, and prepares the output `.asm` file.
pub fn findFileAndParse(dir: std.fs.Dir) !struct {
    file: std.fs.File,
    parser: parserModule.Parser,
    inputFileName: []const u8,
    outputFileName: []const u8,
} {
    var dir_it = dir.iterate();

    while (try dir_it.next()) |entry| {
        if (entry.kind == DIR_FILE_TYPE and std.mem.endsWith(u8, entry.name, ".vm")) {
            const file = try std.fs.Dir.openFile(dir, entry.name, .{});

            // Create parser
            const parser = parserModule.Parser.newParser(file) catch |err| {
                std.debug.print("Error while constructing parser: {}\n", .{err});
                return error.ErrorConstructingParser;
            };

            // Input name without `.vm`
            const inputFileName = try std.heap.page_allocator.dupe(u8, entry.name[0..entry.name.len - 3]);

            // Output file name (e.g., Foo.asm)
            const outputFileName = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.asm", .{inputFileName});

            // Create the output file
            const outFile = try dir.createFile(outputFileName, .{ .read = false, .truncate = true });

            // closing the input file as we've gathered all its information
            file.close();

            return .{
                .file = outFile,
                .parser = parser,
                .inputFileName = inputFileName,
                .outputFileName = outputFileName,
            };
        }
    }

    return error.NoVMFilesFound;
}

/// Main entry point for the VM Translator.
/// Asks the user for a directory path, parses `.vm` files, translates VM commands to Hack assembly,
/// and writes the output to `.asm` files with the same name as the input files.
pub fn main() !void {

    // Setup input and output streams
    const stdout = std.io.getStdOut().writer();

    // Prompt the user for a directory path
    try stdout.print("Enter path: ", .{});

    // Read user input
    const path_val = readAndCleanUserInput() catch |err|{
        print("arg failed, error: {}", .{err});
        return;
    };

    // Try to open the provided directory
    var dir = std.fs.openDirAbsolute(path_val,  .{.iterate = true}) catch |err| {
        print("ERROR: {}\n", .{err});
        return error.InvalidDirectory;
    };
    defer dir.close();

    // finds vm file, creates parser and parses the file, creates output file
    const parsingResult = findFileAndParse(dir) catch |err| {
        print("ERROR: {}\n", .{err});
        return;
    };

    // distributing the tuple of return values to their respective variables
    var parser = parsingResult.parser;
    const wFile = parsingResult.file;
    const inputFileName = parsingResult.inputFileName;
    const outputFileName = parsingResult.outputFileName;

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
        const allocator = std.heap.page_allocator;       //move before loop

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
            .subNum2 => {
                newLines = writer.writeSubNum2();
            },

            else => {
                print("Unsupported command type encountered.\n", .{});
                return error.UnsupportedCommand;
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
