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


pub fn findFilesAndParse(dir: std.fs.Dir, dir_name: []const u8) !struct {
    parser: parserModule.Parser,
    baseName: []const u8,
    outputFile: std.fs.File,
    outputFileName: []const u8,
} {
    const allocator = std.heap.page_allocator;
    var dir_it = dir.iterate();
    var files = std.ArrayList(std.fs.File).init(allocator);

    var baseName: []const u8 = "";
    var outputFileName: []const u8 = "";
    var outputFile: std.fs.File = undefined;


    while (try dir_it.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".vm")) {
            const file = try dir.openFile(entry.name, .{});
            try files.append(file);
        }
        // can only track name when discovering files
        if (files.items.len == 1){
            baseName = try std.heap.page_allocator.dupe(u8, entry.name[0..entry.name.len - 3]);
        }
        // reset name to be directory name
        if (files.items.len == 2){
            baseName = std.fs.path.basename(dir_name);
        }
    }

    if (files.items.len == 0) {
        return error.NoVMFilesFound;
    }

    // Create parser from all .vm files
    const parser = try parserModule.Parser.newParser(files.items);

    outputFileName = try std.fmt.allocPrint(allocator, "{s}.asm", .{baseName});
    outputFile = try dir.createFile(outputFileName, .{ .read = false, .truncate = true });


    // Close all input files after parsing
    for (files.items) |file| {
        file.close();
    }

    return .{
        .parser = parser,
        .outputFile = outputFile,
        .baseName = baseName,
        .outputFileName = outputFileName,
    };
}


/// Generates assembly code based on the command type.
pub fn createNewLines(
    cmdType: parserModule.CommandType,
    writer: *codeWriterModule.CodeWriter,
    allocator: std.mem.Allocator,
    lineNum: usize,
    parser: *parserModule.Parser,
    baseName: []const u8)
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
            return writer.writePushPop("push", parser.valueType(), arg, allocator, baseName) catch @panic("writePush failed");
        },

        // Pop operation
        .pop => {
            const arg = parser.argPushPop() catch |err|{
                print("arg failed, error: {}", .{err});
                return error.WritingPopFailed;
            };
            return writer.writePushPop("pop", parser.valueType(), arg, allocator, baseName) catch @panic("writePop failed");
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

pub fn getDirectoryName(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    // Trim any trailing slashes
    const trimmed = std.mem.trimRight(u8, path, "/");

    // Get the base name (last part of the path)
    const base = std.fs.path.basename(trimmed);

    // Duplicate it to make a heap-allocated copy
    return try allocator.dupe(u8, base);
}
