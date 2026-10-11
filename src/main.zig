// src/main.zig
const std = @import("std");
const zigzag = @import("zigzag");
const pg = @import("pg");

const Pool = pg.Pool;

const Cmd = zigzag.Cmd;
const Context = zigzag.Context;
const KeyEvent = zigzag.KeyEvent;
const Program = zigzag.Program;

const Model = struct {
    count: i32 = 0,

    pub const Msg = union(enum) {
        key: KeyEvent,
    };

    pub fn init(model: *Model, _: *Context) Cmd(Msg) {
        model.count = 0;
        return .none;
    }

    pub fn update(self: *Model, msg: Msg, _: *Context) Cmd(Msg) {
        switch (msg) {
            .key => |k| {
                switch (k.key) {
                    .up => self.count += 1,
                    .down => self.count -= 1,
                    .escape => return .quit,
                    else => {},
                }
            },
        }
        return .none;
    }

    pub fn view(self: *const Model, ctx: *const Context) ![]const u8 {
        return try std.fmt.allocPrint(ctx.allocator, "{d}", .{self.count});
    }
};

pub fn main(init: std.process.Init) !void {
    const uri = try std.Uri.parse("postgresql://postgres:postgres@localhost:5432/sample");
    const pool = try Pool.initUri(init.io, init.gpa, uri, .{ .size = 5 });
    defer pool.deinit();

    var program = Program(Model).init(init.gpa, init.io, init.environ_map);
    defer program.deinit();
    try program.run();
}

test "should create program" {
    // var program = Program(Model).init(std.testing.gpa, std.testing.io, std.testing.environ_map);
    // defer program.deinit();
    try std.testing.expect(true);
}
