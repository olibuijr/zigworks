//! Live demos for docs/pages/components/radio.md (```demo radio``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "radio", true, radio },
    .{ "radio-layout", true, layout },
    .{ "radio-states", true, states },
    .{ "radio-checkout", true, checkout },
    .{ "radio-export", true, export_ },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-radio-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,230px),1fr));gap:24px 28px}
    \\.demo-radio-cap{font:var(--callout);color:var(--secondary);margin-bottom:6px}
    \\.demo-radio-sum{display:grid;gap:4px;margin-top:14px;padding-top:12px;border-top:1px solid var(--separator)}
    \\.demo-radio-sum div{display:flex;justify-content:space-between;gap:12px}
    \\.demo-radio-sum dt{color:var(--secondary)}
    \\.demo-radio-sum dd{margin:0;font-variant-numeric:tabular-nums}
    \\.demo-radio-sum .demo-radio-total{font-weight:600}
    \\.demo-radio-sum .demo-radio-total dt{color:var(--label)}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/radio/x", handler }`.
pub const routes = .{
    .{ "POST /demo/radio/open", openPick },
    .{ "POST /demo/radio/sync", syncToggle },
    .{ "POST /demo/radio/ship", shipPick },
    .{ "POST /demo/radio/export", exportFile },
};

// Hero: a Finder settings pane. Picking an option updates the badge in the card header (oob).

const open_badge = "demo-radio-open-badge";

fn openLabel(value: []const u8) ?[]const u8 {
    const choices = [_][2][]const u8{ .{ "recents", "Recents" }, .{ "home", "Home folder" }, .{ "desktop", "Desktop" } };
    for (choices) |c| if (std.mem.eql(u8, c[0], value)) return c[1];
    return null;
}

fn openPick(c: *zw.Ctx) !void {
    const label = openLabel(c.form("demo-radio-open") orelse "") orelse return c.send(.bad_request, "text/plain", "unknown choice");
    try c.page(ui.badge(.{ .id = open_badge, .oob = true, .text = label, .tone = .accent }));
}

fn radio(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Finder",
        .subtitle = "New windows open with",
        .accessory = ui.badge(.{ .id = open_badge, .text = "Recents", .tone = .accent }),
        .footer = "Applies to Finder windows you open from now on.",
        .body = ui.radio(.{
            .name = "demo-radio-open",
            .label = "New Finder windows open with",
            .z = .{ .post = "/demo/radio/open", .swap = .none },
            .options = &.{
                .{ .value = "recents", .label = "Recents", .selected = true },
                .{ .value = "home", .label = "Home folder", .description = "Your user folder" },
                .{ .value = "desktop", .label = "Desktop", .description = "The folder shown behind your windows" },
                .{ .value = "icloud", .label = "iCloud Drive", .description = "Sign in to iCloud to choose this", .disabled = true },
            },
        }),
    }).render(w);
}

// Layout: every combination of `layout` and `description`.

fn layout(w: *Writer) Writer.Error!void {
    const sort = [_]ui.RadioOption{
        .{ .value = "name", .label = "Name", .selected = true },
        .{ .value = "kind", .label = "Kind" },
        .{ .value = "date", .label = "Date Modified" },
    };
    const plan = [_]ui.RadioOption{
        .{ .value = "free", .label = "Free", .description = "1 project", .selected = true },
        .{ .value = "team", .label = "Team", .description = "Unlimited projects" },
        .{ .value = "ent", .label = "Enterprise", .description = "Single sign-on" },
    };
    try zw.view(
        \\<div class="demo-radio-grid">
        \\<div><p class="demo-radio-cap"><code>.vertical</code> (default)</p>{a}</div>
        \\<div><p class="demo-radio-cap"><code>.horizontal</code></p>{b}</div>
        \\<div><p class="demo-radio-cap"><code>.vertical</code> + <code>description</code></p>{c}</div>
        \\<div><p class="demo-radio-cap"><code>.horizontal</code> + <code>description</code></p>{e}</div>
        \\</div>
    , .{
        .a = ui.radio(.{ .name = "demo-radio-lay-a", .label = "Sort by", .z = d.save, .options = &sort }),
        .b = ui.radio(.{ .name = "demo-radio-lay-b", .label = "Group by", .layout = .horizontal, .z = d.save, .options = &sort }),
        .c = ui.radio(.{ .name = "demo-radio-lay-c", .label = "Plan", .z = d.save, .options = &plan }),
        .e = ui.radio(.{ .name = "demo-radio-lay-d", .label = "Plan, in a row", .layout = .horizontal, .z = d.save, .options = &plan }),
    }).render(w);
}

