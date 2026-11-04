//! zigworks.dev: the documentation site, built with zigworks itself.
//! Pages are Markdown in docs/pages, embedded at compile time. ```demo <name>``` fences render live
//! components from demos.zig. Run `zig build docs`; it listens on 0.0.0.0:8080.
const std = @import("std");
const zw = @import("zigworks");
const ui = zw.ui;
const pages = @import("pages.zig");
const demos = @import("demos.zig");

const app = .{
    .routes = .{
        .{ "GET /", home },
        .{ "GET /search", search },
        .{ "POST /demo", demoEcho },
        .{ "POST /demo/todos", todoAdd },
        .{ "POST /demo/toggle", todoToggle },
        .{ "DELETE /demo/todo", todoDelete },
        .{ "POST /demo/toast", toastDemo },
        .{ "GET /components/:name", component },
        .{ "GET /:page", guide },
    },
    .css = css ++ demos.css,
    .not_found = notFound,
};

const css =
    \\.pager{display:flex;justify-content:space-between;gap:12px;margin-top:48px;padding-top:20px;border-top:1px solid var(--separator);max-width:72ch}
    \\.pager a{display:flex;flex-direction:column;gap:2px;padding:10px 14px;border-radius:var(--radius-control);text-decoration:none;color:var(--label);box-shadow:inset 0 0 0 .5px var(--separator);min-width:0}
    \\.pager a:hover{background:var(--fill)}
    \\.pager small{font:var(--callout);color:var(--secondary)}
    \\.pager .next{margin-left:auto;text-align:right}
    \\.lead{font:400 18px/1.5 var(--font);letter-spacing:-.3px;color:var(--secondary);max-width:60ch}
    \\
;

pub fn main(init: std.process.Init) !void {
    try zw.serve(init, app, .{});
}

fn home(c: *zw.Ctx) !void {
    try show(c, pages.find("/").?);
}

fn guide(c: *zw.Ctx) !void {
    // Not a page: let public/ answer (orbit.js) or fall through to 404.
    const path = try c.arena.print("/{s}", .{c.param("page").?});
    try show(c, pages.find(path) orelse return c.pass());
}

fn component(c: *zw.Ctx) !void {
    const path = try c.arena.print("/components/{s}", .{c.param("name").?});
    try show(c, pages.find(path) orelse return c.pass());
}

fn show(c: *zw.Ctx, page: *const pages.Page) !void {
    const prev, const next = pages.neighbours(page);
    try c.page(ui.layout(.{
        .title = if (page.path.len == 1) "zigworks" else try c.arena.print("{s} · zigworks", .{page.title}),
        .brand = "zigworks",
        .head = "<meta name=\"description\" content=\"zigworks: a small, fast web framework in pure Zig, written for AI agents.\">",
        .toolbar = zw.view("{search}{version}", .{
            .search = ui.search(.{ .action = "/search", .label = "Search docs", .placeholder = "Search docs" }),
            .version = ui.badge(.{ .text = "v" ++ zw.version }),
        }),
        .sidebar = ui.sidebar(.{ .sections = pages.nav, .current = page.path, .label = "Documentation" }),
        .body = zw.view("{doc}{pager}", .{
            .doc = zw.markdownWith(page.md, demos.Fences{}),
            .pager = zw.view(
                \\<nav class="pager" aria-label="Pages">{#each prev as p}<a href="{p.path}"><small>Previous</small>{p.title}</a>{/each}{#each next as p}<a class="next" href="{p.path}"><small>Next</small>{p.title}</a>{/each}</nav>
            , .{ .prev = optSlice(prev), .next = optSlice(next) }),
        }),
    }));
}

/// Zero or one page, so a template can `{#each}` over an optional.
fn optSlice(p: ?*const pages.Page) []const pages.Page {
    return if (p) |page| page[0..1] else &.{};
}

fn search(c: *zw.Ctx) !void {
    const q = std.mem.trim(u8, c.query("q") orelse "", " ");
    const hits = try pages.search(c.arena, q, 8);
    const results = zw.view(
        \\{#each hits as h}<a href="{h.path}">{h.title}<small>{h.snippet}</small></a>{/each}{#if !hits}{#if q}<p>No results for “{q}”.</p>{/if}{/if}
    , .{ .hits = hits, .q = q });
    if (c.isPartial()) return c.page(results);
    // Without JS the search form submits here: show results as a page.
    try c.page(ui.layout(.{
        .title = "Search · zigworks",
        .brand = "zigworks",
        .sidebar = ui.sidebar(.{ .sections = pages.nav, .current = "", .label = "Documentation" }),
        .body = zw.view("<div class=\"zw-prose\"><h1>Search</h1><div class=\"zw-results\" style=\"position:static\">{results}</div></div>", .{ .results = results }),
    }));
}

fn demoEcho(c: *zw.Ctx) !void {
    std.log.info("demo {s}", .{c.body});
    try c.send(.no_content, "text/plain", "");
}

// Home page todo demo: the server renders rows; the page holds the list.
fn todoAdd(c: *zw.Ctx) !void {
    const title = std.mem.trim(u8, c.form("title") orelse "", " ");
    if (title.len == 0 or title.len > 200) return c.send(.no_content, "text/plain", "");
    try c.page(try demos.todoRow(c.arena, false, title));
}

fn todoToggle(c: *zw.Ctx) !void {
    const title = c.query("t") orelse return c.send(.bad_request, "text/plain", "missing t");
    const done = std.mem.eql(u8, c.query("d") orelse "0", "1");
    try c.page(try demos.todoRow(c.arena, !done, title));
}

fn todoDelete(c: *zw.Ctx) !void {
    // An empty 200 lets z.js remove the row (204 would mean "change nothing").
    try c.send(.ok, "text/html; charset=utf-8", "");
}

fn toastDemo(c: *zw.Ctx) !void {
    const err = std.mem.eql(u8, c.query("k") orelse "", "error");
    try c.page(ui.toast(if (err) .{ .text = "Couldn't save: the disk is full", .kind = .@"error" } else .{ .text = "Saved", .kind = .success }));
}

fn notFound(c: *zw.Ctx) !void {
    try c.page(ui.layout(.{
        .title = "Not found · zigworks",
        .brand = "zigworks",
        .sidebar = ui.sidebar(.{ .sections = pages.nav, .current = "", .label = "Documentation" }),
        .body = zw.markdown("# Page not found\n\nThat page doesn't exist. Pick a topic from the sidebar or search the docs."),
    }));
}

test {
    _ = pages;
}
