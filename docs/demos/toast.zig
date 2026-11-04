//! Live demos for docs/pages/components/toast.md (```demo toast``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "toast", true, hero },
    .{ "toast-kinds", true, kinds },
    .{ "toast-options", true, options },
    .{ "toast-invite", true, invite },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-toast-name{overflow-wrap:anywhere}
    \\.demo-toast-size{color:var(--secondary);font:var(--callout);white-space:nowrap}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/toast/x", handler }`.
pub const routes = .{
    .{ "POST /demo/toast/trash", trash },
    .{ "POST /demo/toast/restore", restore },
    .{ "POST /demo/toast/show", show },
    .{ "POST /demo/toast/invite", inviteSend },
};

// Hero: a Downloads list. Trashing a row answers with an Undo toast; Undo brings the row back.
// The file is the index into `files`, so the URLs carry all the state.
const File = struct { name: []const u8, size: []const u8 };
const files = [_]File{
    .{ .name = "Invoice-2026.pdf", .size = "212 KB" },
    .{ .name = "Holiday.heic", .size = "4.1 MB" },
    .{ .name = "Release-notes.md", .size = "6 KB" },
    .{ .name = "Backup.zip", .size = "38 MB" },
};

const FileRow = zw.View(
    \\<li><span class="zw-grow demo-toast-name">{name}</span><small class="demo-toast-size">{size}</small>{trash}</li>
, struct { name: []const u8, size: []const u8, trash: ui.Button });

fn fileRow(a: std.mem.Allocator, i: usize) !FileRow {
    return .{ .data = .{
        .name = files[i].name,
        .size = files[i].size,
        .trash = ui.button(.{
            .label = "Trash",
            .aria = try std.fmt.allocPrint(a, "Move {s} to the Trash", .{files[i].name}),
            .variant = .destructive,
            .size = .small,
            .z = .{ .post = try std.fmt.allocPrint(a, "/demo/toast/trash?i={d}", .{i}), .target = "closest li", .swap = .delete },
        }),
    } };
}

fn fileIndex(c: *zw.Ctx) ?usize {
    const i = std.fmt.parseInt(usize, c.query("i") orelse "", 10) catch return null;
    return if (i < files.len) i else null;
}

fn hero(w: *Writer) Writer.Error!void {
    var buf: [1024]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const a = fba.allocator();
    try ui.list(.{
        .id = "demo-toast-files",
        .header = "Downloads",
        .footer = "Move a file to the Trash, then press Undo in the toast.",
        .empty = "Downloads is empty.",
        .body = zw.view("{a}{b}{c}{d}", .{
            .a = fileRow(a, 0) catch unreachable,
            .b = fileRow(a, 1) catch unreachable,
            .c = fileRow(a, 2) catch unreachable,
            .d = fileRow(a, 3) catch unreachable,
        }),
    }).render(w);
}

/// The response removes the row (`swap = .delete`) and carries the toast next to it.
fn trash(c: *zw.Ctx) !void {
    const i = fileIndex(c) orelse return c.send(.bad_request, "text/plain", "bad file");
    try c.page(ui.toast(.{
        .text = try std.fmt.allocPrint(c.arena, "Moved “{s}” to the Trash", .{files[i].name}),
        .action = "Undo",
        .z = .{ .post = try std.fmt.allocPrint(c.arena, "/demo/toast/restore?i={d}", .{i}), .target = "#demo-toast-files", .swap = .beforeend },
    }));
}

/// The row goes back into the list; the toast confirms. z.js closes the Undo toast by itself.
fn restore(c: *zw.Ctx) !void {
    const i = fileIndex(c) orelse return c.send(.bad_request, "text/plain", "bad file");
    try c.html("{row}{toast}", .{
        .row = try fileRow(c.arena, i),
        .toast = ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Restored “{s}”", .{files[i].name}), .kind = .success }),
    });
}

// Kinds and options: every button asks /demo/toast/show for one toast. The toast is an
// out-of-band append, so the buttons swap nothing.
fn showButton(comptime k: []const u8) ui.Button {
    return ui.button(.{ .label = "Show", .size = .small, .z = .{ .post = "/demo/toast/show?k=" ++ k, .swap = .none } });
}

fn kinds(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Kinds", .subtitle = "The kind sets the icon and its color.", .body = zw.view("{a}{b}{c}{d}", .{
        .a = ui.setting(.{ .label = "Info", .description = ".kind = .info (the default)", .control = showButton("info") }),
        .b = ui.setting(.{ .label = "Success", .description = ".kind = .success", .control = showButton("success") }),
        .c = ui.setting(.{ .label = "Warning", .description = ".kind = .warning", .control = showButton("warning") }),
        .d = ui.setting(.{ .label = "Error", .description = ".kind = .@\"error\", announced at once", .control = showButton("error") }),
    }) }).render(w);
}

