const std = @import("std");
const Allocator = std.mem.Allocator;

const SIZE: usize = 5;

fn parse(input: []const u8, locks: *std.ArrayList([SIZE]u8), keys: *std.ArrayList([SIZE]u8)) !void {
    var groupIter = std.mem.tokenizeSequence(u8, input, "\n\n");
    while (groupIter.next()) |group| {
        var cylinder_values = [SIZE]u8{ 0, 0, 0, 0, 0 };
        if (group[0] == '#') {
            // lock
            var idx: usize = SIZE + 1;

            while (idx < 35) {
                for (0..5) |o| {
                    if (group[idx + o] == '#') {
                        cylinder_values[o] += 1;
                    }
                }
                idx += SIZE + 1;
            }
            try locks.append(cylinder_values);
        } else {
            // key
            var idx: usize = 30;
            while (idx > 5) {
                for (0..5) |o| {
                    if (group[idx + o] == '#') {
                        cylinder_values[o] += 1;
                    }
                }

                idx -= SIZE + 1;
            }

            try keys.append(cylinder_values);
        }
    }
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var locks = std.ArrayList([SIZE]u8).init(alloc);
    defer locks.deinit();
    var keys = std.ArrayList([SIZE]u8).init(alloc);
    defer keys.deinit();

    try parse(input, &locks, &keys);


    var count: usize = 0;

    for (keys.items) |key| {
        check_lock: for (locks.items) |lock| {
            for (key, lock) |k, l| {
                if (k + l > 5) {
                    continue :check_lock;
                }
            }
            count += 1;
        }
    }

    return count;
}

// fn solve2(input: []const u8, alloc: Allocator) !usize {
//
// }

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day25/input",
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

test "part 1 - parse" {
    const input =
        \\#####
        \\.####
        \\.####
        \\.####
        \\.#.#.
        \\.#...
        \\.....
        \\
        \\.....
        \\#....
        \\#....
        \\#...#
        \\#.#.#
        \\#.###
        \\#####
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    var locks = std.ArrayList([SIZE]u8).init(gpa);
    defer locks.deinit();
    var keys = std.ArrayList([SIZE]u8).init(gpa);
    defer keys.deinit();

    try parse(input, &locks, &keys);

    try std.testing.expectEqual([5]u8{ 0, 5, 3, 4, 3 }, locks.items[0]);
    try std.testing.expectEqual([5]u8{ 5, 0, 2, 1, 3 }, keys.items[0]);
}

test "part 1 - simple" {
    const input =
        \\#####
        \\.####
        \\.####
        \\.####
        \\.#.#.
        \\.#...
        \\.....
        \\
        \\#####
        \\##.##
        \\.#.##
        \\...##
        \\...#.
        \\...#.
        \\.....
        \\
        \\.....
        \\#....
        \\#....
        \\#...#
        \\#.#.#
        \\#.###
        \\#####
        \\
        \\.....
        \\.....
        \\#.#..
        \\###..
        \\###.#
        \\###.#
        \\#####
        \\
        \\.....
        \\.....
        \\.....
        \\#....
        \\#.#..
        \\#.#.#
        \\#####
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(3, res);
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
