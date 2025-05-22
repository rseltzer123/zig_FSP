const std = @import("std");
const parserModule = @import("parser.zig");
const codeWriterModule = @import("codeWriter.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;
const print = std.debug.print;

pub fn readAndCleanUserInput() ![]const u8 {
    const allocator = std.heap.page_allocator;
    const stdin = std.io.getStdIn().reader();

    var buffer: [1024]u8 = undefined;
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

    const trimmed = std.mem.trim(u8, buffer[0..i], " \r\n");
    return try allocator.dupe(u8, trimmed); //  makes a heap copy
}



pub fn findFilesAndParse(dir: std.fs.Dir, dir_name: []const u8) !struct {
    parser: parserModule.Parser,
    baseName: []const u8,
    outputFile: std.fs.File,
    outputFileName: []const u8,
    numFiles: i32,
} {
    var numFiles : i32 = 0;
    const allocator = std.heap.page_allocator;
    var dir_it = dir.iterate();
    var files = std.ArrayList(std.fs.File).init(allocator);

    var baseName: []const u8 = "";
    var outputFileName: []const u8 = "";
    var outputFile: std.fs.File = undefined;

    var fileNames  = std.ArrayList([]const u8).init(allocator);
    defer fileNames.deinit();

    while (try dir_it.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".vm")) {
            numFiles += 1;
            const file = try dir.openFile(entry.name, .{});
            try files.append(file);

            const nameDupe = try std.heap.page_allocator.dupe(u8, entry.name[0..entry.name.len - 3]);
            try fileNames.append(nameDupe);

            // can only track name when discovering files
            if (files.items.len == 1){
                baseName = try std.heap.page_allocator.dupe(u8, entry.name[0..entry.name.len - 3]);
                }
            // reset name to be directory name
            if (files.items.len == 2){
                baseName = std.fs.path.basename(dir_name);
                }
        }
    }

    if (files.items.len == 0) {
        return error.NoVMFilesFound;
    }

    // Create parser from all .vm files
    const parser = try parserModule.Parser.newParser(files.items, fileNames.items);


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
        .numFiles = numFiles
    };
}


/// Generates assembly code based on the command type.
pub fn createNewLines(
    cmdType: parserModule.CommandType,
    writer: *codeWriterModule.CodeWriter,
    allocator: std.mem.Allocator,
    parser: *parserModule.Parser,
    // baseName: []const u8,
    vmCounter: *i32)
![] const u8 {

    vmCounter.* += 1;

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
            return writer.writeEq(allocator, vmCounter.*) catch @panic("writeEq failed");
        },
        .gt => {
            return writer.writeGt(allocator, vmCounter.*) catch @panic("writeGt failed");
        },
        .lt => {
            return writer.writeLt(allocator, vmCounter.*) catch @panic("writeLt failed");
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
            const currLine = parser.getCurrentLine();
            const input: []const u8 = currLine[2];
            const arg_value = try std.fmt.parseInt(i32, input, 10);
            return writer.writePushPop("push", currLine[1], arg_value, allocator, currLine[3]) catch @panic("writePush failed");
        },

        // Pop operation
        .pop => {
            const currLine = parser.getCurrentLine();
            const input: []const u8 = currLine[2];
            const arg_value = try std.fmt.parseInt(i32, input, 10);
            return writer.writePushPop("pop", currLine[1], arg_value, allocator, currLine[3]) catch @panic("writePop failed");
        },

        // custom subNum2 for lab 1
        .subNum2 => {
            return writer.writeSubNum2();
        },

        // Branching
        .label => {
            const currLine = parser.getCurrentLine();
            return writer.writeBranchLabel(currLine[1], allocator);
        },
        .goto => {
            const currLine = parser.getCurrentLine();
            return writer.writeBranchGoto(currLine[1], allocator);
        },
        .ifGoto => {
            const currLine = parser.getCurrentLine();
            return writer.writeBranchIfGoto(currLine[1], allocator);
        },
        .function => {
            const currLine = parser.getCurrentLine();
            const input: []const u8 = currLine[2];
            const arg_value = try std.fmt.parseInt(i32, input, 10);
            return writer.writeFunction(currLine[1], arg_value, allocator);
        },
        .call => {
            const currLine = parser.getCurrentLine();
            const input: []const u8 = currLine[2];
            const arg_value = try std.fmt.parseInt(i32, input, 10);
            return writer.writeCall(currLine[1], arg_value, allocator);
        },
        .returnCommand => {
            return writer.writeReturn(allocator);
        },
        // Error handling
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
