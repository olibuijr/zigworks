//! Live demos for docs/pages/components/field.md (```demo field``` fences).
const std = @import("std");
const Writer = std.Io.Writer;
const zw = @import("zigworks");
const ui = zw.ui;
const d = @import("demo.zig");

/// Fence name, block layout (stacked) or inline (wrapping row), render function.
pub const demos = [_]d.Demo{
    .{ "field", true, field },
    .{ "field-types", true, types },
    .{ "field-states", true, states },
    .{ "field-live", true, live },
    .{ "field-validate", true, validate },
    .{ "field-compose", true, compose },
};
/// Extra CSS for these demos (scope it under a demo-specific class).
pub const css =
    \\.demo-field-pair{display:flex;flex-wrap:wrap;gap:12px;
    \\& .zw-field{flex:1 1 140px}}
    \\.demo-field-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(min(100%,230px),1fr));gap:18px 16px}
    \\.demo-field-cap{margin:0 0 6px 2px;font:var(--callout);color:var(--secondary)}
    \\.demo-field-out{display:block;margin:8px 11px 0;font:var(--callout);color:var(--secondary);font-variant-numeric:tabular-nums}
    \\.demo-field-tags{margin-top:12px}
    \\
;
/// Server routes these demos need, e.g. `.{ "POST /demo/field/x", handler }`.
pub const routes = .{
    .{ "GET /demo/field/handle", handle },
    .{ "GET /demo/field/tip", tip },
    .{ "GET /demo/field/signup", signupReset },
    .{ "POST /demo/field/signup", signup },
    .{ "POST /demo/field/invite", invite },
    .{ "DELETE /demo/field/invite", inviteRemove },
};

// Hero: a New Contact form. Values stay after Save (keep), nothing is stored.
const keep: ui.Z = .{ .post = "/demo", .swap = .none, .keep = true };

fn field(w: *Writer) Writer.Error!void {
    try zw.view("<form{z}>{card}</form>", .{
        .z = keep,
        .card = ui.card(.{
            .title = "New Contact",
            .subtitle = "Saved to iCloud",
            .body = zw.view("<div class=\"zw-stack\"><div class=\"demo-field-pair\">{a}{b}</div>{c}{e}{f}</div>", .{
                .a = ui.field(.{ .name = "demo-field-first", .label = "First name", .placeholder = "First name", .value = "Ada", .required = true, .autocomplete = "given-name" }),
                .b = ui.field(.{ .name = "demo-field-last", .label = "Last name", .placeholder = "Last name", .value = "Lovelace", .autocomplete = "family-name" }),
                .c = ui.field(.{ .name = "demo-field-company", .label = "Company", .placeholder = "Company", .autocomplete = "organization" }),
                .e = ui.field(.{ .name = "demo-field-email", .label = "Email", .placeholder = "Email", .type = "email", .inputmode = "email", .autocomplete = "email" }),
                .f = ui.field(.{ .name = "demo-field-phone", .label = "Phone", .placeholder = "Phone", .type = "tel", .inputmode = "tel", .autocomplete = "tel" }),
            }),
            .footer = zw.view("{a}{b}", .{
                .a = ui.button(.{ .label = "Cancel" }),
                .b = ui.button(.{ .label = "Save", .variant = .primary, .type = .submit }),
            }),
        }),
    }).render(w);
}

/// A caption (the props that make the field) above a field.
const Cell = zw.View("<div><p class=\"demo-field-cap\"><code>{cap}</code></p>{f}</div>", struct { cap: []const u8, f: ui.Field });

fn cell(cap: []const u8, f: ui.Field) Cell {
    return .{ .data = .{ .cap = cap, .f = f } };
}

