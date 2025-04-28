const std = @import("std");
const vaxis = @import("vaxis");

const Allocator = std.mem.Allocator;
const RopeApp = @import("RopeApp.zig");

const AppStyles = @import("styles.zig");

const vxfw = vaxis.vxfw;

const InputOptions = struct {
    label: []const u8 = "no_label",
    required: bool = false,
};

const FormInput = @This();

label: []const u8,
input: vxfw.TextField,
value: []const u8,
required: bool = false,

has_focus: bool = false,

pub fn init(input: vxfw.TextField, opt: InputOptions) FormInput {
    var self: FormInput = .{
        .input = input,
        .has_focus = false,
        .value = "no_value",
        .label = "Form_Label",
    };

    self.label = opt.label;
    self.required = opt.required;

    return self;
}

pub fn widget(self: *FormInput) vxfw.Widget {
    return .{
        .userdata = self,
        .eventHandler = typeErasedEventHandler,
        .drawFn = typeErasedDrawFn,
    };
}

pub fn deinit(self: *FormInput) void {
    self.input.deinit();
}

fn typeErasedEventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
    const self: *FormInput = @ptrCast(@alignCast(ptr));
    return self.handleEvent(ctx, event);
}

pub fn handleEvent(self: *FormInput, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
    switch (event) {
        .init => {},
        .key_press => |_| {
            if (self.has_focus) {
                try self.input.handleEvent(ctx, event);
            }
        },
        .mouse => |_| {},
        .mouse_enter => {
            self.has_focus = true;
            try ctx.requestFocus(self.widget());
            ctx.redraw = true;
        },
        .mouse_leave => {},
        .focus_in => {
            if (ctx.phase == .at_target) {
                self.has_focus = true;
                try ctx.requestFocus(self.input.widget());
                try self.input.handleEvent(ctx, event);
                ctx.redraw = true;
            }
        },
        .focus_out => {
            if (ctx.phase == .at_target) {
                self.has_focus = false;
                try self.input.handleEvent(ctx, event);
                ctx.redraw = true;
            }
        },
        else => {},
    }
}

fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
    const self: *FormInput = @ptrCast(@alignCast(ptr));
    return self.draw(ctx);
}

pub fn draw(self: *FormInput, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
    const max_size = ctx.max.size();

    const required_label = if (self.required) "*" else "";
    const required_text: vxfw.Text = .{ .text = required_label };
    const required_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 0, .col = @intCast(self.label.len + 1) },
        .surface = try required_text.draw(ctx.withConstraints(ctx.min, .{ .height = 1, .width = max_size.width - 2 })),
    };

    const input_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 1, .col = 1 },
        .surface = try self.input.draw(ctx.withConstraints(ctx.min, .{ .height = 1, .width = max_size.width - 2 })),
    };

    const text_label: vxfw.Text = .{ .text = self.label };
    const form_label_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 0, .col = 1 },
        .surface = try text_label.draw(ctx.withConstraints(ctx.min, .{ .height = 1, .width = max_size.width - 2 })),
    };

    const text_value: vxfw.Text = .{ .text = self.value };
    const value_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 2, .col = 1 },
        .surface = try text_value.draw(ctx.withConstraints(ctx.min, .{ .height = 1, .width = max_size.width - 2 })),
    };

    const childs = try ctx.arena.alloc(vxfw.SubSurface, 4);
    childs[0] = input_surface;
    childs[1] = form_label_surface;
    childs[2] = value_surface;
    childs[3] = required_surface;

    const surface = try vxfw.Surface.initWithChildren(
        ctx.arena,
        self.widget(),
        max_size,
        childs,
    );

    if (self.has_focus) {
        @memset(surface.buffer, .{ .style = AppStyles.redBg() });
    }
    return surface;
}
