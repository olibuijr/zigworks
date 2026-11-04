//! Live demos for docs/pages/components/avatar.md (```demo avatar``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "avatar", true, avatar },
    .{ "avatar-variants", true, variants },
    .{ "avatar-states", true, states },
    .{ "avatar-live", true, live },
    .{ "avatar-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-avatar-who{display:flex;flex-direction:column;min-width:0;
    \\& strong,& small{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    \\& strong{font-weight:600}
    \\& small{font:var(--callout);color:var(--secondary)}}
    \\.demo-avatar-meta{display:flex;flex-direction:column;align-items:flex-end;gap:4px;flex:none;
    \\& small{font:var(--callout);color:var(--secondary)}}
    \\.demo-avatar-cap{font:var(--callout);font-weight:600;color:var(--secondary)}
    \\.demo-avatar-grid{display:flex;flex-wrap:wrap;align-items:flex-start;gap:16px 20px}
    \\.demo-avatar-cell{display:flex;flex-direction:column;align-items:center;gap:8px;max-width:104px;text-align:center;
    \\& code{white-space:normal;overflow-wrap:anywhere}}
    \\.demo-avatar-preview{display:flex;flex-wrap:wrap;align-items:center;gap:12px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/avatar/x", handler }`.
pub const routes = .{
    .{ "POST /demo/avatar/status", status },
    .{ "GET /demo/avatar/preview", preview },
    .{ "POST /demo/avatar/invite", invite },
};

const A = @TypeOf(ui.avatar(.{ .name = "" }));

/// A drawn "photo" (a silhouette on a flat color), so the demos need no image files.
fn photo(comptime color: []const u8) []const u8 {
    return "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' fill='%23" ++ color ++
        "'/%3E%3Ccircle cx='32' cy='25' r='11' fill='%23fff' fill-opacity='.85'/%3E%3Cpath d='M11 64c2-15 11-21 21-21s19 6 21 21z' fill='%23fff' fill-opacity='.85'/%3E%3C/svg%3E";
}

// Hero: a Messages-style conversation list.
const Convo = zw.View(
    \\<li>{face}<span class="zw-grow demo-avatar-who"><strong>{name}</strong><small>{text}</small></span><span class="demo-avatar-meta"><small>{time}</small>{unread}</span></li>
, struct { face: A, name: []const u8, text: []const u8, time: []const u8, unread: @TypeOf(ui.badge(.{})) });

fn convo(face: A, name: []const u8, text: []const u8, time: []const u8, unread: u32) Convo {
    return .{ .data = .{
        .face = face,
        .name = name,
        .text = text,
        .time = time,
        .unread = ui.badge(.{ .count = unread, .hide_zero = true, .tone = .red, .solid = true, .size = .small }),
    } };
}

fn avatar(w: *Writer) Writer.Error!void {
    try ui.list(.{
        .id = "demo-avatar-chats",
        .header = "Messages",
        .footer = "The dot shows who is around. A photo replaces the initials.",
        .separators = .full,
        .body = zw.view("{a}{b}{c}{d}{e}", .{
            .a = convo(ui.avatar(.{ .name = "Ada Lovelace", .size = 40, .status = .online }), "Ada Lovelace", "Sent the notes for the engine.", "9:41", 2),
            .b = convo(ui.avatar(.{ .name = "Design Team", .size = 40, .shape = .rounded, .hue = 280 }), "Design Team", "Grace: Lunch at noon?", "9:12", 0),
            .c = convo(ui.avatar(.{ .name = "Grace Hopper", .size = 40, .status = .away }), "Grace Hopper", "Found the bug. It was a moth.", "Yesterday", 0),
            .d = convo(ui.avatar(.{ .name = "Alan Turing", .size = 40, .status = .busy, .src = photo("5b8def") }), "Alan Turing", "In a meeting until 3.", "Yesterday", 0),
            .e = convo(ui.avatar(.{ .name = "Margaret Hamilton", .size = 40, .status = .offline }), "Margaret Hamilton", "See you at the launch review.", "Tuesday", 0),
        }),
    }).render(w);
}

// Variants and sizes: every cell is labelled with the prop that makes it.
const Cell = zw.View(
    \\<div class="demo-avatar-cell">{face}<code>{prop}</code></div>
, struct { face: A, prop: []const u8 });

fn cell(face: A, prop: []const u8) Cell {
    return .{ .data = .{ .face = face, .prop = prop } };
}

fn variants(w: *Writer) Writer.Error!void {
    try w.writeAll("<p class=\"demo-avatar-cap\">Size</p><div class=\"demo-avatar-grid\">");
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 24 }), ".size = 24").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace" }), ".size = 32 (default)").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 44 }), ".size = 44").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 64 }), ".size = 64").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 96 }), ".size = 96").render(w);

    try w.writeAll("</div><p class=\"demo-avatar-cap\">Shape</p><div class=\"demo-avatar-grid\">");
    try cell(ui.avatar(.{ .name = "Grace Hopper", .size = 56 }), ".shape = .circle").render(w);
    try cell(ui.avatar(.{ .name = "Zig Software Foundation", .size = 56, .shape = .rounded }), ".shape = .rounded").render(w);

    try w.writeAll("</div><p class=\"demo-avatar-cap\">Color</p><div class=\"demo-avatar-grid\">");
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 56 }), "from the name").render(w);
    try cell(ui.avatar(.{ .name = "Grace Hopper", .size = 56 }), "from the name").render(w);
    try cell(ui.avatar(.{ .name = "Grace Hopper", .size = 56, .hue = 25 }), ".hue = 25").render(w);
    try cell(ui.avatar(.{ .name = "Grace Hopper", .size = 56, .hue = 145 }), ".hue = 145").render(w);
    try cell(ui.avatar(.{ .name = "Grace Hopper", .size = 56, .hue = 265 }), ".hue = 265").render(w);

    try w.writeAll("</div><p class=\"demo-avatar-cap\">Content</p><div class=\"demo-avatar-grid\">");
    try cell(ui.avatar(.{ .name = "Alan Turing", .size = 56 }), "initials").render(w);
    try cell(ui.avatar(.{ .name = "Alan Turing", .size = 56, .src = photo("e0a050") }), ".src").render(w);
    try cell(ui.avatar(.{ .name = "Zig Software Foundation", .size = 56, .shape = .rounded, .src = photo("4cb782") }), ".src, .rounded").render(w);
    try cell(ui.avatar(.{ .name = "", .size = 56, .more = 5 }), ".more = 5").render(w);
    try w.writeAll("</div>");
}

