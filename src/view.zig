//! Svelte-style templates, compiled at comptime. Output is HTML-escaped by default.
//!
//!   {expr}                       escaped value (strings, numbers, bools, enums, optionals)
//!   {@html expr}                 raw value, no escaping
//!   {#if expr}..{:else}..{/if}   `!expr` negates; truthy = true, non-null, non-empty, non-zero
//!   {#each list as item}..{/each}       also `{#each list as item, i}`
//!   {{                           literal `{`
//!
//! `expr` is a variable path: `title`, `todo.done`, `todos.len`.
//! A value with a `render(self, *Writer)` method (e.g. `view(...)`) is written raw: components.
const std = @import("std");
const Writer = std.Io.Writer;
const eql = std.mem.eql;

/// A template bound to data. Pass it as a value to another template to nest it.
pub fn View(comptime src: []const u8, comptime Data: type) type {
    return struct {
        data: Data,
        pub fn render(self: @This(), w: *Writer) Writer.Error!void {
            try block(src, self.data, w);
        }
    };
}

pub fn view(comptime src: []const u8, data: anytype) View(src, @TypeOf(data)) {
    return .{ .data = data };
}

/// Builds a props struct `T` from an anonymous struct, using `T`'s defaults for missing fields.
/// Missing required props and unknown (misspelled) props are compile errors.
pub fn props(comptime T: type, p: anytype) T {
    const P = @TypeOf(p);
    inline for (@typeInfo(P).@"struct".field_names) |n| {
        if (!@hasField(T, n)) @compileError("unknown prop '" ++ n ++ "' for " ++ @typeName(T));
    }
    var out: T = undefined;
    const info = @typeInfo(T).@"struct";
    inline for (info.field_names, info.field_types, info.field_attrs) |n, F, attrs| {
        if (@hasField(P, n)) {
            @field(out, n) = @field(p, n);
        } else if (comptime attrs.defaultValue(F)) |d| {
            @field(out, n) = d;
        } else @compileError("missing prop '" ++ n ++ "' for " ++ @typeName(T));
    }
    return out;
}

/// Renders `component(item)` for every item: `zw.each(todos, todoRow)`.
pub fn each(items: anytype, comptime component: anytype) Each(@TypeOf(items), component) {
    return .{ .items = items };
}

pub fn Each(comptime Items: type, comptime component: anytype) type {
    return struct {
        items: Items,
        pub fn render(self: @This(), w: *Writer) Writer.Error!void {
            for (self.items) |item| try component(item).render(w);
        }
    };
}

pub fn render(w: *Writer, comptime src: []const u8, data: anytype) Writer.Error!void {
    try block(src, data, w);
}

fn block(comptime src: []const u8, scope: anytype, w: *Writer) Writer.Error!void {
    @setEvalBranchQuota(1_000_000);
    comptime var i = 0;
    inline while (i < src.len) {
        const open = comptime std.mem.findScalarPos(u8, src, i, '{') orelse src.len;
        if (open > i) try w.writeAll(src[i..open]);
        if (open == src.len) break;
        if (open + 1 < src.len and src[open + 1] == '{') {
            try w.writeByte('{');
            i = open + 2;
            continue;
        }
        const close = comptime tagEnd(src, open);
        const tag = comptime std.mem.trim(u8, src[open + 1 .. close], " \t\r\n");
        if (comptime std.mem.cutPrefix(u8, tag, "#each ")) |args| {
            const end = comptime matching(src, close + 1, "/each");
            const list_expr, const binding = comptime std.mem.cut(u8, args, " as ") orelse
                @compileError("template: expected {#each list as item}, got {" ++ tag ++ "}");
            const item_name, const index_name = comptime splitBinding(binding);
            const body = src[close + 1 .. end.open];
            for (get(scope, comptime trim(list_expr)), 0..) |item, idx| {
                const s: Scope(@TypeOf(scope), item_name, @TypeOf(item)) = .{ .parent = scope, .value = item };
                if (index_name) |n| {
                    try block(body, Scope(@TypeOf(s), n, usize){ .parent = s, .value = idx }, w);
                } else try block(body, s, w);
            }
            i = end.close + 1;
        } else if (comptime std.mem.cutPrefix(u8, tag, "#if ")) |cond| {
            const end = comptime matching(src, close + 1, "/if");
            const yes = src[close + 1 .. end.open];
            const parts = comptime splitElse(yes);
            const c = comptime trim(cond);
            const negate = c[0] == '!';
            if (truthy(get(scope, comptime trim(if (negate) c[1..] else c))) != negate) {
                try block(parts[0], scope, w);
            } else {
                try block(parts[1], scope, w);
            }
            i = end.close + 1;
        } else if (comptime std.mem.cutPrefix(u8, tag, "@html ")) |expr| {
            try write(w, get(scope, comptime trim(expr)), false);
            i = close + 1;
        } else if (tag.len > 0 and (tag[0] == '/' or tag[0] == ':' or tag[0] == '#' or tag[0] == '@')) {
            @compileError("template: unexpected {" ++ tag ++ "}");
        } else {
            try write(w, get(scope, tag), true);
            i = close + 1;
        }
    }
}

