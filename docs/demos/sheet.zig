//! Live demos for docs/pages/components/sheet.md (```demo sheet``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "sheet", true, sheet },
    .{ "sheet-sizes", true, sizes },
    .{ "sheet-options", true, options },
    .{ "sheet-delete", true, delete },
    .{ "sheet-invite", true, invite },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-sheet-ico{flex:none;display:grid;place-items:center;width:28px;color:var(--accent);svg{width:22px;height:22px}}
    \\.demo-sheet-meta{font:var(--callout);color:var(--secondary);white-space:nowrap}
    \\.demo-sheet-who{display:flex;flex-direction:column;small{font:var(--callout);color:var(--secondary)}}
    \\.demo-sheet-cells{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:20px 16px;align-items:start}
    \\.demo-sheet-cell{display:flex;flex-direction:column;align-items:flex-start;gap:6px;min-width:0;small{font:var(--callout);color:var(--secondary)}}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/sheet/x", handler }`.
pub const routes = .{
    .{ "POST /demo/sheet/folder", folderAdd },
    .{ "DELETE /demo/sheet/project", projectDelete },
    .{ "POST /demo/sheet/restore", projectRestore },
    .{ "POST /demo/sheet/invite", inviteAdd },
};

const folder_icon = "<svg viewBox=\"0 0 24 24\" fill=\"currentColor\"><path d=\"M3 7a2 2 0 0 1 2-2h4.2a2 2 0 0 1 1.5.7l1 1.3H19a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z\"/></svg>";
const plus_icon = "<svg viewBox=\"0 0 18 18\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"1.6\" stroke-linecap=\"round\"><path d=\"M9 3.5v11M3.5 9h11\"/></svg>";

// Rows are rendered by the server too, so the page itself holds the state.
const folder_row = "<li><span class=\"demo-sheet-ico\" aria-hidden=\"true\">" ++ folder_icon ++ "</span><span class=\"zw-grow\">{name}</span><span class=\"demo-sheet-meta\">{meta}</span></li>";
const project_row = "<li id=\"demo-sheet-project\"><span class=\"demo-sheet-ico\" aria-hidden=\"true\">" ++ folder_icon ++ "</span><span class=\"zw-grow demo-sheet-who\">Archive 2026<small>12 items</small></span>{del}</li>";
const person_row = "<li>{avatar}<span class=\"zw-grow demo-sheet-who\">{name}<small>{role}</small></span></li>";
const cell = "<div class=\"demo-sheet-cell\">{b}<small>{@html note}</small></div>";

const delete_button = ui.button(.{ .label = "Delete…", .variant = .destructive, .opens = "demo-sheet-delete" });

/// Hero: a Finder-like folder list whose "New Folder…" sheet adds a row for real.
fn sheet(w: *Writer) Writer.Error!void {
    try zw.view("<div>{files}{new}</div>", .{
        .files = ui.card(.{
            .title = "Documents",
            .subtitle = "On My Mac",
            .flush = true,
            .accessory = ui.button(.{ .label = "New Folder…", .icon = plus_icon, .opens = "demo-sheet-new" }),
            .body = ui.list(.{ .id = "demo-sheet-files", .empty = "No folders yet", .body = zw.view("{a}{b}", .{
                .a = zw.view(folder_row, .{ .name = "Invoices", .meta = "3 items" }),
                .b = zw.view(folder_row, .{ .name = "Photos", .meta = "Yesterday" }),
            }) }),
        }),
        .new = ui.sheet(.{
            .id = "demo-sheet-new",
            .title = "New Folder",
            .description = "Name it now; you can rename it later.",
            .size = .small,
            .close = true,
            .body = zw.view("<form{z}>{f}<div class=\"zw-sheet-actions\">{c}{ok}</div></form>", .{
                .z = ui.Z{ .post = "/demo/sheet/folder", .target = "#demo-sheet-files", .swap = .beforeend },
                .f = ui.field(.{ .name = "name", .label = "Folder name", .placeholder = "Untitled Folder", .required = true, .maxlength = 40 }),
                .c = ui.button(.{ .label = "Cancel", .opens = "demo-sheet-new" }),
                .ok = ui.button(.{ .label = "Create", .variant = .primary, .type = .submit }),
            }),
        }),
    }).render(w);
}

