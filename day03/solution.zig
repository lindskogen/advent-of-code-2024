const std = @import("std");
const Allocator = std.mem.Allocator;

fn tryParseNext(reader: anytype, enabled: bool) !usize {
  const firstChar = try reader.readByte();
  if (enabled and firstChar == 'm') {
    if (try reader.readByte() == 'u') {
      if (try reader.readByte() == 'l') {
        if (try reader.readByte() == '(') {
          var times: usize  = 0;
          var num: [3]u8 = undefined;
          var skipComma = false;
          while (times < 3) {
            const b = try reader.readByte();
            if (std.ascii.isDigit(b)) {

              num[times] = b;
            } else if (b == ',') {
              skipComma = true;
              break;
            } else {
              break;
            }
            times += 1;
          }
          if (times > 0) {
            if (skipComma or try reader.readByte() == ',') {
              var times2: usize  = 0;
              var skipCloseParen = false;
              var num2: [3]u8 = undefined;
              while (times2 < 3) {
                const b = try reader.readByte();
                if (std.ascii.isDigit(b)) {
                  num2[times2] = b;
                } else if (b == ')') {
                  skipCloseParen = true;
                  break;
                } else {
                  break;
                }
                times2 += 1;
              }
              if (times2 > 0) {
                if (skipCloseParen or try reader.readByte() == ')') {
                  const n1 = try std.fmt.parseInt(u32, num[0..times], 10);
                  const n2 = try std.fmt.parseInt(u32, num2[0..times2], 10);
                  return n1 * n2;
                }
              }
            }
          }
        }
      }
    }
  } else if (firstChar == 'd') {
    if (try reader.readByte() == 'o') {
      const n = try reader.readByte();
      if (n == '(') {
        if (try reader.readByte() == ')') {
          return error.Do;
        }
      } else if (n == 'n') {
        if (try reader.readByte() == '\'') {
          if (try reader.readByte() == 't') {
            if (try reader.readByte() == '(') {
              if (try reader.readByte() == ')') {
                return error.Dont;
              }
            }
          }
        }
      }
    }
  }

  return error.WrongParse;
}

fn solve1(input: []const u8, _: Allocator) !usize {
  var stream = std.io.fixedBufferStream(input);
  const reader = stream.reader();
  var sum: usize = 0;

  while (true) {
    sum += tryParseNext(reader, true) catch |err| switch (err) {
      error.WrongParse => continue,
      error.Do => continue,
      error.Dont => continue,
      error.EndOfStream => break,
      else => return err
    };
  }

  return sum;
}

fn solve2(input: []const u8, _: Allocator) !usize {
  var stream = std.io.fixedBufferStream(input);
  const reader = stream.reader();
  var enabled = true;
  var sum: usize = 0;

  while (true) {
    sum += tryParseNext(reader, enabled) catch |err| switch (err) {
      error.WrongParse => continue,
      error.Do => { enabled = true; continue; },
      error.Dont => { enabled = false; continue; },
      error.EndOfStream => break,
      else => return err
    };
  }

  return sum;
}




pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();

  const file = try std.fs.cwd().openFile(
    "day03/input",
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
  const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve1(input, gpa);

  try std.testing.expectEqual(161, res);
}


test "part 2 - simple" {
  const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve2(input, gpa);

  try std.testing.expectEqual(161, res);
}