fn trim(comptime s: []const u8) []const u8 {
    return std.mem.trim(u8, s, " \t\r\n");
}

fn tagEnd(comptime src: []const u8, comptime open: usize) usize {
    return std.mem.findScalarPos(u8, src, open, '}') orelse
        @compileError("template: unclosed '{' at byte " ++ std.fmt.comptimePrint("{d}", .{open}));
}

fn splitBinding(comptime b: []const u8) struct { []const u8, ?[]const u8 } {
    if (std.mem.cutScalar(u8, b, ',')) |pair| return .{ trim(pair[0]), trim(pair[1]) };
    return .{ trim(b), null };
}

const Span = struct { open: usize, close: usize };

/// Finds the closing tag (e.g. `/each`) that matches the block starting at `from`.
fn matching(comptime src: []const u8, comptime from: usize, comptime close_tag: []const u8) Span {
    var depth: usize = 0;
    var i = from;
    while (std.mem.findScalarPos(u8, src, i, '{')) |open| {
        if (open + 1 < src.len and src[open + 1] == '{') {
            i = open + 2;
            continue;
        }
        const close = tagEnd(src, open);
        const tag = trim(src[open + 1 .. close]);
        if (tag.len > 0 and tag[0] == '#') depth += 1;
        if (tag.len > 0 and tag[0] == '/') {
            if (depth == 0) {
                if (!eql(u8, tag, close_tag)) @compileError("template: expected {" ++ close_tag ++ "}, got {" ++ tag ++ "}");
                return .{ .open = open, .close = close };
            }
            depth -= 1;
        }
        i = close + 1;
    }
    @compileError("template: missing {" ++ close_tag ++ "}");
}

/// Splits an if-body at its top-level `{:else}`.
fn splitElse(comptime body: []const u8) [2][]const u8 {
    var depth: usize = 0;
    var i = 0;
    while (std.mem.findScalarPos(u8, body, i, '{')) |open| {
        if (open + 1 < body.len and body[open + 1] == '{') {
            i = open + 2;
            continue;
        }
        const close = tagEnd(body, open);
        const tag = trim(body[open + 1 .. close]);
        if (tag.len > 0 and tag[0] == '#') depth += 1;
        if (tag.len > 0 and tag[0] == '/') depth -= 1;
        if (depth == 0 and eql(u8, tag, ":else")) return .{ body[0..open], body[close + 1 ..] };
        i = close + 1;
    }
    return .{ body, "" };
}

// Scopes: the root is the user's data struct; each `{#each}` pushes one binding.
fn Scope(comptime P: type, comptime n: []const u8, comptime T: type) type {
    return struct {
        parent: P,
        value: T,
        pub const zw_name = n;
        pub const Parent = P;
        pub const Value = T;
    };
}

fn VarT(comptime S: type, comptime name: []const u8) type {
    if (@hasDecl(S, "zw_name")) return if (eql(u8, S.zw_name, name)) S.Value else VarT(S.Parent, name);
    if (!@hasField(S, name)) @compileError("template: unknown variable '" ++ name ++ "'");
    return @FieldType(S, name);
}

fn getVar(scope: anytype, comptime name: []const u8) VarT(@TypeOf(scope), name) {
    const S = @TypeOf(scope);
    if (@hasDecl(S, "zw_name")) {
        if (comptime eql(u8, S.zw_name, name)) return scope.value;
        return getVar(scope.parent, name);
    }
    return @field(scope, name);
}

fn PathT(comptime T: type, comptime rest: []const u8) type {
    if (rest.len == 0) return T;
    const head, const tail = std.mem.cutScalar(u8, rest, '.') orelse .{ rest, "" };
    return PathT(@TypeOf(@field(@as(T, undefined), head)), tail);
}

fn GetT(comptime S: type, comptime path: []const u8) type {
    const head, const tail = std.mem.cutScalar(u8, path, '.') orelse .{ path, "" };
    return PathT(VarT(S, head), tail);
}

