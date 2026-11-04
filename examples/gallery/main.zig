//! Component gallery, laid out as a real preferences window so every ui component is seen in context.
//! Run `zig build gallery`, open http://127.0.0.1:8080. Changes post back and are logged.
const std = @import("std");
const zw = @import("zigworks");
const ui = zw.ui;

const app = .{
    .routes = .{
        .{ "GET /", index },
        .{ "POST /pref", pref },
    },
    .css = css,
};

const css =
    \\.actions{display:flex;justify-content:flex-end;gap:8px}
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

    const account = ui.card(.{ .title = "Account", .body = zw.view("<form class=\"zw-stack\"{z}>{email}<div class=\"actions\">{cancel}{ok}</div></form>", .{
        .z = save,
        .email = ui.field(.{ .name = "email", .label = "Email", .placeholder = "name@example.com", .type = "email" }),
        .cancel = ui.button(.{ .label = "Sign Out", .variant = .destructive }),
        .ok = ui.button(.{ .label = "Save", .variant = .primary, .type = .submit }),
    }) });

    const reminders = ui.list(.{ .id = "reminders", .body = zw.view("{a}{b}{c}", .{
        .a = item(true, "Renew domain"),
        .b = item(false, "Ship zigworks 0.1"),
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
            .more = ui.button(.{ .label = "•••", .aria = "More actions", .variant = .plain, .opens = "more" }),
            .menu = actions,
            .add = ui.button(.{ .label = "New List", .variant = .primary, .opens = "new-list" }),
            .sheet = new_list,
        }),
        .body = zw.view("<div class=\"zw-stack\">{general}{appearance}{account}{reminders}</div>", .{
            .general = general,
            .appearance = appearance,
            .account = account,
            .reminders = reminders,
        }),
    }));
}

fn item(done: bool, title: []const u8) zw.View("<li>{check}<span>{title}</span></li>", struct { check: ui.Check, title: []const u8 }) {
    return .{ .data = .{ .check = ui.check(.{ .on = done, .label = title }), .title = title } };
}
