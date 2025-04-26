const std = @import("std");
const Utils = @This();

// pub fn toLowerCaseUnicode(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
//     var result = std.ArrayList(u8).init(allocator);
//     defer result.deinit();

//     _ = std.unicode.Utf8Iterator{ .bytes = input };
//     return "";

//     // while (iter.nextCodepoint()) |codepoint| {
//     // const loewr = std.unicode.utf8T
//     // }

// }

pub fn toLowerCaseAscii(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var result = try allocator.alloc(u8, input.len);

    for (input, 0..) |char, i| {
        result[i] = if (char >= 'A' and char <= 'Z') {
            char + 32;
        } else {
            char;
        };
    }

    return result;
}
