//! Live demos for docs/pages/components/island.md (```demo island``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "island", true, island },
    .{ "island-sizes", true, sizes },
    .{ "island-loading", true, loading },
    .{ "island-props", true, props },
    .{ "island-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-island-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,200px),1fr));gap:var(--space);width:100%}
    \\.demo-island-cell{display:flex;flex-direction:column;gap:6px;min-width:0}
    \\.demo-island-cap{font:var(--callout);color:var(--secondary)}
    \\.demo-island-ready{display:grid;place-items:center;height:100%;font:var(--body);color:var(--secondary)}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/island/x", handler }`.
pub const routes = .{
    .{ "GET /demo/island/chart", chartRoute },
    .{ "GET /demo/island/slow", slowRoute },
    .{ "GET /demo/island/orbit", orbitRoute },
};

// Island modules are real files in docs/public: /orbit.js (three.js), /chart.js, /slow.js.
const chart_js = "/chart.js";
const slow_js = "/slow.js";

const Range = struct { key: []const u8, props: []const u8, total: []const u8, label: []const u8 };
const ranges = [_]Range{
    .{ .key = "week", .props = "{\"values\":[42,58,35,71,64,96,80]}", .total = "446 downloads", .label = "Bar chart of downloads per day, last 7 days" },
    .{ .key = "month", .props = "{\"values\":[356,310,402,446]}", .total = "1,514 downloads", .label = "Bar chart of downloads per week, last 4 weeks" },
    .{ .key = "year", .props = "{\"values\":[980,1020,1100,1180,1240,1190,1300,1380,1320,1450,1480,1514]}", .total = "15,154 downloads", .label = "Bar chart of downloads per month, last 12 months" },
};

fn rangeFor(key: []const u8) Range {
    for (ranges) |r| if (std.mem.eql(u8, r.key, key)) return r;
    return ranges[0];
}

fn chartIsland(r: Range, fallback: []const u8) ui.Island {
    return ui.island(.{ .src = chart_js, .props = r.props, .aspect = "16/9", .label = r.label, .fallback = fallback });
}

/// An island with a caption under it, for the side-by-side demos.
fn cell(caption: []const u8, isl: ui.Island) zw.View("<div class=\"demo-island-cell\">{i}<span class=\"demo-island-cap\">{c}</span></div>", struct { i: ui.Island, c: []const u8 }) {
    return .{ .data = .{ .i = isl, .c = caption } };
}

// Hero: a Downloads card like an analytics pane. The segmented control asks the server for another
// range; the response swaps the chart (the old island's cleanup runs) and updates the badge out of band.
fn island(w: *Writer) Writer.Error!void {
    const week = ranges[0];
    try ui.card(.{
        .title = "Downloads",
        .subtitle = "zigworks releases",
        .accessory = ui.badge(.{ .id = "demo-island-total", .text = week.total, .tone = .accent }),
        .body = zw.view("<div class=\"zw-stack\">{range}<div id=\"demo-island-chart\">{chart}</div></div>", .{
            .range = ui.segmented(.{
                .name = "range",
                .label = "Range",
                .full = true,
                .z = .{ .get = "/demo/island/chart", .target = "#demo-island-chart", .swap = .inner },
                .options = &.{ .{ .value = "week", .label = "Week", .selected = true }, .{ .value = "month", .label = "Month" }, .{ .value = "year", .label = "Year" } },
            }),
            .chart = chartIsland(week, "Turn on JavaScript to see the chart."),
        }),
    }).render(w);
}

fn chartRoute(c: *zw.Ctx) !void {
    const r = rangeFor(c.query("range") orelse "week");
    try c.page(zw.view("{chart}{total}", .{
        .chart = chartIsland(r, "Turn on JavaScript to see the chart."),
        .total = ui.badge(.{ .id = "demo-island-total", .oob = true, .text = r.total, .tone = .accent }),
    }));
}

// Sizing: a fixed `height`, or an `aspect` ratio that scales with the width. `aspect` wins when both are set.
fn sizes(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-island-grid\">{a}{b}{c}</div>", .{
        .a = cell("height=\"140px\"", ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":2}", .height = "140px", .label = "Orbit with a fixed height" })),
        .b = cell("aspect=\"16/9\"", ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":3}", .aspect = "16/9", .label = "Orbit that keeps a 16 by 9 shape", .fallback = "Turn on JavaScript to see the orbit." })),
        .c = cell("aspect=\"1/1\" (height is ignored)", ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":4}", .height = "300px", .aspect = "1/1", .label = "Square orbit" })),
    }).render(w);
}

