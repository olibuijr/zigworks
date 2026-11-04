//! Live demos for docs/pages/components/skeleton.md (```demo skeleton``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "skeleton", true, skeleton },
    .{ "skeleton-shapes", true, shapes },
    .{ "skeleton-states", true, states },
    .{ "skeleton-notes", true, notesDemo },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-skeleton-load{display:contents}
    \\.demo-skeleton-rows{display:flex;flex-direction:column;gap:12px;padding:6px 12px}
    \\.demo-skeleton-text{display:flex;flex-direction:column;min-width:0}
    \\.demo-skeleton-text span,.demo-skeleton-time{font:var(--callout);color:var(--secondary)}
    \\.demo-skeleton-text span{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    \\.demo-skeleton-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,210px),1fr));gap:12px;width:100%}
    \\.demo-skeleton-grid .zw-card{min-width:0}
    \\.demo-skeleton-albums{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:12px;margin-top:12px}
    \\.demo-skeleton-album{display:flex;flex-direction:column;gap:6px;min-width:0}
    \\.demo-skeleton-album strong{font-weight:600}
    \\.demo-skeleton-album span{font:var(--callout);color:var(--secondary)}
    \\.demo-skeleton-cover{height:96px;border-radius:var(--radius-control);background:color-mix(in srgb,var(--accent) var(--m,20%),var(--fill))}
    \\.demo-skeleton-album:nth-child(2) .demo-skeleton-cover{--m:35%}
    \\.demo-skeleton-album:nth-child(3) .demo-skeleton-cover{--m:50%}
    \\.demo-skeleton-album:nth-child(4) .demo-skeleton-cover{--m:12%}
    \\.demo-skeleton-notes{display:grid;grid-template-columns:minmax(0,220px) minmax(0,1fr);gap:12px;width:100%;align-items:start}
    \\.demo-skeleton-pane{min-height:200px}
    \\@media (max-width:599px){.demo-skeleton-notes{grid-template-columns:minmax(0,1fr)}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/skeleton/x", handler }`.
pub const routes = .{
    .{ "GET /demo/skeleton/inbox", inbox },
    .{ "GET /demo/skeleton/albums", albumStage },
    .{ "GET /demo/skeleton/note", note },
};

// ---- Hero: an inbox that loads itself, and reloads on Refresh ----

const Mail = struct { from: []const u8, subject: []const u8, time: []const u8 };
const mails = [_]Mail{
    .{ .from = "Ada Lovelace", .subject = "Notes on the Analytical Engine", .time = "9:41" },
    .{ .from = "Grace Hopper", .subject = "Found a moth in the relay", .time = "8:15" },
    .{ .from = "Alan Turing", .subject = "Re: Halting problem draft", .time = "Yesterday" },
};

const MailRow = zw.View(
    "<li>{avatar}<div class=\"zw-grow demo-skeleton-text\"><strong>{from}</strong><span>{subject}</span></div><time class=\"demo-skeleton-time\">{time}</time></li>",
    struct { avatar: ui.Avatar, from: []const u8, subject: []const u8, time: []const u8 },
);

fn mailRow(m: Mail) MailRow {
    return .{ .data = .{ .avatar = ui.avatar(.{ .name = m.from, .size = 36 }), .from = m.from, .subject = m.subject, .time = m.time } };
}

/// Three message-shaped skeletons. The wrapper asks for the real list as soon as it is on the
/// page and swaps it in for itself.
const InboxLoading = struct {
    pub fn render(_: InboxLoading, w: *Writer) Writer.Error!void {
        try w.writeAll("<div class=\"demo-skeleton-load\" z-get=\"/demo/skeleton/inbox\" z-trigger=\"load\" z-target=\"#demo-skeleton-inbox\" z-swap=\"inner\"><div class=\"demo-skeleton-rows\">");
        for (0..3) |_| try ui.skeleton(.{ .shape = .media, .lines = 2, .size = 36, .label = "Loading message" }).render(w);
        try w.writeAll("</div></div>");
    }
};

/// `GET /demo/skeleton/inbox?loading=1` answers the skeleton at once; without it the list
/// arrives after a short wait, like a slow network.
fn inbox(c: *zw.Ctx) !void {
    if (c.query("loading") != null) return c.page(InboxLoading{});
    try c.io.sleep(.fromMilliseconds(900), .awake);
    try c.page(ui.list(.{ .id = "demo-skeleton-mail", .inset = false, .body = zw.each(&mails, mailRow) }));
}

fn skeleton(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Inbox",
        .subtitle = "iCloud",
        .accessory = ui.button(.{ .label = "Refresh", .variant = .plain, .z = .{ .get = "/demo/skeleton/inbox?loading=1", .target = "#demo-skeleton-inbox", .swap = .inner } }),
        .body = zw.view("<div id=\"demo-skeleton-inbox\">{loading}</div>", .{ .loading = InboxLoading{} }),
    }).render(w);
}

