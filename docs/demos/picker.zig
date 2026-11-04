//! Live demos for docs/pages/components/picker.md (```demo picker``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "picker", true, picker },
    .{ "picker-options", true, options },
    .{ "picker-states", true, states },
    .{ "picker-form", true, form },
    .{ "picker-checkout", true, checkout },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-picker-bar{display:flex;flex-wrap:wrap;gap:8px}
    \\.demo-picker-icon{display:inline-flex;flex:none;width:20px;height:20px;color:var(--accent);
    \\& svg{width:100%;height:100%;fill:currentColor}}
    \\.demo-picker-meta{display:block;font:var(--callout);color:var(--secondary)}
    \\.demo-picker-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,190px),1fr));gap:20px 16px}
    \\.demo-picker-cell{display:flex;flex-direction:column;align-items:flex-start;gap:6px;min-width:0;
    \\&>.zw-picker--full{align-self:stretch}}
    \\.demo-picker-total{display:flex;align-items:baseline;justify-content:space-between;gap:12px;margin-top:12px;padding-top:12px;border-top:1px solid var(--separator);
    \\& strong{font:var(--headline)}}
    \\.demo-picker-note{margin:4px 0 12px;font:var(--callout);color:var(--secondary)}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/picker/x", handler }`.
pub const routes = .{
    .{ "GET /demo/picker/files", filesRoute },
    .{ "POST /demo/picker/remind", remindRoute },
    .{ "GET /demo/picker/price", priceRoute },
    .{ "POST /demo/picker/checkout", checkoutRoute },
};

const icon_doc = "<svg viewBox=\"0 0 16 16\"><path fill-rule=\"evenodd\" d=\"M3 1h6l4 4v10H3zm5 1v4h4z\"/></svg>";
const icon_image = "<svg viewBox=\"0 0 16 16\"><path fill-rule=\"evenodd\" d=\"M2 3h12v10H2zm1.5 8.5h9L9 6.5 7 9.5 5.8 8z\"/></svg>";
const icon_folder = "<svg viewBox=\"0 0 16 16\"><path d=\"M1.5 3h4.5l1.5 2h7v8.5h-13z\"/></svg>";
const icon_box = "<svg viewBox=\"0 0 16 16\"><path fill-rule=\"evenodd\" d=\"M2 2.5h12v3H2zm1 4h10v7H3zm3 1.5v1.5h4V8z\"/></svg>";
const icon_grid = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 2h5v5H2zm7 0h5v5H9zM2 9h5v5H2zm7 0h5v5H9z\"/></svg>";
const icon_rows = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 3h12v2H2zm0 4h12v2H2zm0 4h12v2H2z\"/></svg>";
const icon_columns = "<svg viewBox=\"0 0 16 16\"><path d=\"M2 2h3v12H2zm4.5 0h3v12h-3zM11 2h3v12h-3z\"/></svg>";

// ---- Hero: a Finder-like toolbar. The pickers sit in one form; a change sends both choices
// as a GET and the server answers with the list rows. Nothing is stored on the server.

const File = struct { name: []const u8, kind: []const u8, icon: []const u8, size_kb: u32, size: []const u8, days: u8, when: []const u8 };

const files = [_]File{
    .{ .name = "Budget 2026.numbers", .kind = "doc", .icon = icon_doc, .size_kb = 840, .size = "840 KB", .days = 1, .when = "Yesterday" },
    .{ .name = "Annual Report.pdf", .kind = "doc", .icon = icon_doc, .size_kb = 2400, .size = "2.4 MB", .days = 3, .when = "3 days ago" },
    .{ .name = "Meeting Notes.txt", .kind = "doc", .icon = icon_doc, .size_kb = 4, .size = "4 KB", .days = 0, .when = "Today" },
    .{ .name = "Beach Trip.jpg", .kind = "image", .icon = icon_image, .size_kb = 3100, .size = "3.1 MB", .days = 12, .when = "12 days ago" },
    .{ .name = "Logo Draft.png", .kind = "image", .icon = icon_image, .size_kb = 520, .size = "520 KB", .days = 6, .when = "6 days ago" },
    .{ .name = "Projects", .kind = "folder", .icon = icon_folder, .size_kb = 0, .size = "--", .days = 2, .when = "2 days ago" },
    .{ .name = "Receipts", .kind = "folder", .icon = icon_folder, .size_kb = 0, .size = "--", .days = 30, .when = "30 days ago" },
};

const FileRow = zw.View(
    "<li><span class=\"demo-picker-icon\" aria-hidden=\"true\">{@html icon}</span><span class=\"zw-grow\">{name}<small class=\"demo-picker-meta\">{when} · {size}</small></span></li>",
    File,
);

