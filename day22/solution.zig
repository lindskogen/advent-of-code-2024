const std = @import("std");
const Allocator = std.mem.Allocator;

const Iter = struct {
    n: usize,

    fn next(self: *@This()) usize {
        const mn: usize = @as(u24, @truncate((self.n * 64) ^ self.n));
        const dn: usize = @as(u24, @truncate((mn / 32) ^ mn));
        self.n = @as(u24, @truncate((dn * 2048) ^ dn));
        return self.n;
    }
};

fn make_iter(n: usize) Iter {
    return Iter{
        .n = n,
    };
}

fn solve1(input: []const u8, _: Allocator) !usize {
    var sum: usize = 0;
    var rowIter = std.mem.tokenizeScalar(u8, input, '\n');

    while (rowIter.next()) |row| {
        var num = try std.fmt.parseInt(usize, row, 10);
        var iter = make_iter(num);
        for (0..2000) |_| {
            num = iter.next();
        }

        sum += num;
    }

    return sum;
}

// fn solve2(input: []const u8, alloc: Allocator) !usize {
//
// }

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day22/input",
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
        \\1
        \\10
        \\100
        \\2024
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(0, res);
}

test make_iter {
    var iter = make_iter(123);
    const nums = [_]usize{ 15887950, 16495136, 527345, 704524, 1553684, 12683156, 11100544, 12249484, 7753432, 5908254 };

    for (0..10) |i| {
        try std.testing.expectEqual(nums[i], iter.next());
    }
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

test "modulo" {
    const res: u24 = @truncate(100000000);
    try std.testing.expectEqual(16113920, res);
}
