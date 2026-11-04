//! Live demos for docs/pages/components/search.md (```demo search``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "search", true, search },
    .{ "search-sizes", true, sizes },
    .{ "search-states", true, states },
    .{ "search-quick", false, quick },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-search-window{background:var(--content);border-radius:var(--radius);box-shadow:var(--shadow)}
    \\.demo-search-bar{display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:8px 12px;padding:10px 12px;border-bottom:1px solid var(--separator);
    \\& .zw-search{flex:1 1 200px;max-width:280px}}
    \\.demo-search-title{display:flex;align-items:center;gap:8px;font:var(--headline)}
    \\.demo-search-note{min-height:230px;padding:16px;
    \\& h3{font:var(--headline)}
    \\&>*+*{margin-top:8px}}
    \\.demo-search-row{display:flex;flex-wrap:wrap;align-items:center;gap:6px 16px;
    \\& code{flex:0 0 18ch}
    \\& .zw-search{flex:1 1 220px}}
    \\.demo-search-meta{flex:none;font:var(--callout);color:var(--secondary)}
    \\.demo-search-quick .zw-search{width:100%}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/search/x", handler }`.
pub const routes = .{
    .{ "GET /demo/search/notes", notesFind },
    .{ "GET /demo/search/note", noteOpen },
    .{ "GET /demo/search/find", quickFind },
    .{ "GET /demo/search/pick", pick },
};

const Note = struct { id: usize, title: []const u8, folder: []const u8, body: []const u8 };

const notes = [_]Note{
    .{ .id = 0, .title = "Weekend groceries", .folder = "Personal", .body = "Oat milk, lemons, basil, sourdough and a bag of coffee." },
    .{ .id = 1, .title = "Lemon pasta", .folder = "Recipes", .body = "Zest two lemons, toss with butter, parmesan and plenty of pepper." },
    .{ .id = 2, .title = "Reykjavik trip", .folder = "Travel", .body = "Flights on Friday, hotel near the harbour, a car for the Golden Circle." },
    .{ .id = 3, .title = "Q3 planning", .folder = "Work", .body = "Agree the roadmap, book the offsite and review the hiring plan." },
    .{ .id = 4, .title = "Sprint retro", .folder = "Work", .body = "Keep short standups. Try demo Fridays. Stop late scope changes." },
    .{ .id = 5, .title = "Reading list", .folder = "Personal", .body = "Notes on the Analytical Engine by Ada Lovelace, then Godel, Escher, Bach." },
    .{ .id = 6, .title = "Packing checklist", .folder = "Travel", .body = "Passport, charger, rain jacket, camera and a good book." },
    .{ .id = 7, .title = "Birthday ideas", .folder = "Personal", .body = "Dinner at home, a long hike and a photo album for Mum." },
};

/// The notes of `pool` whose title, folder or text contain `q` (any case), copied into `out`.
fn matches(out: *[notes.len]Note, pool: []const Note, q: []const u8) []const Note {
    var n: usize = 0;
    for (pool) |note| {
        if (std.ascii.findIgnoreCase(note.title, q) != null or
            std.ascii.findIgnoreCase(note.folder, q) != null or
            std.ascii.findIgnoreCase(note.body, q) != null)
        {
            out[n] = note;
            n += 1;
        }
    }
    return out[0..n];
}

/// What the request asked for. `?q=` (or `?term=`) is the query, `?min=` the shortest query
/// that searches, `?in=archive` searches an empty archive.
const Found = struct { q: []const u8, hits: []const Note, miss: bool };

fn lookup(c: *zw.Ctx, buf: *[notes.len]Note) Found {
    const q = std.mem.trim(u8, c.query("q") orelse c.query("term") orelse "", " ");
    const min = std.fmt.parseInt(usize, c.query("min") orelse "1", 10) catch 1;
    const pool: []const Note = if (std.mem.eql(u8, c.query("in") orelse "", "archive")) &.{} else &notes;
    const searching = q.len > 0 and q.len >= min;
    return .{ .q = q, .hits = if (searching) matches(buf, pool, q) else &.{}, .miss = searching };
}

