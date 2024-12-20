const std = @import("std");
const Allocator = std.mem.Allocator;

fn Coord(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        fn eql(self: @This(), other: @This()) bool {
            return self.x == other.x and self.y == other.y;
        }
    };
}

const Point = Coord(usize);

const Dir = enum { North, South, East, West };

const FixedLineLengthBuffer = struct {
    line_length: usize,
    total_lines: usize,
    text: []const u8,
    const Self = @This();

    pub fn init(text: []const u8) !Self {
        var count = std.mem.count(u8, text, "\n");
        if (text[text.len - 1] != '\n') {
            count += 1;
        }
        const line_length = std.mem.indexOfScalar(u8, text, '\n') orelse return error.NoNewlineFound;

        return .{ .line_length = line_length, .total_lines = count, .text = text };
    }

    pub fn get_signed(self: Self, row: isize, col: isize) ?u8 {
        if (row < 0 or col < 0) {
            return null;
        } else {
            return self.get(@intCast(row), @intCast(col));
        }
    }

    pub fn indexOf(self: Self, needle: u8) ?Point {
        for (self.text, 0..) |c, i| {
            if (c == needle) {
                const col = i % (self.line_length + 1);
                const row = i / (self.line_length + 1);
                return Point{ .x = col, .y = row };
            }
        }

        return null;
    }

    pub fn get(self: Self, row: usize, col: usize) ?u8 {
        if (row < self.total_lines and col < self.line_length) {
            // Account for '\n' at end of line
            const index = row * (self.line_length + 1) + col;
            return self.text[index];
        }

        return null;
    }

    pub fn get_pos(self: Self, pos: Point) ?u8 {
        return self.get(pos.y, pos.x);
    }

    pub fn len(self: Self) usize {
        return self.total_lines;
    }

    pub fn line_len(self: Self) usize {
        return self.line_length;
    }
};

fn move(c: Point, dir: Dir, extent: usize) ?Point {
    switch (dir) {
        .North => {
            if (c.y > 0) {
                return .{ .x = c.x, .y = c.y - 1 };
            }
        },
        .East => {
            if (c.x + 1 < extent) {
                return .{ .x = c.x + 1, .y = c.y };
            }
        },
        .South => {
            if (c.y + 1 < extent) {
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

fn move_with_step(c: Point, dir: Dir, step: usize, extent: usize) ?Point {
    var a: ?Point = c;
    for (0..step) |_| {
        a = move(a.?, dir, extent);
        if (a == null) {
            break;
        }
    }
    return a;
}

// fn printCtx(map: FixedLineLengthBuffer, ch: Cheat) void {
//     for (0..map.len()) |y| {
//         for (0..map.len()) |x| {
//             const p = Point { .x = x, .y = y };
//             const c = map.get_pos(p).?;
//
//             if (ch.@"0".eql(p) or ch.@"1".eql(p)) {
//                 std.debug.print("c", .{});
//             } else {
//                 std.debug.print("{c}", .{ c });
//             }
//         }
//         std.debug.print("\n", .{});
//     }
// }

const DIRS = [_]Dir{ .East, .North, .South, .West };
const State = struct { pos: Point };
const Distances = std.AutoArrayHashMap(State, usize);
const Prev = std.AutoArrayHashMap(State, State);
const Counts = std.AutoArrayHashMap(usize, usize);

const cmp = struct {
    fn cmp(d: *Distances, s1: State, s2: State) std.math.Order {
        const d1 = d.get(s1) orelse std.math.maxInt(usize);
        const d2 = d.get(s2) orelse std.math.maxInt(usize);

        return std.math.order(d1, d2);
    }
};

const PQ = std.PriorityQueue(State, *Distances, cmp.cmp);

const Context = struct { map: FixedLineLengthBuffer, start_pos: Point, goal: Point };

fn walk(ctx: Context, dist: *Distances, ignored: ?Point, Q: *PQ) !usize {
    defer dist.clearRetainingCapacity();

    const initial_state = State{ .pos = ctx.start_pos };

    try dist.put(initial_state, 0);

    try Q.add(initial_state);

    while (Q.removeOrNull()) |u| {
        const step = 1;
        for (DIRS) |dir| {
            if (move_with_step(u.pos, dir, step, ctx.map.len())) |vpos| {
                const vst = State{ .pos = vpos };
                if (ctx.map.get_pos(vst.pos).? != '#' or (ignored != null and ignored.?.eql(vst.pos))) {
                    const v = dist.get(vst) orelse std.math.maxInt(usize);
                    const cost: usize = step;
                    const alt = dist.get(u);
                    if (alt != null and alt.? + cost < v) {
                        try dist.put(vst, alt.? + cost);
                        try Q.add(vst);
                    }
                }
            }
        }
    }

    var entries = dist.iterator();
    var minValue: usize = std.math.maxInt(usize);
    while (entries.next()) |entry| {
        if (entry.key_ptr.pos.eql(ctx.goal) and entry.value_ptr.* < minValue) {
            minValue = entry.value_ptr.*;
        }
    }

    return minValue;
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    const map = try FixedLineLengthBuffer.init(input);

    var dist = Distances.init(alloc);
    defer dist.deinit();

    var counts = Counts.init(alloc);
    defer counts.deinit();

    const start_pos = map.indexOf('S') orelse return error.NoStartFound;
    const goal = map.indexOf('E') orelse return error.NoEndFound;

    var Q = PQ.init(alloc, &dist);

    defer Q.deinit();

    const shortest_path = try walk(.{ .map = map, .start_pos = start_pos, .goal = goal }, &dist, null, &Q);

    for (1..map.len()) |y| {
        for (1..map.line_len()) |x| {
            if (map.get(y, x).? == '#') {
                const pp = Point{ .x = x, .y = y };
                const path = try walk(.{ .map = map, .start_pos = start_pos, .goal = goal }, &dist, pp, &Q);

                if (path < shortest_path) {
                    const save = shortest_path - path;
                    const ptr = try counts.getOrPutValue(save, 0);
                    ptr.value_ptr.* += 1;
                }
            }
        }
    }

    var countsIter = counts.iterator();

    var countOver100: usize = 0;

    while (countsIter.next()) |entry| {
        // std.debug.print("There are {d} cheats that save {d} picoseconds. \n", .{ entry.value_ptr.*, entry.key_ptr.* });

        if (entry.value_ptr.* >= 100) {
            countOver100 += 1;
        }
    }

    return countOver100;
}

// fn solve2(input: []const u8, alloc: Allocator) !usize {
//
// }

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day20/input",
        .{ .mode = .read_only },
    );
    defer file.close();

    const buffer = try file.readToEndAlloc(gpa, 1000000);

    const res = try solve1(buffer, gpa);

    std.debug.print("Part 1: {d}\n", .{res});

    // const res2 = try solve2(buffer, gpa);
    //
    // std.debug.print("Part 2: {d}\n", .{res2});
}

test "part 1 - simple" {
    const input =
        \\###############
        \\#...#...#.....#
        \\#.#.#.#.#.###.#
        \\#S#...#.#.#...#
        \\#######.#.#.###
        \\#######.#.#...#
        \\#######.#.###.#
        \\###..E#...#...#
        \\###.#######.###
        \\#...###...#...#
        \\#.#####.#.###.#
        \\#.#...#.#.#...#
        \\#.#.#.#.#.#.###
        \\#...#...#...###
        \\###############
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(0, res);
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
