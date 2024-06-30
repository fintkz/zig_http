# Simple HTTP Server in Zig

This project implements a basic HTTP server in Zig. It listens for incoming connections, handles HTTP requests, and serves local files.

## Features

- Listens on a specified IP address and port
- Handles incoming HTTP connections
- Parses HTTP headers
- Serves local files with appropriate MIME types
- Provides 404 responses for files not found

## Prerequisites

- Zig compiler (latest version recommended)

## Project Structure

The project consists of the following main components:

- `main.zig`: The entry point of the program, containing the server logic
- `file.zig`: Handles file operations and MIME type determination
- `http.zig`: Contains HTTP-related functionality like header parsing

## Usage

1. Clone the repository:
   ```
   git clone https://github.com/fintkz/zig_http.git
   cd zig_http
   ```

2. Build the project:
   ```
   zig build
   ```

3. Run the server:
   ```
   ./zig-out/bin/simple-http-server
   ```

By default, the server listens on `0.0.0.0:1111`. You can modify this in the `main.zig` file if needed.

## Configuration

To change the listening address or port, modify the following line in `main.zig`:

```zig
const self_addr = try net.Address.resolveIp("0.0.0.0", 1111);
```