fn byKey(sort: []const u8, a: File, b: File) bool {
    if (std.mem.eql(u8, sort, "date")) return a.days < b.days;
    if (std.mem.eql(u8, sort, "size")) return a.size_kb > b.size_kb;
    return std.ascii.lessThanIgnoreCase(a.name, b.name);
}

/// The list rows for a sort order and a kind filter ("all", "doc", "image", "folder", "archive").
const FileRows = struct {
    sort: []const u8,
    kind: []const u8,

    pub fn render(self: FileRows, w: *Writer) Writer.Error!void {
        var buf: [files.len]File = undefined;
        var n: usize = 0;
        for (files) |f| if (std.mem.eql(u8, self.kind, "all") or std.mem.eql(u8, self.kind, f.kind)) {
            buf[n] = f;
            n += 1;
        };
        std.mem.sort(File, buf[0..n], self.sort, byKey);
        for (buf[0..n]) |f| try (FileRow{ .data = f }).render(w);
    }
};

fn filesRoute(c: *zw.Ctx) !void {
    try c.page(FileRows{ .sort = c.query("sort") orelse "name", .kind = c.query("kind") orelse "all" });
}

fn picker(w: *Writer) Writer.Error!void {
    try zw.view("<form class=\"demo-picker-bar\"{z}>{sort}{kind}</form>{files}", .{
        .z = ui.Z{ .get = "/demo/picker/files", .trigger = "change", .target = "#demo-picker-files", .swap = .inner },
        .sort = ui.picker(.{ .id = "demo-picker-sort", .name = "sort", .label = "Sort by", .options = &.{
            .{ .value = "name", .label = "Name", .selected = true },
            .{ .value = "date", .label = "Date Modified" },
            .{ .value = "size", .label = "Size" },
        } }),
        .kind = ui.picker(.{ .id = "demo-picker-kind", .name = "kind", .label = "Show", .options = &.{
            .{ .value = "all", .label = "All Items", .selected = true },
            .{ .value = "doc", .label = "Documents", .icon = icon_doc, .separated = true, .heading = "Kind" },
            .{ .value = "image", .label = "Images", .icon = icon_image },
            .{ .value = "folder", .label = "Folders", .icon = icon_folder },
            .{ .value = "archive", .label = "Archives", .icon = icon_box },
        } }),
        .files = ui.list(.{ .id = "demo-picker-files", .header = "Downloads", .empty = "No items of this kind.", .body = FileRows{ .sort = "name", .kind = "all" } }),
    }).render(w);
}

// ---- Options: each prop on its own, labelled with the prop it shows.

const Cell = zw.View("<div class=\"demo-picker-cell\"><code>{cap}</code>{p}</div>", struct { cap: []const u8, p: ui.Picker });

fn cell(cap: []const u8, p: ui.Picker) Cell {
    return .{ .data = .{ .cap = cap, .p = p } };
}

fn options(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-picker-grid\">{a}{b}{c}{d}{e}</div>", .{
        .a = cell("selected", ui.picker(.{ .id = "demo-picker-sel", .name = "opt-sort", .label = "Sort by", .z = d.save, .options = &.{
            .{ .value = "name", .label = "Name" },
            .{ .value = "date", .label = "Date Modified", .selected = true },
            .{ .value = "size", .label = "Size" },
        } })),
        .b = cell("placeholder", ui.picker(.{ .id = "demo-picker-ph", .name = "opt-group", .label = "Group by", .placeholder = "Group by…", .z = d.save, .options = &.{
            .{ .value = "kind", .label = "Kind" },
            .{ .value = "date", .label = "Date Added" },
            .{ .value = "tags", .label = "Tags" },
        } })),
        .c = cell("icon + description", ui.picker(.{ .id = "demo-picker-rich", .name = "opt-view", .label = "View as", .z = d.save, .options = &.{
            .{ .value = "icons", .label = "as Icons", .icon = icon_grid, .description = "Large thumbnails", .selected = true },
            .{ .value = "list", .label = "as List", .icon = icon_rows, .description = "Name, date and size" },
            .{ .value = "columns", .label = "as Columns", .icon = icon_columns, .description = "Browse folder by folder" },
        } })),
        .d = cell("heading + separated + disabled", ui.picker(.{ .id = "demo-picker-sections", .name = "opt-section", .label = "Group by", .z = d.save, .options = &.{
            .{ .value = "none", .label = "None", .selected = true },
            .{ .value = "kind", .label = "Kind", .heading = "Attributes" },
            .{ .value = "size", .label = "Size" },
            .{ .value = "modified", .label = "Date Modified", .separated = true, .heading = "Dates" },
            .{ .value = "added", .label = "Date Added" },
            .{ .value = "shared", .label = "Shared By", .separated = true, .disabled = true },
        } })),
        .e = cell("full", ui.picker(.{ .id = "demo-picker-full", .name = "opt-open", .label = "Open with", .full = true, .z = d.save, .options = &.{
            .{ .value = "preview", .label = "Preview", .selected = true },
            .{ .value = "textedit", .label = "TextEdit" },
            .{ .value = "other", .label = "Other…", .separated = true },
        } })),
    }).render(w);
}

