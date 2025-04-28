const vaxis = @import("vaxis");

pub const left_panel_size: usize = 32;

const AppStyles = @This();

pub fn default() vaxis.Style {
    const def: vaxis.Style = .{ .reverse = false };
    return def;
}

pub fn redBg() vaxis.Style {
    const def: vaxis.Style = .{ .bg = .{ .rgb = .{ 255, 0, 0 } } };
    return def;
}

pub fn dark_background() vaxis.Style {
    const def: vaxis.Style = .{ .fg = .{ .rgb = .{ 144, 144, 144 } }, .bg = .{ .rgb = .{ 17, 17, 27 } } };
    return def;
}

pub fn wezterm() vaxis.Style {
    const def: vaxis.Style = .{ .fg = .{ .rgb = .{ 144, 144, 144 } }, .bg = .{ .rgb = .{ 51, 51, 51 } } };
    return def;
}

pub fn dark_bg_text() vaxis.Style {
    const def: vaxis.Style = .{ .bg = .{ .rgb = .{ 17, 17, 27 } } };
    return def;
}

pub fn panel_name_dark() vaxis.Style {
    const def: vaxis.Style = .{
        //fg
        .fg = .{ .rgb = .{ 255, 255, 255 } },
        //bg
        .bg = .{ .rgb = .{ 17, 17, 27 } },
    };
    return def;
}

pub fn panel_name_dark_active() vaxis.Style {
    const def: vaxis.Style = .{
        //fg
        .fg = .{ .rgb = .{ 0, 0, 0 } },
        //bg
        .bg = .{ .rgb = .{ 203, 166, 247 } },
    };
    return def;
}

pub fn panel_name_light() vaxis.Style {
    const def: vaxis.Style = .{ .bg = .{ .rgb = .{ 17, 17, 27 } } };
    return def;
}

pub fn panel_name_light_active() vaxis.Style {
    const def: vaxis.Style = .{ .bg = .{ .rgb = .{ 17, 17, 27 } } };
    return def;
}

pub fn status_title() vaxis.Style {
    const def: vaxis.Style = .{
        //
        .fg = .{ .rgb = .{ 0, 0, 0 } },
        //bg
        .bg = .{ .rgb = .{ 203, 166, 247 } },
    };
    return def;
}

//Catpuccin

pub fn cat_background() vaxis.Style {
    const def: vaxis.Style = .{
        //
        .fg = .{ .rgb = .{ 255, 255, 255 } },
        //bg rgb(24, 22, 35)
        .bg = .{ .rgb = .{ 24, 22, 35 } },
    };
    return def;
}

pub fn cat_panel_background() vaxis.Style {
    const def: vaxis.Style = .{
        //
        .fg = .{ .rgb = .{ 255, 255, 255 } },
        //bg rgb(24, 22, 35)
        .bg = .{ .rgb = .{ 29, 27, 43 } },
    };
    return def;
}

pub fn cat_panel2_background() vaxis.Style {
    const def: vaxis.Style = .{
        //
        .fg = .{ .rgb = .{ 255, 255, 255 } },
        .bg = .{ .rgb = .{ 38, 35, 58 } },
    };
    return def;
}

pub fn cat_disable() vaxis.Style {
    const def: vaxis.Style = .{
        //
        .fg = .{ .rgb = .{ 255, 255, 255 } },
        .bg = .{ .rgb = .{ 82, 79, 103 } },
    };
    return def;
}

pub fn cat_select() vaxis.Style {
    const def: vaxis.Style = .{
        //
        .fg = .{ .rgb = .{ 0, 0, 0 } },
        .bg = .{ .rgb = .{ 49, 116, 143 } },
    };
    return def;
}