fn options(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Options", .subtitle = "The toasts appear at the top of the window.", .body = zw.view("{a}{b}{c}{d}", .{
        .a = ui.setting(.{ .label = "Action", .description = ".action = \"Retry\" and .z", .control = showButton("failed") }),
        .b = ui.setting(.{ .label = "Sticky", .description = ".sticky = true: stays until dismissed", .control = showButton("sticky") }),
        .c = ui.setting(.{ .label = "Long text", .description = "Wraps instead of growing wider than the window", .control = showButton("long") }),
        .d = ui.setting(.{ .label = "Several at once", .description = "Toasts stack, newest at the bottom", .control = showButton("many") }),
    }) }).render(w);
}

fn show(c: *zw.Ctx) !void {
    const k = c.query("k") orelse "";
    const eql = std.mem.eql;
    if (eql(u8, k, "info")) return c.page(ui.toast(.{ .text = "A software update is available" }));
    if (eql(u8, k, "success")) return c.page(ui.toast(.{ .text = "Message sent", .kind = .success }));
    if (eql(u8, k, "warning")) return c.page(ui.toast(.{ .text = "Storage is almost full", .kind = .warning }));
    if (eql(u8, k, "error")) return c.page(ui.toast(.{ .text = "Couldn't connect to the server", .kind = .@"error" }));
    // The Retry button asks for the next toast; z.js closes this one when the action is pressed.
    if (eql(u8, k, "failed")) return c.page(ui.toast(.{
        .text = "Upload failed",
        .kind = .@"error",
        .action = "Retry",
        .z = .{ .post = "/demo/toast/show?k=uploaded", .swap = .none },
    }));
    if (eql(u8, k, "uploaded")) return c.page(ui.toast(.{ .text = "Upload complete", .kind = .success }));
    if (eql(u8, k, "sticky")) return c.page(ui.toast(.{
        .text = "You are offline. Changes will sync when you reconnect.",
        .kind = .warning,
        .sticky = true,
    }));
    if (eql(u8, k, "long")) return c.page(ui.toast(.{
        .text = "Couldn't move “Quarterly planning notes with the long title.pages” because the destination volume is read-only",
        .kind = .@"error",
    }));
    if (eql(u8, k, "many")) return c.html("{a}{b}{c}", .{
        .a = ui.toast(.{ .text = "Copying 3 items" }),
        .b = ui.toast(.{ .text = "2 items copied", .kind = .success }),
        .c = ui.toast(.{ .text = "1 item skipped: already exists", .kind = .warning }),
    });
    try c.send(.bad_request, "text/plain", "unknown toast");
}

// Composition: a form, a list, a badge and a toast. A good address adds a row and a success
// toast; a bad one answers with an error toast only, so the list stays as it is.
const InviteRow = zw.View(
    \\<li><span class="zw-grow demo-toast-name">{email}</span>{badge}</li>
, struct { email: []const u8, badge: ui.Badge });

fn inviteRow(email: []const u8) InviteRow {
    return .{ .data = .{ .email = email, .badge = ui.badge(.{ .text = "Invited", .tone = .green }) } };
}

fn invite(w: *Writer) Writer.Error!void {
    try zw.view("<form class=\"zw-row\"{z}>{field}{send}</form>{list}", .{
        .z = ui.Z{ .post = "/demo/toast/invite", .target = "#demo-toast-invited", .swap = .beforeend },
        .field = ui.field(.{ .name = "email", .label = "Invite by email", .placeholder = "name@example.com", .inputmode = "email" }),
        .send = ui.button(.{ .label = "Send Invite", .variant = .primary, .type = .submit }),
        .list = ui.list(.{
            .id = "demo-toast-invited",
            .header = "People with access",
            .empty = "Nobody has been invited yet.",
            .body = inviteRow("ada@example.com"),
        }),
    }).render(w);
}

fn inviteSend(c: *zw.Ctx) !void {
    const email = std.mem.trim(u8, c.form("email") orelse "", " ");
    const at = std.mem.find(u8, email, "@");
    const ok = email.len <= 80 and at != null and at.? > 0 and std.mem.findScalar(u8, email[at.? + 1 ..], '.') != null;
    if (!ok) {
        const msg: []const u8 = if (email.len == 0) "Enter an email address" else try std.fmt.allocPrint(c.arena, "“{s}” isn't a valid email address", .{email});
        return c.page(ui.toast(.{ .text = msg, .kind = .@"error" }));
    }
    try c.html("{row}{toast}", .{
        .row = inviteRow(email),
        .toast = ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Invitation sent to {s}", .{email}), .kind = .success }),
    });
}
