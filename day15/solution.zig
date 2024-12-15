const std = @import("std");
const Allocator = std.mem.Allocator;

fn Coord(comptime T: type) type {
    return struct { x: T, y: T };
}

const Point = Coord(usize);

const Dir = enum { North, South, East, West };

const FixedLineLengthBuffer = struct {
    line_length: usize,
    total_lines: usize,
    text: []u8,

    pub fn init(text: []u8) !@This() {
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

    pub fn indexOf(self: @This(), needle: u8) ?Point {
        for (self.text, 0..) |c, i| {
            if (c == needle) {
                const col = i % (self.line_length + 1);
                const row = i / (self.line_length + 1);
                return Point{ .x = col, .y = row };
            }
        }

        return null;
    }

    pub fn replace(self: @This(), p: Point, v: u8) u8 {
        const index = p.y * (self.line_length + 1) + p.x;
        const prev = self.text[index];
        self.text[index] = v;
        return prev;
    }

    pub fn swap(self: @This(), p1: Point, p2: Point) void {
        const index_1 = p1.y * (self.line_length + 1) + p1.x;
        const index_2 = p2.y * (self.line_length + 1) + p2.x;

        const prev = self.text[index_1];
        self.text[index_1] = self.text[index_2];
        self.text[index_2] = prev;
    }

    pub fn get(self: @This(), row: usize, col: usize) ?u8 {
        if (row < self.total_lines and col < self.line_length) {
            // Account for '\n' at end of line
            const index = row * (self.line_length + 1) + col;
            return self.text[index];
        }

        return null;
    }

    pub fn get_pos(self: @This(), pos: Point) ?u8 {
        return self.get(pos.y, pos.x);
    }

    pub fn len(self: @This()) usize {
        return self.total_lines;
    }

    pub fn line_len(self: @This()) usize {
        return self.line_length;
    }
};

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var groupIter = std.mem.tokenizeSequence(u8, input, "\n\n");

    const mapString = groupIter.next() orelse return error.NoMap;
    const mapStringClone = try alloc.alloc(u8, mapString.len);
    @memcpy(mapStringClone, mapString);
    defer alloc.free(mapStringClone);
    const movesString = groupIter.next() orelse return error.NoMoves;

    var map = try FixedLineLengthBuffer.init(mapStringClone);

    var pos = map.indexOf('@') orelse return error.NoRobot;
    const at = map.replace(pos, '.');
    std.debug.assert(at == '@');

    for (movesString) |m| {
        // for (0..map.len()) |y| {
        //   for (0..map.line_len()) |x| {
        //     const c = map.get(y, x).?;
        //
        //     if (x == pos.x and y == pos.y) {
        //       std.debug.print("@", .{});
        //     } else {
        //       std.debug.print("{c}", .{c});
        //     }
        //
        //   }
        //   std.debug.print("\n", .{});
        // }

        const dir: ?Dir = switch (m) {
            '^' => .North,
            '>' => .East,
            '<' => .West,
            'v' => .South,
            '\n' => null,
            else => blk: {
                std.debug.print("invalid char: {c}\n", .{m});
                break :blk null;
            },
        };

        if (dir) |d| {
            const newPos = move_unsafe(pos, d);
            const c = map.get_pos(newPos).?;
            if (c == '.') {
                // empty space, move!
                pos = newPos;
            } else if (c == '#') {
                // wall - don't move
            } else if (c == 'O') {
                // box
                var nextnextPos = move_unsafe(newPos, d);

                while (map.get_pos(nextnextPos).? == 'O') {
                    nextnextPos = move_unsafe(nextnextPos, d);
                }
                if (map.get_pos(nextnextPos).? == '.') {
                    map.swap(newPos, nextnextPos);
                    pos = newPos;
                }
            }
        }
    }

    var total: usize = 0;

    for (0..map.len()) |y| {
        for (0..map.line_len()) |x| {
            if (map.get(y, x) == 'O') {
                total += y * 100 + x;
            }
        }
    }

    return total;
}

fn move_unsafe(c: Point, dir: Dir) Point {
    switch (dir) {
        .North => {
            return .{ .x = c.x, .y = c.y - 1 };
        },
        .East => {
            return .{ .x = c.x + 1, .y = c.y };
        },
        .South => {
            return .{ .x = c.x, .y = c.y + 1 };
        },
        .West => {
            return .{ .x = c.x - 1, .y = c.y };
        },
    }
}

fn validate_recur(map: FixedLineLengthBuffer, p1: Point, d: Dir) bool {
    if (map.get_pos(p1).? == '.') {
        return true;
    } else if (map.get_pos(p1).? == '#') {
        return false;
    } else if (map.get_pos(p1).? == '[' or map.get_pos(p1).? == ']') {
        const other_dir: Dir = if (map.get_pos(p1).? == '[') .East else .West;
        const p2 = move_unsafe(p1, other_dir);
        const next_p1 = move_unsafe(p1, d);
        const next_p2 = move_unsafe(p2, d);

        if (validate_recur(map, next_p1, d) and validate_recur(map, next_p2, d)) {
            return true;
        } else {
            return false;
        }
    } else {
        std.debug.panic("Unexpected char {c} \n", .{map.get_pos(p1).?});
    }
}

