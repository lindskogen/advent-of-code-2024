const std = @import("std");
const Allocator = std.mem.Allocator;

const Pair = std.meta.Tuple(&.{ isize, isize });

const dirs1 = [_]Pair{ .{ -1, 0 }, .{ -1, -1 }, .{ -1, 1 }, .{ 1, 0 }, .{ 1, -1 }, .{ 1, 1 }, .{ 0, -1 }, .{ 0, 1 } };

const WORD = "XMAS";

fn solve1(input: []const u8, _: Allocator) !usize {
    const rows = try FixedLineLengthBuffer.init(input);

    var count: usize = 0;

    for (0..rows.len()) |y| {
        for (0..rows.line_len()) |x| {
            dir: for (dirs1) |p| {
                inline for (0..4) |d| {
                    const yd: isize = @as(isize, @intCast(y)) + p[0] * d;
                    const xd: isize = @as(isize, @intCast(x)) + p[1] * d;

                    if (rows.get_signed(yd, xd)) |c| {
                        if (c != WORD[d]) {
                            continue :dir;
                        }
                    } else {
                        continue :dir;
                    }
                }
                count += 1;
            }
        }
    }

    return count;
}

const dirs2 = [_][2]Pair{
    [_]Pair{ .{ -1, -1 }, .{ 1, 1 } },
    [_]Pair{ .{ -1, 1 }, .{ 1, -1 } },
    [_]Pair{ .{ 1, -1 }, .{ -1, 1 } },
    [_]Pair{ .{ 1, 1 }, .{ -1, -1 } },
};

const WORD2 = "MS";

fn solve2(input: []const u8, _: Allocator) !usize {
    const rows = try FixedLineLengthBuffer.init(input);

    var count: usize = 0;

    for (0..rows.len()) |y| {
        for (0..rows.line_len()) |x| {
            if (rows.get(y, x) != 'A') {
                continue;
            }

            var pointCount: usize = 0;
            dir: for (dirs2) |dd| {
                for (dd, 0..) |p, idx| {
                    const yd: isize = @as(isize, @intCast(y)) + p[0];
                    const xd: isize = @as(isize, @intCast(x)) + p[1];

                    if (rows.get_signed(yd, xd)) |c| {
                        if (c != WORD2[idx]) {
                            continue :dir;
                        }
                    } else {
                        continue :dir;
                    }
                }
                pointCount += 1;
            }
            if (pointCount == 2) {
                count += 1;
            }
        }
    }

    return count;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day04/input",
        .{ .mode = .read_only },
    );
    defer file.close();

    const buffer = try file.readToEndAlloc(gpa, 1000000);

    const res = try solve1(buffer, gpa);

    std.debug.print("Part 1: {d}\n", .{res});

    const res2 = try solve2(buffer, gpa);

    std.debug.print("Part 2: {d}\n", .{res2});
}

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

    pub fn len(self: @This()) usize {
        return self.total_lines;
    }

    pub fn line_len(self: @This()) usize {
        return self.line_length;
    }

    pub fn lines_iter(buf: @This()) LinesIter {
        return .{ .line_length = buf.line_length, .total_lines = buf.total_lines, .text = buf.text };
    }
};

const LinesIter = struct {
    index: usize = 0,
    line_length: usize,
    total_lines: usize,
    text: []const u8,
    pub fn next(self: *@This()) ?[]const u8 {
        const start = self.index * (self.line_length + 1);
        const end = start + self.line_length;
        if (end > self.text.len) {
            return null;
        }
        self.index += 1;
        return self.text[start..end];
    }
};

test "fixedLineLengthBuffer" {
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
        \\MXMXAXMASX
    ;

    const fixedBuffer = try FixedLineLengthBuffer.init(input);

    try std.testing.expectEqual(10, fixedBuffer.line_len());
    try std.testing.expectEqual(11, fixedBuffer.len());
}

test "part 1 - simple" {
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(18, res);
}

test "part 2 - simple" {
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(9, res);
}