fn types(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-field-grid\">{a}{b}{c}{e}{f}{g}{h}{i}</div>", .{
        .a = cell("type = \"text\"", ui.field(.{ .name = "demo-field-t-text", .label = "Full name", .placeholder = "Full name", .autocomplete = "name" })),
        .b = cell("type = \"email\"", ui.field(.{ .name = "demo-field-t-email", .label = "Email", .placeholder = "name@example.com", .type = "email", .inputmode = "email", .autocomplete = "email" })),
        .c = cell("type = \"password\"", ui.field(.{ .name = "demo-field-t-password", .label = "Password", .placeholder = "Password", .type = "password", .autocomplete = "current-password" })),
        .e = cell("type = \"url\"", ui.field(.{ .name = "demo-field-t-url", .label = "Website", .placeholder = "https://", .type = "url", .inputmode = "url" })),
        .f = cell("type = \"search\"", ui.field(.{ .name = "demo-field-t-search", .label = "Search", .placeholder = "Search", .type = "search", .value = "zigworks" })),
        .g = cell("type = \"number\", step = \"0.1\", min, max", ui.field(.{ .name = "demo-field-t-weight", .label = "Weight", .type = "number", .value = "72.5", .step = "0.1", .min = "0", .max = "300", .suffix = "kg" })),
        .h = cell("prefix = \"$\", pattern = \"…\"", ui.field(.{ .name = "demo-field-t-price", .label = "Price", .placeholder = "0.00", .prefix = "$", .inputmode = "decimal", .pattern = "[0-9]+(\\.[0-9]{2})?" })),
        .i = cell("maxlength = 6, autocomplete = \"one-time-code\"", ui.field(.{ .name = "demo-field-t-code", .label = "Verification code", .placeholder = "000000", .inputmode = "numeric", .maxlength = 6, .pattern = "[0-9]{6}", .autocomplete = "one-time-code" })),
    }).render(w);
}

fn states(w: *Writer) Writer.Error!void {
    try zw.view("<div class=\"demo-field-grid\">{a}{b}{c}{e}{f}{g}{h}</div>", .{
        .a = cell("placeholder only (empty)", ui.field(.{ .name = "demo-field-s-empty", .label = "Nickname", .placeholder = "Nickname" })),
        .b = cell("help", ui.field(.{ .name = "demo-field-s-help", .label = "Display name", .value = "Ada", .help = "Shown next to your messages." })),
        .c = cell("disabled", ui.field(.{ .name = "demo-field-s-disabled", .label = "Team", .value = "Analytical Engine", .disabled = true })),
        .e = cell("readonly", ui.field(.{ .name = "demo-field-s-readonly", .label = "Account ID", .value = "ZW-1042", .readonly = true, .help = "You can select and copy it." })),
        .f = cell("invalid (replaces help)", ui.field(.{ .name = "demo-field-s-invalid", .label = "Username", .value = "ab", .help = "3 to 20 characters.", .invalid = "Use at least 3 characters.", .maxlength = 20 })),
        .h = cell("show_label", ui.field(.{ .name = "demo-field-s-label", .label = "Name", .show_label = true, .value = "Ada Lovelace", .autocomplete = "name" })),
        .g = cell("required, pattern: type letters, then leave", ui.field(.{ .name = "demo-field-s-native", .label = "ZIP code", .placeholder = "Digits only", .required = true, .pattern = "[0-9]{5}", .inputmode = "numeric", .help = "Five digits." })),
    }).render(w);
}

// Live: z.js sends the value on every input (debounced) and the server answers with a fragment.
fn live(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Choose a username",
        .body = zw.view("{f}", .{
            .f = ui.field(.{
                .name = "demo-field-handle",
                .label = "Username",
                .placeholder = "Try “ada” or “lovelace”",
                .help = "3 to 20 lowercase letters or numbers.",
                .pattern = "[a-z0-9]{3,20}",
                .maxlength = 20,
                .autocomplete = "username",
                .z = .{ .get = "/demo/field/handle", .trigger = "input", .target = "#zw-demo-field-handle-msg", .swap = .outer },
            }),
        }),
    }).render(w);
    try ui.card(.{
        .title = "Tip calculator",
        .body = zw.view("{f}<output id=\"demo-field-tip\" class=\"demo-field-out\">Tip $8.73 · Total $57.23</output>", .{
            .f = ui.field(.{
                .name = "demo-field-bill",
                .label = "Bill amount",
                .placeholder = "0.00",
                .value = "48.50",
                .prefix = "$",
                .inputmode = "decimal",
                .pattern = "[0-9]*\\.?[0-9]{0,2}",
                .help = "Tip is 18%.",
                .z = .{ .get = "/demo/field/tip", .trigger = "input", .target = "#demo-field-tip", .swap = .inner },
            }),
        }),
    }).render(w);
}

