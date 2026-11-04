//! Live demos for docs/pages/components/layout.md (```demo layout``` fences).
//! A layout is a whole document, so every demo shows a real `ui.layout` page in an iframe that
//! loads `GET /demo/layout/frame?v=<name>`.
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "layout", true, hero },
    .{ "layout-titles", true, titles },
    .{ "layout-chrome", true, chrome },
    .{ "layout-live", true, live },
    .{ "layout-settings", true, settings },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-layout-pair{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,280px),1fr));gap:16px}
    \\.demo-layout-fig{margin:0;min-width:0;display:flex;flex-direction:column;gap:8px}
    \\.demo-layout-fig figcaption{font:var(--callout);color:var(--secondary)}
    \\.demo-layout-frame{display:block;width:100%;height:240px;border:.5px solid var(--separator);border-radius:var(--radius-control);background:var(--window)}
    \\.demo-layout-frame--tall{height:400px}
.demo-layout-scroll{overflow-x:auto;border-radius:var(--radius-control)}
.demo-layout-scroll .demo-layout-frame{min-width:840px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/layout/x", handler }`.
pub const routes = .{
    .{ "GET /demo/layout/frame", frame },
    .{ "POST /demo/layout/add", add },
};

const plus = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.7\" stroke-linecap=\"round\"><path d=\"M9 3.5v11M3.5 9h11\"/></svg>";
const svg = "<svg viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'>";
const note = svg ++ "<path d='M4 1.7h5l3 3v9.6H4z'/><path d='M9 1.7v3h3M6 8h4M6 10.5h4'/></svg>";
const inbox = svg ++ "<path d='M2 9.5l1.6-5.2a1 1 0 0 1 .95-.7h6.9a1 1 0 0 1 .95.7L14 9.5v2.9a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1z'/><path d='M2 9.5h3.4l.6 1.5h4l.6-1.5H14'/></svg>";
const sent = svg ++ "<path d='M14 2L7 9M14 2l-4.5 12L7 9 1.5 6.5z'/></svg>";
const gear = svg ++ "<circle cx='8' cy='8' r='2.2'/><path d='M8 1.8v2M8 12.2v2M1.8 8h2M12.2 8h2M3.6 3.6l1.4 1.4M11 11l1.4 1.4M3.6 12.4L5 11M11 5l1.4-1.4'/></svg>";
const bell = svg ++ "<path d='M4 11V7.5a4 4 0 0 1 8 0V11l1.2 1.5H2.8z'/><path d='M6.5 14h3'/></svg>";

/// One figure: a frame running page `v` and a caption (trusted HTML) that maps it to props.
/// `wide` frames are 840px wide (scrolling sideways on a phone) so the sidebar shows as a column.
fn figure(w: *Writer, v: []const u8, label: []const u8, caption: []const u8, wide: bool) Writer.Error!void {
    try zw.view(
        \\<figure class="demo-layout-fig">{#if wide}<div class="demo-layout-scroll" tabindex="0" role="group" aria-label="{label}, scrolls sideways on narrow screens">{/if}<iframe class="demo-layout-frame{#if wide} demo-layout-frame--tall{/if}" src="/demo/layout/frame?v={v}" aria-label="{label}" loading="lazy"></iframe>{#if wide}</div>{/if}<figcaption>{@html caption}</figcaption></figure>
    , .{ .v = v, .label = label, .caption = caption, .wide = wide }).render(w);
}

fn hero(w: *Writer) Writer.Error!void {
    try figure(w, "notes", "A Notes app built with ui.layout", "A <code>ui.layout</code> with a <code>sidebar</code> and a <code>toolbar</code> (badge and button). The frame is 840px wide, so the sidebar is a column (below 800px it opens from the title bar button). Scroll the notes: they slide under the soft title bar.", true);
}

fn titles(w: *Writer) Writer.Error!void {
    try w.writeAll("<div class=\"demo-layout-pair\">");
    try figure(w, "leading", "A page with a brand and a leading title", "<code>.title_align = .leading</code> (default) with a <code>.brand</code> and a <code>.brand_href</code> (it defaults to <code>/</code>; here it stays in the frame). Press <kbd>Tab</kbd> for the skip link.", false);
    try figure(w, "center", "A page with a centered title and a sidebar", "<code>.title_align = .center</code> keeps the title between the sidebar button and the <code>.toolbar</code>, like a macOS window.", false);
    try w.writeAll("</div>");
}

fn chrome(w: *Writer) Writer.Error!void {
    try figure(w, "skip", "A page in Icelandic with a footer and a skip link", "Click inside the frame and press <kbd>Tab</kbd> once: the <code>.skip_label</code> pill appears. This page sets <code>.lang = \"is\"</code> and a <code>.footer</code>. <code>.skip_link = false</code> would remove it.", false);
}

fn live(w: *Writer) Writer.Error!void {
    try figure(w, "live", "A reminders page that updates its title bar", "Add a reminder. One response appends the row, replaces the title bar badge (<code>oob</code>) and shows a toast. The count travels in a hidden field, so the server keeps nothing.", false);
}

fn settings(w: *Writer) Writer.Error!void {
    try figure(w, "settings", "A settings window built from a layout, a sidebar, a card and settings rows", "<code>layout</code> + <code>sidebar</code> + <code>card</code> + <code>setting</code>. Controls save with <code>POST /demo</code> as you change them.", true);
}

/// Which page the iframes load. The pages are plain `ui.layout`s, nothing special.
fn frame(c: *zw.Ctx) !void {
    const v = c.query("v") orelse "";
    if (std.mem.eql(u8, v, "notes")) return c.page(ui.layout(.{
        .title = "Notes",
        .toolbar = zw.view("{n}{b}", .{
            .n = ui.badge(.{ .text = "24 notes" }),
            .b = ui.button(.{ .label = "New Note", .icon = plus, .icon_only = true, .variant = .primary, .z = d.save }),
        }),
        .sidebar = ui.sidebar(.{
            .label = "Folders",
            .current = "#all",
            .sections = &.{
                .{ .title = "iCloud", .links = &.{
                    .{ .label = "All Notes", .href = "#all", .icon = note, .badge = "24" },
                    .{ .label = "Recipes", .href = "#recipes", .icon = note, .badge = "6" },
                    .{ .label = "Travel", .href = "#travel", .icon = note },
                } },
                .{ .title = "On My Mac", .collapsible = true, .open = false, .links = &.{.{ .label = "Drafts", .href = "#drafts", .icon = note }} },
            },
        }),
        .body = ui.list(.{
            .id = "demo-layout-notes",
            .header = "Today",
            .footer = "Seven more notes this week.",
            .nav = true,
            .body = zw.view(
                \\<li><a href="#n1">Grocery list</a></li><li><a href="#n2">Sourdough starter schedule</a></li><li><a href="#n3">Trip to Lisbon</a></li>
                \\<li><a href="#n4">Book ideas</a></li><li><a href="#n5">Meeting notes</a></li><li><a href="#n6">Gift ideas</a></li><li><a href="#n7">Garden plan</a></li>
            , .{}),
        }),
    }));
    if (std.mem.eql(u8, v, "leading")) return c.page(ui.layout(.{
        .title = "Atlas",
        .brand = "Atlas",
        // The brand links to "/" by default, which would load the docs inside the frame.
        .brand_href = "#welcome",
        .toolbar = ui.button(.{ .label = "Share", .size = .small }),
        .body = ui.card(.{ .title = "Welcome back", .subtitle = "Brand on the leading edge", .body = "The title is a link home. The toolbar sits at the trailing edge." }),
    }));
    if (std.mem.eql(u8, v, "center")) return c.page(ui.layout(.{
        .title = "Inbox",
        .title_align = .center,
        .toolbar = ui.badge(.{ .count = 3, .tone = .red, .solid = true }),
        .sidebar = ui.sidebar(.{
            .label = "Mailboxes",
            .current = "#inbox",
            .sections = &.{.{ .title = "Mail", .links = &.{
                .{ .label = "Inbox", .href = "#inbox", .icon = inbox, .badge = "3" },
                .{ .label = "Sent", .href = "#sent", .icon = sent },
            } }},
        }),
        .body = ui.card(.{ .title = "Ada Lovelace", .subtitle = "Notes on the Analytical Engine", .body = "Centered titles suit windows with a few controls on either side." }),
    }));
    if (std.mem.eql(u8, v, "skip")) return c.page(ui.layout(.{
        .title = "Velkomin",
        .lang = "is",
        .skip_label = "Fara í efni",
        .footer = "© 2026 Atlas · Persónuvernd",
        .body = ui.card(.{ .title = "Velkomin", .subtitle = "Síðan er á íslensku", .body = "Ýttu á Tab til að sjá hlekkinn efst til vinstri." }),
    }));
    if (std.mem.eql(u8, v, "live")) return c.page(ui.layout(.{
        .title = "Reminders",
        .toolbar = ui.badge(.{ .count = 2, .id = "demo-layout-left", .tone = .accent }),
        .body = zw.view(
            \\<div class="zw-stack"><form class="zw-row"{z}><input type="hidden" id="demo-layout-n" name="n" value="2">{f}{b}</form>{l}</div>
        , .{
            .z = ui.Z{ .post = "/demo/layout/add", .target = "#demo-layout-list", .swap = .beforeend },
            .f = ui.field(.{ .name = "title", .label = "New reminder", .placeholder = "New reminder", .required = true, .maxlength = 80 }),
            .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
            .l = ui.list(.{ .id = "demo-layout-list", .empty = "All done.", .body = zw.view(
                \\<li><span class="zw-grow">Call the dentist</span><span class="zw-secondary">Today</span></li><li><span class="zw-grow">Water the plants</span><span class="zw-secondary">Today</span></li>
            , .{}) }),
        }),
    }));
    if (std.mem.eql(u8, v, "settings")) return c.page(ui.layout(.{
        .title = "Settings",
        .title_align = .center,
        .footer = "Changes save as you make them.",
        .sidebar = ui.sidebar(.{
            .label = "Settings",
            .current = "#general",
            .sections = &.{.{ .title = "", .links = &.{
                .{ .label = "General", .href = "#general", .icon = gear },
                .{ .label = "Notifications", .href = "#notifications", .icon = bell },
            } }},
        }),
        .body = zw.view("<div class=\"zw-stack\">{a}{b}</div>", .{
            .a = ui.card(.{ .title = "Appearance", .body = zw.view("{a}{b}", .{
                .a = ui.setting(.{ .label = "Theme", .description = "Applies to every window.", .control = ui.segmented(.{ .name = "look", .label = "Theme", .z = d.save, .options = &.{ .{ .value = "light", .label = "Light" }, .{ .value = "dark", .label = "Dark" }, .{ .value = "auto", .label = "Auto", .selected = true } } }) }),
                .b = ui.toggle(.{ .name = "sounds", .label = "Play sounds", .on = true, .z = d.save }),
            }) }),
            .b = ui.card(.{ .title = "Sync", .body = ui.setting(.{ .label = "Interval", .control = ui.stepper(.{ .name = "sync", .label = "Sync interval in minutes", .value = 15, .min = 5, .max = 60, .unit = "min", .z = d.save }) }) }),
        }),
    }));
    c.pass();
}

/// `POST /demo/layout/add`: the new row, the title bar badge and a toast, all from one response.
fn add(c: *zw.Ctx) !void {
    const title = std.mem.trim(u8, c.form("title") orelse "", " ");
    if (title.len == 0 or title.len > 80) return c.send(.no_content, "text/plain", "");
    const n = (std.fmt.parseInt(u32, c.form("n") orelse "0", 10) catch 0) +| 1;
    try c.page(zw.view("{row}{badge}{n}{toast}", .{
        .row = zw.view("<li><span class=\"zw-grow\">{t}</span><span class=\"zw-secondary\">Just now</span></li>", .{ .t = title }),
        .badge = ui.badge(.{ .count = n, .id = "demo-layout-left", .tone = .accent, .oob = true }),
        .n = zw.view("<input type=\"hidden\" id=\"demo-layout-n\" name=\"n\" value=\"{n}\" z-oob>", .{ .n = n }),
        .toast = ui.toast(.{ .text = "Reminder added", .kind = .success }),
    }));
}
