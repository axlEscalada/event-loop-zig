const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var eventLoop = EventLoop.init(allocator);

    // <<<<<<< Updated upstream
    eventLoop.on("hello 1", toLower)
        .dispatch(Event{ .key = "hello 1", .data = "How are ASYNC?", .asynchronous = true });
    eventLoop.on("hello 2", toLower)
        .dispatch(Event{ .key = "hello 2", .data = "How are You Doing?", .asynchronous = false });
    eventLoop.on("hello 3", toUpper)
        .dispatch(Event{ .key = "hello 3", .data = "How are u doing ASYNC?", .asynchronous = true });
    eventLoop.on("hello 4", toUpper)
        .dispatch(Event{ .key = "hello 4", .data = "How are You Doing?", .asynchronous = false });
    // =======
    //     eventLoop.on("hello", toUpper)
    //         .dispatch(Event{ .key = "hello", .data = "This is a SYNC task", .asynchronous = false });
    //     eventLoop.on("hello", toLower)
    //         .dispatch(Event{ .key = "hello", .data = "This is an ASYNC task", .asynchronous = true });
    // >>>>>>> Stashed changes
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

    pub fn init(allocator: Allocator, comptime Callback: *const (fn ([]const u8) []const u8), ctx: []const u8) *Func {
        var function = allocator.create(Func) catch @panic("can't allocate task");
        function.* = Func{
            .context = ctx,
            .function = Callback,
        };
        return function;
    }
};

fn toLower(str: []const u8) []const u8 {
    // <<<<<<< Updated upstream
    // =======
    std.debug.print("LOWER: {s}\n", .{str});
    // >>>>>>> Stashed changes
    var buf: [1024]u8 = undefined;
    _ = std.ascii.lowerString(&buf, str);
    return &buf;
}

fn toUpper(str: []const u8) []const u8 {
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
    handlers: std.StringHashMap(*const (fn ([]const u8) []const u8)),

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
                const endTime = @as(f64, @floatFromInt(timer.lap())) / @as(f64, @floatFromInt(std.time.ns_per_ms));

                std.debug.print("Event loop `{s}` was blocked for {d:3} ms due to this operation\n", .{ event.key, endTime });
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
        // <<<<<<< Updated upstream
        var res = task(event.data);
        @memcpy(result[0..res.len], res);
        // =======
        //         @memcpy(result[0..], task(event.data));
        // >>>>>>> Stashed changes

        var eventResult = EventResult{ .key = event.key, .result = &result };
        self.produceOutput(eventResult);
    }

    fn pushEvent(self: *EventLoop, event: Event) void {
        // <<<<<<< Updated upstream
        const sleepTime = 5000 * std.time.ns_per_ms;
        std.time.sleep(sleepTime);
        var task = self.handlers.get(event.key).?;
        var result: [1024]u8 = undefined;
        var res = task(event.data);

        @memcpy(result[0..res.len], res);
        // =======
        //         // std.time.sleep(3 * std.time.ns_per_us / 2);
        //         var task = self.handlers.get(event.key).?;
        //         // var eventResult = self.allocator.create(EventResult) catch @panic("Error allocating even result");
        //         // var result = self.allocator.create([]const u8) catch @panic("ERror allocating");
        //         var result: [1024]u8 = undefined;
        //         @memcpy(result[0..], task(event.data));
        //         std.debug.print("RESULT {s}\n", .{result});

        //         // std.debug.print("RESULT: {s}\n", .{eventResult.*.result});
        //         // var result = task(event.data);
        //         // var result: [14]u8 = undefined;
        //         // std.debug.print("RESULT: {s}, size {} string {s} size {}\n", .{ result.*, result.len, event.data, event.data.len });
        //         // @memcpy(result[0..14], task(event.data));
        // >>>>>>> Stashed changes
        var eventResult = EventResult{ .key = event.key, .result = &result };

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
            .handlers = std.StringHashMap(*const (fn ([]const u8) []const u8)).init(allocator),
            .processedEvents = std.atomic.Queue(EventResult).init(),
        };
    }
};

const EventResult = struct {
    key: []const u8,
    result: []const u8,
};
