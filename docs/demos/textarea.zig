//! Live demos for docs/pages/components/textarea.md (```demo textarea``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "textarea", true, textarea },
    .{ "textarea-sizes", true, sizes },
    .{ "textarea-states", true, states },
    .{ "textarea-autosave", true, autosave },
    .{ "textarea-comments", true, comments },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-textarea-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,240px),1fr));gap:20px 16px}
    \\.demo-textarea-cap{font:var(--callout);color:var(--secondary);margin:0 0 6px}
    \\.demo-textarea-actions{display:flex;justify-content:flex-end;gap:8px}
    \\.zw-list>.demo-textarea-comment{align-items:flex-start;
    \\  & p{margin:0}
    \\  & small{font:var(--callout);color:var(--secondary);margin-left:6px}}
    \\.demo-textarea-text{white-space:pre-wrap;overflow-wrap:anywhere}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/textarea/x", handler }`.
pub const routes = .{
    .{ "POST /demo/textarea/feedback", feedbackPost },
    .{ "POST /demo/textarea/autosave", autosavePost },
    .{ "POST /demo/textarea/comment", commentPost },
};

// Hero: a Send Feedback card. The server validates and answers with a fresh form
// (replacing the old one) plus a toast, so nothing is stored.
const Feedback = zw.View(
    \\<form id="demo-textarea-feedback" class="zw-stack"{z}>{ta}<div class="demo-textarea-actions">{send}</div></form>
, struct { z: ui.Z, ta: ui.Textarea, send: ui.Button });

fn feedbackForm(error_text: []const u8) Feedback {
    return .{ .data = .{
        .z = .{ .post = "/demo/textarea/feedback", .target = "#demo-textarea-feedback", .swap = .outer },
        .ta = ui.textarea(.{
            .name = "demo-textarea-feedback-text",
            .label = "Feedback",
            .placeholder = "What happened? What did you expect?",
            .rows = 4,
            .max_rows = 8,
            .maxlength = 280,
            .help = "Don't include passwords or personal data.",
            .invalid = error_text,
        }),
        .send = ui.button(.{ .label = "Send", .variant = .primary, .type = .submit }),
    } };
}

fn feedbackPost(c: *zw.Ctx) !void {
    const text = std.mem.trim(u8, c.form("demo-textarea-feedback-text") orelse "", " \t\r\n");
    if (text.len == 0) return c.page(feedbackForm("Write a few words first."));
    try c.html("{form}{toast}", .{
        .form = feedbackForm(""),
        .toast = ui.toast(.{ .text = "Thanks, your feedback was sent", .kind = .success }),
    });
}

fn textarea(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Send Feedback",
        .subtitle = "Tell us what went wrong. Try sending it empty.",
        .body = feedbackForm(""),
    }).render(w);
}

// Sizes: auto-grow with a cap, fixed height, drag handle, and a one-line start.
fn sizes(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-textarea-grid">
        \\<div><p class="demo-textarea-cap"><code>grow</code> (default) up to <code>max_rows = 4</code>, then it scrolls</p>{a}</div>
        \\<div><p class="demo-textarea-cap"><code>grow = false</code>, <code>rows = 4</code>: fixed height</p>{b}</div>
        \\<div><p class="demo-textarea-cap"><code>grow = false</code>, <code>resize = .vertical</code>: drag the corner</p>{c}</div>
        \\<div><p class="demo-textarea-cap"><code>rows = 1</code>: starts as one line, like a message box</p>{e}</div>
        \\</div>
    , .{
        .a = ui.textarea(.{
            .name = "demo-textarea-grow",
            .label = "Notes that grow",
            .rows = 2,
            .max_rows = 4,
            .value =
            \\Buy oat milk
            \\Renew the passport
            \\Book a table for Friday
            \\Call the plumber
            \\Water the plants
            \\Back up the laptop
            ,
        }),
        .b = ui.textarea(.{ .name = "demo-textarea-fixed", .label = "Fixed notes", .placeholder = "Always four lines tall", .rows = 4, .grow = false }),
        .c = ui.textarea(.{ .name = "demo-textarea-resize", .label = "Resizable notes", .placeholder = "Drag the handle to resize", .rows = 3, .grow = false, .resize = .vertical }),
        .e = ui.textarea(.{ .name = "demo-textarea-compact", .label = "Message", .placeholder = "iMessage", .rows = 1, .max_rows = 5 }),
    }).render(w);
}

