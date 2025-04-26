const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const std = @import("std");
const Allocator = std.mem.Allocator;

const Center = vxfw.Center;
const TextInput = vaxis.widgets.TextInput;
const Text = vxfw.Text;

const OptionsList = @import("options_list_component.zig");
const StringOptionsList = OptionsList.init([]const u8);

const PersonRepository = @import("person_repository.zig");
const Person = PersonRepository.Person;
const Database = @import("database.zig");

const InputFocus = enum {
    text,
    filter,

    pub fn next(self: InputFocus) InputFocus {
        return switch (self) {
            .text => .filter,
            .filter => .text,
        };
    }
};

const App = @This();

allocator: Allocator,
input_component: vxfw.TextField,
filter_input_component: vxfw.TextField,

text_input: []const u8,
text_filter_input: []const u8,
vaxis_app: *vxfw.App,

input_list: std.ArrayList([]const u8),
filter_list: std.ArrayList([]const u8),

input_focus: InputFocus,

options_list_widget: StringOptionsList,
filter_list_widget: StringOptionsList,

//database
db: *Database,
person_repository: PersonRepository,

debug_print: []const u8,

pub fn init(model: *App, allocator: std.mem.Allocator, vaxis_app: *vxfw.App, db: *Database) !App {
    const input: vxfw.TextField = .{
        .buf = vxfw.TextField.Buffer.init(allocator),
        .unicode = &vaxis_app.vx.unicode,
        .userdata = model,
        .onChange = App.onChange,
        .onSubmit = App.onSubmit,
    };

    const filter_input: vxfw.TextField = .{
        .buf = vxfw.TextField.Buffer.init(allocator),
        .unicode = &vaxis_app.vx.unicode,
        .userdata = model,
        .onChange = App.filterOnChange,
        .onSubmit = App.filterOnSubmit,
    };

    const input_list = std.ArrayList([]const u8).init(allocator);
    const options_list = StringOptionsList.init(&.{}, formatListItem);

    const filter_list = std.ArrayList([]const u8).init(allocator);
    const filter_list_widget = StringOptionsList.init(&.{}, formatListItem);

    // Database
    var person_repository = try PersonRepository.init(db, allocator);

    const result = try person_repository.findAll();
    const p1: Person = result[0];
    std.debug.print("{any}", .{result});
    const debug_print = p1.name;

    return .{
        .debug_print = debug_print,
        .allocator = allocator,
        .db = db,
        .person_repository = person_repository,
        .filter_list = filter_list,
        .filter_list_widget = filter_list_widget,
        .options_list_widget = options_list,
        .input_list = input_list,
        .filter_input_component = filter_input,
        .input_component = input,
        .vaxis_app = vaxis_app,
        .text_input = "",
        .text_filter_input = "",
        .input_focus = .text,
    };
}

fn formatListItem(arena: Allocator, index: usize, item: []const u8) Allocator.Error![]const u8 {
    return std.fmt.allocPrint(arena, "{d} - {s}", .{ index + 1, item });
}

fn toLower(allocator: std.mem.Allocator, src: []const u8) std.mem.Allocator.Error![]const u8 {
    const lower = try allocator.alloc(u8, src.len);
    for (src, 0..) |b, i| {
        lower[i] = std.ascii.toLower(b);
    }
    return lower;
}

pub fn updateInput(self: *App, str: []const u8) void {
    self.text_input = str;
}

pub fn updateList(self: *App) !void {
    if (self.text_input.len > 0) {
        try self.input_list.append(self.text_input);
        self.text_input = "";
        // Atualiza a lista de opções
        self.options_list_widget.items = self.input_list.items;
    }
}

fn onChange(maybe_ptr: ?*anyopaque, _: *vxfw.EventContext, str: []const u8) anyerror!void {
    const ptr = maybe_ptr orelse return;
    const self: *App = @ptrCast(@alignCast(ptr));
    self.updateInput(str);
}

fn onSubmit(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, str: []const u8) anyerror!void {
    const ptr = maybe_ptr orelse return;
    const self: *App = @ptrCast(@alignCast(ptr));
    const allocator = self.input_list.allocator;
    const text_copy = try allocator.dupe(u8, str);
    errdefer allocator.free(text_copy);
    self.text_input = text_copy;
    try self.updateList();
    self.input_component.buf.clearAndFree();

    const name_copy = try allocator.dupe(u8, text_copy);
    defer allocator.free(name_copy);

    const person: PersonRepository.Person = .{ .id = 0, .name = name_copy, .age = 10 };
    self.debug_print = try self.person_repository.create(person);
    ctx.consumeAndRedraw();
}

fn filterOnSubmit(_: ?*anyopaque, _: *vxfw.EventContext, _: []const u8) anyerror!void {
    // const ptr = maybe_ptr orelse return;
    // const self: *App = @ptrCast(@alignCast(ptr));
    // const allocator = self.input_list.allocator;
    // const text_copy = try allocator.dupe(u8, str);
    // errdefer allocator.free(text_copy);
    // self.text_input = text_copy;
    // try self.updateList();
    // self.input_component.buf.clearAndFree();
    // ctx.consumeAndRedraw();
}