// ---- States: a Settings pane. Choices save as they change (POST /demo, answers 204).

fn states(w: *Writer) Writer.Error!void {
    try ui.card(.{ .body = zw.view("{a}{b}{c}{d}", .{
        .a = ui.setting(.{ .label = "Language", .description = "Menus and dialogs use this language.", .control = ui.picker(.{ .id = "demo-picker-lang", .name = "language", .label = "Language", .z = d.save, .options = &.{
            .{ .value = "en", .label = "English", .selected = true },
            .{ .value = "is", .label = "Icelandic" },
            .{ .value = "de", .label = "German" },
        } }) }),
        .b = ui.setting(.{ .label = "Calendar", .description = "Nothing is chosen yet, so the button shows the placeholder.", .control = ui.picker(.{ .id = "demo-picker-cal", .name = "calendar", .label = "Calendar", .placeholder = "Choose…", .z = d.save, .options = &.{
            .{ .value = "gregorian", .label = "Gregorian" },
            .{ .value = "iso", .label = "ISO 8601" },
            .{ .value = "hebrew", .label = "Hebrew", .disabled = true, .description = "Not installed" },
        } }) }),
        .c = ui.setting(.{ .label = "First day of week", .control = ui.picker(.{ .id = "demo-picker-week", .name = "week", .label = "First day of week", .z = d.save, .options = &.{
            .{ .value = "sun", .label = "Sunday" },
            .{ .value = "mon", .label = "Monday", .selected = true },
            .{ .value = "sat", .label = "Saturday" },
        } }) }),
        .d = ui.setting(.{ .label = "Time zone", .description = "Set automatically using your location.", .control = ui.picker(.{ .id = "demo-picker-zone", .name = "zone", .label = "Time zone", .disabled = true, .options = &.{
            .{ .value = "auto", .label = "Reykjavik", .selected = true },
        } }) }),
    }) }).render(w);
}

// ---- Form: pickers submit like selects. The server answers with a toast that lists what arrived.

fn form(w: *Writer) Writer.Error!void {
    try zw.view("<form class=\"zw-stack\"{z}>{title}{card}{add}</form>", .{
        .z = ui.Z{ .post = "/demo/picker/remind", .swap = .none, .keep = true },
        .title = ui.field(.{ .name = "title", .label = "Title", .placeholder = "Call the dentist", .maxlength = 60 }),
        .card = ui.card(.{ .body = zw.view("{a}{b}{c}", .{
            .a = ui.setting(.{ .label = "List", .control = ui.picker(.{ .id = "demo-picker-list", .name = "list", .label = "List", .placeholder = "Choose…", .options = &.{
                .{ .value = "reminders", .label = "Reminders" },
                .{ .value = "groceries", .label = "Groceries" },
                .{ .value = "work", .label = "Work" },
            } }) }),
            .b = ui.setting(.{ .label = "Priority", .control = ui.picker(.{ .id = "demo-picker-priority", .name = "priority", .label = "Priority", .options = &.{
                .{ .value = "none", .label = "None", .selected = true },
                .{ .value = "low", .label = "Low" },
                .{ .value = "medium", .label = "Medium" },
                .{ .value = "high", .label = "High" },
            } }) }),
            .c = ui.setting(.{ .label = "Account", .description = "Disabled, so it submits nothing.", .control = ui.picker(.{ .id = "demo-picker-account", .name = "account", .label = "Account", .disabled = true, .options = &.{
                .{ .value = "icloud", .label = "iCloud", .selected = true },
            } }) }),
        }) }),
        .add = ui.button(.{ .label = "Add Reminder", .variant = .primary, .type = .submit }),
    }).render(w);
}

fn remindRoute(c: *zw.Ctx) !void {
    const title = std.mem.trim(u8, c.form("title") orelse "", " ");
    if (title.len == 0) return c.page(ui.toast(.{ .text = "Add a title first", .kind = .warning }));
    if (title.len > 200) return c.page(ui.toast(.{ .text = "That title is too long", .kind = .warning }));
    // No option checked means the browser sends no field at all, exactly like an empty select.
    const list = c.form("list") orelse return c.page(ui.toast(.{ .text = "Choose a list: the picker sent nothing", .kind = .@"error" }));
    const text = try std.fmt.allocPrint(c.arena, "Sent title={s}, list={s}, priority={s}. The disabled Account picker sent nothing.", .{ title, list, c.form("priority") orelse "" });
    try c.page(ui.toast(.{ .text = text, .kind = .success }));
}