/// One link per hit. A click asks `open` for the note and puts the answer in `target`.
const links = "{#each hits as h}<a href=\"#\" z-get=\"{open}?id={h.id}\" z-target=\"{target}\" z-swap=\"{swap}\">{h.title}<small>{h.folder} · {h.body}</small></a>{/each}" ++
    "{#if !hits}{#if miss}<p>No results for “{q}”.</p>{/if}{/if}";

/// Hero: live results, plus the match count in the title bar as an out-of-band badge.
fn notesFind(c: *zw.Ctx) !void {
    var buf: [notes.len]Note = undefined;
    const f = lookup(c, &buf);
    try c.html(links ++ "{count}", .{
        .hits = f.hits,
        .miss = f.miss,
        .q = f.q,
        .open = "/demo/search/note",
        .target = "#demo-search-note",
        .swap = "inner",
        .count = ui.badge(.{ .id = "demo-search-count", .oob = true, .tone = .accent, .count = @as(u32, @intCast(if (f.q.len == 0) notes.len else f.hits.len)) }),
    });
}

/// Opens a note in the hero window and empties the results panel (out-of-band) so it closes.
fn noteOpen(c: *zw.Ctx) !void {
    const id = std.fmt.parseInt(usize, c.query("id") orelse "", 10) catch return c.send(.bad_request, "text/plain", "bad id");
    if (id >= notes.len) return c.send(.bad_request, "text/plain", "bad id");
    try c.html(
        "<h3>{n.title}</h3><p>{folder}</p><p>{n.body}</p>" ++
            "<div class=\"zw-results zw-glass\" id=\"demo-search-notes\" aria-live=\"polite\" z-oob></div>",
        .{ .n = notes[id], .folder = ui.badge(.{ .text = notes[id].folder, .tone = .accent }) },
    );
}

/// Results for the other demos: a click shows a toast.
fn quickFind(c: *zw.Ctx) !void {
    var buf: [notes.len]Note = undefined;
    const f = lookup(c, &buf);
    try c.html(links, .{ .hits = f.hits, .miss = f.miss, .q = f.q, .open = "/demo/search/pick", .target = "body", .swap = "none" });
}

fn pick(c: *zw.Ctx) !void {
    const id = std.fmt.parseInt(usize, c.query("id") orelse "", 10) catch return c.send(.bad_request, "text/plain", "bad id");
    if (id >= notes.len) return c.send(.bad_request, "text/plain", "bad id");
    const text = try std.fmt.allocPrint(c.arena, "Opened “{s}”", .{notes[id].title});
    try c.page(ui.toast(.{ .text = text, .kind = .success }));
}

fn search(w: *Writer) Writer.Error!void {
    try zw.view(
        "<div class=\"demo-search-window\"><div class=\"demo-search-bar\"><span class=\"demo-search-title\">Notes {count}</span>{field}</div>" ++
            "<div class=\"demo-search-note\" id=\"demo-search-note\">{empty}</div></div>",
        .{
            .count = ui.badge(.{ .id = "demo-search-count", .tone = .accent, .count = notes.len }),
            .field = ui.search(.{
                .action = "/demo/search/notes",
                .id = "demo-search-notes",
                .label = "Search notes",
                .placeholder = "Search",
                .shortcut = "k",
            }),
            .empty = ui.empty(.{ .size = .compact, .title = "No note open", .text = "Search for “lemon”, “flights” or “retro”, then pick a result." }),
        },
    ).render(w);
}

