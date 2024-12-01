const std = @import("std");
const Allocator = std.mem.Allocator;


fn absDiff(comptime T: type, a: T, b: T) T {
  return if (a > b) a - b else b - a;
}

fn solve1(input: []const u8, allocator: Allocator) !u32 {
  var l1 = std.ArrayList(u32).init(allocator);
  defer l1.deinit();
  var l2 = std.ArrayList(u32).init(allocator);
  defer l2.deinit();
  var iterator = std.mem.tokenizeScalar(u8, input, '\n');

  while (iterator.next()) |line| {
    var innerIter = std.mem.tokenizeSequence(u8, line, "   ");

    const first = innerIter.next() orelse break;
    const second = innerIter.next() orelse return error.NoSecondNumber;

    try l1.append(try std.fmt.parseInt(u32, first, 10));
    try l2.append(try std.fmt.parseInt(u32, second, 10));
  }

  std.mem.sort(u32, l1.items, {},  comptime std.sort.asc(u32));
  std.mem.sort(u32, l2.items, {},  comptime std.sort.asc(u32));

  var sum: u32 = 0;

  for (l1.items, l2.items) |it1, it2| {
    sum += absDiff(u32, it1, it2);
  }

  return sum;
}

fn solve2(input: []const u8, allocator: Allocator) !u32 {
  var l1 = std.ArrayList(u32).init(allocator);
  defer l1.deinit();

  var countMap = std.AutoHashMap(u32, u32).init(allocator);
  defer countMap.deinit();

  var iterator = std.mem.tokenizeScalar(u8, input, '\n');

  while (iterator.next()) |line| {
    var innerIter = std.mem.tokenizeSequence(u8, line, "   ");

    const first = innerIter.next() orelse break;
    const second = innerIter.next() orelse return error.NoSecondNumber;

    try l1.append(try std.fmt.parseInt(u32, first, 10));
    const num2 = try std.fmt.parseInt(u32, second, 10);

    const entry = try countMap.getOrPutValue(num2, 0);
    entry.value_ptr.* += 1;
  }

  var sum: u32 = 0;

  for (l1.items) |it| {
    sum += it * (countMap.get(it) orelse 0);
  }

  return sum;
}



pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();

  const file = try std.fs.cwd().openFile(
    "day01/input",
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
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve1(input, gpa);

  try std.testing.expectEqual(11, res);
}

test "part 2 - simple" {
  const input =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve2(input, gpa);

  try std.testing.expectEqual(31, res);
}