// ---- Shapes and sizes ----

fn shapes(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-skeleton-grid\">{a}{b}{c}{d}{e}{f}{g}</div>", .{
        .a = ui.card(.{ .title = "Lines", .subtitle = "default: .lines = 3", .body = ui.skeleton(.{ .label = "Loading text" }) }),
        .b = ui.card(.{ .title = "Short last line", .subtitle = ".lines = 2, .last_width = 30", .body = ui.skeleton(.{ .lines = 2, .last_width = 30 }) }),
        .c = ui.card(.{ .title = "Single line", .subtitle = ".lines = 1", .body = ui.skeleton(.{ .lines = 1 }) }),
        .d = ui.card(.{ .title = "Block", .subtitle = ".shape = .block, .height = \"96px\"", .body = ui.skeleton(.{ .shape = .block, .height = "96px", .label = "Loading photo" }) }),
        .e = ui.card(.{
            .title = "Circle",
            .subtitle = ".shape = .circle, .size = 24, 32, 48, 64",
            .body = zw.view("<div class=\"zw-row\">{a}{b}{c}{d}</div>", .{
                .a = ui.skeleton(.{ .shape = .circle, .size = 24, .label = "Loading avatar" }),
                .b = ui.skeleton(.{ .shape = .circle, .size = 32, .label = "Loading avatar" }),
                .c = ui.skeleton(.{ .shape = .circle, .size = 48, .label = "Loading avatar" }),
                .d = ui.skeleton(.{ .shape = .circle, .size = 64, .label = "Loading avatar" }),
            }),
        }),
        .f = ui.card(.{ .title = "Media", .subtitle = ".shape = .media, .lines = 2, .size = 44", .body = ui.skeleton(.{ .shape = .media, .lines = 2, .size = 44, .label = "Loading contact" }) }),
        .g = ui.card(.{ .title = "Compact media", .subtitle = ".shape = .media, .lines = 1, .size = 28", .body = ui.skeleton(.{ .shape = .media, .lines = 1, .size = 28, .label = "Loading contact" }) }),
    }).render(w);
}

// ---- States: loading, still, loaded, empty ----

const Album = struct { title: []const u8, count: []const u8 };
const album_list = [_]Album{
    .{ .title = "Iceland", .count = "128 photos" },
    .{ .title = "Family", .count = "64 photos" },
    .{ .title = "Screenshots", .count = "412 photos" },
    .{ .title = "Recents", .count = "9 photos" },
};

/// The album grid in one of four states (`loading`, `still`, `loaded`, `empty`).
const Stage = struct {
    state: []const u8,
    pub fn render(self: Stage, w: *Writer) Writer.Error!void {
        const is = std.mem.eql;
        if (is(u8, self.state, "empty")) return ui.empty(.{
            .icon = "🖼",
            .title = "No Albums",
            .text = "Albums you create show up here.",
            .size = .compact,
            .action = ui.button(.{ .label = "New Album", .variant = .primary, .z = d.save }),
        }).render(w);
        try w.writeAll("<div class=\"demo-skeleton-albums\">");
        if (is(u8, self.state, "loaded")) {
            for (album_list) |a| try zw.view(
                "<div class=\"demo-skeleton-album\"><div class=\"demo-skeleton-cover\"></div><strong>{title}</strong><span>{count}</span></div>",
                .{ .title = a.title, .count = a.count },
            ).render(w);
        } else {
            const shimmer = !is(u8, self.state, "still");
            for (album_list) |_| {
                try w.writeAll("<div class=\"demo-skeleton-album\">");
                try ui.skeleton(.{ .shape = .block, .height = "96px", .label = "Loading album", .shimmer = shimmer }).render(w);
                try ui.skeleton(.{ .lines = 2, .last_width = 55, .label = "Loading album name", .shimmer = shimmer }).render(w);
                try w.writeAll("</div>");
            }
        }
        try w.writeAll("</div>");
    }
};

/// `GET /demo/skeleton/albums?state=loaded`: the stage for the chosen state.
fn albumStage(c: *zw.Ctx) !void {
    try c.page(Stage{ .state = c.query("state") orelse "loading" });
}