fn filterOnChange(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, str: []const u8) anyerror!void {
    const ptr = maybe_ptr orelse return;
    const self: *App = @ptrCast(@alignCast(ptr));

    const filter = try filterOptions([]const u8, self.allocator, &self.input_list, str, "null");
    self.filter_list_widget.items = filter.items;
    ctx.consumeAndRedraw();
}

fn filterOptions(
    //
    comptime T: type,
    allocator: std.mem.Allocator,
    list: *const std.ArrayList(T),
    substring: []const u8,
    comptime field_name: []const u8,
) !std.ArrayList(T) {
    _ = field_name;
    var filtered = std.ArrayList(T).init(allocator);

    for (list.items) |item| {
        if (std.mem.indexOf(u8, item, substring) != null) {
            try filtered.append(item);
        }
    }
    return filtered;
}

pub fn deinit(self: *App) void {
    const allocator = self.input_list.allocator;
    for (self.input_list.items) |item| {
        allocator.free(item);
    }

    for (self.filter_list.items) |item| {
        allocator.free(item);
    }

    self.input_component.deinit();
    self.filter_input_component.deinit();
    self.input_list.deinit();
    self.db.deinit();
}

pub fn widget(self: *App) vxfw.Widget {
    return .{
        .userdata = self,
        .eventHandler = typeErasedEventHandler,
        .drawFn = typeErasedDrawFn,
    };
}

fn typeErasedEventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
    const self: *App = @ptrCast(@alignCast(ptr));
    return self.handleEvent(ctx, event);
}

pub fn handleEvent(self: *App, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
    switch (event) {
        .init => {
            try ctx.requestFocus(self.input_component.widget());
        },
        .key_press => |key| {
            if (key.matches('c', .{ .ctrl = true })) {
                ctx.quit = true;
                return;
            }

            if (key.matches(0x09, .{})) {
                self.input_focus = self.input_focus.next();
                switch (self.input_focus) {
                    .text => try ctx.requestFocus(self.input_component.widget()),
                    .filter => try ctx.requestFocus(self.filter_input_component.widget()),
                }
                return ctx.consumeAndRedraw();
            }
        },
        .mouse => |_| {},
        .mouse_enter => {},
        .mouse_leave => {},
        .focus_in => {
            if (ctx.phase == .at_target) {
                if (self.input_component.widget().eql(self.widget())) {
                    self.input_focus = .text;
                } else if (self.filter_input_component.widget().eql(self.widget())) {
                    self.input_focus = .filter;
                }
            }
        },
        .focus_out => {},
        else => {},
    }
}

fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
    const self: *App = @ptrCast(@alignCast(ptr));
    return self.draw(ctx);
}

pub fn draw(self: *App, ctx: vxfw.DrawContext) Allocator.Error!vxfw.Surface {
    const max_size = ctx.max.size();
    const half_width = @divFloor(max_size.width, 2);

    //Input
    const border: vxfw.Border = .{ .child = self.input_component.widget() };
    const input_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 0, .col = 0 },
        .surface = try border.draw(ctx.withConstraints(
            ctx.min,
            .{ .width = half_width, .height = 3 },
        )),
    };

    //Filter
    const filter_border: vxfw.Border = .{ .child = self.filter_input_component.widget() };
    const filter_input_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 0, .col = half_width },
        .surface = try filter_border.draw(ctx.withConstraints(
            ctx.min,
            .{ .width = half_width + 1, .height = 3 },
        )),
    };

    const options_border: vxfw.Border = .{
        .child = self.options_list_widget.widget(),
    };

    const options_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 3, .col = 0 },
        .surface = try options_border.draw(ctx.withConstraints(
            ctx.min,
            .{ .width = max_size.width / 2, .height = max_size.height - 3 },
        )),
    };

    const filter_list_border: vxfw.Border = .{
        .child = self.filter_list_widget.widget(),
    };

    const filter_list_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 3, .col = max_size.width / 2 },
        .surface = try filter_list_border.draw(ctx.withConstraints(
            ctx.min,
            .{ .width = max_size.width / 2 + 1, .height = max_size.height - 3 },
        )),
    };

    const debug_text: vxfw.Text = .{ .text = self.debug_print, .style = .{ .reverse = true } };

    const debug_text_surface: vxfw.SubSurface = .{
        .origin = .{ .row = 5, .col = 3 },
        .surface = try debug_text.draw(ctx.withConstraints(
            ctx.min,
            .{ .width = 20, .height = 20 },
        )),
    };

    const childs = try ctx.arena.alloc(vxfw.SubSurface, 5);
    childs[0] = input_surface;
    childs[1] = filter_input_surface;
    childs[2] = options_surface;
    childs[3] = filter_list_surface;
    childs[4] = debug_text_surface;

    const surface = try vxfw.Surface.initWithChildren(
        ctx.arena,
        self.widget(),
        max_size,
        childs,
    );
    return surface;
}

fn doClick(self: *App, ctx: *vxfw.EventContext) anyerror!void {
    try self.onClick(self.userdata, ctx);
    ctx.consume_event = true;
}
