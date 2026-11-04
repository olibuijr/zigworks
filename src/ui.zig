//! zigworks UI: the component library. One file per component in src/ui/, each with its own `css`.
//! Defaults follow the macOS HIG. Glass only on the functional layer (bars, menus); content is opaque.
//!
//! Containers take a body and are generic over it: `ui.Card(Body)`. Leaf components have a fixed
//! type: `ui.Button`. To add a component: create src/ui/<name>.zig, import it, export it, list it in `all`.
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

const all = .{ Layout_, Card_, List_, Sheet_, Setting_, Button_, Field_, Check_, Toggle_, Segmented_, Slider_, Picker_, Menu_, Badge_, Island_ };

pub const Z = @import("ui/z.zig").Z;
pub const Swap = @import("ui/z.zig").Swap;

// Containers
pub const layout = Layout_.layout;
pub const Layout = Layout_.Layout;
pub const card = Card_.card;
pub const Card = Card_.Card;
pub const list = List_.list;
pub const List = List_.List;
pub const sheet = Sheet_.sheet;
pub const Sheet = Sheet_.Sheet;
pub const setting = Setting_.setting;
pub const Setting = Setting_.Setting;

// Controls
pub const button = Button_.button;
pub const Button = Button_.Button;
pub const field = Field_.field;
pub const Field = Field_.Field;
pub const check = Check_.check;
pub const Check = Check_.Check;
pub const toggle = Toggle_.toggle;
pub const Toggle = Toggle_.Toggle;
pub const segmented = Segmented_.segmented;
pub const Segmented = Segmented_.Segmented;
pub const slider = Slider_.slider;
pub const Slider = Slider_.Slider;
pub const picker = Picker_.picker;
pub const Picker = Picker_.Picker;
pub const menu = Menu_.menu;
pub const Menu = Menu_.Menu;

// Display
pub const badge = Badge_.badge;
pub const Badge = Badge_.Badge;
pub const island = Island_.island;
pub const Island = Island_.Island;

/// Every component's CSS, appended to /_zw/zw.css.
pub const css = blk: {
    var s: []const u8 = "";
    for (all) |f| s = s ++ f.css;
    break :blk s;
};

test {
    _ = @import("ui/z.zig");
}
