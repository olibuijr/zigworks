//! zigworks UI: the component library. One file per component in src/ui/, each with its own `css`.
//! Defaults follow the macOS HIG. Glass only on the functional layer (bars, menus); content is opaque.
//!
//! Containers take a body and are generic over it: `ui.Card(Body)`. Leaf components have a fixed
//! type: `ui.Button`. To add a component: create src/ui/<name>.zig, import it, export it, list it in `all`.
const std = @import("std");
const Layout_ = @import("ui/layout.zig");
const Card_ = @import("ui/card.zig");
const List_ = @import("ui/list.zig");
const Sheet_ = @import("ui/sheet.zig");
const Setting_ = @import("ui/setting.zig");
const Button_ = @import("ui/button.zig");
const Field_ = @import("ui/field.zig");
const Check_ = @import("ui/check.zig");
const Toggle_ = @import("ui/toggle.zig");
const Segmented_ = @import("ui/segmented.zig");
const Slider_ = @import("ui/slider.zig");
const Picker_ = @import("ui/picker.zig");
const Menu_ = @import("ui/menu.zig");
const Badge_ = @import("ui/badge.zig");
const Island_ = @import("ui/island.zig");
const Sidebar_ = @import("ui/sidebar.zig");
const Code_ = @import("ui/code.zig");
const Callout_ = @import("ui/callout.zig");
const Table_ = @import("ui/table.zig");
const Progress_ = @import("ui/progress.zig");
const Search_ = @import("ui/search.zig");
const Prose_ = @import("ui/prose.zig");
const Tabs_ = @import("ui/tabs.zig");
const Textarea_ = @import("ui/textarea.zig");
const Stepper_ = @import("ui/stepper.zig");
const Checkbox_ = @import("ui/checkbox.zig");
const Radio_ = @import("ui/radio.zig");
const Disclosure_ = @import("ui/disclosure.zig");
const Tooltip_ = @import("ui/tooltip.zig");
const Toast_ = @import("ui/toast.zig");
const Avatar_ = @import("ui/avatar.zig");
const Tag_ = @import("ui/tag.zig");
const Empty_ = @import("ui/empty.zig");
const Skeleton_ = @import("ui/skeleton.zig");
const Kbd_ = @import("ui/kbd.zig");
const Path_ = @import("ui/path.zig");

const Glass_ = @import("ui/glass.zig");
// Glass comes first: it is the shared material, and component rules after it refine it.
const all = .{ Glass_, Layout_, Card_, List_, Sheet_, Setting_, Button_, Field_, Check_, Toggle_, Segmented_, Slider_, Picker_, Menu_, Badge_, Island_, Sidebar_, Code_, Callout_, Table_, Progress_, Search_, Prose_, Tabs_, Textarea_, Stepper_, Checkbox_, Radio_, Disclosure_, Tooltip_, Toast_, Avatar_, Tag_, Empty_, Skeleton_, Kbd_, Path_ };

pub const Z = @import("ui/z.zig").Z;
pub const Swap = @import("ui/z.zig").Swap;

// Containers
pub const layout = Layout_.layout;
pub const Layout = Layout_.Layout;
pub const card = Card_.card;
pub const Card = Card_.Card;
pub const CardVariant = Card_.Variant;
pub const list = List_.list;
pub const List = List_.List;
pub const sheet = Sheet_.sheet;
pub const Sheet = Sheet_.Sheet;
pub const setting = Setting_.setting;
pub const Setting = Setting_.Setting;
pub const sidebar = Sidebar_.sidebar;
pub const Sidebar = Sidebar_.Sidebar;
pub const SidebarSection = Sidebar_.Section;
pub const SidebarLink = Sidebar_.Link;
pub const tabs = Tabs_.tabs;
pub const Tabs = Tabs_.Tabs;
pub const disclosure = Disclosure_.disclosure;
pub const Disclosure = Disclosure_.Disclosure;
pub const tooltip = Tooltip_.tooltip;
pub const Tooltip = Tooltip_.Tooltip;
pub const empty = Empty_.empty;
pub const Empty = Empty_.Empty;
pub const callout = Callout_.callout;
pub const Callout = Callout_.Callout;
pub const CalloutKind = Callout_.Kind;

// Controls
pub const button = Button_.button;
pub const Button = Button_.Button;
pub const field = Field_.field;
pub const Field = Field_.Field;
pub const check = Check_.check;
pub const Check = Check_.Check;
pub const CheckSize = Check_.Size;
pub const CheckTint = Check_.Tint;
pub const toggle = Toggle_.toggle;
pub const Toggle = Toggle_.Toggle;
pub const segmented = Segmented_.segmented;
pub const Segmented = Segmented_.Segmented;
pub const SegmentedOption = Segmented_.Option;
pub const slider = Slider_.slider;
pub const Slider = Slider_.Slider;
pub const picker = Picker_.picker;
pub const Picker = Picker_.Picker;
pub const PickerOption = Picker_.Option;
pub const menu = Menu_.menu;
pub const Menu = Menu_.Menu;
pub const MenuItem = Menu_.Item;
pub const textarea = Textarea_.textarea;
pub const Textarea = Textarea_.Textarea;
pub const stepper = Stepper_.stepper;
pub const Stepper = Stepper_.Stepper;
pub const checkbox = Checkbox_.checkbox;
pub const Checkbox = Checkbox_.Checkbox;
pub const radio = Radio_.radio;
pub const Radio = Radio_.Radio;
pub const RadioOption = Radio_.Option;
pub const tag = Tag_.tag;
pub const Tag = Tag_.Tag;
pub const path = Path_.path;
pub const Path = Path_.Path;
pub const PathItem = Path_.Item;
pub const search = Search_.search;
pub const Search = Search_.Search;

// Display
pub const badge = Badge_.badge;
pub const Badge = Badge_.Badge;
pub const island = Island_.island;
pub const Island = Island_.Island;
pub const code = Code_.code;
pub const Code = Code_.Code;
pub const table = Table_.table;
pub const Table = Table_.Table;
pub const toast = Toast_.toast;
pub const Toast = Toast_.Toast;
pub const avatar = Avatar_.avatar;
pub const Avatar = Avatar_.Avatar;
pub const skeleton = Skeleton_.skeleton;
pub const Skeleton = Skeleton_.Skeleton;
pub const kbd = Kbd_.kbd;
pub const Kbd = Kbd_.Kbd;
pub const progress = Progress_.progress;
pub const Progress = Progress_.Progress;

/// Every component's CSS, appended to /_zw/zw.css.
pub const css = blk: {
    var s: []const u8 = "";
    for (all) |f| s = s ++ f.css;
    break :blk s;
};

test {
    std.testing.refAllDecls(@import("ui/z.zig"));
    inline for (all) |f| std.testing.refAllDecls(f);
}

test "every component's css closes its braces" {
    inline for (all) |f| {
        var depth: isize = 0;
        for (f.css) |c| depth += switch (c) {
            '{' => 1,
            '}' => -1,
            else => 0,
        };
        std.testing.expectEqual(0, depth) catch |e| {
            std.debug.print("unbalanced css in {s}\n", .{@typeName(f)});
            return e;
        };
    }
}