// Loading: both modules take 2.5 s. The placeholder fills the wait; without it the box stays empty.
// Reload swaps the pair for fresh islands, so the wait can be watched again.
fn slowIslands(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-island-grid\" id=\"demo-island-slow\">{a}{b}</div>", .{
        .a = cell("loading=true (default)", ui.island(.{ .src = slow_js, .props = "{\"text\":\"Module ready\"}", .height = "120px", .label = "Island with a placeholder" })),
        .b = cell("loading=false", ui.island(.{ .src = slow_js, .props = "{\"text\":\"Module ready\"}", .height = "120px", .label = "Island without a placeholder", .loading = false })),
    }).render(w);
}

fn loading(w: *Writer) Writer.Error!void {
    try slowIslands(w);
    try zw.view("<div>{reload}</div>", .{
        .reload = ui.button(.{ .label = "Reload", .z = .{ .get = "/demo/island/slow", .target = "#demo-island-slow", .swap = .outer } }),
    }).render(w);
}

fn slowRoute(c: *zw.Ctx) !void {
    var out: std.Io.Writer.Allocating = .init(c.arena);
    try slowIslands(&out.writer);
    try c.send(.ok, "text/html; charset=utf-8", out.written());
}

// Props: a Screen Saver pane. The form sends its values with GET; the server answers with an island
// whose `props` and `aspect` follow them. State lives in the request, nothing is kept on the server.
fn props(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Screen Saver",
        .subtitle = "Orbit",
        .body = zw.view("<form class=\"zw-stack\"{z}><div id=\"demo-island-orbit\">{preview}</div>{planets}{shape}<div>{apply}</div></form>", .{
            .z = ui.Z{ .get = "/demo/island/orbit", .target = "#demo-island-orbit", .swap = .inner },
            .preview = ui.island(.{ .src = "/orbit.js", .props = "{\"planets\":5}", .aspect = "21/9", .label = "Orbit preview with 5 planets" }),
            .planets = ui.setting(.{ .label = "Planets", .control = ui.stepper(.{ .name = "n", .label = "Planets", .value = 5, .min = 1, .max = 8 }) }),
            .shape = ui.setting(.{ .label = "Shape", .control = ui.segmented(.{ .name = "shape", .label = "Preview shape", .options = &.{ .{ .value = "wide", .label = "Wide", .selected = true }, .{ .value = "square", .label = "Square" } } }) }),
            .apply = ui.button(.{ .label = "Update Preview", .variant = .primary, .type = .submit }),
        }),
    }).render(w);
}

fn orbitRoute(c: *zw.Ctx) !void {
    const n = std.math.clamp(std.fmt.parseInt(u8, c.query("n") orelse "5", 10) catch 5, 1, 8);
    const wide = !std.mem.eql(u8, c.query("shape") orelse "wide", "square");
    try c.page(ui.island(.{
        .src = "/orbit.js",
        .props = try std.fmt.allocPrint(c.arena, "{{\"planets\":{d}}}", .{n}),
        .aspect = if (wide) "21/9" else "1/1",
        .label = try std.fmt.allocPrint(c.arena, "Orbit preview with {d} planets", .{n}),
    }));
}

// Composition: islands inside tabs and a sheet start out hidden. The chart module redraws once the
// panel opens and its size is known.
fn compose(w: *Writer) Writer.Error!void {
    const week = ranges[0];
    const year = ranges[2];
    try zw.view("{tabs}<div>{open}</div>{sheet}", .{
        .tabs = ui.tabs(.{ .id = "demo-island-tabs", .label = "Report", .labels = &.{ "Chart", "Details" }, .panels = .{
            chartIsland(week, "Turn on JavaScript to see the chart."),
            ui.list(.{ .id = "demo-island-days", .body = zw.view(
                "<li><span class=\"zw-grow\">Best day</span><span>Saturday</span></li>" ++
                    "<li><span class=\"zw-grow\">Total</span>{total}</li>" ++
                    "<li><span class=\"zw-grow\">Average</span><span>64 a day</span></li>",
                .{ .total = ui.badge(.{ .text = week.total, .tone = .accent }) },
            ) }),
        } }),
        .open = ui.button(.{ .label = "Open Full Chart…", .opens = "demo-island-sheet" }),
        .sheet = ui.sheet(.{
            .id = "demo-island-sheet",
            .title = "Downloads",
            .description = "Per month, last 12 months.",
            .size = .large,
            .close = true,
            .body = chartIsland(year, "Turn on JavaScript to see the chart."),
            .footer = ui.button(.{ .label = "Done", .variant = .primary, .opens = "demo-island-sheet" }),
        }),
    }).render(w);
}
