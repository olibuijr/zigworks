//! Shared by the per-component demo files in this folder.
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");

/// Fence name, block layout, render function.
pub const Demo = struct { []const u8, bool, *const fn (*Writer) Writer.Error!void };

/// For demo controls that save: POST /demo logs the body and answers 204.
pub const save: zw.ui.Z = .{ .post = "/demo", .swap = .none };
