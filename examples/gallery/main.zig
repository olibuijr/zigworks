//! Component gallery, laid out as a real preferences window so every ui component is seen in context.
//! Run `zig build gallery`, open http://127.0.0.1:8080 (or this machine's LAN address). Changes post back and are logged.
const std = @import("std");
const zw = @import("zigworks");
const ui = zw.ui;

const app = .{
    .routes = .{
        .{ "GET /", index },
        .{ "POST /pref", pref },
        .{ "POST /account", saveAccount },
        .{ "GET /activity", activity },
        .{ "DELETE /tag", untag },
    },
    .css = css,
};

const css =
    \\.actions{display:flex;justify-content:flex-end;gap:8px}
    \\.who{display:flex;align-items:center;gap:12px}
    \\.who b{display:block;font:var(--headline)}
    \\.who small{color:var(--secondary);font:var(--callout)}
    \\
;

pub fn main(init: std.process.Init) !void {
    try zw.serve(init, app, .{});
}

fn pref(c: *zw.Ctx) !void {
    std.log.info("pref {s}", .{c.body});
    try c.send(.no_content, "text/plain", "");
}

const save: ui.Z = .{ .post = "/pref", .swap = .none };

fn saveAccount(c: *zw.Ctx) !void {
    std.log.info("account {s}", .{c.body});
    try c.page(ui.toast(.{ .text = "Account saved", .kind = .success }));
}

fn untag(c: *zw.Ctx) !void {
    try c.send(.ok, "text/html; charset=utf-8", ""); // empty 200: z.js removes the tag
}

// Loaded by the Activity card's skeleton (z-trigger=load); the pause shows the skeleton.
fn activity(c: *zw.Ctx) !void {
    c.io.sleep(.fromMilliseconds(600), .awake) catch {};
    try c.page(ui.list(.{ .id = "activity", .body = zw.view("{a}{b}", .{ .a = event("Ada Lovelace", "shared “Groceries”"), .b = event("Grace Hopper", "completed 3 reminders") }) }));
}

fn event(who: []const u8, what: []const u8) zw.View("<li>{a}<span><b>{who}</b> {what}</span></li>", struct { a: ui.Avatar, who: []const u8, what: []const u8 }) {
    return .{ .data = .{ .a = ui.avatar(.{ .name = who, .size = 28 }), .who = who, .what = what } };
}

