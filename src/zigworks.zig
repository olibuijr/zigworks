//! zigworks: a small, fast web framework in pure Zig, written for AI agents to read and extend.
//!
//!   server.zig  HTTP server (std.http), keep-alive, per-request arena
//!   router.zig  comptime routes: "GET /todos/:id"
//!   ctx.zig     request context: params, query, form, json, headers, responses
//!   view.zig    Svelte-style templates compiled at comptime, auto-escaped
//!   markdown.zig  safe Markdown subset -> HTML; highlight.zig: Zig syntax highlighting
//!   ui/         reusable components, each with its own CSS (macOS HIG defaults)
//!   css.zig     design tokens -> CSS variables
//!   client/     z.js: htmx-style attributes + islands (three.js etc.)
//!   static.zig  public/ directory
const std = @import("std");

pub const version = "0.6.1";

pub const serve = @import("server.zig").serve;
pub const Options = @import("server.zig").Options;
pub const Ctx = @import("ctx.zig").Ctx;
pub const view = @import("view.zig").view;
pub const View = @import("view.zig").View;
pub const each = @import("view.zig").each;
pub const Each = @import("view.zig").Each;
pub const props = @import("view.zig").props;
pub const markdown = @import("markdown.zig").markdown;
pub const markdownWith = @import("markdown.zig").markdownWith;
pub const Markdown = @import("markdown.zig").Markdown;
pub const highlight = @import("highlight.zig").write;
pub const writeEscaped = @import("view.zig").writeEscaped;
pub const render = @import("view.zig").render;
pub const ui = @import("ui.zig");
pub const css = @import("css.zig");
pub const Tokens = css.Tokens;

test {
    _ = @import("view.zig");
    _ = @import("markdown.zig");
    _ = @import("highlight.zig");
    _ = @import("router.zig");
    _ = @import("ctx.zig");
    _ = @import("static.zig");
    _ = @import("css.zig");
    _ = @import("ui.zig");
    _ = @import("server.zig");
}
