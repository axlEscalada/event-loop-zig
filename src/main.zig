const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    // var s = allocator.create(Func);
    // var task = Func.init(allocator, &toUpper, "holi");
    // defer allocator.destroy(task);
    // var result = task.*.run();
    // std.debug.print("Result of task: {s}\n", .{result});
    // var as = std.StringHashMap(*Func).init(allocator);
    // defer as.deinit();
    // _ = try as.put("first", task);
    // var v = as.get("first");
    // if (v) |function| {
    //     var rs = function.*.run();
    //     std.debug.print("Result from hashmap: {s}\n", .{rs});
    // }
    var eventLoop = EventLoop.init(allocator);

    eventLoop.on("hello", toUpper)
        .dispatch(Event{ .key = "hello", .data = "How are You Doing?", .asynchronous = false });
    // eventLoop.on("hello", toLower)
    // .dispatch(Event{ .key = "hello", .data = "How are You Doing?", .asynchronous = false });
    while (true) {
        try eventLoop.run();
    }
}

const Func = struct {
    context: []const u8,
    function: *const fn ([]const u8) []const u8,

    fn run(self: *Func) []const u8 {
        var function = self.function;
        var context = self.context;
        return function(context);
    }

    pub fn init(allocator: Allocator, comptime Callback: *const fn ([]const u8) []const u8, ctx: []const u8) *Func {
        var function = allocator.create(Func) catch @panic("can't allocate task");
        function.* = Func{
            .context = ctx,
            .function = Callback,
        };
        return function;
    }
};

fn toLower(str: []const u8) []const u8 {
    std.debug.print("LOWE: {s}\n", .{str});
    var buf: [1024]u8 = undefined;
    _ = std.ascii.lowerString(&buf, str);
    return &buf;
}

fn toUpper(str: []const u8) []const u8 {
    std.debug.print("UPPER: {s}\n", .{str});
    var buf: [1024]u8 = undefined;
    return std.ascii.upperString(&buf, str);
}

const Event = struct {
    key: []const u8,
    data: []const u8,
    asynchronous: bool,
};

const EventLoop = struct {
    allocator: Allocator,
    events: std.atomic.Queue(Event),
    processedEvents: std.atomic.Queue(EventResult),
    handlers: std.StringHashMap(*const fn ([]const u8) []const u8),

    fn on(self: *EventLoop, key: []const u8, comptime handler: *const fn ([]const u8) []const u8) *EventLoop {
        self.handlers.put(key, handler) catch @panic("Error storing handler");
        return self;
    }

    fn dispatch(self: *EventLoop, event: Event) void {
        var node = self.allocator.create(std.atomic.Queue(Event).Node) catch @panic("Error storing node");
        node.data = event;
        self.events.put(node);
    }

    fn run(self: *EventLoop) !void {
        var dequedEvent = self.events.get();
        if (dequedEvent) |node| {
            var event = node.data;
            std.debug.print("Received event: {s}\n", .{event.key});

            if (self.handlers.get(event.key)) |handler| {
                _ = handler;
                var timer = try std.time.Timer.start();
                if (event.asynchronous) {
                    try self.processAsync(event);
                } else self.processSync(event);
                const endTime = timer.read();

                std.debug.print("Event loop was blocked for {any} ms due to this operation\n", .{endTime});
            } else std.debug.print("No handler found for {s}\n", .{event.key});
        }

        var processedEvent = self.processedEvents.get();
        if (processedEvent) |node| {
            self.produceOutput(node.data);
        }
    }

    fn processAsync(self: *EventLoop, event: Event) !void {
        _ = try std.Thread.spawn(.{}, pushEvent, .{ self, event });
    }

    fn processSync(self: *EventLoop, event: Event) void {
        var task = self.handlers.get(event.key).?;
        var result: [1024]u8 = undefined;
        @memcpy(result[0..event.data.len], task(event.data));

        var eventResult = EventResult{ .key = event.key, .result = &result };
        self.produceOutput(eventResult);
    }

    fn pushEvent(self: *EventLoop, event: Event) void {
        var task = self.handlers.get(event.key).?;
        var result = task(event.data);
        var eventResult = EventResult{ .key = event.key, .result = result };

        var node = self.allocator.create(std.atomic.Queue(EventResult).Node) catch @panic("Error storing node");
        node.*.data = eventResult;
        self.processedEvents.put(node);
    }

    fn produceOutput(self: *EventLoop, eventResult: EventResult) void {
        _ = self;
        std.debug.print("Output for Event {s} : {s}\n", .{ eventResult.key, eventResult.result });
    }

    fn init(allocator: Allocator) EventLoop {
        return EventLoop{
            .allocator = allocator,
            .events = std.atomic.Queue(Event).init(),
            .handlers = std.StringHashMap(*const fn ([]const u8) []const u8).init(allocator),
            .processedEvents = std.atomic.Queue(EventResult).init(),
        };
    }
};

const EventResult = struct {
    key: []const u8,
    result: []const u8,
};

test "simple test" {
    // var list = std.ArrayList(i32).init(std.testing.allocator);
    // defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    // try list.append(42);
    // try std.testing.expectEqual(@as(i32, 42), list.pop());
}
