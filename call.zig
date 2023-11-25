const std = @import("std");

pub fn main() void {
    const func = @as(*anyopaque, @constCast(&asd));
    const ctx = Ctx{ .hello = "holi" };
    const greet: *anyopaque = @constCast(&ctx);
    const ty = @TypeOf(&asd);
    const typeFn = @TypeOf(asd);
    const tp = @typeInfo(typeFn).Fn;
    _ = tp;
    // std.debug.print("TP: {} | {}\n", .{ typeFn, tp });
    // std.debug.print("Func type: {} arg type: {}\n", .{ ty, comptime tp });

    // var task = Task{ .func = func, .ctx = greet, .funcType = ty };
    const task = Task.init(func, greet, ty);
    task.run();
}

fn asd(ctx: Ctx) []const u8 {
    std.debug.print("S: {s}\n", .{ctx.hello});
    return "chauchi";
}

const Ctx = struct {
    hello: []const u8,
};

const Task = struct {
    func: *anyopaque,
    ctx: *anyopaque,
    funcType: type,
    returnType: T,

    fn run(comptime self: *const Task) T {
        const function = @as(self.funcType, @ptrCast(@alignCast(self.func)));
        const tp = @TypeOf(function.*);
        const args = @typeInfo(tp).Fn.params[0].type.?;
        // std.debug.print("Type {} args {}\n", .{ tp, typeInfo.Fn.args[0] });
        var params = @as(*args, @ptrCast(@alignCast(self.ctx)));
        // _ = params;
        // var r = @call(.auto, function, .{@as([*]u8, @ptrCast(self.ctx))[0..4]}));
        var r = @call(.auto, function, .{params.*});
        std.debug.print("Result: {s}\n", .{r});
    }

    fn init(comptime func: *anyopaque, comptime ctx: *anyopaque, comptime functype: anytype) Task {
        return .{
            .func = func,
            .ctx = ctx,
            .funcType = functype,
        };
    }
};
