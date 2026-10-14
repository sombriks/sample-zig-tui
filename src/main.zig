// src/main.zig
const std = @import("std");
const zigzag = @import("zigzag");
const pg = @import("pg");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Pool = pg.Pool;

const Cmd = zigzag.Cmd;
const Tick = zigzag.msg.Tick;
const Context = zigzag.Context;
const Program = zigzag.Program;
const KeyEvent = zigzag.KeyEvent;
const AsyncRunner = zigzag.AsyncRunner;

const TodoModel = struct {
    allocator: Allocator,
    pool: *Pool,
    count: i32 = 0,
    task: ?AsyncRunner(Msg) = null,
    todos: ?ArrayList(TodoItem) = null,

    // model contract, this one MUST be called Msg
    pub const Msg = union(enum) {
        key: KeyEvent,
        tick: Tick,
    };

    // our item
    pub const TodoItem = struct {
        id: i32 = 0,
        description: []const u8 = "",
        done: bool = false,
    };

    // model contract
    pub fn init(model: *TodoModel, _: *Context) Cmd(Msg) {
        model.task = AsyncRunner(Msg).init(model.allocator);
        model.todos = .empty;

        model.initDb() catch return .quit;
        model.listTodos() catch return .quit;

        return .none;
    }

    // optional model contract
    pub fn deinit(self: *TodoModel) void {
        if (self.task) |*t| {
            t.deinit();
        }
        if (self.todos) |*t| {
            t.deinit(self.allocator);
        }
    }

    // model contract
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

    // model contract
    pub fn view(self: *const TodoModel, ctx: *const Context) ![]const u8 {
        return try std.fmt.allocPrint(ctx.allocator, "{d}", .{self.count});
    }

    // custom contract, check database sanity
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

    // custom contract check app state
    pub fn listTodos(model: *TodoModel) !void {
        model.todos.?.clearAndFree(model.allocator);

        const q =
            \\     select id, description, done
            \\      from todos
            \\ ordeer by created dec, description asc;
        ;

        var con = try model.pool.acquire();
        defer con.release();

        var result = try con.queryOpts(q, .{}, .{ .column_names = true });
        defer result.deinit();

        var mapper = result.mapper(TodoItem, .{ .dupe = true });
        while (try mapper.next()) |item| {
            try model.todos.?.append(model.allocator, item);
        }
    }

    pub fn addTodo(_: *TodoModel) !void {}
    pub fn todoDone(_: *TodoModel) !void {}
};

// sample entry point
pub fn main(init: std.process.Init) !void {
    const uri = try std.Uri.parse("postgresql://postgres:postgres@localhost:5432/sample");
    const pool = try Pool.initUri(init.io, init.gpa, uri, .{ .size = 5 });
    defer pool.deinit();

    const model: TodoModel = .{ .allocator = init.gpa, .pool = pool };

    var program = Program(TodoModel).initWithModel(init.gpa, init.io, init.environ_map, model, .{});
    defer program.deinit();
    try program.run();
}

test "should create program" {
    // var program = Program(Model).init(std.testing.gpa, std.testing.io, std.testing.environ_map);
    // defer program.deinit();
    try std.testing.expect(true);
}