// States: presence, images that load or fail, loading, initials rules, overflow.
fn states(w: *Writer) Writer.Error!void {
    try w.writeAll("<p class=\"demo-avatar-cap\">Presence</p><div class=\"demo-avatar-grid\">");
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 56 }), ".none").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 56, .status = .online }), ".online").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 56, .status = .away }), ".away").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 56, .status = .busy }), ".busy").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 56, .status = .offline }), ".offline").render(w);
    try cell(ui.avatar(.{ .name = "Ada Lovelace", .size = 56, .shape = .rounded, .status = .online }), ".rounded + .online").render(w);

    try w.writeAll("</div><p class=\"demo-avatar-cap\">Image</p><div class=\"demo-avatar-grid\">");
    try cell(ui.avatar(.{ .name = "Grace Hopper", .size = 56, .src = photo("5b8def"), .status = .online }), "loaded").render(w);
    try cell(ui.avatar(.{ .name = "Grace Hopper", .size = 56, .src = "/demo/avatar/missing.jpg" }), "fails: initials stay").render(w);
    try w.writeAll("<div class=\"demo-avatar-cell\">");
    try ui.skeleton(.{ .shape = .circle, .size = 56, .label = "Loading photo" }).render(w);
    try w.writeAll("<code>loading: skeleton</code></div></div>");

    try w.writeAll("<p class=\"demo-avatar-cap\">Initials</p><div class=\"demo-avatar-grid\">");
    try cell(ui.avatar(.{ .name = "Plato", .size = 56 }), "one word").render(w);
    try cell(ui.avatar(.{ .name = "Ásta Sigurðardóttir", .size = 56 }), "first two words").render(w);
    try cell(ui.avatar(.{ .name = "Ada King Lovelace", .size = 56 }), "third word ignored").render(w);

    try w.writeAll("</div><p class=\"demo-avatar-cap\">Stack and overflow</p><div class=\"demo-avatar-grid\">");
    try ui.avatar(.{ .name = "", .size = 56, .more = 3 }).render(w);
    try zw.view("<div class=\"zw-avatars\">{a}{b}{c}{d}</div>", .{
        .a = ui.avatar(.{ .name = "Ada Lovelace", .size = 40 }),
        .b = ui.avatar(.{ .name = "Grace Hopper", .size = 40 }),
        .c = ui.avatar(.{ .name = "Alan Turing", .size = 40, .src = photo("e0a050") }),
        .d = ui.avatar(.{ .name = "", .size = 40, .more = 12 }),
    }).render(w);
    try w.writeAll("</div>");
}

