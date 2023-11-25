const std = @import("std");

pub fn main() void {
    const func: *anyopaque = @constCast(&asd);
    const callbackFunction: *anyopaque = @constCast(&cbk);
    const ctx = Ctx{ .hello = "holi" };
    const ctx2 = Ctx{ .hello = "hi" };
    const greet: *anyopaque = @constCast(&ctx);
    const greethi: *anyopaque = @constCast(&ctx2);
    const ty = @TypeOf(&asd);
    const cty = @TypeOf(&cbk);
    // const fun = Function{ .func = struct {
    //     f: *const fn (Ctx) []const u8 = &asd,
    // } };
    // const fun = Function{ .func = asd };
    const task = Task.init(
        func,
        ty,
        greet,
        callbackFunction,
        cty,
        @as(*anyopaque, @constCast(&errorCallb)),
        @TypeOf(&errorCallb),
    );
    task.run();
    const tk = Task.init(
        func,
        ty,
        greethi,
        callbackFunction,
        cty,
        @as(*anyopaque, @constCast(&errorCallb)),
        @TypeOf(&errorCallb),
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
    func: type,
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
        var r = function(params.*) catch |e| {
            const errFn = @as(self.cbackErrorType, @ptrCast(@alignCast(self.cbackError)));
            errFn(e);
            return;
        };
        // std.debug.print("Result: {}\n", .{@TypeOf(r)});
        const callbackFunc = @as(self.callbackType, @ptrCast(@alignCast(self.callback)));
        callbackFunc(r);
    }

    fn init(comptime func: *anyopaque, comptime funcType: anytype, comptime ctx: *anyopaque, comptime callback: *anyopaque, comptime callbType: anytype, comptime errCallback: *anyopaque, comptime errCallbackType: anytype) Task {
        // fn init(comptime function: anytype, comptime ctx: *anyopaque, comptime callback: *anyopaque, comptime callbType: anytype, comptime errCallback: *anyopaque, comptime errCallbackType: anytype) Task {
        return .{
            .func = func,
            .funcType = funcType,
            .ctx = ctx,
            .callback = callback,
            .callbackType = callbType,
            .cbackError = errCallback,
            .cbackErrorType = errCallbackType,
        };
    }
};