// ---- Checkout: two pickers in a form re-price the order. The server returns the summary and
// swaps the plan badge out of band. The choices travel in the URL, nothing is stored.

const Plan = enum { monthly, yearly };
const Currency = enum { usd, eur, gbp };

fn planBadge(plan: Plan, oob: bool) ui.Badge {
    return switch (plan) {
        .monthly => ui.badge(.{ .id = "demo-picker-plan", .oob = oob, .text = "Monthly" }),
        .yearly => ui.badge(.{ .id = "demo-picker-plan", .oob = oob, .text = "Save 20%", .tone = .green }),
    };
}

/// Total, note and Subscribe button for a plan and currency (prices are fixed sample numbers).
const Summary = struct {
    plan: Plan,
    cur: Currency,

    pub fn render(self: Summary, w: *Writer) Writer.Error!void {
        const rate: u32 = switch (self.cur) {
            .usd => 1000,
            .eur => 920,
            .gbp => 790,
        };
        const sym: []const u8 = switch (self.cur) {
            .usd => "$",
            .eur => "€",
            .gbp => "£",
        };
        const month: u32 = 1200 * rate / 1000;
        const due: u32 = if (self.plan == .yearly) month * 12 * 80 / 100 else month;
        var price: [24]u8 = undefined;
        var note: [64]u8 = undefined;
        var url: [64]u8 = undefined;
        const per_month = due / 12;
        const text: []const u8 = if (self.plan == .yearly)
            std.fmt.bufPrint(&note, "About {s}{d}.{d:0>2} a month, billed once a year.", .{ sym, per_month / 100, per_month % 100 }) catch unreachable
        else
            "Billed monthly. Cancel any time.";
        try zw.view("<div class=\"demo-picker-total\"><span>Due today</span><strong>{price}</strong></div><p class=\"demo-picker-note\">{note}</p>{buy}", .{
            .price = std.fmt.bufPrint(&price, "{s}{d}.{d:0>2}", .{ sym, due / 100, due % 100 }) catch unreachable,
            .note = text,
            .buy = ui.button(.{
                .label = "Subscribe",
                .variant = .primary,
                .full = true,
                .z = .{ .post = std.fmt.bufPrint(&url, "/demo/picker/checkout?plan={s}&cur={s}", .{ @tagName(self.plan), @tagName(self.cur) }) catch unreachable, .swap = .none },
            }),
        }).render(w);
    }
};

fn priceRoute(c: *zw.Ctx) !void {
    const plan = std.meta.stringToEnum(Plan, c.query("plan") orelse "") orelse .monthly;
    const cur = std.meta.stringToEnum(Currency, c.query("cur") orelse "") orelse .usd;
    try c.page(zw.view("{summary}{badge}", .{ .summary = Summary{ .plan = plan, .cur = cur }, .badge = planBadge(plan, true) }));
}

fn checkoutRoute(c: *zw.Ctx) !void {
    const plan = std.meta.stringToEnum(Plan, c.query("plan") orelse "") orelse .monthly;
    const cur = std.meta.stringToEnum(Currency, c.query("cur") orelse "") orelse .usd;
    const text = try std.fmt.allocPrint(c.arena, "Subscribed to Zigworks Pro ({s}, {s}). This is a demo: nothing was charged.", .{ @tagName(plan), @tagName(cur) });
    try c.page(ui.toast(.{ .text = text, .kind = .success }));
}

fn checkout(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Zigworks Pro",
        .subtitle = "Priority support and early releases.",
        .accessory = planBadge(.monthly, false),
        .body = zw.view("<form{z}>{plan}{cur}</form><div id=\"demo-picker-summary\" aria-live=\"polite\">{summary}</div>", .{
            .z = ui.Z{ .get = "/demo/picker/price", .trigger = "change", .target = "#demo-picker-summary", .swap = .inner },
            .plan = ui.setting(.{ .label = "Billing", .control = ui.picker(.{ .id = "demo-picker-plan-pick", .name = "plan", .label = "Billing", .options = &.{
                .{ .value = "monthly", .label = "Monthly", .selected = true, .description = "Pay as you go" },
                .{ .value = "yearly", .label = "Yearly", .description = "Save 20%" },
            } }) }),
            .cur = ui.setting(.{ .label = "Currency", .control = ui.picker(.{ .id = "demo-picker-cur", .name = "cur", .label = "Currency", .options = &.{
                .{ .value = "usd", .label = "US Dollar", .selected = true },
                .{ .value = "eur", .label = "Euro" },
                .{ .value = "gbp", .label = "British Pound" },
            } }) }),
            .summary = Summary{ .plan = .monthly, .cur = .usd },
        }),
    }).render(w);
}