fn sizes(w: *Writer) Writer.Error!void {
    try zw.view(
        "<div class=\"demo-search-row\"><code>size = .small</code>{a}</div>" ++
            "<div class=\"demo-search-row\"><code>size = .regular</code>{b}</div>" ++
            "<div class=\"demo-search-row\"><code>size = .large</code>{c}</div>" ++
            "<div class=\"demo-search-row\"><code>clear = false</code>{e}</div>" ++
            "<div class=\"demo-search-row\"><code>shortcut = \"j\"</code>{f}</div>" ++
            "<div class=\"demo-search-row\"><code>platform = .pc</code>{g}</div>",
        .{
            .a = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-small", .label = "Search (small)", .placeholder = "Small, 24px", .size = .small }),
            .b = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-regular", .label = "Search (regular)", .placeholder = "Regular, 30px" }),
            .c = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-large", .label = "Search (large)", .placeholder = "Large, 36px", .size = .large }),
            .e = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-noclear", .label = "Search (no clear button)", .placeholder = "Type, no clear button", .clear = false }),
            .f = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-hint", .label = "Search (shortcut)", .placeholder = "Search", .shortcut = "j" }),
            .g = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-pc", .label = "Search (Ctrl hint)", .placeholder = "Search", .shortcut = "y", .platform = .pc }),
        },
    ).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    // A results page: the field starts with the query that produced the list below it.
    var buf: [notes.len]Note = undefined;
    const lemon = matches(&buf, &notes, "lemon");
    try zw.view(
        "<div class=\"demo-search-row\"><code>value = \"lemon\"</code>{a}</div>" ++
            "{list}" ++
            "<div class=\"demo-search-row\"><code>min_length = 3</code>{b}</div>" ++
            "<div class=\"demo-search-row\"><code>no matches</code>{c}</div>" ++
            "<div class=\"demo-search-row\"><code>disabled = true</code>{d}</div>" ++
            "<div class=\"demo-search-row\"><code>readonly = true</code>{e}</div>" ++
            "<div class=\"demo-search-row\"><code>invalid = true</code>{f}</div>",
        .{
            .a = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-prefilled", .name = "term", .value = "lemon", .label = "Search notes", .placeholder = "Search notes" }),
            .list = ui.list(.{
                .id = "demo-search-page",
                .header = "Results for “lemon”",
                .body = zw.view("{#each hits as h}<li><span class=\"zw-grow\">{h.title}</span><span class=\"demo-search-meta\">{h.folder}</span></li>{/each}", .{ .hits = lemon }),
            }),
            .b = ui.search(.{ .action = "/demo/search/find?min=3", .id = "demo-search-min", .label = "Search (three letters)", .placeholder = "Type at least 3 letters", .min_length = 3 }),
            .c = ui.search(.{ .action = "/demo/search/find?in=archive", .id = "demo-search-archive", .label = "Search the archive", .placeholder = "Search the archive" }),
            .d = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-disabled", .label = "Search (disabled)", .placeholder = "Search is unavailable", .disabled = true }),
            .e = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-readonly", .label = "Search (read only)", .value = "lemon", .readonly = true }),
            .f = ui.search(.{ .action = "/demo/search/find", .id = "demo-search-invalid", .label = "Search (invalid)", .placeholder = "Search", .value = "??", .invalid = true }),
        },
    ).render(w);
}

fn quick(w: *Writer) Writer.Error!void {
    try zw.view("{open}{sheet}", .{
        .open = ui.button(.{ .label = "Quick Open…", .opens = "demo-search-sheet" }),
        .sheet = ui.sheet(.{
            .id = "demo-search-sheet",
            .title = "Quick Open",
            .description = "Type a few letters, then pick a note.",
            .size = .small,
            .close = true,
            .body = zw.view("<div class=\"demo-search-quick\">{field}</div>", .{
                .field = ui.search(.{
                    .action = "/demo/search/find",
                    .id = "demo-search-quick-results",
                    .label = "Quick open",
                    .placeholder = "Open note",
                    .clear = false,
                    .autofocus = true,
                    .inline_results = true,
                }),
            }),
        }),
    }).render(w);
}