// States: a disabled option, a disabled group, nothing selected, a required group with an error, long labels, and a group a switch turns on.

/// The group the switch enables: served at first as disabled, then again by /demo/radio/sync.
fn syncGroup(disabled: bool) ui.Radio {
    return ui.radio(.{
        .name = "demo-radio-sync-every",
        .label = "Sync every",
        .disabled = disabled,
        .z = d.save,
        .options = &.{
            .{ .value = "15", .label = "15 minutes" },
            .{ .value = "60", .label = "Hour", .selected = true },
            .{ .value = "day", .label = "Day" },
        },
    });
}

fn syncToggle(c: *zw.Ctx) !void {
    // z.js sends the switch only while it is on.
    try c.page(syncGroup(c.form("demo-radio-sync") == null));
}

fn states(w: *Writer) Writer.Error!void {
    try zw.view(
        \\<div class="demo-radio-grid">
        \\<div><p class="demo-radio-cap">An option with <code>disabled</code></p>{a}</div>
        \\<div><p class="demo-radio-cap">Group <code>disabled</code></p>{b}</div>
        \\<div><p class="demo-radio-cap">Nothing <code>selected</code></p>{c}</div>
        \\<div><p class="demo-radio-cap"><code>required</code> with <code>invalid</code></p>{r}</div>
        \\<div><p class="demo-radio-cap">Long labels wrap</p>{e}</div>
        \\<div><p class="demo-radio-cap">Disabled until the switch is on</p>{t}<div id="demo-radio-sync-group">{g}</div></div>
        \\</div>
    , .{
        .a = ui.radio(.{ .name = "demo-radio-st-a", .label = "Theme", .z = d.save, .options = &.{
            .{ .value = "light", .label = "Light", .selected = true },
            .{ .value = "dark", .label = "Dark" },
            .{ .value = "auto", .label = "Automatic", .description = "Needs macOS 10.14", .disabled = true },
        } }),
        .b = ui.radio(.{ .name = "demo-radio-st-b", .label = "Tracking speed", .disabled = true, .options = &.{
            .{ .value = "slow", .label = "Slow" },
            .{ .value = "medium", .label = "Medium", .selected = true },
            .{ .value = "fast", .label = "Fast" },
        } }),
        .c = ui.radio(.{ .name = "demo-radio-st-c", .label = "Default browser", .z = d.save, .options = &.{
            .{ .value = "safari", .label = "Safari" },
            .{ .value = "other", .label = "Another browser" },
        } }),
        .r = ui.radio(.{ .name = "demo-radio-st-r", .label = "Delivery", .caption = true, .required = true, .help = "Choose how you want to receive it", .invalid = "Choose a delivery option", .options = &.{
            .{ .value = "ship", .label = "Ship to me" },
            .{ .value = "pickup", .label = "Pick up in store" },
        } }),
        .e = ui.radio(.{ .name = "demo-radio-st-d", .label = "When the lid closes", .z = d.save, .options = &.{
            .{ .value = "sleep", .label = "Put the Mac to sleep and wake it when the lid opens again", .selected = true },
            .{ .value = "stay", .label = "Keep the Mac awake while an external display is connected" },
        } }),
        .t = ui.toggle(.{ .name = "demo-radio-sync", .label = "Sync automatically", .z = .{ .post = "/demo/radio/sync", .target = "#demo-radio-sync-group", .swap = .inner } }),
        .g = syncGroup(true),
    }).render(w);
}

// Checkout: each choice changes the order summary, which comes back as an oob swap.
// Nothing is stored on the server: the request carries the choice.

