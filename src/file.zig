const std = @import("std");
const net = std.net;
const fs = std.fs;
const mem = std.mem;
const expect = std.testing.expect;

const constantHandler = @import("constants.zig");

/// Opens a local file and returns its contents as a byte array.
/// If the file is not found, it returns an error.
pub fn openLocalFile(path: []const u8) ![]u8 {
    const localPath = path[1..];
    const file = fs.cwd().openFile(localPath, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("File not found: {s}\n", .{localPath});
            return error.FileNotFound;
        },
        else => return err,
    };
    defer file.close();
    std.debug.print("file: {}\n", .{file});
    const memory = std.heap.page_allocator;
    const maxSize = std.math.maxInt(usize);
    return try file.readToEndAlloc(memory, maxSize);
}

/// Returns the MIME type for a given file path.
/// If the MIME type is not found, it returns "application/octet-stream".
pub fn mimeForPath(path: []const u8) []const u8 {
    const extension = std.fs.path.extension(path);
    inline for (constantHandler.mimeTypes) |kv| {
        if (mem.eql(u8, extension, kv[0])) {
            return kv[1];
        }
    }
    return "application/octet-stream";
}