/// `POST /demo/sheet/folder`: the new row, plus a toast.
fn folderAdd(c: *zw.Ctx) !void {
    const name = std.mem.trim(u8, c.form("name") orelse "", " ");
    if (name.len == 0 or name.len > 40) {
        return c.html("{t}", .{ .t = ui.toast(.{ .text = "A folder name needs 1 to 40 characters", .kind = .@"error" }) });
    }
    try c.html(folder_row ++ "{t}", .{
        .name = name,
        .meta = "Just now",
        .t = ui.toast(.{ .text = try c.arena.print("Created “{s}”", .{name}), .kind = .success }),
    });
}

/// The three widths, each with content that suits it.
fn sizes(w: *Writer) Writer.Error!void {
    try zw.view("<div><div class=\"demo-sheet-cells\">{a}{b}{c}</div>{s}{m}{l}</div>", .{
        .a = zw.view(cell, .{ .b = ui.button(.{ .label = "Small", .opens = "demo-sheet-small" }), .note = "<code>.small</code> · 360 px" }),
        .b = zw.view(cell, .{ .b = ui.button(.{ .label = "Medium", .opens = "demo-sheet-medium" }), .note = "<code>.medium</code> · 480 px, the default" }),
        .c = zw.view(cell, .{ .b = ui.button(.{ .label = "Large", .opens = "demo-sheet-large" }), .note = "<code>.large</code> · 640 px" }),
        .s = ui.sheet(.{
            .id = "demo-sheet-small",
            .title = "Empty Trash?",
            .size = .small,
            .body = zw.view("<p>12 items will be deleted for good.</p>", .{}),
            .footer = zw.view("{a}{b}", .{
                .a = ui.button(.{ .label = "Cancel", .opens = "demo-sheet-small" }),
                .b = ui.button(.{ .label = "Empty Trash", .variant = .destructive, .z = d.save }),
            }),
        }),
        .m = ui.sheet(.{
            .id = "demo-sheet-medium",
            .title = "Share Link",
            .description = "Anyone with the link can view this folder.",
            .body = ui.field(.{ .name = "link", .label = "Link", .value = "https://zigworks.dev/share/k7Qx2p", .readonly = true }),
            .footer = ui.button(.{ .label = "Done", .variant = .primary, .opens = "demo-sheet-medium" }),
        }),
        .l = ui.sheet(.{
            .id = "demo-sheet-large",
            .title = "Keyboard Shortcuts",
            .description = "Wide sheets suit lists and previews.",
            .size = .large,
            .body = ui.list(.{ .id = "demo-sheet-keys", .body = zw.view("<li><span class=\"zw-grow\">Show Sidebar</span>{a}</li><li><span class=\"zw-grow\">New Folder</span>{b}</li><li><span class=\"zw-grow\">Move to Trash</span>{c}</li>", .{
                .a = ui.kbd(.{ .keys = "⌘ B" }),
                .b = ui.kbd(.{ .keys = "⌘ ⇧ N" }),
                .c = ui.kbd(.{ .keys = "⌘ ⌫" }),
            }) }),
            .footer = ui.button(.{ .label = "Done", .variant = .primary, .opens = "demo-sheet-large" }),
        }),
    }).render(w);
}

