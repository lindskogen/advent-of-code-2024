const std = @import("std");
const Allocator = std.mem.Allocator;

fn absDiff(comptime T: type, a: T, b: T) T {
    return if (a > b) a - b else b - a;
}

fn manhattan_distance(p1: Point, p2: Point) usize {
    return absDiff(usize, p1.x, p2.x) + absDiff(usize, p1.y, p2.y);
}

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

const DIRS = [_]Dir{ .East, .North, .South, .West };
const Distances = std.AutoArrayHashMap(Point, usize);

const Context = struct { map: FixedLineLengthBuffer, start_pos: Point, goal: Point };

fn walk(ctx: Context, dist: *Distances) !void {
    const initial_state = ctx.start_pos;

    try dist.put(initial_state, 0);

    var state = initial_state;

    while (!state.eql(ctx.goal)) {
        for (DIRS) |d| {
            if (move(state, d, ctx.map.len())) |p| {
                if (!dist.contains(p) and ctx.map.get_pos(p) != '#') {
                    const newDist = dist.get(state).? + 1;
                    try dist.putNoClobber(p, newDist);
                    state = p;
                    break;
                }
            }
        }
    }
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    const map = try FixedLineLengthBuffer.init(input);

    var dist = Distances.init(alloc);
    defer dist.deinit();

    const start_pos = map.indexOf('S') orelse return error.NoStartFound;
    const goal = map.indexOf('E') orelse return error.NoEndFound;

    try walk(.{ .map = map, .start_pos = start_pos, .goal = goal }, &dist);

    const keys = dist.keys();
    var countOver100: usize = 0;
    for (keys, 0..) |p1, i| {
        for (keys[i + 1 ..]) |p2| {
            const d1 = dist.get(p1).?;
            const d2 = dist.get(p2).?;

            const d = manhattan_distance(p1, p2);

            if (d == 2 and d2 - d1 - d >= 100) {
                countOver100 += 1;
            }
        }
    }

    return countOver100;
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
    const map = try FixedLineLengthBuffer.init(input);

    var dist = Distances.init(alloc);
    defer dist.deinit();

    const start_pos = map.indexOf('S') orelse return error.NoStartFound;
    const goal = map.indexOf('E') orelse return error.NoEndFound;

    try walk(.{ .map = map, .start_pos = start_pos, .goal = goal }, &dist);

    const keys = dist.keys();
    var countOver100: usize = 0;
    for (keys, 0..) |p1, i| {
        for (keys[i + 1 ..]) |p2| {
            const d1 = dist.get(p1).?;
            const d2 = dist.get(p2).?;

            const d = manhattan_distance(p1, p2);

            if (d <= 20 and d2 - d1 - d >= 100) {
                countOver100 += 1;
            }
        }
    }

    return countOver100;
}

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

    const res2 = try solve2(buffer, gpa);

    std.debug.print("Part 2: {d}\n", .{res2});
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
