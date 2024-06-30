const std = @import("std");
const net = std.net;
const fs = std.fs;
const mem = std.mem;
const expect = std.testing.expect;
const fileHandler = @import("file.zig");
const constantHandler = @import("constants.zig");
const errorHandler = @import("errors.zig");

/// Generates a 404 NOT FOUND HTTP response.
/// Returns the response as a byte slice.
pub fn http404() []const u8 {
    return "HTTP/1.1 404 NOT FOUND \r\n" ++
        "Connection: close\r\n" ++
        "Content-Type: text/html; charset=utf8\r\n" ++
        "Content-Length: 9\r\n" ++
        "\r\n" ++
        "NOT FOUND";
}

/// Represents an HTTP header.
pub const HTTPHeader = struct {
    requestLine: []const u8,
    host: []const u8,
    userAgent: []const u8,

    /// Prints the request line and host of the HTTP header.
    pub fn print(self: HTTPHeader) void {
        std.debug.print("{s} - {s}\n", .{
            self.requestLine,
            self.host,
        });
    }
};

/// Parses the request line of an HTTP request and returns the path.
/// If the request line is malformed or the HTTP method is not supported, an error is returned.
pub fn parsePath(requestLine: []const u8) ![]const u8 {
    var requestLineIter = mem.tokenizeScalar(u8, requestLine, ' ');
    const method = requestLineIter.next().?;
    if (!mem.eql(u8, method, "GET")) return errorHandler.ServeFileError.MethodNotSupported;
    const path = requestLineIter.next().?;
    if (path.len <= 0) return error.NoPath;
    const proto = requestLineIter.next().?;
    if (!mem.eql(u8, proto, "HTTP/1.1")) return errorHandler.ServeFileError.ProtoNotSupported;
    if (mem.eql(u8, path, "/")) {
        return "/index.html";
    }
    return path;
}

/// Parses the header of an HTTP request and returns a structured representation.
/// If the header is malformed, an error is returned.
pub fn parseHeader(header: []const u8) !HTTPHeader {
    var headerStruct = HTTPHeader{
        .requestLine = undefined,
        .host = undefined,
        .userAgent = undefined,
    };
    var headerIter = mem.tokenizeSequence(u8, header, "\r\n");
    headerStruct.requestLine = headerIter.next() orelse return errorHandler.ServeFileError.HeaderMalformed;
    while (headerIter.next()) |line| {
        const nameSlice = mem.sliceTo(line, ':');
        if (nameSlice.len == line.len) return errorHandler.ServeFileError.HeaderMalformed;
        const headerName = std.meta.stringToEnum(constantHandler.HeaderNames, nameSlice) orelse continue;
        const headerValue = mem.trimLeft(u8, line[nameSlice.len + 1 ..], " ");
        switch (headerName) {
            .Host => headerStruct.host = headerValue,
            .@"User-Agent" => headerStruct.userAgent = headerValue,
        }
    }
    return headerStruct;
}
