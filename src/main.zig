const std = @import("std");
const net = std.net;
const fs = std.fs;
const mem = std.mem;
const expect = std.testing.expect;

const fileHandler = @import("file.zig");

const httpHandler = @import("http.zig");

/// This function is the entry point of the program.
/// It starts a server, listens for incoming connections,
/// and handles HTTP requests by sending appropriate responses.
pub fn main() !void {
    std.debug.print("Starting server\n", .{});

    // Resolve the IP address and port to listen on
    const self_addr = try net.Address.resolveIp("0.0.0.0", 1111);

    // Create a listener socket using the resolved address
    var listener = try self_addr.listen(.{ .reuse_address = true });

    std.debug.print("Listening on {}\n", .{self_addr});

    // Accept incoming connections and handle them
    while (listener.accept()) |conn| {
        std.debug.print("Accepted connection from: {}\n", .{conn.address});

        // Read the request header from the connection
        var recv_buf: [4096]u8 = undefined;
        var recv_total: usize = 0;
        while (conn.stream.read(recv_buf[recv_total..])) |recv_len| {
            if (recv_len == 0) break;
            recv_total += recv_len;

            // Check if the header has been fully received
            if (mem.containsAtLeast(u8, recv_buf[0..recv_total], 1, "\r\n\r\n")) {
                break;
            }
        } else |read_err| {
            return read_err;
        }

        const recv_data = recv_buf[0..recv_total];

        // If no header is received, continue to the next connection
        if (recv_data.len == 0) {
            std.debug.print("Got connection but no header!\n", .{});
            continue;
        }

        // Parse the request header and extract the path
        const header = try httpHandler.parseHeader(recv_data);
        const path = try httpHandler.parsePath(header.requestLine);

        // Determine the MIME type of the requested file
        const mime = fileHandler.mimeForPath(path);

        // Open the local file corresponding to the path
        const buf = fileHandler.openLocalFile(path) catch |err| {
            if (err == error.FileNotFound) {
                // If the file is not found, send a 404 response
                _ = try conn.stream.writer().write(httpHandler.http404());
                continue;
            } else {
                return err;
            }
        };

        std.debug.print("SENDING----\n", .{});

        // Send the HTTP response header and the file contents
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
