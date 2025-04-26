const std = @import("std");
const sqlite = @import("sqlite");

const Utils = @import("utils.zig");

const Database = @import("database.zig");

pub fn Repository(comptime T: type) type {
    return struct {
        db: *Database,
        allocator: std.mem.Allocator,
        is_initialized: bool,

        const Self = @This();

        pub fn init(db: *Database, allocator: std.mem.Allocator) !Self {
            var self: Self = .{
                .allocator = allocator,
                .db = db,
                .is_initialized = false,
            };

            try self.ensureTableExists();
            return self;
        }

        fn getTableName() []const u8 {
            const table_name = @typeName(T);
            return if (std.mem.lastIndexOf(u8, table_name, ".")) |last_dot|
                table_name[last_dot + 1 ..]
            else
                table_name;
        }

        pub fn ensureTableExists(self: *Self) !void {
            if (!self.is_initialized) {
                try self.db.createTable(T);
                self.is_initialized = true;
            }
        }

        fn buildInsertQuery() []const u8 {
            const table_name = comptime getTableName();
            comptime var query: []const u8 = "INSERT INTO " ++ table_name ++ " (";

            const fields = std.meta.fields(T);
            comptime {
                var first = true;
                for (fields) |field| {
                    // Pula o campo id se ele for opcional
                    if (std.mem.eql(u8, field.name, "id")) {
                        // if (@typeInfo(field.type) == .optional) {
                        continue;
                        // }
                    }
                    if (!first) {
                        query = query ++ ", ";
                    }
                    query = query ++ field.name;
                    first = false;
                }
            }

            query = query ++ ") VALUES (";

            comptime {
                var first = true;
                for (fields) |field| {
                    // Pula o campo id se ele for opcional
                    if (std.mem.eql(u8, field.name, "id")) {
                        // if (@typeInfo(field.type) == .optional) {
                        continue;
                        // }
                    }
                    if (!first) {
                        query = query ++ ", ";
                    }
                    query = query ++ ":" ++ field.name;
                    first = false;
                }
            }

            return query ++ ")";
        }

        fn RemoveId() type {
            const fields = std.meta.fields(T);
            var new_fields: [fields.len - 1]std.builtin.Type.StructField = undefined;

            var i: usize = 0;
            for (fields) |field| {
                if (!std.mem.eql(u8, field.name, "id")) {
                    new_fields[i] = field;
                    i += 1;
                }
            }

            return @Type(.{
                .Struct = .{
                    .layout = .Auto,
                    .fields = &new_fields,
                    .decls = &.{},
                },
            });
        }

        pub fn create_bug(self: *Self, entity: T) ![]const u8 {
            const query = comptime buildInsertQuery();

            _ = self;

            // var diags = sqlite.Diagnostics{};
            // var stmt = try self.db.conn.prepareWithDiags(query, .{ .diags = &diags });
            // defer stmt.deinit();

            _ = entity;
            // try stmt.exec(.{}, entity);
            return query;
        }

        fn GetInsertType(comptime U: type) type {
            const fields = std.meta.fields(U);
            var insert_fields: [fields.len - 1]std.builtin.Type.StructField = undefined;

            var i: usize = 0;
            for (fields) |field| {
                if (!std.mem.eql(u8, field.name, "id")) {
                    insert_fields[i] = field;
                    i += 1;
                }
            }

            return @Type(.{
                .@"struct" = .{
                    .is_tuple = false,
                    .layout = .auto,
                    .fields = &insert_fields,
                    .decls = &.{},
                },
            });
        }

        pub fn create(self: *Self, entity: T) ![]const u8 {
            const InsertType = GetInsertType(T);
            const query = comptime buildInsertQuery();

            // Converte `entity` para o tipo sem ID
            const insert_entity: InsertType = blk: {
                var tmp: InsertType = undefined;
                inline for (std.meta.fields(InsertType)) |field| {
                    @field(tmp, field.name) = @field(entity, field.name);
                }
                break :blk tmp;
            };

            var diags = sqlite.Diagnostics{};
            var stmt = try self.db.conn.prepareWithDiags(query, .{ .diags = &diags });
            defer stmt.deinit();

            try stmt.exec(.{}, insert_entity); // Executa com a entidade sem ID
            return query;
        }

        pub fn findById(self: *Self, id: usize) !?T {
            try self.ensureTableExists();
            _ = id;
            // TODO: Implement SQLite select by id
            return null;
        }

        pub fn update(self: *Self, id: usize, entity: T) !void {
            try self.ensureTableExists();
            _ = id;
            _ = entity;
            // TODO: Implement SQLite update
        }

        pub fn delete(self: *Self, id: usize) !void {
            try self.ensureTableExists();
            _ = id;
            // TODO: Implement SQLite delete
        }

        // pub fn findAll(self: *Self) !std.ArrayList(T) {
        pub fn findAll_Errada(self: *Self) ![]T {
            const table_name = comptime getTableName();
            const query = comptime "SELECT * FROM " ++ table_name ++ "";

            var diags = sqlite.Diagnostics{};
            var stmt = try self.db.conn.prepareWithDiags(query, .{ .diags = &diags });
            defer stmt.deinit();

            return try stmt.all(T, self.allocator, .{}, .{});
        }

        pub fn findAll(self: *Self) ![]T {
            const table_name = comptime getTableName();
            const query = comptime "SELECT * FROM " ++ table_name;

            var diags = sqlite.Diagnostics{};
            var stmt = self.db.conn.prepareWithDiags(query, .{ .diags = &diags }) catch |err| {
                std.debug.print("ERRO NA PREPARAÇÃO:\n", .{});
                std.debug.print("Query: {s}\n", .{query});
                std.debug.print("Mensagem: {s}\n", .{diags.message});
                return err;
            };
            defer stmt.deinit();

            // Verifica se há erro na preparação da query
            std.debug.print("Erro na preparação da query: {s}\n", .{diags.message});
            // return error.QueryPreparationFailed;

            // Executa a consulta com tratamento de erros explícito
            const results = stmt.all(T, self.allocator, .{}, .{}) catch |err| {
                std.debug.print("Erro ao executar a query: {}\n", .{err});
                return err;
            };

            return results;
        }
    };
}
