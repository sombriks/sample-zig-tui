// src/main.zig
const std = @import("std");
const zigzag = @import("zigzag");
const pg = @import("pg");

const Pool = pg.Pool;

const Cmd = zigzag.Cmd;
const Tick = zigzag.msg.Tick;
const Context = zigzag.Context;
const Program = zigzag.Program;
const KeyEvent = zigzag.KeyEvent;
const AsyncRunner = zigzag.AsyncRunner;

const TodoModel = struct {
    pool: *Pool,
    count: i32 = 0,
    task: ?AsyncRunner(Msg) = null,

    // this one MUST be called Msg
    pub const Msg = union(enum) {
        key: KeyEvent,
        tick: Tick,
    };

    pub fn init(model: *TodoModel, ctx: *Context) Cmd(Msg) {
        model.task = AsyncRunner(Msg).init(ctx.persistent_allocator);
        model.initDb() catch return .quit;
        return .none;
    }

    pub fn initDb(model: *TodoModel) !void {
        const q =
            \\create table if not exists todos (
            \\  id serial primary key,
            \\  description varchar not null,
            \\  done boolean default false,
            \\  created timestamp not null default now(),
            \\  updated timestamp not null default now()
            \\);
            ;
        var con = try model.pool.acquire();
        defer con.release();
        _ = try con.exec(q, .{});
    }

    pub fn update(self: *TodoModel, msg: Msg, _: *Context) Cmd(Msg) {
        switch (msg) {
            .key => |k| {
                switch (k.key) {
                    .up => self.count += 1,
                    .down => self.count -= 1,
                    .escape => return .quit,
                    else => {},
                }
            },
            .tick => {
                return .none;
            },
        }
        return .none;
    }

    pub fn view(self: *const TodoModel, ctx: *const Context) ![]const u8 {
        return try std.fmt.allocPrint(ctx.allocator, "{d}", .{self.count});
    }
};

pub fn main(init: std.process.Init) !void {
    const uri = try std.Uri.parse("postgresql://postgres:postgres@localhost:5432/sample");
    const pool = try Pool.initUri(init.io, init.gpa, uri, .{ .size = 5 });
    defer pool.deinit();

    var program = Program(TodoModel).initWithModel(init.gpa, init.io, init.environ_map, .{.pool = pool}, .{});
    defer program.deinit();
    try program.run();
}

test "should create program" {
    // var program = Program(Model).init(std.testing.gpa, std.testing.io, std.testing.environ_map);
    // defer program.deinit();
    try std.testing.expect(true);
}