/// close, close_label, focus_first and a body in an error state.
fn options(w: *Writer) Writer.Error!void {
    try zw.view("<div><div class=\"demo-sheet-cells\">{a}{b}{c}{d}{e}</div>{s1}{s2}{s3}{s4}{s5}</div>", .{
        .a = zw.view(cell, .{ .b = ui.button(.{ .label = "Close button", .opens = "demo-sheet-close" }), .note = "<code>close = true</code>" }),
        .b = zw.view(cell, .{ .b = ui.button(.{ .label = "Own label", .opens = "demo-sheet-label" }), .note = "<code>close_label = \"Loka\"</code>" }),
        .c = zw.view(cell, .{ .b = ui.button(.{ .label = "Focus the field", .opens = "demo-sheet-focus" }), .note = "<code>focus_first = true</code> (default)" }),
        .d = zw.view(cell, .{ .b = ui.button(.{ .label = "Keep focus here", .opens = "demo-sheet-nofocus" }), .note = "<code>focus_first = false</code>" }),
        .e = zw.view(cell, .{ .b = ui.button(.{ .label = "Invalid body", .opens = "demo-sheet-invalid" }), .note = "An error and a disabled action in the body" }),
        .s1 = ui.sheet(.{
            .id = "demo-sheet-close",
            .title = "Software Update",
            .description = "Version 2.4 is ready to install.",
            .close = true,
            .body = zw.view("<p>Installing takes about 15 minutes. Your Mac restarts once.</p>", .{}),
            .footer = zw.view("{a}{b}", .{
                .a = ui.button(.{ .label = "Later", .opens = "demo-sheet-close" }),
                .b = ui.button(.{ .label = "Install Now", .variant = .primary, .z = d.save }),
            }),
        }),
        .s2 = ui.sheet(.{
            .id = "demo-sheet-label",
            .title = "Ný skilaboð",
            .close = true,
            .close_label = "Loka",
            .body = zw.view("<p>Screen readers announce the close button as “Loka”.</p>", .{}),
        }),
        .s3 = ui.sheet(.{
            .id = "demo-sheet-focus",
            .title = "Add Email",
            .description = "The cursor is already in the field.",
            .size = .small,
            .body = ui.field(.{ .name = "focus-email", .label = "Email", .type = "email", .placeholder = "name@example.com", .autocomplete = "email" }),
            .footer = ui.button(.{ .label = "Done", .variant = .primary, .opens = "demo-sheet-focus" }),
        }),
        .s4 = ui.sheet(.{
            .id = "demo-sheet-nofocus",
            .title = "Add Email",
            .description = "Focus stays on the button until you click the field.",
            .size = .small,
            .focus_first = false,
            .body = ui.field(.{ .name = "nofocus-email", .label = "Email", .type = "email", .placeholder = "name@example.com", .autocomplete = "email" }),
            .footer = ui.button(.{ .label = "Done", .variant = .primary, .opens = "demo-sheet-nofocus" }),
        }),
        .s5 = ui.sheet(.{
            .id = "demo-sheet-invalid",
            .title = "Choose a Username",
            .description = "Usernames are public.",
            .size = .small,
            .body = ui.field(.{ .name = "username", .label = "Username", .value = "ada", .invalid = "That username is taken.", .maxlength = 20 }),
            .footer = zw.view("{a}{b}", .{
                .a = ui.button(.{ .label = "Cancel", .opens = "demo-sheet-invalid" }),
                .b = ui.button(.{ .label = "Continue", .variant = .primary, .disabled = true }),
            }),
        }),
    }).render(w);
}

/// A destructive confirmation: the footer button sends the request and the sheet closes itself.
fn delete(w: *Writer) Writer.Error!void {
    try zw.view("<div>{card}{confirm}</div>", .{
        .card = ui.card(.{
            .title = "Projects",
            .flush = true,
            .body = ui.list(.{ .id = "demo-sheet-projects", .empty = "No projects", .body = zw.view(project_row, .{ .del = delete_button }) }),
        }),
        .confirm = ui.sheet(.{
            .id = "demo-sheet-delete",
            .title = "Delete “Archive 2026”?",
            .description = "This removes 12 items and cannot be undone.",
            .size = .small,
            .body = zw.view("<p>Collaborators lose access straight away.</p>", .{}),
            .footer = zw.view("{a}{b}", .{
                .a = ui.button(.{ .label = "Cancel", .opens = "demo-sheet-delete" }),
                .b = ui.button(.{ .label = "Delete", .variant = .destructive, .z = .{ .delete = "/demo/sheet/project", .target = "#demo-sheet-project", .swap = .delete } }),
            }),
        }),
    }).render(w);
}

/// `DELETE /demo/sheet/project`: z.js removes the row; the toast offers to bring it back.
fn projectDelete(c: *zw.Ctx) !void {
    try c.html("{t}", .{ .t = ui.toast(.{
        .text = "Archive 2026 deleted",
        .action = "Undo",
        .z = .{ .post = "/demo/sheet/restore", .target = "#demo-sheet-projects", .swap = .beforeend },
        .sticky = true,
    }) });
}

