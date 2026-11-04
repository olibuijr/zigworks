//! Live demos for docs/pages/components/checkbox.md (```demo checkbox``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "checkbox", true, checkbox },
    .{ "checkbox-states", true, states },
    .{ "checkbox-values", true, values },
    .{ "checkbox-select-all", true, selectAllDemo },
    .{ "checkbox-form", true, form },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-checkbox-group{display:flex;flex-direction:column;gap:6px;
    \\  & .zw-btn{align-self:flex-start;margin-top:6px}}
    \\.demo-checkbox-grid{display:grid;grid-template-columns:max-content minmax(0,1fr);align-items:center;gap:6px 16px;
    \\  &>code{white-space:nowrap}}
    \\.demo-checkbox-bar{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:0 12px 8px}
    \\.demo-checkbox-sent{font:var(--callout);color:var(--secondary);margin-top:10px;overflow-wrap:anywhere}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/checkbox/x", handler }`.
pub const routes = .{
    .{ "POST /demo/checkbox/echo", echo },
    .{ "POST /demo/checkbox/rows", rowsChanged },
    .{ "POST /demo/checkbox/all", allChanged },
    .{ "POST /demo/checkbox/order", order },
};

// Hero: a Mail settings pane.
fn checkbox(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Composing", .subtitle = "Mail settings", .body = zw.view("<div class=\"demo-checkbox-group\">{a}{b}{c}{d}</div>", .{
        .a = ui.checkbox(.{ .name = "spell", .label = "Check spelling while typing", .on = true, .z = d.save }),
        .b = ui.checkbox(.{ .name = "grammar", .label = "Check grammar with spelling", .z = d.save }),
        .c = ui.checkbox(.{ .name = "quote", .label = "Include the original message when replying", .description = "Quoted text appears below your reply.", .on = true, .z = d.save }),
        .d = ui.checkbox(.{ .name = "remote", .label = "Load remote content in messages", .description = "Images and links can tell the sender you opened the message.", .z = d.save }),
    }) }).render(w);
}

// States: each prop next to the checkbox it changes.
fn states(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view(
        \\<div class="demo-checkbox-grid">
        \\<code>default</code>{a}
        \\<code>.on = true</code>{b}
        \\<code>.mixed = true</code>{c}
        \\<code>.description</code>{d}
        \\<code>.disabled = true</code>{e}
        \\<code>.disabled, .on</code>{f}
        \\<code>.invalid = true</code>{g}
        \\</div>
    , .{
        .a = ui.checkbox(.{ .name = "s-off", .label = "Show message previews", .z = d.save }),
        .b = ui.checkbox(.{ .name = "s-on", .label = "Show message previews", .on = true, .z = d.save }),
        .c = ui.checkbox(.{ .name = "s-mixed", .label = "Select all", .mixed = true, .description = "2 of 5 selected", .z = d.save }),
        .d = ui.checkbox(.{ .name = "s-desc", .label = "Badge the app icon", .description = "Shows the number of unread messages.", .on = true, .z = d.save }),
        .e = ui.checkbox(.{ .name = "s-disabled", .label = "Sync with iCloud", .description = "Turned off by your administrator.", .disabled = true }),
        .f = ui.checkbox(.{ .name = "s-locked", .label = "Require a password", .description = "Turned on by your administrator.", .on = true, .disabled = true }),
        .g = ui.checkbox(.{ .name = "s-invalid", .label = "I accept the terms of use", .invalid = true, .z = d.save }),
    }) }).render(w);
}

// Values: the form posts on change, the server answers with the raw body it received.
fn values(w: *Writer) Writer.Error!void {
    try zw.view("<form{z}>{card}</form>", .{
        .z = ui.Z{ .post = "/demo/checkbox/echo", .trigger = "change", .target = "#demo-checkbox-sent", .swap = .inner, .keep = true },
        .card = ui.card(.{ .title = "Notify me by", .body = zw.view(
            \\<div class="demo-checkbox-group">{a}{b}{c}{d}</div>
            \\<p class="demo-checkbox-sent">The form sends <code id="demo-checkbox-sent">notify=mail</code></p>
        , .{
            .a = ui.checkbox(.{ .name = "notify", .value = "mail", .label = "Email", .on = true }),
            .b = ui.checkbox(.{ .name = "notify", .value = "sms", .label = "Text message" }),
            .c = ui.checkbox(.{ .name = "notify", .value = "push", .label = "Push notification" }),
            .d = ui.checkbox(.{ .name = "quiet", .label = "Not between 10 pm and 7 am" }),
        }) }),
    }).render(w);
}

fn echo(c: *zw.Ctx) !void {
    try c.html("{#if body}{body}{:else}nothing{/if}", .{ .body = c.body });
}

// Select all: a parent checkbox over a list. The server keeps nothing: every request carries the
// checked rows, and the answer re-renders the parent (or the rows) and the count badge.
const Mail = struct { from: []const u8, subject: []const u8 };
const inbox = [_]Mail{
    .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine" },
    .{ .from = "Grace Hopper", .subject = "Compiler status update" },
    .{ .from = "Alan Turing", .subject = "Re: Halting problem" },
    .{ .from = "Katherine Johnson", .subject = "Trajectory check, 9:30" },
    .{ .from = "Margaret Hamilton", .subject = "Software review notes" },
};
const ids = "01234";
const all_mask: u8 = (1 << inbox.len) - 1;

