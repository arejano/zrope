const std = @import("std");
const vaxis = @import("vaxis");

const Allocator = std.mem.Allocator;
const RopeApp = @import("RopeApp.zig");

const vxfw = vaxis.vxfw;

const FormInput = @This();

input: vxfw.TextField,
allocator: std.mem.Allocator,
userdata: *anyopaque,

pub fn init(model: *RopeApp, allocator: std.mem.Allocator, vaxis_app: *vxfw.App) FormInput {
    const input: vxfw.TextField = .{
        .buf = vxfw.TextField.Buffer.init(allocator),
        .unicode = &vaxis_app.vx.unicode,
        .userdata = model,
        .onChange = FormInput.onChange,
        .onSubmit = FormInput.onSubmit,
    };

    return .{
        .allocator = allocator,
        .userdata = model,
        .input = input,
    };
}

fn onChange(maybe_ptr: ?*anyopaque, _: *vxfw.EventContext, str: []const u8) anyerror!void {
    const ptr = maybe_ptr orelse return;
    const self: *FormInput = @ptrCast(@alignCast(ptr));
    _ = self;
    _ = str;
    // self.updateInput(str);
}

fn onSubmit(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, str: []const u8) anyerror!void {
    const ptr = maybe_ptr orelse return;
    const self: *FormInput = @ptrCast(@alignCast(ptr));
    _ = self;
    _ = ctx;
    _ = str;
}

pub fn deinit(self: *FormInput) void {
    self.input.deinit();
}

pub fn widget(self: *const FormInput) vxfw.Widget {
    return .{
        .userdata = @constCast(self),
        .eventHandler = typeErasedEventHandler,
        .drawFn = typeErasedDrawFn,
    };
}

fn typeErasedEventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
    const self: *FormInput = @ptrCast(@alignCast(ptr));
    return self.handleEvent(ctx, event);
}

pub fn handleEvent(self: *FormInput, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
    _ = self;
    _ = ctx;
    switch (event) {
        .init => {
            // try ctx.requestFocus(self.input_component.widget());
        },
        .key_press => |_| {},
        .mouse => |_| {},
        .mouse_enter => {},
        .mouse_leave => {},
        .focus_in => {
            // if (ctx.phase == .at_target) {
            //     if (self.input_component.widget().eql(self.widget())) {
            //         self.input_focus = .text;
            //     } else if (self.filter_input_component.widget().eql(self.widget())) {
            //         self.input_focus = .filter;
            //     }
            // }
        },
        .focus_out => {},
        else => {},
    }
}

fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
    const self: *const FormInput = @ptrCast(@alignCast(ptr));
    return self.draw(ctx);
}

pub fn draw(self: *const FormInput, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
    const max_size = ctx.max.size();

    const debug_text: vxfw.Text = .{ .text = "Clodoaldo", .style = .{ .reverse = true } };

    const debug_text_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 0, .col = 0 },
        .surface = try debug_text.draw(ctx.withConstraints(
            ctx.min,
            .{ .width = 20, .height = 20 },
        )),
    };

    const childs = try ctx.arena.alloc(vxfw.SubSurface, 1);
    childs[0] = debug_text_surface;

    const surface = try vxfw.Surface.initWithChildren(
        ctx.arena,
        self.widget(),
        max_size,
        childs,
    );
    return surface;
}