fn get(scope: anytype, comptime path: []const u8) GetT(@TypeOf(scope), path) {
    const head, const tail = comptime std.mem.cutScalar(u8, path, '.') orelse .{ path, "" };
    return field(getVar(scope, head), tail);
}

fn field(v: anytype, comptime rest: []const u8) PathT(@TypeOf(v), rest) {
    if (rest.len == 0) return v;
    const head, const tail = comptime std.mem.cutScalar(u8, rest, '.') orelse .{ rest, "" };
    return field(@field(v, head), tail);
}

fn isString(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .pointer => |p| switch (p.size) {
            .slice => p.child == u8,
            .one => switch (@typeInfo(p.child)) {
                .array => |a| a.child == u8,
                else => false,
            },
            else => false,
        },
        else => false,
    };
}

fn truthy(v: anytype) bool {
    const T = @TypeOf(v);
    return switch (@typeInfo(T)) {
        .bool => v,
        .optional => v != null,
        .null => false,
        .int, .comptime_int => v != 0,
        .pointer => |p| if (p.size == .slice or @typeInfo(p.child) == .array) v.len > 0 else true,
        else => @compileError("template: cannot test " ++ @typeName(T) ++ " in {#if}"),
    };
}

fn write(w: *Writer, v: anytype, escape: bool) Writer.Error!void {
    const T = @TypeOf(v);
    if (comptime isString(T)) return if (escape) writeEscaped(w, v) else w.writeAll(v);
    switch (@typeInfo(T)) {
        .@"struct", .@"union" => if (@hasDecl(T, "render")) return v.render(w),
        .optional => return if (v) |x| write(w, x, escape),
        .null => return,
        .int, .comptime_int, .float, .comptime_float => return w.print("{d}", .{v}),
        .bool => return w.writeAll(if (v) "true" else "false"),
        .@"enum", .enum_literal => return w.writeAll(@tagName(v)),
        else => {},
    }
    @compileError("template: cannot print " ++ @typeName(T) ++ " (give it a render(self, *Writer) method)");
}

pub fn writeEscaped(w: *Writer, s: []const u8) Writer.Error!void {
    var start: usize = 0;
    for (s, 0..) |c, i| {
        const rep: []const u8 = switch (c) {
            '&' => "&amp;",
            '<' => "&lt;",
            '>' => "&gt;",
            '"' => "&quot;",
            '\'' => "&#39;",
            else => continue,
        };
        try w.writeAll(s[start..i]);
        try w.writeAll(rep);
        start = i + 1;
    }
    try w.writeAll(s[start..]);
}

fn expectRender(expected: []const u8, comptime src: []const u8, data: anytype) !void {
    var buf: [1024]u8 = undefined;
    var w: Writer = .fixed(&buf);
    try render(&w, src, data);
    try std.testing.expectEqualStrings(expected, w.buffered());
}

test "values and escaping" {
    try expectRender("<b>a &lt;i&gt; &amp; &quot;q&quot;</b> 3 true", "<b>{s}</b> {n} {ok}", .{ .s = "a <i> & \"q\"", .n = 3, .ok = true });
    try expectRender("<i>x</i>", "{@html s}", .{ .s = "<i>x</i>" });
    try expectRender("a { b", "a {{ b", .{});
    try expectRender("", "{x}", .{ .x = @as(?[]const u8, null) });
}

test "each, if, else, nesting, components" {
    const Todo = struct { title: []const u8, done: bool };
    const todos: []const Todo = &.{ .{ .title = "a", .done = true }, .{ .title = "<b>", .done = false } };
    try expectRender(
        "[0:a✓][1:&lt;b&gt;·]2",
        "{#each todos as t, i}[{i}:{t.title}{#if t.done}✓{:else}·{/if}]{/each}{todos.len}",
        .{ .todos = todos },
    );
    try expectRender("none", "{#if !todos}none{:else}some{/if}", .{ .todos = @as([]const Todo, &.{}) });
    const inner = view("<p>{name}</p>", .{ .name = "x&y" });
    try expectRender("<main><p>x&amp;y</p></main>", "<main>{body}</main>", .{ .body = inner });
    // outer variables stay visible inside loops; nested ifs inside each
    try expectRender("k:a k:b ", "{#each xs as x}{#if x}{p}:{x} {/if}{/each}", .{ .xs = @as([]const []const u8, &.{ "a", "", "b" }), .p = "k" });
}
