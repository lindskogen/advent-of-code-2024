const std = @import("std");
const Allocator = std.mem.Allocator;


fn recursiveSum(slice: []usize, sum: usize, target: usize) ?usize {
    if (sum > target) {
        return null;
    }
    if (slice.len == 0) {
        if (sum == target) {
            return sum;
        } else {
            return null;
        }
    }

    if (recursiveSum(slice[1..], sum + slice[0], target)) |total| {
        return total;
    } else if (recursiveSum(slice[1..], (if (sum == 0) 1 else sum) * slice[0], target)) |total| {
        return total;
    } else {
        return null;
    }
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');
    var total: usize = 0;

    while (rowsIter.next()) |row| {
        var numbersIter = std.mem.tokenizeAny(u8, row, ": ");
        const target = try std.fmt.parseInt(usize, numbersIter.next() orelse return error.InvalidInput, 10);
        var list = std.ArrayList(usize).init(alloc);
        defer list.deinit();

        while (numbersIter.next()) |num| {
            const n = try std.fmt.parseInt(usize, num, 10);
            try list.append(n);
        }

        if (recursiveSum(list.items, 0, target)) |_| {
            total += target;
        }
    }

    return total;
}


fn recursiveSum2(slice: []usize, sum: usize, target: usize, alloc: Allocator) !?usize {
    if (sum > target) {
        return null;
    }
    if (slice.len == 0) {
        if (sum == target) {
            return sum;
        } else {
            return null;
        }
    }

    if (try recursiveSum2(slice[1..], sum + slice[0], target, alloc)) |total| {
        return total;
    } else if (try recursiveSum2(slice[1..], (if (sum == 0) 1 else sum) * slice[0], target, alloc)) |total| {
        return total;
    }

    if (sum == 0) {
        const prt = try std.fmt.allocPrint(alloc, "{d}{d}", .{ slice[0], slice[1] });
        defer alloc.free(prt);
        const parse = try std.fmt.parseInt(usize, prt, 10);
        if (try recursiveSum2(slice[2..], parse, target, alloc)) |total| {
            return total;
        }
    } else {
        const prt = try std.fmt.allocPrint(alloc, "{d}{d}", .{ sum, slice[0] });
        defer alloc.free(prt);
        const parse = try std.fmt.parseInt(usize, prt, 10);
        if (try recursiveSum2(slice[1..], parse, target, alloc)) |total| {
            return total;
        }
    }
    return null;
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
    var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');
    var total: usize = 0;

    while (rowsIter.next()) |row| {
        var numbersIter = std.mem.tokenizeAny(u8, row, ": ");
        const target = try std.fmt.parseInt(usize, numbersIter.next() orelse return error.InvalidInput, 10);
        var list = std.ArrayList(usize).init(alloc);
        defer list.deinit();

        while (numbersIter.next()) |num| {
            const n = try std.fmt.parseInt(usize, num, 10);
            try list.append(n);
        }

        if (try recursiveSum2(list.items, 0, target, alloc)) |_| {
            total += target;
        }
    }

    return total;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day07/input",
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
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(3749, res);
}


test "part 2 - simple" {
    const input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(11387, res);
}
