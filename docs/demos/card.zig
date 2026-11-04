//! Live demos for docs/pages/components/card.md (```demo card``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "card", true, card },
    .{ "card-variants", true, variants },
    .{ "card-states", true, states },
    .{ "card-links", true, links },
    .{ "card-plans", true, plansDemo },
    .{ "card-reminders", true, reminders },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-card-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,230px),1fr));gap:16px;align-items:start}
    \\.demo-card-case{display:flex;flex-direction:column;gap:6px;min-width:0}
    \\.demo-card-cap{font:var(--footnote);color:var(--secondary)}
    \\.demo-card-note{font:var(--callout);color:var(--secondary)}
    \\.demo-card-meta{flex:none;font:var(--callout);color:var(--secondary)}
    \\.demo-card-price{font:var(--title2);font-weight:600;
    \\  & span{font:var(--callout);color:var(--secondary)}}
    \\.demo-card-plan{border-radius:var(--radius);transition:outline-color var(--speed);outline:2px solid transparent;
    \\  &.is-on{outline-color:var(--accent)}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/card/x", handler }`.
pub const routes = .{
    .{ "GET /demo/card/plan", planPick },
    .{ "GET /demo/card/activity", activityLoad },
    .{ "POST /demo/card/add", reminderAdd },
    .{ "POST /demo/card/toggle", reminderToggle },
    .{ "DELETE /demo/card/trash", reminderTrash },
    .{ "POST /demo/card/restore", reminderRestore },
};

/// Opens a labelled grid cell; the caller closes it with `</div>`.
fn open(w: *Writer, caption: []const u8) Writer.Error!void {
    try w.print("<div class=\"demo-card-case\"><p class=\"demo-card-cap\">{s}</p>", .{caption});
}

// Hero: a Settings pane.
fn card(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .id = "demo-card-storage",
        .title = "Storage",
        .subtitle = "Macintosh HD",
        .accessory = ui.button(.{ .label = "Manage…", .variant = .plain, .z = d.save }),
        .footer = "Updated just now",
        .body = ui.progress(.{ .value = 64, .label = "Storage used", .text = "41.2 GB of 64 GB used", .show_value = true }),
    }).render(w);
    try ui.card(.{
        .title = "Software Update",
        .subtitle = "Version 2.4 is available",
        .accessory = ui.badge(.{ .text = "1 update", .tone = .accent }),
        .body = "Improves security and battery life. Installing takes about ten minutes.",
        .footer = zw.view("{a}{b}", .{
            .a = ui.button(.{ .label = "Later", .z = d.save }),
            .b = ui.button(.{ .label = "Update Now", .variant = .primary, .z = d.save }),
        }),
    }).render(w);
}

fn variants(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-card-grid\">");
    try open(w, "<code>.variant = .elevated</code> (default)");
    try ui.card(.{ .title = "Elevated", .subtitle = "Opaque with a soft shadow", .body = "The default surface for page content.", .footer = "A footer caption" }).render(w);
    try w.writeAll("</div>");
    try open(w, "<code>.variant = .inset</code>");
    try ui.card(.{ .variant = .inset, .title = "Inset", .subtitle = "Grouped fill, no shadow", .body = "For a card inside another card, or on a plain window.", .footer = "A footer caption" }).render(w);
    try w.writeAll("</div>");
    try open(w, "<code>.variant = .plain</code>");
    try ui.card(.{ .variant = .plain, .title = "Plain", .subtitle = "No surface", .body = "Keeps the heading and footer layout, nothing else.", .footer = "A footer caption" }).render(w);
    try w.writeAll("</div></div>");

    try open(w, "<code>.inset</code> cards nested in an <code>.elevated</code> one");
    try ui.card(.{
        .title = "Time Machine",
        .subtitle = "Backs up every hour",
        .accessory = ui.badge(.{ .text = "On", .tone = .green }),
        .body = zw.view("<div class=\"zw-stack\">{a}{b}</div>", .{
            .a = ui.card(.{ .variant = .inset, .title = "Last backup", .body = "Today at 9:41 AM" }),
            .b = ui.card(.{ .variant = .inset, .title = "Next backup", .body = "Today at 10:41 AM" }),
        }),
    }).render(w);
    try w.writeAll("</div>");
}