const Rows = struct {
    mask: u8,
    pub fn render(self: Rows, w: *Writer) Writer.Error!void {
        for (inbox, 0..) |mail, i| {
            const bit: u8 = @as(u8, 1) << @intCast(i);
            try w.writeAll("<li>");
            try ui.checkbox(.{ .name = "m", .value = ids[i .. i + 1], .label = mail.from, .description = mail.subject, .on = self.mask & bit != 0 }).render(w);
            try w.writeAll("</li>");
        }
    }
};

const Head = zw.View("<div id=\"demo-checkbox-all\"{#if oob} z-oob{/if}>{box}</div>", struct { oob: bool, box: ui.Checkbox });

/// The parent checkbox: checked when every row is, mixed when only some are.
fn head(mask: u8, oob: bool) Head {
    const n = @popCount(mask);
    return .{ .data = .{ .oob = oob, .box = ui.checkbox(.{
        .name = "all",
        .label = "Select all",
        .on = n == inbox.len,
        .mixed = n > 0 and n < inbox.len,
        .z = .{ .post = "/demo/checkbox/all", .target = "#demo-checkbox-rows", .swap = .inner },
    }) } };
}

fn count(mask: u8, oob: bool) ui.Badge {
    return ui.badge(.{ .id = "demo-checkbox-count", .count = @as(u32, @popCount(mask)), .hide_zero = true, .tone = .accent, .oob = oob });
}

fn selectAllDemo(w: *Writer) Writer.Error!void {
    const mask: u8 = 0b00101;
    try zw.view("<form{z}><div class=\"demo-checkbox-bar\">{head}{count}</div>{list}</form>", .{
        .z = ui.Z{ .post = "/demo/checkbox/rows", .trigger = "change", .swap = .none, .keep = true },
        .head = head(mask, false),
        .count = count(mask, false),
        .list = ui.list(.{ .id = "demo-checkbox-rows", .body = Rows{ .mask = mask } }),
    }).render(w);
}

/// Bitmask of the rows in a body like `m=0&m=3`.
fn selected(body: []const u8) u8 {
    var mask: u8 = 0;
    var it = std.mem.splitScalar(u8, body, '&');
    while (it.next()) |pair| {
        const k, const v = std.mem.cutScalar(u8, pair, '=') orelse continue;
        if (!std.mem.eql(u8, k, "m")) continue;
        const i = std.fmt.parseInt(u3, v, 10) catch continue;
        if (i < inbox.len) mask |= @as(u8, 1) << i;
    }
    return mask;
}

// A row changed: refresh the parent and the badge, leave the rows alone.
fn rowsChanged(c: *zw.Ctx) !void {
    const mask = selected(c.body);
    try c.html("{head}{count}", .{ .head = head(mask, true), .count = count(mask, true) });
}

// The parent changed: check or clear every row (only the parent's own `all=on` is sent).
fn allChanged(c: *zw.Ctx) !void {
    const mask: u8 = if (c.form("all") != null) all_mask else 0;
    try c.html("{rows}{count}", .{ .rows = Rows{ .mask = mask }, .count = count(mask, true) });
}

// Checkout: a required box. Submitting without it re-renders the form with the box marked invalid.
const Order = struct {
    gift: bool = false,
    news: bool = false,
    terms: bool = false,
    invalid: bool = false,
    pub fn render(self: Order, w: *Writer) Writer.Error!void {
        try zw.view("<form id=\"demo-checkbox-order\" class=\"demo-checkbox-group\"{z}>{gift}{news}{terms}{buy}</form>", .{
            .z = ui.Z{ .post = "/demo/checkbox/order", .swap = .outer },
            .gift = ui.checkbox(.{ .name = "gift", .label = "This order is a gift", .description = "The price stays off the receipt.", .on = self.gift }),
            .news = ui.checkbox(.{ .name = "news", .label = "Email me about new arrivals", .on = self.news }),
            .terms = ui.checkbox(.{ .name = "terms", .label = "I accept the terms of sale", .on = self.terms, .invalid = self.invalid }),
            .buy = ui.button(.{ .label = "Place order", .variant = .primary, .type = .submit }),
        }).render(w);
    }
};

fn form(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Checkout", .subtitle = "2 items, $48.00", .body = Order{} }).render(w);
}

fn order(c: *zw.Ctx) !void {
    const terms = c.form("terms") != null;
    if (terms) return c.html("{form}{toast}", .{
        .form = Order{},
        .toast = ui.toast(.{ .text = "Order placed", .kind = .success }),
    });
    try c.html("{form}{toast}", .{
        .form = Order{ .gift = c.form("gift") != null, .news = c.form("news") != null, .invalid = true },
        .toast = ui.toast(.{ .text = "Accept the terms to place your order", .kind = .@"error" }),
    });
}
