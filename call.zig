const std = @import("std");

pub fn main() void {
    const ctx = Ctx{ .hello = "holi" };
    const ctx2 = Ctx{ .hello = "hi" };
    const greet: *anyopaque = @constCast(&ctx);
    const greethi: *anyopaque = @constCast(&ctx2);
    // const G1 = @typeInfo(@TypeOf(asd));
    // try expect(G1.Fn.params.len == 1);
    // std.debug.print("SFD: {}", .{G1.Fn.return_type.?});
    const task = Task.init(
        Function.init(&asd),
        greet,
        Function.init(&cbk),
        Function.init(&errorCallb),
    );
    task.run();
    const tk = Task.init(
        Function.init(&dsa),
        greethi,
        Function.init(&cbk),
        Function.init(&errorCallb),
    );
    tk.run();
}

fn asd(ctx: Ctx) ![]const u8 {
    if (std.mem.eql(u8, ctx.hello, "holi")) {
        return CustomError.AccesDenied;
    }
    std.debug.print("S: {s}\n", .{ctx.hello});
    return "chauchi";
}

fn dsa(ctx: Ctx) []const u8 {
    std.debug.print("S: {s}\n", .{ctx.hello});
    return "chauchi";
}

fn cbk(ctx: []const u8) void {
    std.debug.print("Callback: {s}\n", .{ctx});
}

fn errorCallb(err: anyerror) void {
    std.debug.print("There was an error: {}\n", .{err});
}

const CustomError = error{
    AccesDenied,
};

const Ctx = struct {
    hello: []const u8,
};

const Function = struct {
    func: *anyopaque,
    funcType: type,

    fn init(comptime ptr: anytype) Function {
        const T = @TypeOf(ptr);
        const func: *anyopaque = @constCast(ptr);
        return .{
            .func = func,
            .funcType = T,
        };
    }
};

const Task = struct {
    func: *anyopaque,
    funcType: type,
    ctx: *anyopaque,
    callback: *anyopaque,
    callbackType: type,
    cbackError: *anyopaque,
    cbackErrorType: type,

    fn run(comptime self: *const Task) void {
        const function = @as(self.funcType, @ptrCast(@alignCast(self.func)));
        const tp = @TypeOf(function.*);
        const args = @typeInfo(tp).Fn.params[0].type.?;
        var params = @as(*args, @ptrCast(@alignCast(self.ctx)));

        //TODO void/no return case
        var r = switch (@typeInfo(@typeInfo(tp).Fn.return_type.?)) {
            .ErrorUnion => blk: {
                var result = function(params.*) catch |e| {
                    const errFn = @as(self.cbackErrorType, @ptrCast(@alignCast(self.cbackError)));
                    errFn(e);
                    return;
                };
                break :blk result;
            },
            else => function(params.*),
        };
        const callbackFunc = @as(self.callbackType, @ptrCast(@alignCast(self.callback)));
        callbackFunc(r);
    }

    fn init(comptime func: anytype, comptime ctx: *anyopaque, comptime callback: anytype, comptime errCallback: anytype) Task {
        return .{
            .func = func.func,
            .funcType = func.funcType,
            .ctx = ctx,
            .callback = callback.func,
            .callbackType = callback.funcType,
            .cbackError = errCallback.func,
            .cbackErrorType = errCallback.funcType,
        };
    }
};