// Loading, empty, error, invalid and disabled content, and a card that loads itself.
fn states(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-card-grid\">");
    try open(w, "Loading: a skeleton body and a spinner accessory");
    try ui.card(.{
        .title = "Photos",
        .subtitle = "Syncing with iCloud",
        .accessory = ui.progress(.{ .value = null, .label = "Syncing", .size = .small }),
        .body = ui.skeleton(.{ .shape = .media, .lines = 2, .size = 36, .label = "Loading photos" }),
    }).render(w);
    try w.writeAll("</div>");

    try open(w, "Empty: an empty state as the body");
    try ui.card(.{
        .title = "Reminders",
        .body = ui.empty(.{
            .icon = "✓",
            .title = "No Reminders",
            .text = "Reminders you add show up here.",
            .size = .compact,
            .action = ui.button(.{ .label = "New Reminder", .variant = .primary, .z = d.save }),
        }),
    }).render(w);
    try w.writeAll("</div>");

    try open(w, "Error: a callout, a red badge and a retry");
    try ui.card(.{
        .title = "Backup failed",
        .subtitle = "Time Machine",
        .accessory = ui.badge(.{ .text = "Error", .tone = .red }),
        .body = ui.callout(.{ .kind = .caution, .compact = true, .body = "The backup disk is full. Free up space or choose another disk." }),
        .footer = zw.view("{a}{b}", .{
            .a = ui.button(.{ .label = "Choose Disk…", .z = d.save }),
            .b = ui.button(.{ .label = "Try Again", .variant = .primary, .z = d.save }),
        }),
    }).render(w);
    try w.writeAll("</div>");

    try open(w, "Invalid: a field error and a disabled action");
    try ui.card(.{
        .title = "Account",
        .body = ui.field(.{ .name = "demo-card-email", .label = "Email", .type = "email", .value = "ada@example", .invalid = "Enter a complete address, like ada@example.com." }),
        .footer = ui.button(.{ .label = "Save", .variant = .primary, .disabled = true }),
    }).render(w);
    try w.writeAll("</div>");

    try open(w, "Disabled: controls dimmed, with the reason in the footer");
    try ui.card(.{
        .title = "Sync",
        .subtitle = "Managed by your administrator",
        .body = ui.toggle(.{ .name = "demo-card-sync", .label = "Sync with iCloud", .description = "Documents and Desktop", .on = true, .disabled = true }),
        .footer = "Contact your administrator to change this.",
    }).render(w);
    try w.writeAll("</div>");

    try open(w, "Lazy: <code>.z</code> with <code>.trigger = \"load\"</code> fetches the content");
    try (Activity{ .loading = true }).render(w);
    try w.writeAll("</div></div>");
}

/// The card from the "Lazy" case: a skeleton that asks the server for its content, then the content.
/// Reload swaps the skeleton back in, which loads again.
const Activity = struct {
    loading: bool,

    pub fn render(self: Activity, w: *Writer) Writer.Error!void {
        if (self.loading) {
            try ui.card(.{
                .id = "demo-card-activity",
                .title = "Recent Activity",
                .subtitle = "Loading…",
                .z = ui.Z{ .get = "/demo/card/activity", .trigger = "load", .swap = .outer },
                .body = ui.skeleton(.{ .shape = .media, .lines = 2, .size = 36, .label = "Loading activity" }),
            }).render(w);
        } else {
            try ui.card(.{
                .id = "demo-card-activity",
                .title = "Recent Activity",
                .subtitle = "Updated just now",
                .footer = ui.button(.{ .label = "Reload", .variant = .plain, .z = .{ .get = "/demo/card/activity?loading=1", .target = "#demo-card-activity", .swap = .outer } }),
                .body = ui.list(.{ .id = "demo-card-events", .inset = false, .separators = .full, .body = zw.view(
                    "<li>{a}<span class=\"zw-grow\">Ada Lovelace edited Notes</span><span class=\"demo-card-meta\">2m</span></li>" ++
                        "<li>{b}<span class=\"zw-grow\">Grace Hopper shared a folder</span><span class=\"demo-card-meta\">1h</span></li>",
                    .{
                        .a = ui.avatar(.{ .name = "Ada Lovelace", .size = 28 }),
                        .b = ui.avatar(.{ .name = "Grace Hopper", .size = 28 }),
                    },
                ) }),
            }).render(w);
        }
    }
};

fn activityLoad(c: *zw.Ctx) !void {
    try c.page(Activity{ .loading = c.query("loading") != null });
}

fn links(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-card-grid\">");
    try ui.card(.{ .href = "/components/list", .title = "List", .subtitle = "Inset rows", .body = "Rows, separators and navigation." }).render(w);
    try ui.card(.{ .href = "/components/setting", .variant = .inset, .title = "Setting", .subtitle = "A row with a control", .body = "Labels, descriptions and trailing controls." }).render(w);
    try ui.card(.{
        .href = "/components/progress",
        .title = "Progress",
        .subtitle = "Bars, rings and spinners",
        .accessory = ui.badge(.{ .text = "New", .tone = .accent }),
        .body = "Show how far a task has come.",
        .footer = "A footer is a caption here",
    }).render(w);
    try w.writeAll("</div>");
}

// Selecting a plan: every card is re-rendered by the server, the chosen one is marked.
const Plan = struct { id: []const u8, name: []const u8, label: []const u8, price: []const u8, blurb: []const u8, url: []const u8 };

const plans = [_]Plan{
    .{ .id = "free", .name = "Free", .label = "Starter", .price = "$0", .blurb = "5 GB of storage", .url = "/demo/card/plan?p=free" },
    .{ .id = "plus", .name = "Plus", .label = "Popular", .price = "$2.99", .blurb = "200 GB of storage", .url = "/demo/card/plan?p=plus" },
    .{ .id = "pro", .name = "Pro", .label = "Best value", .price = "$9.99", .blurb = "2 TB and family sharing", .url = "/demo/card/plan?p=pro" },
};