// Live: presence and a name preview, both answered by the server.
const me_name = "Ada Lovelace";

const Me = zw.View(
    \\{face}<span class="zw-grow demo-avatar-who"><strong>{name}</strong><small>{label}</small></span>
, struct { face: A, name: []const u8, label: []const u8 });

fn me(face: A, label: []const u8) Me {
    return .{ .data = .{ .face = face, .name = me_name, .label = label } };
}

fn setStatus(c: *zw.Ctx, label: []const u8, face: A) !void {
    const text = try std.fmt.allocPrint(c.arena, "Status: {s}", .{label});
    try c.page(zw.view("{m}{t}", .{ .m = me(face, label), .t = ui.toast(.{ .text = text }) }));
}

fn status(c: *zw.Ctx) !void {
    const s = c.form("demo-avatar-status") orelse "online";
    if (std.mem.eql(u8, s, "away")) return setStatus(c, "Away", ui.avatar(.{ .name = me_name, .size = 56, .status = .away }));
    if (std.mem.eql(u8, s, "busy")) return setStatus(c, "Do Not Disturb", ui.avatar(.{ .name = me_name, .size = 56, .status = .busy }));
    if (std.mem.eql(u8, s, "offline")) return setStatus(c, "Appear Offline", ui.avatar(.{ .name = me_name, .size = 56, .status = .offline }));
    try setStatus(c, "Available", ui.avatar(.{ .name = me_name, .size = 56, .status = .online }));
}

const Preview = zw.View("{a}{b}{c}", struct { a: A, b: A, c: A });

fn previewOf(name: []const u8) Preview {
    return .{ .data = .{
        .a = ui.avatar(.{ .name = name, .size = 64 }),
        .b = ui.avatar(.{ .name = name, .size = 40, .shape = .rounded }),
        .c = ui.avatar(.{ .name = name, .size = 24 }),
    } };
}

fn preview(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.query("demo-avatar-name") orelse "", " ");
    if (name.len > 160) return c.send(.no_content, "text/plain", "");
    if (name.len == 0) return c.page(zw.view("<span class=\"zw-secondary\">Type a name to see its avatar.</span>", .{}));
    try c.page(previewOf(name));
}