fn handle(c: *zw.Ctx) !void {
    const v = c.query("demo-field-handle") orelse "";
    try c.page(handleMsg(v));
}

// The reply replaces the field's own message element, so its text and red box change while the cursor stays put.
const Msg = zw.View("<small id=\"zw-demo-field-handle-msg\" class=\"zw-help{#if bad} zw-help--error{/if}\"{#if bad} role=\"alert\"{/if}>{text}</small>", struct { text: []const u8, bad: bool });

fn handleMsg(v: []const u8) Msg {
    const help = "3 to 20 lowercase letters or numbers.";
    if (v.len == 0) return .{ .data = .{ .text = help, .bad = false } };
    for (v) |ch| if (!std.ascii.isLower(ch) and !std.ascii.isDigit(ch)) return .{ .data = .{ .text = "Use lowercase letters and numbers only.", .bad = true } };
    if (v.len < 3) return .{ .data = .{ .text = "Too short: use at least 3 characters.", .bad = true } };
    for ([_][]const u8{ "ada", "admin", "guest", "root", "zig" }) |taken| {
        if (std.mem.eql(u8, v, taken)) return .{ .data = .{ .text = "Already taken.", .bad = true } };
    }
    return .{ .data = .{ .text = "Available.", .bad = false } };
}

fn tip(c: *zw.Ctx) !void {
    const bill = std.fmt.parseFloat(f64, c.query("demo-field-bill") orelse "") catch return c.text("Enter an amount");
    if (!(bill >= 0 and bill < 1e9)) return c.text("Enter an amount");
    const t = bill * 0.18;
    try c.text(try std.fmt.allocPrint(c.arena, "Tip ${d:.2} · Total ${d:.2}", .{ t, bill + t }));
}

// Validate: the server checks the form and answers with the same form carrying `invalid` messages.
// `novalidate` keeps the browser's own bubbles out of the way.
const Signup = zw.View("<form id=\"demo-field-signup\" class=\"zw-stack\" novalidate{z}>{email}{password}{button}</form>", struct { z: ui.Z, email: ui.Field, password: ui.Field, button: ui.Button });

fn signupForm(email: []const u8, email_err: []const u8, password_err: []const u8) Signup {
    return .{ .data = .{
        .z = .{ .post = "/demo/field/signup", .swap = .outer },
        .email = ui.field(.{ .name = "demo-field-signup-email", .label = "Email", .placeholder = "Email", .type = "email", .value = email, .autocomplete = "email", .help = "We send a confirmation link.", .invalid = email_err }),
        .password = ui.field(.{ .name = "demo-field-signup-password", .label = "Password", .placeholder = "Password", .type = "password", .autocomplete = "new-password", .help = "At least 8 characters.", .invalid = password_err }),
        .button = ui.button(.{ .label = "Create Account", .variant = .primary, .type = .submit, .full = true }),
    } };
}

fn validate(w: *Writer) Writer.Error!void {
    try ui.card(.{ .title = "Create your account", .body = signupForm("", "", "") }).render(w);
}

fn validEmail(s: []const u8) bool {
    if (s.len > 100 or std.mem.cutScalar(u8, s, ' ') != null) return false;
    const local, const domain = std.mem.cutScalar(u8, s, '@') orelse return false;
    const host, const tld = std.mem.cutScalar(u8, domain, '.') orelse return false;
    return local.len > 0 and host.len > 0 and tld.len > 0;
}

