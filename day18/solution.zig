const std = @import("std");
const Allocator = std.mem.Allocator;

const Dir = enum { North, South, East, West };

fn Coord(comptime T: type) type {
    return struct { x: T, y: T };
}

const Point = Coord(usize);

fn move(c: Point, dir: Dir, extent: usize) ?Point {
    switch (dir) {
        .North => {
            if (c.y > 0) {
                return .{ .x = c.x, .y = c.y - 1 };
            }
        },
        .East => {
            if (c.x + 1 <= extent) {
                return .{ .x = c.x + 1, .y = c.y };
            }
        },
        .South => {
            if (c.y + 1 <= extent) {
                return .{ .x = c.x, .y = c.y + 1 };
            }
        },
        .West => {
            if (c.x > 0) {
                return .{ .x = c.x - 1, .y = c.y };
            }
        },
    }
    return null;
}

const DIRS = [_]Dir{ .East, .North, .South, .West };
const Distances = std.AutoArrayHashMap(Point, usize);

fn solve1(input: []const u8, extent: usize, alloc: Allocator) !usize {
    var map = std.AutoArrayHashMap(Point, void).init(alloc);
    defer map.deinit();
    var dist = Distances.init(alloc);
    defer dist.deinit();

    var rowIter = std.mem.tokenizeAny(u8, input, "\n,");
    for (0..1024) |_| {
        const xs = rowIter.next() orelse return error.UnevenXY;
        const ys = rowIter.next() orelse return error.UnevenXY;

        const x = try std.fmt.parseInt(usize, xs, 10);
        const y = try std.fmt.parseInt(usize, ys, 10);

        try map.putNoClobber(.{ .x = x, .y = y }, {});
    }

    const start_pos = Point{ .x = 0, .y = 0 };
    const goal = Point{ .x = extent, .y = extent };

    try dist.put(start_pos, 0);

    const cmp = struct {
        fn cmp(d: *Distances, s1: Point, s2: Point) std.math.Order {
            const d1 = d.get(s1) orelse std.math.maxInt(usize);
            const d2 = d.get(s2) orelse std.math.maxInt(usize);

            return std.math.order(d1, d2);
        }
    };

    var Q = std.PriorityQueue(Point, *Distances, cmp.cmp).init(alloc, &dist);
    defer Q.deinit();

    try Q.add(start_pos);

    while (Q.removeOrNull()) |u| {
        for (DIRS) |dir| {
            if (move(u, dir, extent)) |vst| {
                if (!map.contains(vst)) {
                    const v = dist.get(vst) orelse std.math.maxInt(usize);
                    const cost: usize = 1;
                    const alt = dist.get(u);
                    if (alt != null and alt.? + cost < v) {
                        try dist.put(vst, alt.? + cost);
                        try Q.add(vst);
                    }
                }
            }
        }
    }

    return dist.get(goal).?;
}

fn solve2(input: []const u8, extent: usize, alloc: Allocator) !?Point {
    var map = std.AutoArrayHashMap(Point, void).init(alloc);
    defer map.deinit();
    var visited = std.AutoArrayHashMap(Point, void).init(alloc);
    defer visited.deinit();

    var dist = Distances.init(alloc);
    defer dist.deinit();
    var prev = std.AutoArrayHashMap(Point, Point).init(alloc);
    defer prev.deinit();

    var rowIter = std.mem.tokenizeAny(u8, input, "\n,");
    for (0..1024) |_| {
        const xs = rowIter.next() orelse return error.UnevenXY;
        const ys = rowIter.next() orelse return error.UnevenXY;

        const x = try std.fmt.parseInt(usize, xs, 10);
        const y = try std.fmt.parseInt(usize, ys, 10);

        try map.putNoClobber(.{ .x = x, .y = y }, {});
    }

    const start_pos = Point{ .x = 0, .y = 0 };
    const goal = Point{ .x = extent, .y = extent };

    const cmp = struct {
        fn cmp(d: *Distances, s1: Point, s2: Point) std.math.Order {
            const d1 = d.get(s1) orelse std.math.maxInt(usize);
            const d2 = d.get(s2) orelse std.math.maxInt(usize);

            return std.math.order(d1, d2);
        }
    };
    var Q = std.PriorityQueue(Point, *Distances, cmp.cmp).init(alloc, &dist);
    defer Q.deinit();

    while (true) {
        const xs = rowIter.next() orelse return error.UnevenXY;
        const ys = rowIter.next() orelse return error.UnevenXY;

        const x = try std.fmt.parseInt(usize, xs, 10);
        const y = try std.fmt.parseInt(usize, ys, 10);

        const last_corrupted = Point{ .x = x, .y = y };

        try map.putNoClobber(last_corrupted, {});

        if (visited.count() > 0 and !visited.contains(last_corrupted)) {
            continue;
        }

        visited.clearRetainingCapacity();

        try dist.put(start_pos, 0);

        try Q.add(start_pos);

        while (Q.removeOrNull()) |u| {
            for (DIRS) |dir| {
                if (move(u, dir, extent)) |v| {
                    if (!map.contains(v)) {
                        const v_dist = dist.get(v) orelse std.math.maxInt(usize);
                        const cost: usize = 1;
                        const alt = dist.get(u);
                        if (alt != null and alt.? + cost < v_dist) {
                            try dist.put(v, alt.? + cost);
                            try prev.put(v, u);
                            try Q.add(v);
                        }
                    }
                }
            }
        }

        if (dist.get(goal)) |_| {
            var prev2 = goal;
            while (prev.get(prev2)) |p| {
                try visited.put(p, {});
                prev2 = p;
            }
        }

        if (dist.get(goal) == null) {
            return last_corrupted;
        }

        dist.clearRetainingCapacity();
        prev.clearRetainingCapacity();
    }

    return null;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day18/input",
        .{ .mode = .read_only },
    );
    defer file.close();

    const buffer = try file.readToEndAlloc(gpa, 1000000);

    const res = try solve1(buffer, 70, gpa);

    std.debug.print("Part 1: {d}\n", .{res});

    const res2 = try solve2(buffer, 70, gpa);

    std.debug.print("Part 2: {d},{d}\n", .{ res2.?.x, res2.?.y });
}

test "part 1 - simple" {
    const input =
        \\5,4
        \\4,2
        \\4,5
        \\3,0
        \\2,1
        \\6,3
        \\2,4
        \\1,5
        \\0,6
        \\3,3
        \\2,6
        \\5,1
        \\1,2
        \\5,5
        \\2,5
        \\6,5
        \\1,4
        \\0,4
        \\6,4
        \\1,1
        \\6,1
        \\1,0
        \\0,5
        \\1,6
        \\2,0
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, 6, gpa);

    try std.testing.expectEqual(22, res);
}

// test "part 2 - simple" {
//   const input =
//     \\
//     \\
//     ;
//
//
//   var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
//   defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
//
//   const gpa = general_purpose_allocator.allocator();
//
//   const res = try solve2(input, gpa);
//
//   try std.testing.expectEqual(0, res);
// }
