const std = @import("std");
const Allocator = std.mem.Allocator;

const Res = union(enum) {
    one: usize,
    two: struct { usize, usize },
};

fn step(num: usize) !Res {
    if (num == 0) {
        return .{ .one = 1 };
    }

    const num_digits = std.math.log10_int(num) + 1;
    if (num_digits % 2 == 0) {
        const mid = try std.math.powi(usize, 10, num_digits / 2);

        return .{ .two = .{ num / mid, num % mid } };
    }

    return .{ .one = num * 2024 };
}

fn work(comptime count: usize, input: []const u8, alloc: Allocator) !usize {
    var map = std.AutoArrayHashMap(usize, usize).init(alloc);
    defer map.deinit();
    var newMap = std.AutoArrayHashMap(usize, usize).init(alloc);
    defer newMap.deinit();

    var rowIter = std.mem.tokenizeAny(u8, input, " \n");

    while (rowIter.next()) |n| {
        const num = try std.fmt.parseInt(usize, n, 10);
        const entry = try map.getOrPutValue(num, 0);
        entry.value_ptr.* += 1;
    }

    for (0..count) |_| {
        var iter = map.iterator();
        while (iter.next()) |entry| {
            switch (try step(entry.key_ptr.*)) {
                .one => |n| {
                    const e1 = try newMap.getOrPutValue(n, 0);
                    e1.value_ptr.* += entry.value_ptr.*;
                },
                .two => |s| {
                    const e1 = try newMap.getOrPutValue(s.@"0", 0);
                    e1.value_ptr.* += entry.value_ptr.*;

                    const e2 = try newMap.getOrPutValue(s.@"1", 0);
                    e2.value_ptr.* += entry.value_ptr.*;
                },
            }
        }

        map.clearRetainingCapacity();
        const d = map;
        map = newMap;
        newMap = d;
    }

    var sum: usize = 0;

    const valueIter = map.values();
    for (valueIter) |v| {
        sum += v;
    }

    return sum;
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    return work(25, input, alloc);
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
    return work(75, input, alloc);
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day11/input",
        .{ .mode = .read_only },
    );
    defer file.close();

    const buffer = try file.readToEndAlloc(gpa, 1000000);

    const res = try solve1(buffer, gpa);

    std.debug.print("Part 1: {d}\n", .{res});

    const res2 = try solve2(buffer, gpa);

    std.debug.print("Part 2: {d}\n", .{res2});
}

test "step" {
    try std.testing.expectEqual(Res{ .one = 1 }, try step(0));
    try std.testing.expectEqual(Res{ .two = .{ 10, 0 } }, try step(1000));
    try std.testing.expectEqual(Res{ .two = .{ 9, 9 } }, try step(99));
    try std.testing.expectEqual(Res{ .two = .{ 1, 0 } }, try step(10));
    try std.testing.expectEqual(Res{ .one = 2021976 }, try step(999));
    try std.testing.expectEqual(Res{ .one = 2024 * 2 }, try step(2));
}

test "part 1 - simple" {
    const input = "125 17";

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(55312, res);
}