fn live(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Your status",
        .subtitle = "Pick one: the avatar and a toast answer from the server.",
        .body = zw.view("<div class=\"zw-stack\"><div class=\"zw-row\" id=\"demo-avatar-me\">{me}</div>{seg}</div>", .{
            .me = me(ui.avatar(.{ .name = me_name, .size = 56, .status = .online }), "Available"),
            .seg = ui.segmented(.{
                .name = "demo-avatar-status",
                .label = "Status",
                .full = true,
                .z = .{ .post = "/demo/avatar/status", .target = "#demo-avatar-me", .swap = .inner },
                .options = &.{
                    .{ .value = "online", .label = "Online", .selected = true },
                    .{ .value = "away", .label = "Away" },
                    .{ .value = "busy", .label = "Busy" },
                    .{ .value = "offline", .label = "Offline" },
                },
            }),
        }),
    }).render(w);
    try ui.card(.{
        .title = "Try a name",
        .subtitle = "Initials come from the first two words. The color comes from the whole name.",
        .body = zw.view("<div class=\"zw-stack\">{f}<div class=\"demo-avatar-preview\" id=\"demo-avatar-preview\">{p}</div></div>", .{
            .f = ui.field(.{
                .name = "demo-avatar-name",
                .label = "Name",
                .value = "Katherine Johnson",
                .placeholder = "Type a name",
                .maxlength = 40,
                .z = .{ .get = "/demo/avatar/preview", .trigger = "input", .target = "#demo-avatar-preview", .swap = .inner },
            }),
            .p = previewOf("Katherine Johnson"),
        }),
    }).render(w);
}

// Compose: a share list where avatars sit next to a field, text, a badge and buttons.
const Member = zw.View(
    \\<li>{face}<span class="zw-grow demo-avatar-who"><strong>{name}</strong><small>{role}</small></span>{#if owner}{badge}{:else}{remove}{/if}</li>
, struct { face: A, name: []const u8, role: []const u8, owner: bool, badge: @TypeOf(ui.badge(.{})), remove: ui.Button });

fn member(face: A, name: []const u8, role: []const u8, owner: bool) Member {
    return .{ .data = .{
        .face = face,
        .name = name,
        .role = role,
        .owner = owner,
        .badge = ui.badge(.{ .text = "Owner", .tone = .accent }),
        .remove = ui.button(.{ .label = "Remove", .variant = .destructive, .size = .small, .z = .{ .delete = "/demo/todo", .target = "closest li", .swap = .delete } }),
    } };
}

fn invite(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("demo-avatar-invitee") orelse "", " ");
    if (name.len == 0 or name.len > 160) return c.send(.no_content, "text/plain", "");
    try c.page(member(ui.avatar(.{ .name = name, .size = 36 }), name, "Can view", false));
}

fn compose(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Share Project Apollo",
        .subtitle = "Invite someone by name: they join the list below.",
        .body = zw.view("<div class=\"zw-stack\"><form class=\"zw-row\"{z}>{f}{b}</form>{l}</div>", .{
            .z = ui.Z{ .post = "/demo/avatar/invite", .target = "#demo-avatar-members", .swap = .beforeend },
            .f = ui.field(.{ .name = "demo-avatar-invitee", .label = "Name", .placeholder = "Add a name", .required = true, .maxlength = 40 }),
            .b = ui.button(.{ .label = "Invite", .variant = .primary, .type = .submit }),
            .l = ui.list(.{
                .id = "demo-avatar-members",
                .empty = "Only you have access.",
                .inset = false,
                .separators = .full,
                .body = zw.view("{a}{b}{c}", .{
                    .a = member(ui.avatar(.{ .name = "Ada Lovelace", .size = 36, .status = .online }), "Ada Lovelace", "ada@example.com", true),
                    .b = member(ui.avatar(.{ .name = "Grace Hopper", .size = 36, .status = .away, .src = photo("5b8def") }), "Grace Hopper", "Can edit", false),
                    .c = member(ui.avatar(.{ .name = "Alan Turing", .size = 36 }), "Alan Turing", "Can view", false),
                }),
            }),
        }),
    }).render(w);
}
