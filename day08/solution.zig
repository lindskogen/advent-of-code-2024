const std = @import("std");
const Allocator = std.mem.Allocator;

const Coord = struct { x: isize, y: isize };

fn solve1(input: []const u8, alloc: Allocator) !isize {
    var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');
    const extent = std.mem.indexOfScalar(u8, input, '\n') orelse return error.InvalidInput;
    var antiNodePoints = std.AutoHashMap(Coord, void).init(alloc);
    defer antiNodePoints.deinit();
    var frequencies = std.AutoHashMap(u8, std.BoundedArray(Coord, 1000)).init(alloc);
    defer frequencies.deinit();

    var y: isize = 0;
    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '.') {
                continue;
            }

            var entry = try frequencies.getOrPut(c);

            if (!entry.found_existing) {
                entry.value_ptr.* = try std.BoundedArray(Coord, 1000).init(0);
            }
            try entry.value_ptr.append(.{ .x = @intCast(x), .y = y });
        }
        y += 1;
    }

    var freqIter = frequencies.iterator();

    while (freqIter.next()) |e| {
        const slice = e.value_ptr.slice();

        for (slice, 0..) |p1, i| {
            for (slice[(i + 1)..]) |p2| {
                const dx = p1.x - p2.x;
                const dy = p1.y - p2.y;

                const x1 = p1.x + dx;
                const y1 = p1.y + dy;

                const x2 = p2.x - dx;
                const y2 = p2.y - dy;

                if (x1 >= 0 and x1 < extent and y1 >= 0 and y1 < extent) {
                    try antiNodePoints.put(.{ .x = x1, .y = y1 }, {});
                }

                if (x2 >= 0 and x2 < extent and y2 >= 0 and y2 < extent) {
                    try antiNodePoints.put(.{ .x = x2, .y = y2 }, {});
                }
            }
        }
    }

    return antiNodePoints.count();
}

fn solve2(input: []const u8, alloc: Allocator) !isize {
    var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');
    const extent = std.mem.indexOfScalar(u8, input, '\n') orelse return error.InvalidInput;
    var antiNodePoints = std.AutoHashMap(Coord, void).init(alloc);
    defer antiNodePoints.deinit();
    var frequencies = std.AutoHashMap(u8, std.BoundedArray(Coord, 1000)).init(alloc);
    defer frequencies.deinit();

    var y: isize = 0;
    while (rowsIter.next()) |row| {
        for (row, 0..) |c, x| {
            if (c == '.') {
                continue;
            }

            var entry = try frequencies.getOrPut(c);

            if (!entry.found_existing) {
                entry.value_ptr.* = try std.BoundedArray(Coord, 1000).init(0);
            }
            try entry.value_ptr.append(.{ .x = @intCast(x), .y = y });
        }
        y += 1;
    }

    var freqIter = frequencies.iterator();

    while (freqIter.next()) |e| {
        const slice = e.value_ptr.slice();

        for (slice, 0..) |p1, i| {
            for (slice[(i + 1)..]) |p2| {
                const dx = p1.x - p2.x;
                const dy = p1.y - p2.y;

                var addedPoints = true;
                var d: isize = 0;

                while (addedPoints) {
                    addedPoints = false;
                    const x1 = p1.x + (dx * d);
                    const y1 = p1.y + (dy * d);

                    const x2 = p2.x - (dx * d);
                    const y2 = p2.y - (dy * d);

                    if (x1 >= 0 and x1 < extent and y1 >= 0 and y1 < extent) {
                        try antiNodePoints.put(.{ .x = x1, .y = y1 }, {});
                        addedPoints = true;
                    }

                    if (x2 >= 0 and x2 < extent and y2 >= 0 and y2 < extent) {
                        try antiNodePoints.put(.{ .x = x2, .y = y2 }, {});
                        addedPoints = true;
                    }

                    d += 1;
                }
            }
        }
    }

    return antiNodePoints.count();
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day08/input",
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
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(14, res);
}

test "part 2 - half" {
    const input =
        \\T.........
        \\...T......
        \\.T........
        \\..........
        \\..........
        \\..........
        \\..........
        \\..........
        \\..........
        \\..........
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(9, res);
}

test "part 2 - simple" {
    const input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(34, res);
}
