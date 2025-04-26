const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Rope = @import("RopeApp.zig");
const Database = @import("database.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var db = try Database.init(allocator);

    var app = try vxfw.App.init(allocator);
    defer app.deinit();

    const model = try allocator.create(Rope);
    defer allocator.destroy(model);

    model.* = try Rope.init(model, allocator, &app, &db);
    defer model.*.deinit();

    try app.run(model.widget(), .{});
}
