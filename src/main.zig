const std = @import("std");
const zigzag = @import("zigzag");
const pg = @import("pg");

pub fn main(_: std.process.Init) !void {
    std.debug.print("{any}\n", .{@TypeOf(zigzag)});
    std.debug.print("{any}\n", .{@TypeOf(pg)});
}

test "should pass" {
    try std.testing.expect(true);
}