fn states(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Photos",
        .subtitle = "Pick a state",
        .body = zw.view("{seg}<div id=\"demo-skeleton-stage\">{stage}</div>", .{
            .seg = ui.segmented(.{
                .name = "state",
                .label = "State",
                .full = true,
                .z = .{ .get = "/demo/skeleton/albums", .target = "#demo-skeleton-stage", .swap = .inner },
                .options = &.{
                    .{ .value = "loading", .label = "Loading", .selected = true },
                    .{ .value = "still", .label = "Still" },
                    .{ .value = "loaded", .label = "Loaded" },
                    .{ .value = "empty", .label = "Empty" },
                },
            }),
            .stage = Stage{ .state = "loading" },
        }),
    }).render(w);
}

// ---- Composition: a notes list whose pane shows a skeleton while the note loads ----

const Note = struct { title: []const u8, who: []const u8, when: []const u8, tag: []const u8, text: []const u8 };
const notes = [_]Note{
    .{ .title = "Trip itinerary", .who = "Ada Lovelace", .when = "Today, 10:12", .tag = "Travel", .text = "The flight lands at 14:20. Collect the keys from the front desk, then dinner at 19:30." },
    .{ .title = "Release checklist", .who = "Grace Hopper", .when = "Yesterday", .tag = "Work", .text = "Tag the build, update the changelog, and post the notes once the last test run is green." },
    .{ .title = "Reading list", .who = "Alan Turing", .when = "Monday", .tag = "Personal", .text = "Three books to finish before the end of the month, starting with the shortest one." },
};

const NoteRow = zw.View(
    "<li><a href=\"#demo-skeleton-note\" z-get=\"/demo/skeleton/note?id={id}\" z-target=\"#demo-skeleton-note\" z-swap=\"inner\"><span class=\"zw-grow\">{title}</span></a></li>",
    struct { id: usize, title: []const u8 },
);

const NoteLoading = zw.View(
    "<div class=\"demo-skeleton-load\" z-get=\"/demo/skeleton/note?id={id}&amp;full=1\" z-trigger=\"load\" z-target=\"#demo-skeleton-note\" z-swap=\"inner\">" ++
        "<div class=\"zw-stack\">{head}{body}</div></div>",
    struct { id: usize, head: ui.Skeleton, body: ui.Skeleton },
);

const NoteBody = zw.View(
    "<article class=\"zw-stack\"><div class=\"zw-row\">{avatar}<div class=\"zw-grow demo-skeleton-text\"><strong>{who}</strong><span>{when}</span></div>{tag}</div><p>{text}</p></article>",
    struct { avatar: ui.Avatar, who: []const u8, when: []const u8, tag: ui.Badge, text: []const u8 },
);

/// `GET /demo/skeleton/note?id=1` answers the skeleton; the skeleton then asks for
/// `...&full=1`, which answers the note after a short wait.
fn note(c: *zw.Ctx) !void {
    const i = @min(std.fmt.parseInt(usize, c.query("id") orelse "0", 10) catch 0, notes.len - 1);
    if (c.query("full") == null) return c.page(NoteLoading{ .data = .{
        .id = i,
        .head = ui.skeleton(.{ .shape = .media, .lines = 2, .size = 40, .label = "Loading note" }),
        .body = ui.skeleton(.{ .lines = 4, .last_width = 45, .label = "Loading note text" }),
    } });
    try c.io.sleep(.fromMilliseconds(700), .awake);
    const n = notes[i];
    try c.page(NoteBody{ .data = .{
        .avatar = ui.avatar(.{ .name = n.who, .size = 40 }),
        .who = n.who,
        .when = n.when,
        .tag = ui.badge(.{ .text = n.tag, .tone = .accent }),
        .text = n.text,
    } });
}

const NoteRows = struct {
    pub fn render(_: NoteRows, w: *Writer) Writer.Error!void {
        for (notes, 0..) |n, i| try NoteRow.render(.{ .data = .{ .id = i, .title = n.title } }, w);
    }
};

fn notesDemo(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-skeleton-notes\">{list}{pane}</div>", .{
        .list = ui.list(.{ .id = "demo-skeleton-notelist", .header = "Notes", .nav = true, .body = NoteRows{} }),
        .pane = ui.card(.{
            .body = zw.view("<div id=\"demo-skeleton-note\" class=\"demo-skeleton-pane\">{empty}</div>", .{
                .empty = ui.empty(.{ .title = "No Note Selected", .text = "Choose a note from the list.", .size = .compact }),
            }),
        }),
    }).render(w);
}
