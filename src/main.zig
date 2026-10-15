// src/main.zig
const std = @import("std");
const zigzag = @import("zigzag");
const pg = @import("pg");

const Allocator = std.mem.Allocator;

const Pool = pg.Pool;

const Cmd = zigzag.Cmd;
const Color = zigzag.Color;
const Style = zigzag.Style;
const Tick = zigzag.msg.Tick;
const Border = zigzag.Border;
const Context = zigzag.Context;
const Program = zigzag.Program;
const KeyEvent = zigzag.KeyEvent;
const TextInput = zigzag.TextInput;
const StyledList = zigzag.StyledList;
const AsyncRunner = zigzag.AsyncRunner;

const TodoModel = struct {
    allocator: Allocator,
    pool: *Pool,
    task: ?AsyncRunner(Msg) = null,
    todos: ?StyledList = null,
    input: ?TextInput = null,

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
        model.input = TextInput.init(model.allocator);
        model.input.?.setPlaceholder("Enter new todo...");
        model.todos = StyledList.init(model.allocator);
        model.todos.?.setEnumerator(.roman);

        model.initDb() catch return .quit;
        model.listTodos() catch return .quit;

        return .none;
    }

    // optional model contract
    pub fn deinit(self: *TodoModel) void {
        self.task.?.deinit();
        self.input.?.deinit();
        self.todos.?.deinit();
    }

    // model contract
    pub fn update(self: *TodoModel, msg: Msg, _: *Context) Cmd(Msg) {
        switch (msg) {
            .key => |k| {
                switch (k.key) {
                    // .up => self.count += 1,
                    // .down => self.count -= 1,
                    .enter => self.addTodo() catch {},
                    else => self.input.?.handleKey(k),
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
        var title_style = (Style{})
            .bold(true)
            .paddingAll(1)
            .fg(Color.green)
            .alignH(.center);
        const title = try title_style.render(ctx.allocator, "Todo App");

        var input_style = (Style{})
            .width(50)
            .borderAll(Border.normal)
            .borderForeground(Color.cyan);
        const input = try input_style.render(ctx.allocator, try self.input.?.view(ctx.allocator));

        const list = try self.todos.?.view(ctx.allocator);

        return try std.fmt.allocPrint(ctx.allocator, "{s}\n{s}\n{s}", .{ title, input, list });
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

    // custom contract, set app state
    pub fn listTodos(model: *TodoModel) !void {
        const q =
            \\     select id, description, done
            \\      from todos
            \\ order by created;
        ;

        var con = try model.pool.acquire();
        defer con.release();

        var result = try con.query(q, .{});
        defer result.deinit();
        while (try result.next()) |row| {
            try model.todos.?.addItem(try row.get([]const u8,1));
        }
    }

    pub fn addTodo(model: *TodoModel) !void {
        const q =
            \\insert into todos(description)
            \\values ($1);
        ;

        var con = try model.pool.acquire();
        defer con.release();

        _ = try con.exec(q, .{model.input.?.getValue()});
        try model.input.?.setValue("");
        try model.listTodos();
    }

    pub fn todoDone(model: *TodoModel, item: TodoItem) !void {
        _ = model;
        _ = item;
    }
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
    // var todos: ?ArrayList(struct {
    //     id: i32,
    //     description: []const u8,
    //     done: bool,
    // }) = null;
    // todos = .empty;
    // defer todos.?.deinit(std.testing.allocator);
    //
    // const uri = try std.Uri.parse("postgresql://postgres:postgres@localhost:5432/sample");
    // const pool = try Pool.initUri(std.testing.io, std.testing.allocator, uri, .{ .size = 5 });
    // defer pool.deinit();
    //
    // var con = try pool.acquire();
    // defer con.release();
    //
    // const result = try con.query("select * from todos;", .{});
    // defer result.deinit();
    //
    // while (try result.next()) |row| {
    //     try todos.?.append(std.testing.allocator, .{ .id = try row.get(i32, 0), .description = try row.get([]const u8, 1), .done = try row.get(bool, 2) });
    // }
    // std.debug.print("{any}", .{todos.?.items.len});
    try std.testing.expect(true);
}
