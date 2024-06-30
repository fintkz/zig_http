const std = @import("std");
const net = std.net;
const fs = std.fs;
const mem = std.mem;
const expect = std.testing.expect;

const fileHandler = @import("file.zig");

const httpHandler = @import("http.zig");

pub fn main() !void {
    std.debug.print("Starting server\n", .{});
    const self_addr = try net.Address.resolveIp("0.0.0.0", 4206);
    var listener = try self_addr.listen(.{ .reuse_address = true });
    std.debug.print("Listening on {}\n", .{self_addr});

    while (listener.accept()) |conn| {
        std.debug.print("Accepted connection from: {}\n", .{conn.address});
        var recv_buf: [4096]u8 = undefined;
        var recv_total: usize = 0;
        while (conn.stream.read(recv_buf[recv_total..])) |recv_len| {
            if (recv_len == 0) break;
            recv_total += recv_len;
            if (mem.containsAtLeast(u8, recv_buf[0..recv_total], 1, "\r\n\r\n")) {
                break;
            }
        } else |read_err| {
            return read_err;
        }
        const recv_data = recv_buf[0..recv_total];
        if (recv_data.len == 0) {
            // Browsers (or firefox?) attempt to optimize for speed
            // by opening a connection to the server once a user highlights
            // a link, but doesn't start sending the request until it's
            // clicked. The request eventually times out so we just
            // go again
            std.debug.print("Got connection but no header!\n", .{});
            continue;
        }
        const header = try httpHandler.parseHeader(recv_data);
        const path = try httpHandler.parsePath(header.requestLine);
        const mime = fileHandler.mimeForPath(path);
        const buf = fileHandler.openLocalFile(path) catch |err| {
            if (err == error.FileNotFound) {
                _ = try conn.stream.writer().write(httpHandler.http404());
                continue;
            } else {
                return err;
            }
        };
        std.debug.print("SENDING----\n", .{});
        const httpHead =
            "HTTP/1.1 200 OK \r\n" ++
            "Connection: close\r\n" ++
            "Content-Type: {s}\r\n" ++
            "Content-Length: {}\r\n" ++
            "\r\n";
        _ = try conn.stream.writer().print(httpHead, .{ mime, buf.len });
        _ = try conn.stream.writer().write(buf);
    } else |err| {
        std.debug.print("error in accept: {}\n", .{err});
    }
}
