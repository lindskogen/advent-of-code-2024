const std = @import("std");
const Allocator = std.mem.Allocator;

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var sum: usize = 0;

    var beforeMap = std.AutoHashMap(usize, std.StaticBitSet(100)).init(alloc);
    defer beforeMap.deinit();
    var afterMap = std.AutoHashMap(usize, std.StaticBitSet(100)).init(alloc);
    defer afterMap.deinit();

    var groups = std.mem.tokenizeSequence(u8, input, "\n\n");

    const orderingRules = groups.next() orelse return error.InvalidInput;

    var rulesIter = std.mem.tokenizeScalar(u8, orderingRules, '\n');

    while (rulesIter.next()) |rule| {
        var ruleIter = std.mem.tokenizeScalar(u8, rule, '|');

        const before = try std.fmt.parseInt(usize, ruleIter.next() orelse return error.InvalidInput, 10);
        const after = try std.fmt.parseInt(usize, ruleIter.next() orelse return error.InvalidInput, 10);

        var entryBefore = try beforeMap.getOrPutValue(before, std.StaticBitSet(100).initEmpty());
        var entryAfter = try afterMap.getOrPutValue(after, std.StaticBitSet(100).initEmpty());

        entryBefore.value_ptr.set(after);
        entryAfter.value_ptr.set(before);
    }

    const updateRows = groups.next() orelse return error.InvalidInput;
    var updateRowIter = std.mem.tokenizeScalar(u8, updateRows, '\n');

    outer: while (updateRowIter.next()) |updatesRow| {
        var updates = try std.BoundedArray(usize, 25).init(0);
        var updateIter = std.mem.tokenizeScalar(u8, updatesRow, ',');

        while (updateIter.next()) |u| {
            const a = try std.fmt.parseInt(usize, u, 10);
            try updates.append(a);
        }

        const slice = updates.slice();

        for (slice, 0..) |n, index| {
            if (beforeMap.get(n)) |entry| {
                // check all numbers before N
                for (0..index) |i| {
                    const nn = slice[i];
                    const isset = entry.isSet(nn);
                    if (isset) {
                        continue :outer;
                    }
                }
            }

            if (afterMap.get(n)) |entry| {
                // check all numbers after N
                for ((index + 1)..slice.len) |i| {
                    const nn = slice[i];
                    const isset = entry.isSet(nn);
                    if (isset) {
                        continue :outer;
                    }
                }
            }
        }
        // All before and after are valid!
        sum += slice[slice.len / 2];
    }

    return sum;
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
    var sum: usize = 0;

    var beforeMap = std.AutoHashMap(usize, std.StaticBitSet(100)).init(alloc);
    defer beforeMap.deinit();
    var afterMap = std.AutoHashMap(usize, std.StaticBitSet(100)).init(alloc);
    defer afterMap.deinit();

    var groups = std.mem.tokenizeSequence(u8, input, "\n\n");

    const orderingRules = groups.next() orelse return error.InvalidInput;

    var rulesIter = std.mem.tokenizeScalar(u8, orderingRules, '\n');

    while (rulesIter.next()) |rule| {
        var ruleIter = std.mem.tokenizeScalar(u8, rule, '|');

        const before = try std.fmt.parseInt(usize, ruleIter.next() orelse return error.InvalidInput, 10);
        const after = try std.fmt.parseInt(usize, ruleIter.next() orelse return error.InvalidInput, 10);

        var entryBefore = try beforeMap.getOrPutValue(before, std.StaticBitSet(100).initEmpty());
        var entryAfter = try afterMap.getOrPutValue(after, std.StaticBitSet(100).initEmpty());

        entryBefore.value_ptr.set(after);
        entryAfter.value_ptr.set(before);
    }

    const updateRows = groups.next() orelse return error.InvalidInput;
    var updateRowIter = std.mem.tokenizeScalar(u8, updateRows, '\n');

    while (updateRowIter.next()) |updatesRow| {
        var isOrderedCorrectly = true;
        var updates = try std.BoundedArray(usize, 25).init(0);
        var updateIter = std.mem.tokenizeScalar(u8, updatesRow, ',');

        while (updateIter.next()) |u| {
            const a = try std.fmt.parseInt(usize, u, 10);
            try updates.append(a);
        }

        const slice = updates.slice();

        for (slice, 0..) |n, index| {
            if (beforeMap.get(n)) |entry| {
                // check all numbers before N
                for (0..index) |i| {
                    const nn = slice[i];
                    const isset = entry.isSet(nn);
                    if (isset) {
                        isOrderedCorrectly = false;
                        break;
                    }
                }
            }

            if (isOrderedCorrectly) {
                if (afterMap.get(n)) |entry| {
                    // check all numbers after N
                    for ((index + 1)..slice.len) |i| {
                        const nn = slice[i];
                        const isset = entry.isSet(nn);
                        if (isset) {
                            isOrderedCorrectly = false;
                            break;
                        }
                    }
                }
            }
        }

        const sorter = struct {
            fn sortByBefore(ctx: @TypeOf(beforeMap), lhs: usize, rhs: usize) bool {
                if (ctx.get(lhs)) |entry| {
                    if (entry.isSet(rhs)) {
                        return true;
                    }
                }
                return false;
            }
        };

        if (!isOrderedCorrectly) {
            // fix sorting...
            std.mem.sort(usize, slice, beforeMap, sorter.sortByBefore);
            sum += slice[slice.len / 2];
        }
    }

    return sum;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day05/input",
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
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(143, res);
}

test "part 2 - simple" {
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(123, res);
}