fn index(c: *zw.Ctx) !void {
    const general = ui.card(.{ .title = "General", .body = zw.view("{a}{b}", .{
        .a = ui.toggle(.{ .name = "login", .label = "Open at login", .on = true, .z = save }),
        .b = ui.toggle(.{ .name = "menubar", .label = "Show in menu bar", .z = save }),
    }) });

    const appearance = ui.card(.{ .title = "Appearance", .body = zw.view("{theme}{accent}{size}", .{
        .theme = ui.setting(.{ .label = "Theme", .control = ui.segmented(.{ .name = "theme", .label = "Theme", .z = save, .options = &.{
            .{ .value = "light", .label = "Light" },
            .{ .value = "dark", .label = "Dark" },
            .{ .value = "auto", .label = "Auto", .selected = true },
        } }) }),
        .accent = ui.setting(.{ .label = "Accent", .control = ui.picker(.{ .id = "accent", .name = "accent", .label = "Accent color", .z = save, .options = &.{
            .{ .value = "blue", .label = "Blue", .selected = true },
            .{ .value = "purple", .label = "Purple" },
            .{ .value = "graphite", .label = "Graphite" },
        } }) }),
        .size = ui.setting(.{ .label = "Text size", .control = ui.slider(.{ .name = "size", .label = "Text size", .min = 10, .max = 20, .value = 13, .z = save }) }),
    }) });

    const account = ui.card(.{ .title = "Account", .body = zw.view(
        \\<form class="zw-stack"{z}><div class="who">{avatar}<div><b>Ada Lovelace</b><small>ada@example.com</small></div></div>{email}{bio}
        \\<div class="zw-tags">{t1}{t2}{t3}</div>{news}<div class="actions">{cancel}{ok}</div></form>
    , .{
        .z = ui.Z{ .post = "/account", .swap = .none, .keep = true },
        .avatar = ui.avatar(.{ .name = "Ada Lovelace", .size = 44 }),
        .email = ui.field(.{ .name = "email", .label = "Email", .placeholder = "name@example.com", .type = "email" }),
        .bio = ui.textarea(.{ .name = "bio", .label = "About", .placeholder = "A few words about you" }),
        .t1 = ui.tag(.{ .text = "mathematics" }),
        .t2 = ui.tag(.{ .text = "engines", .remove = .{ .delete = "/tag" } }),
        .t3 = ui.tag(.{ .text = "poetry", .remove = .{ .delete = "/tag" } }),
        .news = ui.checkbox(.{ .name = "news", .label = "Email me product news" }),
        .cancel = ui.button(.{ .label = "Sign Out", .variant = .destructive }),
        .ok = ui.button(.{ .label = "Save", .variant = .primary, .type = .submit }),
    }) });

    const storage = ui.card(.{ .title = "Storage", .body = zw.view(
        \\<div class="zw-stack"><div><p class="zw-row" style="margin-bottom:8px"><span class="zw-grow">Macintosh HD</span><span class="zw-secondary">41.2 GB of 64 GB used</span></p>{bar}</div>{table}<p class="zw-row">{spin}<span class="zw-secondary">Calculating System Data…</span></p>{tip}</div>
    , .{
        .bar = ui.progress(.{ .value = 64, .label = "41.2 GB of 64 GB used" }),
        .table = ui.table(.{ .head = &.{ "Category", "Size" }, .rows = &.{
            &.{ "Applications", "18.4 GB" },
            &.{ "Documents", "12.9 GB" },
            &.{ "Photos", "9.9 GB" },
        } }),
        .spin = ui.progress(.{ .value = null, .label = "Calculating" }),
        .tip = ui.callout(.{ .kind = .tip, .title = "Tip", .body = "Empty the Trash to free 2.1 GB." }),
    }) });

    const developer = ui.card(.{ .title = "Developer", .body = zw.view("<div class=\"zw-stack\">{path}{code}{help}</div>", .{
        .path = ui.path(.{ .items = &.{ .{ .label = "zigworks", .href = "/" }, .{ .label = "examples", .href = "/" }, .{ .label = "gallery" } } }),
        .code = ui.code(.{ .lang = "sh", .src = "zig build gallery" }),
        .help = ui.disclosure(.{ .title = "Keyboard shortcuts", .body = zw.view(
            \\<div class="zw-stack" style="gap:8px"><div class="zw-row"><span class="zw-grow">New list</span>{a}</div><div class="zw-row"><span class="zw-grow">Search</span>{b}</div></div>
        , .{ .a = ui.kbd(.{ .keys = "⌘ N" }), .b = ui.kbd(.{ .keys = "⌘ F" }) }) }),
    }) });

    const printing = ui.card(.{ .title = "Printing", .body = ui.tabs(.{ .id = "print", .labels = &.{ "Copies", "Layout", "Shared" }, .panels = .{
        zw.view("{copies}{both}", .{
            .copies = ui.setting(.{ .label = "Copies", .control = ui.stepper(.{ .name = "copies", .label = "Copies", .value = 1, .min = 1, .max = 99, .z = save }) }),
            .both = ui.toggle(.{ .name = "duplex", .label = "Print on both sides", .z = save }),
        }),
        ui.radio(.{ .name = "orientation", .label = "Orientation", .z = save, .options = &.{
            .{ .value = "portrait", .label = "Portrait", .selected = true },
            .{ .value = "landscape", .label = "Landscape" },
        } }),
        ui.empty(.{ .title = "No shared printers", .text = "Printers shared on your network show up here." }),
    } }) });

    const recent = ui.card(.{ .title = "Activity", .body = zw.view("<div z-get=\"/activity\" z-trigger=\"load\" z-swap=\"outer\">{s}</div>", .{ .s = ui.skeleton(.{ .lines = 2, .label = "Loading activity" }) }) });

    const reminders = ui.list(.{ .id = "reminders", .body = zw.view("{a}{b}{c}", .{
        .a = item(true, "Renew domain"),
        .b = item(false, "Ship zigworks 0.2"),
        .c = item(false, "Write release notes"),
    }) });

    const new_list = ui.sheet(.{ .id = "new-list", .title = "New List", .body = zw.view("<form{z}>{name}<div class=\"zw-sheet-actions\">{cancel}{create}</div></form>", .{
        .z = save,
        .name = ui.field(.{ .name = "list", .label = "List name", .placeholder = "List name", .required = true }),
        .cancel = ui.button(.{ .label = "Cancel", .opens = "new-list" }),
        .create = ui.button(.{ .label = "Create", .variant = .primary, .type = .submit }),
    }) });

    const actions = ui.menu(.{ .id = "more", .items = &.{
        .{ .label = "Duplicate", .z = save },
        .{ .label = "Export…", .z = save },
        .{ .label = "Delete All", .z = save, .destructive = true, .separated = true },
    } });

    try c.page(ui.layout(.{
        .title = "Preferences",
        .toolbar = zw.view("{badge}{more}{menu}{add}{sheet}", .{
            .badge = ui.badge(.{ .text = "2 due" }),
            .more = ui.tooltip(.{ .text = "More actions", .side = .below, .body = ui.button(.{ .label = "•••", .aria = "More actions", .variant = .plain, .opens = "more" }) }),
            .menu = actions,
            .add = ui.button(.{ .label = "New List", .variant = .primary, .opens = "new-list" }),
            .sheet = new_list,
        }),
        .body = zw.view("<div class=\"zw-stack\">{general}{appearance}{account}{printing}{storage}{recent}{developer}{reminders}</div>", .{
            .printing = printing,
            .recent = recent,
            .general = general,
            .appearance = appearance,
            .account = account,
            .storage = storage,
            .developer = developer,
            .reminders = reminders,
        }),
    }));
}

fn item(done: bool, title: []const u8) zw.View("<li>{check}<span>{title}</span></li>", struct { check: ui.Check, title: []const u8 }) {
    return .{ .data = .{ .check = ui.check(.{ .on = done, .label = title }), .title = title } };
}