/// `POST /demo/sheet/restore`: the row again.
fn projectRestore(c: *zw.Ctx) !void {
    try c.html(project_row, .{ .del = delete_button });
}

/// Composition: card, badge, list, avatar, segmented, toggle and toast around one sheet.
fn invite(w: *Writer) Writer.Error!void {
    try zw.view("<div>{team}{sheet}</div>", .{
        .team = ui.card(.{
            .title = "Project Team",
            .flush = true,
            .accessory = zw.view("{count}{open}", .{
                .count = ui.badge(.{ .id = "demo-sheet-count", .count = 2 }),
                .open = ui.button(.{ .label = "Invite…", .opens = "demo-sheet-invite" }),
            }),
            .body = ui.list(.{ .id = "demo-sheet-people", .body = zw.view("{a}{b}", .{
                .a = zw.view(person_row, .{ .avatar = ui.avatar(.{ .name = "Ada Lovelace" }), .name = "Ada Lovelace", .role = "Owner" }),
                .b = zw.view(person_row, .{ .avatar = ui.avatar(.{ .name = "Grace Hopper" }), .name = "Grace Hopper", .role = "Can edit" }),
            }) }),
        }),
        .sheet = ui.sheet(.{
            .id = "demo-sheet-invite",
            .title = "Invite People",
            .description = "They get access as soon as you invite them.",
            .close = true,
            .body = zw.view("<form{z}><div class=\"zw-stack\">{email}{role}{notify}</div><input type=\"hidden\" id=\"demo-sheet-n\" name=\"n\" value=\"2\"><div class=\"zw-sheet-actions\">{c}{ok}</div></form>", .{
                .z = ui.Z{ .post = "/demo/sheet/invite", .target = "#demo-sheet-people", .swap = .beforeend },
                .email = ui.field(.{ .name = "email", .label = "Email address", .type = "email", .placeholder = "name@example.com", .autocomplete = "email", .required = true }),
                .role = ui.segmented(.{ .name = "role", .label = "Permission", .full = true, .options = &.{
                    .{ .value = "view", .label = "Can view", .selected = true },
                    .{ .value = "edit", .label = "Can edit" },
                } }),
                .notify = ui.toggle(.{ .name = "notify", .label = "Send an email invitation", .on = true }),
                .c = ui.button(.{ .label = "Cancel", .opens = "demo-sheet-invite" }),
                .ok = ui.button(.{ .label = "Invite", .variant = .primary, .type = .submit }),
            }),
        }),
    }).render(w);
}

/// `POST /demo/sheet/invite`: a person row, the new head count (badge and hidden field, out of
/// band) and a toast. The count travels in the form, so the server keeps nothing.
fn inviteAdd(c: *zw.Ctx) !void {
    const email = std.mem.trim(u8, c.form("email") orelse "", " ");
    if (email.len > 80 or std.mem.findScalar(u8, email, '@') == null) {
        return c.html("{t}", .{ .t = ui.toast(.{ .text = "Enter a valid email address", .kind = .@"error" }) });
    }
    const n = (std.fmt.parseInt(u32, c.form("n") orelse "2", 10) catch 2) +| 1;
    const edit = std.mem.eql(u8, c.form("role") orelse "view", "edit");
    const text = if (c.form("notify") != null)
        try c.arena.print("Invitation sent to {s}", .{email})
    else
        try c.arena.print("Added {s}", .{email});
    try c.html(person_row ++ "{count}{n}{t}", .{
        .avatar = ui.avatar(.{ .name = email }),
        .name = email,
        .role = if (edit) "Can edit" else "Can view",
        .count = ui.badge(.{ .id = "demo-sheet-count", .oob = true, .count = n }),
        .n = zw.view("<input type=\"hidden\" id=\"demo-sheet-n\" name=\"n\" value=\"{n}\" z-oob>", .{ .n = n }),
        .t = ui.toast(.{ .text = text, .kind = .success }),
    });
}
