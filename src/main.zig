/// Rachamim Seltzer: 662215912
/// Efrem Mincer: 3246291982
/// Fundamentals of Software Programming Lab 0

const std = @import("std");
const hand = @import("handlers.zig");
const DIR_FILE_TYPE = std.fs.File.Kind.file;

pub fn strEq( a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn handleLine (input: []const u8, seg: ?[]const u8, index: ?[]const u8, counter: *u32) ![]const u8 {
    // make mutable version of split iterator
        if (strEq("add", input)) {
            return hand.handle_add();
        } else if (strEq("sub", input)){
            return hand.handle_sub();
        } else if (strEq("neg", input)){
            return hand.handle_neg();
        } else if (strEq("eq", input)) {
            return hand.handle_eq(counter, std.heap.page_allocator);
        } else if (strEq("gt", input)){
            return hand.handle_gt(counter, std.heap.page_allocator);
        } else if (strEq("lt", input)) {
            return hand.handle_lt(counter, std.heap.page_allocator);
        } else if (strEq("pop", input)) {
            if (seg) | seg_v |
                if (index) | index_v | {
                    const res = try hand.handle_pop(std.heap.page_allocator, seg_v, index_v);
                    return res;
                };
        } else if (strEq("push", input)){
            if (seg) |seg_v|
                if (index) |index_v| {
                    const res = try hand.handle_push(std.heap.page_allocator, seg_v, index_v);
                    return res;
                };
        } else {
            return error.NO_CASE_FOUND;
        }
    return error.NO_INPUT;
}

fn getOutputFileName(path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "{s}.asm", .{std.fs.path.basename(path)}) catch | err | {
        return err;
    };
    return res;
}

fn runFileInputs(file: std.fs.File, comptime WriterType: type, writer: WriterType) !void {
    var buffer: [1028]u8 = undefined;
    const reader = file.reader();
    var i: u64 = 0;
    var line = try reader.readUntilDelimiterOrEof(buffer[0..], '\n');
    var line_val = line.?;
    var counter: u32 = 1;
    while (line_val.len != 0) {

        var lineSplitIt = std.mem.splitScalar(u8, line_val, ' ');

        const res = lineSplitIt.next();
        if (res == null) continue;

        const defRes = res.?; // definitely has a value here
        var printVal : []const u8 = undefined;

        if (strEq(defRes, "pop") or strEq(defRes, "push")) {
            const seg = lineSplitIt.next() orelse "";
            const index = lineSplitIt.next() orelse "";
            printVal = try handleLine(defRes, seg, index, &counter);
        } else {
            printVal = try handleLine(defRes, "", "", &counter);
        }

        const bytes = try writer.print("command: {?s}\n", .{printVal});
        _ = bytes;

        line = try reader.readUntilDelimiterOrEof(buffer[0..], '\n');
        line_val = line.?;
        i += 1;
    }
}

const print = std.debug.print;

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var buffer : [1028]u8 = undefined;
    print("Please write a valid file path: \n", .{});
    var isGoodPath = false;
    while (!isGoodPath) {
        // get path from the user
        const path =  try stdin.readUntilDelimiterOrEof(buffer[0..], '\n');

        // convert path from ?[]u8 to []const u8
        if (path) |value| {
            const path_val: []const u8 = value;

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
                    runFileInputs(file, @TypeOf(wFile.writer()), wFile.writer()) catch | err | {
                        print("{}", .{err});
                    };
                }
            }
        } else {
            print("NO INPUT FOUND!\n", .{});
        }
    }
}

