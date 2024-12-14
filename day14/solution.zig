const std = @import("std");
const c = @cImport({
    @cDefine("FENSTER_HEADER", {});
    @cInclude("fenster.h");
});
const Allocator = std.mem.Allocator;

fn Coord(comptime T: type) type {
    return struct { x: T, y: T };
}

const Point = Coord(isize);

fn solve1(input: []const u8, _: Allocator, extent: Point) !usize {
    var rowIter = std.mem.tokenizeScalar(u8, input, '\n');

    var q1: usize = 0;
    var q2: usize = 0;
    var q3: usize = 0;
    var q4: usize = 0;

    while (rowIter.next()) |row| {
        var iter = std.mem.tokenizeAny(u8, row, "pv= ,");

        const px = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);
        const py = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);

        const vx = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);
        const vy = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);

        var p = Point{ .x = px, .y = py };
        const v = Point{ .x = vx, .y = vy };

        for (0..100) |_| {
            p.x = @rem(p.x + v.x, extent.x);
            if (p.x < 0) {
                p.x += extent.x;
            }
            p.y = @rem(p.y + v.y, extent.y);
            if (p.y < 0) {
                p.y += extent.y;
            }
        }

        if (p.x < @divFloor(extent.x, 2)) {
            if (p.y < @divFloor(extent.y, 2)) {
                q1 += 1;
            } else if (p.y > @divFloor(extent.y, 2)) {
                q3 += 1;
            }
        } else if (p.x > @divFloor(extent.x, 2)) {
            if (p.y < @divFloor(extent.y, 2)) {
                q2 += 1;
            } else if (p.y > @divFloor(extent.y, 2)) {
                q4 += 1;
            }
        }
    }

    return q1 * q2 * q3 * q4;
}

const Robot = struct { p: Point, v: Point };

fn print_grid(robots: []Robot, extent: Point) void {
    for (0..@intCast(extent.y)) |y| {
        for (0..@intCast(extent.x)) |x| {
            var print: u8 = ' ';
            for (robots) |r| {
                if (r.p.x == x and r.p.y == y) {
                    print = '#';
                    break;
                }
            }
            std.debug.print("{c}", .{ print });
        }
        std.debug.print("\n", .{});
    }
}

fn solve2(input: []const u8, _: Allocator, comptime extent: Point) !usize {
    var robots = try std.BoundedArray(Robot, 500).init(0);
    var rowIter = std.mem.tokenizeScalar(u8, input, '\n');

    while (rowIter.next()) |row| {
        var iter = std.mem.tokenizeAny(u8, row, "pv= ,");

        const px = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);
        const py = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);

        const vx = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);
        const vy = try std.fmt.parseInt(isize, iter.next() orelse return error.InvalidInput, 10);

        const p = Point{ .x = px, .y = py };
        const v = Point{ .x = vx, .y = vy };

        try robots.append(.{ .p = p, .v = v });
    }

    for (1..std.math.maxInt(usize)) |seconds| {
        var board: [extent.x * extent.y]u1 = std.mem.zeroes([extent.x * extent.y]u1);

        for (robots.slice()) |*r| {
            r.p.x = @rem(r.p.x + r.v.x, extent.x);
            if (r.p.x < 0) {
                r.p.x += extent.x;
            }
            r.p.y = @rem(r.p.y + r.v.y, extent.y);
            if (r.p.y < 0) {
                r.p.y += extent.y;
            }

            board[@as(usize, @intCast(r.p.y)) * extent.x + @as(usize, @intCast(r.p.x))] = 1;
        }

        if (std.mem.indexOf(u1, &board, &[_]u1{1} ** 10) != null) {
            print_grid(robots.slice(), extent);
            return seconds;
        }
    }


    return error.NoTreeFound;

}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day14/input",
        .{ .mode = .read_only },
    );
    defer file.close();

    const buffer = try file.readToEndAlloc(gpa, 1000000);

    const res = try solve1(buffer, gpa, .{ .x = 101, .y = 103 });

    std.debug.print("Part 1: {d}\n", .{res});

    const res2 = try solve2(buffer, gpa, .{ .x = 101, .y = 103 });

    std.debug.print("Part 2: {d}\n", .{res2});
}

test "part 1 - simple" {
    const input =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa, .{ .x = 11, .y = 7 });

    try std.testing.expectEqual(12, res);
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
