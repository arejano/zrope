const std = @import("std");
const sqlite = @import("sqlite");

pub const Database = @This();

allocator: std.mem.Allocator,
conn: sqlite.Db,

pub fn init(allocator: std.mem.Allocator) !Database {
    const db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "rope.db" },
        .open_flags = .{
            .write = true,
            .create = true,
        },
        .threading_mode = .MultiThread,
    });

    return .{ .conn = db, .allocator = allocator };
}

fn toLower(allocator: std.mem.Allocator, src: []const u8) std.mem.Allocator.Error![]const u8 {
    const lower = try allocator.alloc(u8, src.len);
    for (src, 0..) |b, i| {
        lower[i] = std.ascii.toLower(b);
    }
    return lower;
}

fn buildCreateTableQuery(comptime T: type) []const u8 {
    const table_name = @typeName(T);
    const clean_table_name = if (std.mem.lastIndexOf(u8, table_name, ".")) |last_dot|
        table_name[last_dot + 1 ..]
    else
        table_name;

    comptime var query: []const u8 = "CREATE TABLE IF NOT EXISTS " ++ clean_table_name ++ " (";

    const fields = std.meta.fields(T);
    comptime {
        for (fields, 0..) |field, i| {
            query = query ++ field.name ++ " ";

            query = query ++ switch (field.type) {
                []const u8 => "TEXT",
                usize, u64, u32, u16, u8 => "INTEGER",
                i64, i32, i16, i8, ?i8 => "INTEGER",
                f64, f32 => "REAL",
                bool => "INTEGER",
                else => @compileError("Tipo não suportado: " ++ @typeName(field.type)),
            };

            if (std.mem.eql(u8, field.name, "id")) {
                query = query ++ " PRIMARY KEY";
            }

            if (i < fields.len - 1) {
                query = query ++ ", ";
            }
        }
    }

    return query ++ ")";
}

pub fn createTable(self: *Database, comptime T: type) !void {
    const query = comptime buildCreateTableQuery(T);
    // std.debug.print("SQL Query: {s}\n", .{query});

    var stmt = try self.conn.prepare(query);
    defer stmt.deinit();
    try stmt.exec(.{}, .{});
}

pub fn deinit(self: *Database) void {
    self.conn.deinit();
}
