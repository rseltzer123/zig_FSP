const std = @import("std");
const parserModule = @import("parser.zig");
const codeWriterModule = @import("codeWriter.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;
const print = std.debug.print;

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

pub fn multiFileFindAndParse(dir: std.fs.Dir) !struct {file: std.fs.File, parser: parserModule.Parser, inputFileName: []const u8, outputFileName: []const u8,} {
    _ = dir;
    return .{
        // .file = outFile,
        // .parser = parser,
        // .inputFileName = inputFileName,
        // .outputFileName = outputFileName,
    };
}

pub fn findFileAndParse(dir: std.fs.Dir) !struct {file: std.fs.File, parser: parserModule.Parser, inputFileName: []const u8, outputFileName: []const u8,} {
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

/// Generates assembly code based on the command type.
pub fn createNewLines(
    cmdType: parserModule.CommandType,
    writer: *codeWriterModule.CodeWriter,
    allocator: std.mem.Allocator,
    lineNum: usize,
    parser: *parserModule.Parser,
    inputFileName: []const u8)
![] const u8 {

    // Determine which code generation function to call based on the command type
    switch (cmdType) {
    // Arithmetic Binary Operations
        .add => {
        return writer.writeAdd();
    },
        .sub => {
            return writer.writeSub();
        },
        .eq => {
            return writer.writeEq(allocator, lineNum) catch @panic("writeEq failed");
        },
        .gt => {
            return writer.writeGt(allocator, lineNum) catch @panic("writeGt failed");
        },
        .lt => {
            return writer.writeLt(allocator, lineNum) catch @panic("writeLt failed");
        },
        .andCommand => {
            return writer.writeAnd();
        },
        .orCommand => {
            return writer.writeOr();
        },

        // Arithmetic Unary Operations
        .not => {
            return writer.writeNot();
        },
        .neg => {
            return writer.writeNeg();
        },

        // Push operation
        .push => {
            const arg = parser.argPushPop() catch |err|{
                print("arg failed, error: {}", .{err});
                return error.WritingPushFailed;
            };
            return writer.writePushPop("push", parser.valueType(), arg, allocator, inputFileName) catch @panic("writePush failed");
        },

        // Pop operation
        .pop => {
            const arg = parser.argPushPop() catch |err|{
                print("arg failed, error: {}", .{err});
                return error.WritingPopFailed;
            };
            return writer.writePushPop("pop", parser.valueType(), arg, allocator, inputFileName) catch @panic("writePop failed");
        },

        .subNum2 => {
            return writer.writeSubNum2();
        },

        else => {
            print("Unsupported command type encountered.\n", .{});
            return error.UnsupportedCommand;
        }
    }
}
