const std = @import("std");

pub fn handle_add() []const u8 {
    return "add";
}

pub fn handle_sub() []const u8 {
    return "sub";
}
pub fn handle_neg() []const u8 {
    return "neg";
}
pub fn handle_eq(counter: *u32, allocator: std.mem.Allocator) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "eq \ncounter: {d}", .{counter.*}) catch | err | {
      return err;
    };
    counter.* +=  1;
    return res;
}

pub fn handle_gt(counter: *u32, allocator: std.mem.Allocator) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "gt \ncounter: {d}", .{counter.*}) catch | err | {
        return err;
    };
    counter.* += 1;
    return res;
}

pub fn handle_lt(counter: *u32, allocator: std.mem.Allocator) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "lt \ncounter: {d}", .{counter.*}) catch | err | {
        return err;
    };
    counter.* +=  1;
    return res;
}

pub fn handle_push(allocator: std.mem.Allocator, segment: []const u8, index: []const u8 ) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "push segment: {s} index: {s}", .{segment, index}) catch |err| {
        return err;
    };
    return res;
}

pub fn handle_pop(allocator: std.mem.Allocator, segment: []const u8, index: []const u8 ) ![]const u8 {
    const res = std.fmt.allocPrint(allocator, "push segment: {s} index: {s}", .{segment, index}) catch |err| {
        return err;
    };
    return res;
}