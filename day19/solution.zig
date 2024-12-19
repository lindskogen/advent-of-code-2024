const std = @import("std");
const Allocator = std.mem.Allocator;

const Patterns = std.StringArrayHashMap(void);
const Memo = std.StringArrayHashMap(usize);

fn search(data: []const u8, maxLen: usize, patterns: *Patterns, memo: *Memo) !usize {
  if (memo.get(data)) |res| {
    return res;
  }

  if (data.len == 0) {
    return 1;
  }

  var sum: usize = 0;

  for (1..@min(data.len, maxLen)+1) |l| {
    if (patterns.contains(data[0..l])) {
      const n = try search(data[l..], maxLen, patterns, memo);
      try memo.put(data, n);
      sum += n;
    }
  }
  try memo.put(data, sum);
  return sum;
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
  var groupIter = std.mem.tokenizeSequence(u8, input, "\n\n");
  const g1 = groupIter.next() orelse return error.NoGroup1;
  var patterns = Patterns.init(alloc);
  defer patterns.deinit();
  var memo = Memo.init(alloc);
  defer memo.deinit();

  var maxLen: usize = 0;

  var patternIter = std.mem.tokenizeSequence(u8, g1, ", ");

  while (patternIter.next()) |ptrn| {
    try patterns.put(ptrn, {});
    if (ptrn.len > maxLen) {
      maxLen = ptrn.len;
    }
  }

  const g2 = groupIter.next() orelse return error.NoGroup2;
  var designsIter = std.mem.tokenizeScalar(u8, g2, '\n');

  var count: usize = 0;

  while (designsIter.next()) |design| {
    if (try search(design,  maxLen,&patterns, &memo) > 0) {
      count += 1;
    }
  }

  return count;
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
  var groupIter = std.mem.tokenizeSequence(u8, input, "\n\n");
  const g1 = groupIter.next() orelse return error.NoGroup1;
  var patterns = Patterns.init(alloc);
  defer patterns.deinit();
  var memo = Memo.init(alloc);
  defer memo.deinit();

  var maxLen: usize = 0;

  var patternIter = std.mem.tokenizeSequence(u8, g1, ", ");

  while (patternIter.next()) |ptrn| {
    try patterns.put(ptrn, {});
    if (ptrn.len > maxLen) {
      maxLen = ptrn.len;
    }
  }

  const g2 = groupIter.next() orelse return error.NoGroup2;
  var designsIter = std.mem.tokenizeScalar(u8, g2, '\n');

  var count: usize = 0;

  while (designsIter.next()) |design| {
    count += try search(design,  maxLen,&patterns, &memo);
  }

  return count;
}

pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();

  const file = try std.fs.cwd().openFile(
    "day19/input",
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
    \\r, wr, b, g, bwu, rb, gb, br
    \\
    \\brwrr
    \\bggr
    \\gbbr
    \\rrbgbr
    \\ubwu
    \\bwurrg
    \\brgr
    \\bbrgwb
  ;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve1(input, gpa);

  try std.testing.expectEqual(6, res);
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
