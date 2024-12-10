const std = @import("std");
const Allocator = std.mem.Allocator;

const FixedLineLengthBuffer = struct {
    line_length: usize,
    total_lines: usize,
    text: []const u8,

    pub fn init(text: []const u8) !@This() {
        var count = std.mem.count(u8, text, "\n");
        if (text[text.len - 1] != '\n') {
            count += 1;
        }
        const line_length = std.mem.indexOfScalar(u8, text, '\n') orelse return error.NoNewlineFound;

        return .{ .line_length = line_length, .total_lines = count, .text = text };
    }

    pub fn get_signed(self: @This(), row: isize, col: isize) ?u8 {
        if (row < 0 or col < 0) {
            return null;
        } else {
            return self.get(@intCast(row), @intCast(col));
        }
    }

    pub fn get(self: @This(), row: usize, col: usize) ?u8 {
        if (row < self.total_lines and col < self.line_length) {
            // Account for '\n' at end of line
            const index = row * (self.line_length + 1) + col;
            return self.text[index];
        }

        return null;
    }

    pub fn get_pos(self: @This(), pos: Coord) ?u8 {
        return self.get(pos.y, pos.x);
    }

    pub fn len(self: @This()) usize {
        return self.total_lines;
    }

    pub fn line_len(self: @This()) usize {
        return self.line_length;
    }
};

const Coord = struct { x: usize, y: usize };

fn move(c: Coord, dir: Dir, extent: usize) ?Coord {
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

const Dir = enum { North, South, East, West };

const DIRS = [_]Dir{ .East, .North, .South, .West };

const RecurData = struct { len: usize, ends: *std.AutoArrayHashMap(Coord, void) };

fn recurse(map: FixedLineLengthBuffer, pos: Coord, data: RecurData) !RecurData {
    if (data.len == 9) {
        try data.ends.put(pos, {});
        return .{ .len = 9, .ends = data.ends };
    }
    for (DIRS) |dir| {
        if (move(pos, dir, map.line_len())) |p| {
            if (map.get_pos(p).? == map.get_pos(pos).? + 1) {
                _ = try recurse(map, p, .{ .len = data.len + 1, .ends = data.ends });
            }
        }
    }
    return .{ .len = 0, .ends = data.ends };
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    const map = try FixedLineLengthBuffer.init(input);

    var zeros = std.ArrayList(Coord).init(alloc);
    defer zeros.deinit();

    for (0..map.len()) |y| {
        for (0..map.line_len()) |x| {
            if (map.get(y, x)) |c| {
                if (c == '0') {
                    try zeros.append(.{ .x = x, .y = y });
                }
            }
        }
    }

    var sum: usize = 0;
    var ends = std.AutoArrayHashMap(Coord, void).init(alloc);
    defer ends.deinit();

    for (zeros.items) |pos| {
        _ = try recurse(map, pos, .{ .len = 0, .ends = &ends });
        sum += ends.count();

        ends.clearRetainingCapacity();
    }

    return sum;
}

const RecurData2 = struct { len: usize, paths_collected: usize };

fn recurse2(map: FixedLineLengthBuffer, pos: Coord, data: RecurData2) RecurData2 {
    if (data.len == 9) {
        return .{ .len = 9, .paths_collected = data.paths_collected + 1 };
    }
    var count: usize = 0;
    for (DIRS) |dir| {
        if (move(pos, dir, map.line_len())) |p| {
            if (map.get_pos(p).? == map.get_pos(pos).? + 1) {
                const d = recurse2(map, p, .{ .len = data.len + 1, .paths_collected = 0 });

                count += d.paths_collected;
            }
        }
    }
    return .{ .len = 0, .paths_collected = count };
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
    const map = try FixedLineLengthBuffer.init(input);

    var zeros = std.ArrayList(Coord).init(alloc);
    defer zeros.deinit();

    for (0..map.len()) |y| {
        for (0..map.line_len()) |x| {
            if (map.get(y, x)) |c| {
                if (c == '0') {
                    try zeros.append(.{ .x = x, .y = y });
                }
            }
        }
    }

    var sum: usize = 0;

    for (zeros.items) |pos| {
        const p = recurse2(map, pos, .{ .len = 0, .paths_collected = 0 }).paths_collected;
        sum += p;
    }

    return sum;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day10/input",
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
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(36, res);
}

test "part 2 - simple" {
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(81, res);
}
