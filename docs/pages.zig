//! Page registry: order here is the sidebar order and the previous/next order.
//! A page's title is the first `# ` heading of its Markdown file.
const std = @import("std");
const ui = @import("zigworks").ui;

pub const Page = struct { path: []const u8, title: []const u8, section: []const u8, md: []const u8 };

const sections = .{
    .{ "Start", .{
        .{ "/", "index" },
        .{ "/getting-started", "getting-started" },
        .{ "/agents", "agents" },
    } },
    .{ "Guides", .{
        .{ "/routing", "routing" },
        .{ "/context", "context" },
        .{ "/templates", "templates" },
        .{ "/interactivity", "interactivity" },
        .{ "/markdown", "markdown" },
        .{ "/theming", "theming" },
        .{ "/islands", "islands" },
        .{ "/testing", "testing" },
    } },
    .{ "Components", .{
        .{ "/components/layout", "components/layout" },
        .{ "/components/sidebar", "components/sidebar" },
        .{ "/components/card", "components/card" },
        .{ "/components/list", "components/list" },
        .{ "/components/setting", "components/setting" },
        .{ "/components/sheet", "components/sheet" },
        .{ "/components/button", "components/button" },
        .{ "/components/field", "components/field" },
        .{ "/components/search", "components/search" },
        .{ "/components/check", "components/check" },
        .{ "/components/toggle", "components/toggle" },
        .{ "/components/segmented", "components/segmented" },
        .{ "/components/slider", "components/slider" },
        .{ "/components/picker", "components/picker" },
        .{ "/components/menu", "components/menu" },
        .{ "/components/badge", "components/badge" },
        .{ "/components/progress", "components/progress" },
        .{ "/components/callout", "components/callout" },
        .{ "/components/code", "components/code" },
        .{ "/components/table", "components/table" },
        .{ "/components/island", "components/island" },
    } },
};

pub const all: []const Page = blk: {
    var list: []const Page = &.{};
    for (sections) |s| for (s[1]) |p| {
        const md = @embedFile("pages/" ++ p[1] ++ ".md");
        list = list ++ [_]Page{.{ .path = p[0], .title = titleOf(md), .section = s[0], .md = md }};
    };
    break :blk list;
};

pub const nav: []const ui.SidebarSection = blk: {
    var out: []const ui.SidebarSection = &.{};
    for (sections) |s| {
        var links: []const ui.SidebarLink = &.{};
        for (all) |p| if (std.mem.eql(u8, p.section, s[0])) {
            links = links ++ [_]ui.SidebarLink{.{ .label = p.title, .href = p.path }};
        };
        out = out ++ [_]ui.SidebarSection{.{ .title = s[0], .links = links }};
    }
    break :blk out;
};

fn titleOf(comptime md: []const u8) []const u8 {
    @setEvalBranchQuota(100_000);
    const first = std.mem.cutScalar(u8, md, '\n') orelse .{ md, "" };
    return std.mem.cutPrefix(u8, first[0], "# ") orelse @compileError("page must start with '# Title'");
}

pub fn find(path: []const u8) ?*const Page {
    for (all) |*p| if (std.mem.eql(u8, p.path, path)) return p;
    return null;
}

pub fn neighbours(page: *const Page) struct { ?*const Page, ?*const Page } {
    const i = (@intFromPtr(page) - @intFromPtr(all.ptr)) / @sizeOf(Page);
    return .{ if (i > 0) &all[i - 1] else null, if (i + 1 < all.len) &all[i + 1] else null };
}

pub const Hit = struct { path: []const u8, title: []const u8, snippet: []const u8, score: u8 };

/// Case-insensitive search over titles and text. Title matches rank first.
pub fn search(arena: std.mem.Allocator, q: []const u8, limit: usize) ![]Hit {
    if (q.len == 0) return &.{};
    var hits: std.ArrayList(Hit) = .empty;
    for (all) |p| {
        const in_title = std.ascii.findIgnoreCase(p.title, q) != null;
        const at = std.ascii.findIgnoreCase(p.md, q);
        if (!in_title and at == null) continue;
        try hits.append(arena, .{ .path = p.path, .title = p.title, .snippet = try snippet(arena, p.md, at orelse 0, q.len), .score = if (in_title) 2 else 1 });
    }
    std.mem.sort(Hit, hits.items, {}, struct {
        fn lt(_: void, a: Hit, b: Hit) bool {
            return a.score > b.score;
        }
    }.lt);
    return hits.items[0..@min(limit, hits.items.len)];
}

/// ~90 characters of plain text around the match, without Markdown markers.
fn snippet(arena: std.mem.Allocator, md: []const u8, at: usize, len: usize) ![]const u8 {
    const body = if (std.mem.cutScalar(u8, md, '\n')) |parts| parts[1] else "";
    const offset = md.len - body.len;
    const pos = if (at >= offset) at - offset else 0;
    var start = pos -| 40;
    var end = @min(body.len, pos + len + 50);
    // Never cut a UTF-8 sequence in half.
    // Start at a word, never inside one (or inside a UTF-8 sequence).
    if (start > 0) {
        while (start < pos and body[start - 1] != ' ' and body[start - 1] != '\n') start += 1;
    }
    while (end < body.len and body[end] & 0xC0 == 0x80) end += 1;
    var out: std.ArrayList(u8) = .empty;
    if (start > 0) try out.appendSlice(arena, "…");
    var space = false;
    for (body[start..end], start..) |ch, i| {
        if (std.mem.findScalar(u8, "#`*|>[]", ch) != null) continue;
        // List markers: "- " at the start of a line.
        if (ch == '-' and (i == 0 or body[i - 1] == '\n') and i + 1 < body.len and body[i + 1] == ' ') continue;
        const s = ch == '\n' or ch == ' ';
        if (s and space) continue;
        space = s;
        try out.append(arena, if (s) ' ' else ch);
    }
    if (end < body.len) try out.appendSlice(arena, "…");
    return out.items;
}

test "registry and search" {
    try std.testing.expectEqualStrings("Introduction", find("/").?.title);
    const prev, const next = neighbours(find("/").?);
    try std.testing.expect(prev == null and next != null);
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const hits = try search(arena.allocator(), "picker", 8);
    try std.testing.expectEqualStrings("/components/picker", hits[0].path);
    try std.testing.expectEqual(0, (try search(arena.allocator(), "zzzqqq", 8)).len);
}
