//! Serves files from the public directory at their path: public/scene.js -> /scene.js.
//! Covers JS modules, wasm and 3D assets (three.js: .glb, .gltf, .hdr, .ktx2).
const std = @import("std");
const Io = std.Io;
const Ctx = @import("ctx.zig").Ctx;
const decode = @import("ctx.zig").decode;

pub const max_file = 64 << 20;

/// Sends the file for `c.path` if it exists. Returns false when there is no such file.
pub fn serve(c: *Ctx, dir: Io.Dir) !bool {
    if (c.method != .GET and c.method != .HEAD) return false;
    const rel = safePath(try decode(c.arena, c.path)) orelse return false;
    // ponytail: whole file in memory per request; stream with respondStreaming if assets get large.
    const data = dir.readFileAlloc(c.io, rel, c.arena, .limited(max_file)) catch |err| switch (err) {
        error.FileNotFound, error.IsDir, error.NotDir => return false,
        else => return err,
    };
    try c.setHeader("cache-control", "no-cache");
    try c.send(.ok, mime(rel), data);
    return true;
}

/// Strips the leading '/' and rejects traversal, hidden files and empty segments.
fn safePath(path: []const u8) ?[]const u8 {
    if (path.len < 2 or path[0] != '/') return null;
    const rel = path[1..];
    var it = std.mem.splitScalar(u8, rel, '/');
    while (it.next()) |seg| {
        if (seg.len == 0 or seg[0] == '.' or std.mem.findScalar(u8, seg, '\\') != null or std.mem.findScalar(u8, seg, 0) != null) return null;
    }
    return rel;
}

pub fn mime(path: []const u8) []const u8 {
    const ext = std.fs.path.extension(path);
    const table = [_]struct { []const u8, []const u8 }{
        .{ ".html", "text/html; charset=utf-8" },  .{ ".css", "text/css; charset=utf-8" },
        .{ ".js", "text/javascript; charset=utf-8" }, .{ ".mjs", "text/javascript; charset=utf-8" },
        .{ ".json", "application/json" },           .{ ".map", "application/json" },
        .{ ".wasm", "application/wasm" },           .{ ".svg", "image/svg+xml" },
        .{ ".png", "image/png" },                   .{ ".jpg", "image/jpeg" },
        .{ ".jpeg", "image/jpeg" },                 .{ ".gif", "image/gif" },
        .{ ".webp", "image/webp" },                 .{ ".avif", "image/avif" },
        .{ ".ico", "image/x-icon" },                .{ ".glb", "model/gltf-binary" },
        .{ ".gltf", "model/gltf+json" },            .{ ".hdr", "image/vnd.radiance" },
        .{ ".ktx2", "image/ktx2" },                 .{ ".woff2", "font/woff2" },
        .{ ".txt", "text/plain; charset=utf-8" },   .{ ".mp4", "video/mp4" },
        .{ ".webm", "video/webm" },                 .{ ".mp3", "audio/mpeg" },
        .{ ".ogg", "audio/ogg" },                   .{ ".wav", "audio/wav" },
    };
    for (table) |e| if (std.ascii.eqlIgnoreCase(ext, e[0])) return e[1];
    return "application/octet-stream";
}

test safePath {
    try std.testing.expectEqualStrings("a/b.js", safePath("/a/b.js").?);
    try std.testing.expect(safePath("/../etc/passwd") == null);
    try std.testing.expect(safePath("/a/../../x") == null);
    try std.testing.expect(safePath("/.env") == null);
    try std.testing.expect(safePath("/a//b") == null);
    try std.testing.expect(safePath("/") == null);
    try std.testing.expect(safePath("/a\\..\\b") == null);
}

test mime {
    try std.testing.expectEqualStrings("model/gltf-binary", mime("m/duck.GLB"));
    try std.testing.expectEqualStrings("text/javascript; charset=utf-8", mime("three.module.js"));
}