// States: every message and flag the component supports.
fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-textarea-grid">
        \\<div><p class="demo-textarea-cap">Empty, with a <code>placeholder</code></p>{a}</div>
        \\<div><p class="demo-textarea-cap"><code>help</code> and <code>required</code></p>{b}</div>
        \\<div><p class="demo-textarea-cap"><code>maxlength = 80</code>: type to watch the counter</p>{c}</div>
        \\<div><p class="demo-textarea-cap">At the limit: the counter turns red</p>{e}</div>
        \\<div><p class="demo-textarea-cap"><code>invalid</code>: red, announced as an alert</p>{f}</div>
        \\<div><p class="demo-textarea-cap"><code>disabled</code>: dimmed, not submitted</p>{g}</div>
        \\<div><p class="demo-textarea-cap"><code>readonly</code>: focusable, not editable</p>{h}</div>
        \\</div>
    , .{
        .a = ui.textarea(.{ .name = "demo-textarea-empty", .label = "Comment", .placeholder = "Add a comment" }),
        .b = ui.textarea(.{ .name = "demo-textarea-help", .label = "Reason", .placeholder = "Why do you need access?", .required = true, .help = "Your manager sees this." }),
        .c = ui.textarea(.{ .name = "demo-textarea-counter", .label = "Bio", .value = "Mathematician and first programmer.", .maxlength = 80, .rows = 2 }),
        .e = ui.textarea(.{ .name = "demo-textarea-full", .label = "Tagline", .value = "Exactly twenty chars", .maxlength = 20, .rows = 2 }),
        .f = ui.textarea(.{ .name = "demo-textarea-invalid", .label = "Reason", .rows = 2, .required = true, .invalid = "Add a reason before you send." }),
        .g = ui.textarea(.{ .name = "demo-textarea-disabled", .label = "Notes", .value = "Locked while the document syncs.", .rows = 2, .disabled = true }),
        .h = ui.textarea(.{ .name = "demo-textarea-readonly", .label = "Shared note", .value = "Shared by Ada Lovelace. Only the owner can edit.", .rows = 2, .readonly = true }),
    }).render(w);
}

// Autosave: every pause in typing posts the text; the server answers with the badge, which
// replaces the one in the header (out of band). Nothing is stored.
fn autosave(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="zw-row"><strong class="zw-grow">Meeting notes</strong>{status}</div>{ta}
    , .{
        .status = ui.badge(.{ .id = "demo-textarea-status", .text = "Not edited yet", .size = .small }),
        .ta = ui.textarea(.{
            .name = "demo-textarea-notes",
            .label = "Meeting notes",
            .placeholder = "Start typing. Your notes are saved as you go.",
            .rows = 4,
            .max_rows = 10,
            .maxlength = 500,
            .z = .{ .post = "/demo/textarea/autosave", .trigger = "input", .swap = .none },
        }),
    }).render(w);
}

fn autosavePost(c: *zw.Ctx) !void {
    var words: usize = 0;
    var it = std.mem.tokenizeAny(u8, c.form("demo-textarea-notes") orelse "", " \t\r\n");
    while (it.next()) |_| words += 1;
    const text = try std.fmt.allocPrint(c.arena, "Saved · {d} {s}", .{ words, if (words == 1) "word" else "words" });
    try c.page(ui.badge(.{ .id = "demo-textarea-status", .oob = true, .text = text, .tone = .green, .size = .small }));
}

// Comments: a list, a composer, and an avatar per row. A post adds one row and swaps in a
// fresh composer (so the counter starts at 0 again).
const Comment = zw.View(
    \\<li class="demo-textarea-comment">{avatar}<div class="zw-grow"><p><strong>{name}</strong><small>{when}</small></p><p class="demo-textarea-text">{text}</p></div></li>
, struct { avatar: ui.Avatar, name: []const u8, when: []const u8, text: []const u8 });

fn comment(name: []const u8, when: []const u8, text: []const u8) Comment {
    return .{ .data = .{ .avatar = ui.avatar(.{ .name = name, .size = 28 }), .name = name, .when = when, .text = text } };
}

const Composer = zw.View(
    \\<form id="demo-textarea-composer" class="zw-stack"{#if oob} z-oob{/if}{z}>{ta}<div class="demo-textarea-actions">{post}</div></form>
, struct { oob: bool, z: ui.Z, ta: ui.Textarea, post: ui.Button });

fn composer(oob: bool, error_text: []const u8) Composer {
    return .{ .data = .{
        .oob = oob,
        .z = .{ .post = "/demo/textarea/comment", .target = "#demo-textarea-comments", .swap = .beforeend },
        .ta = ui.textarea(.{
            .name = "demo-textarea-comment",
            .label = "Comment",
            .placeholder = "Add a comment",
            .rows = 2,
            .max_rows = 6,
            .maxlength = 280,
            .invalid = error_text,
        }),
        .post = ui.button(.{ .label = "Post", .variant = .primary, .type = .submit }),
    } };
}

fn commentPost(c: *zw.Ctx) !void {
    const text = std.mem.trim(u8, c.form("demo-textarea-comment") orelse "", " \t\r\n");
    if (text.len == 0) return c.page(composer(true, "Write a comment first."));
    try c.html("{row}{composer}", .{ .row = comment("You", "just now", text), .composer = composer(true, "") });
}

fn comments(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-textarea-comments",
        .header = "Comments",
        .empty = "No comments yet",
        .body = zw.view("{a}{b}", .{
            .a = comment("Ada Lovelace", "2h ago", "The notes read well. Can we add a diagram?"),
            .b = comment("Grace Hopper", "1h ago", "Added one to the second section."),
        }),
    }).render(w);
    try composer(false, "").render(w);
}