const Plans = struct {
    current: []const u8,

    pub fn render(self: Plans, w: *Writer) Writer.Error!void {
        for (plans) |p| {
            const on = std.mem.eql(u8, p.id, self.current);
            try w.print("<div class=\"demo-card-plan{s}\">", .{if (on) " is-on" else ""});
            try ui.card(.{
                .title = p.name,
                .subtitle = p.blurb,
                .accessory = ui.badge(.{ .text = if (on) "Current plan" else p.label, .tone = if (on) .accent else .gray, .solid = on }),
                .body = zw.view("<p class=\"demo-card-price\">{price} <span>per month</span></p>", .{ .price = p.price }),
                .footer = ui.button(.{
                    .label = if (on) "Selected" else "Choose",
                    .variant = if (on) .primary else .secondary,
                    .disabled = on,
                    .z = .{ .get = p.url, .target = "#demo-card-plans", .swap = .inner },
                }),
            }).render(w);
            try w.writeAll("</div>");
        }
    }
};

fn plansDemo(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-card-grid\" id=\"demo-card-plans\">");
    try (Plans{ .current = "plus" }).render(w);
    try w.writeAll("</div>");
}

fn planPick(c: *zw.Ctx) !void {
    const id = c.query("p") orelse "plus";
    for (plans) |p| {
        if (!std.mem.eql(u8, p.id, id)) continue;
        return c.page(zw.view("{a}{b}", .{
            .a = Plans{ .current = p.id },
            .b = ui.toast(.{ .text = try std.fmt.allocPrint(c.arena, "Switched to {s}", .{p.name}), .kind = .success }),
        }));
    }
    try c.send(.no_content, "text/plain", "");
}

// A flush card around a list, with an add form in the footer.
const Row = zw.View(
    \\<li>{check}<span class="zw-grow{#if done} is-done{/if}">{title}</span>{del}</li>
, struct { check: ui.Check, title: []const u8, done: bool, del: ui.Button });

fn row(arena: std.mem.Allocator, title: []const u8, done: bool) !Row {
    const t = std.fmt.alt(std.Uri.Component{ .raw = title }, .formatEscaped);
    return .{ .data = .{
        .check = ui.check(.{ .on = done, .label = title, .z = .{
            .post = try std.fmt.allocPrint(arena, "/demo/card/toggle?d={d}&t={f}", .{ @intFromBool(done), t }),
            .target = "closest li",
            .swap = .outer,
        } }),
        .title = title,
        .done = done,
        .del = ui.button(.{ .label = "Delete", .variant = .destructive, .size = .small, .z = .{
            .delete = try std.fmt.allocPrint(arena, "/demo/card/trash?t={f}", .{t}),
            .target = "closest li",
            .swap = .delete,
        } }),
    } };
}

fn reminders(w: *Writer) Writer.Error!void {
    var buf: [4096]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const a = fba.allocator();
    try ui.card(.{
        .id = "demo-card-reminders",
        .title = "Reminders",
        .subtitle = "Today",
        .flush = true,
        .body = ui.list(.{
            .id = "demo-card-list",
            .empty = "All done. Add a reminder below.",
            .reveal = true,
            .body = zw.view("{a}{b}{c}", .{
                .a = row(a, "Buy oat milk", true) catch unreachable,
                .b = row(a, "Renew passport", false) catch unreachable,
                .c = row(a, "Book the dentist", false) catch unreachable,
            }),
        }),
        .footer = zw.view("<form class=\"zw-row zw-grow\"{z}>{f}{b}</form>", .{
            .z = ui.Z{ .post = "/demo/card/add", .target = "#demo-card-list", .swap = .beforeend },
            .f = ui.field(.{ .name = "title", .label = "New reminder", .placeholder = "New reminder", .required = true, .maxlength = 80 }),
            .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
        }),
    }).render(w);
}

fn reminderAdd(c: *zw.Ctx) !void {
    const title = std.mem.trim(u8, c.form("title") orelse "", " ");
    if (title.len == 0 or title.len > 80) return c.send(.no_content, "text/plain", "");
    try c.page(try row(c.arena, title, false));
}

fn reminderToggle(c: *zw.Ctx) !void {
    const title = c.query("t") orelse return c.send(.bad_request, "text/plain", "missing t");
    const done = std.mem.eql(u8, c.query("d") orelse "0", "1");
    try c.page(try row(c.arena, title, !done));
}

/// The row leaves through z-swap=delete; the toast in the response offers Undo.
fn reminderTrash(c: *zw.Ctx) !void {
    const title = c.query("t") orelse "";
    const undo = try std.fmt.allocPrint(c.arena, "/demo/card/restore?t={f}", .{std.fmt.alt(std.Uri.Component{ .raw = title }, .formatEscaped)});
    try c.page(ui.toast(.{
        .text = "Reminder deleted",
        .action = "Undo",
        .z = .{ .post = undo, .target = "#demo-card-list", .swap = .beforeend },
    }));
}

fn reminderRestore(c: *zw.Ctx) !void {
    const title = c.query("t") orelse return c.send(.bad_request, "text/plain", "missing t");
    try c.page(try row(c.arena, title, false));
}