const Ship = struct { value: []const u8, price: []const u8, total: []const u8 };
const ships = [_]Ship{
    .{ .value = "standard", .price = "Free", .total = "$48.00" },
    .{ .value = "express", .price = "$9.00", .total = "$57.00" },
    .{ .value = "overnight", .price = "$19.00", .total = "$67.00" },
};

const Summary = zw.View(
    \\<dl id="demo-radio-sum" class="demo-radio-sum" aria-live="polite"{#if oob} z-oob{/if}>
    \\<div><dt>Subtotal</dt><dd>$48.00</dd></div>
    \\<div><dt>Shipping</dt><dd>{price}</dd></div>
    \\<div class="demo-radio-total"><dt>Total</dt><dd>{total}</dd></div></dl>
, struct { oob: bool, price: []const u8, total: []const u8 });

fn shipPick(c: *zw.Ctx) !void {
    const value = c.form("demo-radio-ship") orelse "";
    for (ships) |s| if (std.mem.eql(u8, s.value, value)) {
        return c.page(Summary{ .data = .{ .oob = true, .price = s.price, .total = s.total } });
    };
    try c.send(.bad_request, "text/plain", "unknown shipping method");
}

fn checkout(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Shipping",
        .subtitle = "Order of 3 items",
        .body = zw.view("{r}{s}", .{
            .r = ui.radio(.{
                .name = "demo-radio-ship",
                .label = "Shipping method",
                .z = .{ .post = "/demo/radio/ship", .swap = .none },
                .options = &.{
                    .{ .value = "standard", .label = "Standard", .description = "5 to 7 business days", .detail = "Free", .selected = true },
                    .{ .value = "express", .label = "Express", .description = "2 business days", .detail = "$9.00" },
                    .{ .value = "overnight", .label = "Overnight", .description = "Next business day", .detail = "$19.00" },
                    .{ .value = "pickup", .label = "Store pickup", .description = "Not available for this order", .disabled = true },
                },
            }),
            .s = Summary{ .data = .{ .oob = false, .price = ships[0].price, .total = ships[0].total } },
        }),
    }).render(w);
}

// Composition: a field, two radio groups and a button in one form. Leaving the format
// unchosen is stopped by `required`; the server still checks and answers with a toast.

const formats = [_][]const u8{ "pdf", "png", "txt" };

fn exportFile(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("demo-radio-file") orelse "", " ");
    const format = c.form("demo-radio-format") orelse "";
    if (name.len == 0) return c.page(ui.toast(.{ .text = "Name the file first", .kind = .@"error" }));
    for (formats) |f| if (std.mem.eql(u8, f, format)) {
        return c.page(ui.toast(.{ .text = try c.arena.print("Exported “{s}.{s}”", .{ name, f }), .kind = .success }));
    };
    try c.page(ui.toast(.{ .text = "Choose a format first", .kind = .@"error" }));
}

fn export_(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Export",
        .subtitle = "Choose a name and a format",
        .body = zw.view(
            \\<form class="zw-stack"{z}>{name}
            \\{format}
            \\{pages}
            \\<div class="zw-row">{btn}</div></form>
        , .{
            .z = ui.Z{ .post = "/demo/radio/export", .swap = .none, .keep = true },
            .name = ui.field(.{ .name = "demo-radio-file", .label = "File name", .value = "Quarterly report", .maxlength = 40 }),
            .format = ui.radio(.{ .name = "demo-radio-format", .label = "Format", .caption = true, .required = true, .layout = .horizontal, .options = &.{
                .{ .value = "pdf", .label = "PDF", .description = "Best for sharing" },
                .{ .value = "png", .label = "PNG", .description = "Lossless image" },
                .{ .value = "txt", .label = "Text", .description = "Plain text" },
            } }),
            .pages = ui.radio(.{ .name = "demo-radio-pages", .label = "Pages", .caption = true, .options = &.{
                .{ .value = "all", .label = "All pages", .selected = true },
                .{ .value = "current", .label = "Current page" },
                .{ .value = "selection", .label = "Selection", .description = "Select text in the document first", .disabled = true },
            } }),
            .btn = ui.button(.{ .label = "Export", .variant = .primary, .type = .submit }),
        }),
    }).render(w);
}
