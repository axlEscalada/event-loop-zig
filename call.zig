const std = @import("std");

pub fn main() void {
    const func = @as(*anyopaque, @constCast(&asd));
    const greet = @constCast("holi");
    const ty = @TypeOf(&asd);
    // std.debug.print("Func type: {} arg type: {}\n", .{ ty, @typeInfo(ty).Ptr });

    // var task = Task{ .func = func, .ctx = greet, .funcType = ty };
    const task = Task.init(func, greet, ty);
    task.run();
}

fn asd(d: []const u8) []const u8 {
    std.debug.print("S: {s}\n", .{d});
    return "chauchi";
}

const Task = struct {
    func: *anyopaque,
    ctx: *anyopaque,
    funcType: type,

    fn run(comptime self: *const Task) void {
        const function = @as(self.funcType, @ptrCast(@alignCast(self.func)));
        // const tp = @TypeOf(function.*);
        // const typeInfo = @typeInfo(tp);
        // std.debug.print("Type {} args {}\n", .{ tp, typeInfo.Fn.args[0] });
        var r = @call(.auto, function, .{@as([*]u8, @ptrCast(self.ctx))[0..4]});
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