fn move_recur(map: FixedLineLengthBuffer, p1: Point, d: Dir) bool {
    if (map.get_pos(p1).? == '.') {
        return true;
    } else if (map.get_pos(p1).? == '#') {
        return false;
    } else if (map.get_pos(p1).? == '[' or map.get_pos(p1).? == ']') {
        const other_dir: Dir = if (map.get_pos(p1).? == '[') .East else .West;
        const p2 = move_unsafe(p1, other_dir);
        const next_p1 = move_unsafe(p1, d);
        const next_p2 = move_unsafe(p2, d);

        if (move_recur(map, next_p1, d) and move_recur(map, next_p2, d)) {
            map.swap(p1, next_p1);
            map.swap(p2, next_p2);
            return true;
        } else {
            return false;
        }
    } else {
        std.debug.panic("Unexpected char {c} \n", .{map.get_pos(p1).?});
    }
}

fn print_board(map: FixedLineLengthBuffer, pos: Point) void {
    for (0..map.len()) |y| {
        for (0..map.line_len()) |x| {
            const c = map.get(y, x).?;

            if (x == pos.x and y == pos.y) {
                std.debug.print("@", .{});
            } else {
                std.debug.print("{c}", .{c});
            }
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("\n", .{});
}

fn solve2(input: []const u8, alloc: Allocator, debug: bool) !usize {
    var groupIter = std.mem.tokenizeSequence(u8, input, "\n\n");

    const mapString = groupIter.next() orelse return error.NoMap;
    const mapStringClone = try alloc.alloc(u8, mapString.len * 2);
    defer alloc.free(mapStringClone);

    {
        var i: usize = 0;
        for (mapString) |v| {
            switch (v) {
                '#' => {
                    mapStringClone[i] = '#';
                    mapStringClone[i + 1] = '#';
                    i += 2;
                },
                'O' => {
                    mapStringClone[i] = '[';
                    mapStringClone[i + 1] = ']';
                    i += 2;
                },
                '.' => {
                    mapStringClone[i] = '.';
                    mapStringClone[i + 1] = '.';
                    i += 2;
                },
                '@' => {
                    mapStringClone[i] = '@';
                    mapStringClone[i + 1] = '.';
                    i += 2;
                },
                '\n' => {
                    mapStringClone[i] = '\n';
                    i += 1;
                },
                else => {
                    std.debug.print("invalid char: {c}\n", .{v});
                },
            }
        }
    }

    const movesString = groupIter.next() orelse return error.NoMoves;

    var map = try FixedLineLengthBuffer.init(mapStringClone);

    var pos = map.indexOf('@') orelse return error.NoRobot;
    const at = map.replace(pos, '.');
    std.debug.assert(at == '@');

    for (movesString) |m| {
        const dir: ?Dir = switch (m) {
            '^' => .North,
            '>' => .East,
            '<' => .West,
            'v' => .South,
            '\n' => null,
            else => blk: {
                std.debug.print("invalid char: {c}\n", .{m});
                break :blk null;
            },
        };

        if (dir) |d| {
            if (debug) {
                print_board(map, pos);
            }

            const newPos = move_unsafe(pos, d);
            const c = map.get_pos(newPos).?;
            if (c == '.') {
                // empty space, move!
                pos = newPos;
            } else if (c == '#') {
                // wall - don't move
            } else if (c == '[' or c == ']') {
                // box
                if (d == .North or d == .South) {
                    if (validate_recur(map, newPos, d) and move_recur(map, newPos, d)) {
                        pos = newPos;
                    }
                } else {
                    var nextnextPos = move_unsafe(newPos, d);
                    while (map.get_pos(nextnextPos).? == '[' or map.get_pos(nextnextPos).? == ']') {
                        nextnextPos = move_unsafe(nextnextPos, d);
                    }
                    const opp_dir: Dir = if (d == .East) .West else .East;
                    if (map.get_pos(nextnextPos).? == '.') {
                        while (nextnextPos.x != newPos.x) {
                            const pp = move_unsafe(nextnextPos, opp_dir);
                            map.swap(nextnextPos, pp);
                            nextnextPos = pp;
                        }
                        map.swap(newPos, nextnextPos);
                        pos = newPos;
                    }
                }
            }
        }
    }

    if (debug) {
        print_board(map, pos);
    }

    var total: usize = 0;

    for (0..map.len()) |y| {
        for (0..map.line_len()) |x| {
            if (map.get(y, x) == '[') {
                total += y * 100 + x;
            }
        }
    }

    return total;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day15/input",
        .{ .mode = .read_only },
    );
    defer file.close();

    const buffer = try file.readToEndAlloc(gpa, 1000000);

    const res = try solve1(buffer, gpa);

    std.debug.print("Part 1: {d}\n", .{res});

    const res2 = try solve2(buffer, gpa, false);

    std.debug.print("Part 2: {d}\n", .{res2});
}

test "part 1 - small" {
    const input =
        \\########
        \\#..O.O.#
        \\##@.O..#
        \\#...O..#
        \\#.#.O..#
        \\#...O..#
        \\#......#
        \\########
        \\
        \\<^^>>>vv<v>>v<<
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(2028, res);
}

test "part 1 - simple" {
    const input =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
        \\
        \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(10092, res);
}

test "part 2 - small" {
    const input =
        \\#######
        \\#...#.#
        \\#.....#
        \\#..OO@#
        \\#..O..#
        \\#.....#
        \\#######
        \\
        \\<vv<<^^<<^^
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa, false);

    try std.testing.expectEqual(618, res);
}

test "part 2 - simple" {
    const input =
        \\##########
        \\#..O..O.O#
        \\#......O.#
        \\#.OO..O.O#
        \\#..O@..O.#
        \\#O#..O...#
        \\#O..O..O.#
        \\#.OO.O.OO#
        \\#....O...#
        \\##########
        \\
        \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
        \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
        \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
        \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
        \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
        \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
        \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
        \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
        \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
        \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa, false);

    try std.testing.expectEqual(9021, res);
}
