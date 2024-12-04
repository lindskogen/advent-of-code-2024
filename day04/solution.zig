const std = @import("std");
const Allocator = std.mem.Allocator;

const Pair = std.meta.Tuple(&.{ isize, isize });

const dirs1: [8]Pair = [_]Pair {
  .{ -1, 0 }, .{ -1, -1 }, .{ -1, 1 }, .{  1, 0 },
  .{  1, -1 }, .{  1, 1 }, .{  0, -1 }, .{  0, 1 }
};

const WORD = "XMAS";

fn solve1(input: []const u8, alloc: Allocator) !usize {
  var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');
  var rows = std.ArrayList([]const u8).init(alloc);
  defer rows.deinit();

  while (rowsIter.next()) |row| {
    try rows.append(row);
  }

  var count: usize = 0;


  for (rows.items, 0..) |r, y| {
    for (r, 0..) |_, x| {
      dir: for (dirs1) |p| {
          inline for (0..4) |d|{
            const yd: isize = @as(isize, @intCast(y)) + p[0] * d;
            const xd: isize = @as(isize, @intCast(x)) + p[1] * d;

            if (yd >= 0 and yd < rows.items.len and xd >= 0 and xd < rows.items[y].len) {
              if (rows.items[@intCast(yd)][@intCast(xd)] != WORD[d]) {
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

const dirs2: [4][2]Pair = [4][2]Pair {
  [2]Pair {.{ -1, -1 }, .{  1,  1 }},
  [2]Pair {.{ -1,  1 }, .{  1, -1 }},
  [2]Pair {.{  1, -1 }, .{ -1,  1 }},
  [2]Pair {.{  1,  1 }, .{ -1, -1 }},
};

const WORD2 = "MS";

fn solve2(input: []const u8, alloc: Allocator) !usize {
  var rowsIter = std.mem.tokenizeScalar(u8, input, '\n');
  var rows = std.ArrayList([]const u8).init(alloc);
  defer rows.deinit();

  while (rowsIter.next()) |row| {
    try rows.append(row);
  }

  var count: usize = 0;


  for (rows.items, 0..) |r, y| {
    for (r, 0..) |_, x| {
      if (rows.items[y][x] != 'A') {
        continue;
      }

      var pointCount: usize = 0;
      dir: for (dirs2) |dd| {
        for (dd, 0..) |p, idx|{
          const yd: isize = @as(isize, @intCast(y)) + p[0];
          const xd: isize = @as(isize, @intCast(x)) + p[1];

          if (yd >= 0 and yd < rows.items.len and xd >= 0 and xd < rows.items[y].len) {
            if (rows.items[@intCast(yd)][@intCast(xd)] != WORD2[idx]) {
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

  std.debug.print("Part 1: {d}\n", .{ res });

  const res2 = try solve2(buffer, gpa);

  std.debug.print("Part 2: {d}\n", .{ res2 });
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