fn signupReset(c: *zw.Ctx) !void {
    try c.page(signupForm("", "", ""));
}

fn signup(c: *zw.Ctx) !void {
    const email = std.mem.trim(u8, c.form("demo-field-signup-email") orelse "", " ");
    const password = c.form("demo-field-signup-password") orelse "";
    const email_err: []const u8 = if (validEmail(email)) "" else "Enter an address like name@example.com.";
    const password_err: []const u8 = if (password.len >= 8) "" else "Use at least 8 characters.";
    if (email_err.len > 0 or password_err.len > 0) return c.page(signupForm(email, email_err, password_err));
    try c.page(zw.view("{toast}<div id=\"demo-field-signup\" class=\"zw-stack\">{note}{again}</div>", .{
        .toast = ui.toast(.{ .text = "Account created", .kind = .success }),
        .note = ui.callout(.{ .kind = .tip, .title = "Check your inbox.", .body = zw.view("We sent a confirmation link to <strong>{e}</strong>.", .{ .e = email }) }),
        .again = ui.button(.{ .label = "Start over", .z = .{ .get = "/demo/field/signup", .target = "#demo-field-signup", .swap = .outer } }),
    }));
}

// Compose: a field with a button and tags, and a field inside a sheet.
fn compose(w: *Writer) Writer.Error!void {
    try ui.card(.{
        .title = "Share “Q4 Plan”",
        .subtitle = "Invitees get a link by email",
        .body = zw.view("<form class=\"zw-row\"{z}>{f}{b}</form><div id=\"demo-field-invitees\" class=\"zw-tags demo-field-tags\">{t1}{t2}</div>", .{
            .z = ui.Z{ .post = "/demo/field/invite", .target = "#demo-field-invitees", .swap = .beforeend },
            .f = ui.field(.{ .name = "demo-field-invite", .label = "Invite by email", .placeholder = "Add an email address", .type = "email", .inputmode = "email" }),
            .b = ui.button(.{ .label = "Add", .variant = .primary, .type = .submit }),
            .t1 = ui.tag(.{ .text = "ada@example.com", .remove = .{ .delete = "/demo/field/invite" } }),
            .t2 = ui.tag(.{ .text = "grace@example.com", .remove = .{ .delete = "/demo/field/invite" } }),
        }),
    }).render(w);
    try ui.card(.{ .body = ui.setting(.{
        .label = "Quarterly report.pdf",
        .description = "PDF document · 1.2 MB",
        .icon = "📄",
        .control = ui.button(.{ .label = "Rename…", .opens = "demo-field-rename" }),
    }) }).render(w);
    try ui.sheet(.{
        .id = "demo-field-rename",
        .title = "Rename File",
        .description = "The extension stays the same.",
        .size = .small,
        .close = true,
        .body = zw.view("<form{z}>{f}<div class=\"zw-sheet-actions\">{c}{ok}</div></form>", .{
            .z = d.save,
            .f = ui.field(.{ .name = "demo-field-rename-name", .label = "File name", .value = "Quarterly report", .suffix = ".pdf", .required = true, .autofocus = true, .maxlength = 60 }),
            .c = ui.button(.{ .label = "Cancel", .opens = "demo-field-rename" }),
            .ok = ui.button(.{ .label = "Rename", .variant = .primary, .type = .submit }),
        }),
    }).render(w);
}

fn invite(c: *zw.Ctx) !void {
    const email = std.mem.trim(u8, c.form("demo-field-invite") orelse "", " ");
    if (email.len == 0) return c.send(.no_content, "text/plain", "");
    if (!validEmail(email)) return c.page(ui.toast(.{ .text = "That doesn't look like an email address", .kind = .@"error" }));
    try c.page(ui.tag(.{ .text = email, .remove = .{ .delete = "/demo/field/invite" } }));
}

fn inviteRemove(c: *zw.Ctx) !void {
    // An empty 200 lets z.js remove the tag (204 would mean "change nothing").
    try c.send(.ok, "text/html; charset=utf-8", "");
}
