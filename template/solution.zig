const std = @import("std");
const Allocator = std.mem.Allocator;

fn solve1(input: []const u8, alloc: Allocator) !usize {
  return 10;
}

// fn solve2(input: []const u8, alloc: Allocator) !usize {
//
// }

pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();

  const file = try std.fs.cwd().openFile(
    "dayXX/input",
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
    \\
    \\
  ;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve1(input, gpa);

  try std.testing.expectEqual(0, res);
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
