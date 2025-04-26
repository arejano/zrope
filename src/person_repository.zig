const std = @import("std");
const Repository = @import("repository.zig").Repository;
const Database = @import("database.zig");

pub const Person = struct {
    id: i8,
    name: []const u8,
    age: u16,
};

pub const PersonRepository = @This();

repository: Repository(Person),
allocator: std.mem.Allocator,

pub fn init(db: *Database, allocator: std.mem.Allocator) !PersonRepository {
    return .{
        .allocator = allocator,
        .repository = try Repository(Person).init(db, allocator),
    };
}

// Métodos básicos delegados ao repository genérico
pub fn create(self: *PersonRepository, person: Person) ![]const u8 {
    return try self.repository.create(person);
}

pub fn findById(self: *PersonRepository, id: usize) !?Person {
    return self.repository.findById(id);
}

pub fn update(self: *PersonRepository, id: usize, person: Person) !void {
    return self.repository.update(id, person);
}

pub fn delete(self: *PersonRepository, id: usize) !void {
    return self.repository.delete(id);
}

pub fn findAll(self: *PersonRepository) ![]Person {
    return try self.repository.findAll();
}

// Métodos específicos do PersonRepository
pub fn findByName(self: *PersonRepository, name: []const u8) !?Person {
    _ = self;
    _ = name;
    // TODO: Implementar busca específica por nome
    return null;
}

// pub fn findByAgeRange(self: *PersonRepository, min: u10, max: u10) !std.ArrayList(Person) {
//     _ = self;
//     _ = min;
//     _ = max;
//     // TODO: Implementar busca específica por faixa de idade
//     return std.ArrayList(Person).init(self.allocator);
// }
