const std = @import("std");
const Allocator = std.mem.Allocator;

fn absDiff(comptime T: type, a: T, b: T) T {
  return if (a > b) a - b else b - a;
}

const IncOrDec = enum {
  Increasing,
  Decreasing
};

fn checkRow(row: []u32, skipIdx: ?usize) bool {
  var incOrDec: ?IncOrDec = null;
  var prevNum: ?u32 = null;

  for (row, 0..) |num, i| {
    if (i == skipIdx) {
      continue;
    }
    if (prevNum == null) {
      prevNum = num;
      continue;
    }

    const diff = absDiff(u32, prevNum.?, num);
    if (diff < 1 or diff > 3) {
      return false;
    }

    if (incOrDec) |id| {
      if ((num > prevNum.? and id == .Increasing) or (num < prevNum.? and id == .Decreasing)) {
      } else {
        return false;
      }
    } else {
      incOrDec = if (num > prevNum.?) .Increasing else .Decreasing;
    }
    prevNum = num;
  }
  return true;
}


fn solve1(input: []const u8, allocator: Allocator) !u32 {
  var list = std.ArrayList(std.ArrayList(u32)).init(allocator);
  defer list.deinit();

  var iterator = std.mem.tokenizeScalar(u8, input, '\n');

  while (iterator.next()) |line| {
    var innerList = std.ArrayList(u32).init(allocator);
    var innerIter = std.mem.tokenizeScalar(u8, line, ' ');

    while (innerIter.next()) |num|{
      try innerList.append(try std.fmt.parseInt(u32, num, 10));
    }
    try list.append(innerList);
  }

  var sum: u32 = 0;

  for (list.items) |row| {
    sum += if (checkRow(row.items, null)) 1 else 0;
    row.deinit();
  }

  return sum;
}

fn checkWithDampener(row: []u32) bool {
  if (checkRow(row, null)) {
    return true;
  } else {
    for (row, 0..) |_, idx| {
      if (checkRow(row, idx)) {
        return true;
      }
    }
  }
  return false;
}

fn solve2(input: []const u8, allocator: Allocator) !u32 {
  var list = std.ArrayList(std.ArrayList(u32)).init(allocator);
  defer list.deinit();

  var iterator = std.mem.tokenizeScalar(u8, input, '\n');

  while (iterator.next()) |line| {
    var innerList = std.ArrayList(u32).init(allocator);
    var innerIter = std.mem.tokenizeScalar(u8, line, ' ');

    while (innerIter.next()) |num|{
      try innerList.append(try std.fmt.parseInt(u32, num, 10));
    }
    try list.append(innerList);
  }

  var sum: u32 = 0;

  for (list.items) |row| {
    if (checkWithDampener(row.items)) {
      sum += 1;
    }
    row.deinit();
  }

  return sum;
}



pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();

  const file = try std.fs.cwd().openFile(
    "day02/input",
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
  \\7 6 4 2 1
  \\1 2 7 8 9
  \\9 7 6 2 1
  \\1 3 2 4 5
  \\8 6 4 4 1
  \\1 3 6 7 9
;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve1(input, gpa);

  try std.testing.expectEqual(2, res);
}


test "cases" {
  var a1 = [_]u32{7, 6, 4, 2, 1};
  var a2 = [_]u32{1, 2, 7, 8, 9};
  var a3 = [_]u32{9, 7, 6, 2, 1};
  var a4 = [_]u32{1, 3, 2, 4, 5};
  var a5 = [_]u32{8, 6, 4, 4, 1};
  var a6 = [_]u32{1, 3, 6, 7, 9};


  try std.testing.expectEqual(true, checkRow(&a1, null));
  try std.testing.expectEqual(false, checkRow(&a2, null));
  try std.testing.expectEqual(false, checkRow(&a3, null));
  try std.testing.expectEqual(false, checkRow(&a4, null));
  try std.testing.expectEqual(false, checkRow(&a5, null));
  try std.testing.expectEqual(true, checkRow(&a6, null));
}


test "part 2 - simple" {
  const input =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve2(input, gpa);

  try std.testing.expectEqual(4, res);
}

test "cases - 2" {
  var a1 = [_]u32{7, 6, 4, 2, 1};
  var a2 = [_]u32{1, 2, 7, 8, 9};
  var a3 = [_]u32{9, 7, 6, 2, 1};
  var a4 = [_]u32{1, 3, 2, 4, 5};
  var a5 = [_]u32{8, 6, 4, 4, 1};
  var a6 = [_]u32{1, 3, 6, 7, 9};


  try std.testing.expectEqual(true, checkWithDampener(&a1));
  try std.testing.expectEqual(false, checkWithDampener(&a2));
  try std.testing.expectEqual(false, checkWithDampener(&a3));
  try std.testing.expectEqual(true, checkWithDampener(&a4));
  try std.testing.expectEqual(true, checkWithDampener(&a5));
  try std.testing.expectEqual(true, checkWithDampener(&a6));
}
