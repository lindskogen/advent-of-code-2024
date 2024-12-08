const std = @import("std");
const Allocator = std.mem.Allocator;

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

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var visited = std.AutoArrayHashMap(Coord, void).init(alloc);
    var map = std.AutoArrayHashMap(Coord, u8).init(alloc);

    var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');

    const extent = std.mem.indexOfScalar(u8, input, '\n') orelse return error.NoNewline;

    var foundPos: ?Coord = null;
    var guardDir: Dir = .North;

    var y: usize = 0;
    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '#') {
                try map.putNoClobber(.{ .x = x, .y = y }, c);
            } else if (c == '^') {
                foundPos = .{ .x = x, .y = y };
            }
        }
        y += 1;
    }

    var guardPos = foundPos orelse return error.NoGuardInInput;
    try visited.put(guardPos, {});

    while (move(guardPos, guardDir, extent)) |next| {
        if (map.get(next)) |_| {
            guardDir = switch (guardDir) {
                .North => .East,
                .East => .South,
                .South => .West,
                .West => .North,
            };
        } else {
            guardPos = next;
            try visited.put(next, {});
        }
    }

    return visited.count();
}

fn detect_loop(map: std.AutoArrayHashMap(Coord, void), initialGuardPos: Coord, extent: usize, visited: *std.AutoArrayHashMap(Coord, Dir)) !bool {
    var guardDir: Dir = .North;
    var guardPos: Coord = initialGuardPos;

    try visited.put(guardPos, guardDir);

    while (move(guardPos, guardDir, extent)) |next| {
        if (visited.get(next)) |prevDir| {
            if (prevDir == guardDir) {
                return true;
            }
        }
        if (map.get(next)) |_| {
            guardDir = switch (guardDir) {
                .North => .East,
                .East => .South,
                .South => .West,
                .West => .North,
            };
        } else {
            guardPos = next;
            try visited.put(next, guardDir);
        }
    }

    return false;
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
    var map = std.AutoArrayHashMap(Coord, void).init(alloc);

    var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');

    const extent = std.mem.indexOfScalar(u8, input, '\n') orelse return error.NoNewline;

    var foundPos: ?Coord = null;
    {
        var y: usize = 0;
        while (rowsIter.next()) |row| {
            for (row, 0..) |c, x| {
                if (c == '#') {
                    try map.putNoClobber(.{ .x = x, .y = y }, {});
                } else if (c == '^') {
                    foundPos = .{ .x = x, .y = y };
                }
            }
            y += 1;
        }
    }

    const initialGuardPos = foundPos orelse return error.NoGuardInInput;
    var visited = std.AutoArrayHashMap(Coord, void).init(alloc);
    var local_visited = std.AutoArrayHashMap(Coord, Dir).init(alloc);

    {
        var guardPos = initialGuardPos;
        var guardDir: Dir = .North;
        try visited.put(guardPos, {});

        while (move(guardPos, guardDir, extent)) |next| {
            if (map.get(next)) |_| {
                guardDir = switch (guardDir) {
                    .North => .East,
                    .East => .South,
                    .South => .West,
                    .West => .North,
                };
            } else {
                guardPos = next;
                try visited.put(next, {});
            }
        }
    }

    var sum: usize = 0;
    var iter = visited.iterator();

    while (iter.next()) |entry| {
        const pos = entry.key_ptr;
        if (initialGuardPos.x == pos.x and initialGuardPos.y == pos.y) {
            continue;
        } else if (map.get(pos.*)) |_| {
            continue;
        } else {
            try map.putNoClobber(pos.*, {});
            defer _ = map.swapRemove(pos.*);
            defer local_visited.clearRetainingCapacity();

            if (try detect_loop(map, initialGuardPos, extent, &local_visited)) {
                sum += 1;
            }
        }
    }

    return sum;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day06/input",
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
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(41, res);
}

test "part 2 - simple" {
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(6, res);
}
