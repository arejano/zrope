const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const std = @import("std");
const Allocator = std.mem.Allocator;

const Center = vxfw.Center;
const Text = vxfw.Text;

pub const OptionsList = @This();

pub fn init(comptime T: type) type {
    return OptionsListType(T);
}

pub fn OptionsListType(comptime T: type) type {
    return struct {
        const Self = @This();

        items: []const T,
        format_fn: *const fn (arena: Allocator, index: usize, item: T) Allocator.Error![]const u8,

        pub fn init(items: []const T, format_fn: *const fn (arena: Allocator, index: usize, item: T) Allocator.Error![]const u8) Self {
            return .{
                .items = items,
                .format_fn = format_fn,
            };
        }

        pub fn widget(self: *Self) vxfw.Widget {
            return .{
                .userdata = self,
                .eventHandler = typeErasedEventHandler,
                .drawFn = typeErasedDrawFn,
            };
        }

        fn typeErasedEventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.handleEvent(ctx, event);
        }

        pub fn handleEvent(_: *Self, _: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
            switch (event) {
                .init => {},
                .key_press => |_| {},
                .mouse => |_| {},
                .mouse_enter => {},
                .mouse_leave => {},
                .focus_in => {},
                .focus_out => {},
                else => {},
            }
        }

        fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.draw(ctx);
        }

        pub fn draw(self: *Self, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
            const max_size = ctx.max.size();
            const max_childs = self.items.len;
            const childs = try ctx.arena.alloc(vxfw.SubSurface, max_childs);

            for (self.items, 0..) |item, i| {
                const label = try self.format_fn(ctx.arena, i, item);
                const text: Text = .{
                    .text = label,
                    .text_align = .center,
                };
                const slot_text: vxfw.SubSurface = .{
                    .origin = .{ .row = @intCast(i), .col = 1 },
                    .surface = try text.draw(ctx.withConstraints(
                        ctx.min,
                        .{ .width = max_size.width - 2, .height = 1 },
                    )),
                };
                childs[i] = slot_text;
            }

            const surface = try vxfw.Surface.initWithChildren(
                ctx.arena,
                self.widget(),
                max_size,
                childs,
            );
            return surface;
        }
    };
}
