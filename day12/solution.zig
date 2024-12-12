const std = @import("std");
const Allocator = std.mem.Allocator;


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

  pub fn get_pos(self: @This(), pos: Coord) ?u8 {
    return self.get_signed(pos.y, pos.x);
  }

  pub fn len(self: @This()) usize {
    return self.total_lines;
  }

  pub fn line_len(self: @This()) usize {
    return self.line_length;
  }
};

const Coord = struct { x: isize, y: isize };
const CoordSet = std.AutoArrayHashMap(Coord, void);

fn move_unsafe(c: Coord, dir: Dir) Coord {
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

fn move_unsafe_diag(c: Coord, dir: DiagDirs) Coord {
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
    .NorthWest => {
      return .{ .x = c.x - 1, .y = c.y - 1 };
    },
    .NorthEast => {
      return .{ .x = c.x + 1, .y = c.y - 1 };
    },
    .SouthWest => {
      return .{ .x = c.x - 1, .y = c.y + 1 };
    },
    .SouthEast => {
      return .{ .x = c.x + 1, .y = c.y + 1 };
    },
  }
}

fn move(c: Coord, dir: Dir, extent: usize) ?Coord {
  switch (dir) {
    .North => {
      if (c.y > 0) {
        return .{ .x = c.x, .y = c.y - 1 };
      }
    },
    .East => {
      if (c.x + 1 < extent) {
        return .{ .x = c.x + 1, .y = c.y };
      }
    },
    .South => {
      if (c.y + 1 < extent) {
        return .{ .x = c.x, .y = c.y + 1 };
      }
    },
    .West => {
      if (c.x > 0) {
        return .{ .x = c.x - 1, .y = c.y };
      }
    },
  }
  return null;
}

const Dir = enum { North, South, East, West };
const DiagDirs = enum { North, South, East, West, NorthWest, NorthEast, SouthWest, SouthEast };


const DIRS = [_]Dir{ .East, .North, .South, .West };
const DIAG_DIRS = [_]DiagDirs{ .East, .North, .South, .West, .NorthWest, .NorthEast, .SouthWest, .SouthEast };

fn find_neighbors(map: FixedLineLengthBuffer, pos: Coord, visited: *CoordSet, group: *CoordSet) !void {
  const groupName = map.get_pos(pos).?;
  for (DIRS) |d| {
    if (move(pos, d, map.len())) |p| {
      if (!visited.contains(p) and map.get_pos(p).? == groupName) {
        try group.putNoClobber(p, {});
        try visited.putNoClobber(p, {});
        try find_neighbors(map, p, visited, group);
      }
    }
  }
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
  const map = try FixedLineLengthBuffer.init(input);
  var groups = std.ArrayList(CoordSet).init(alloc);
  defer groups.deinit();
  var visited = CoordSet.init(alloc);
  defer visited.deinit();

  for (0..map.len()) |y| {
    for (0..map.line_len()) |x| {
      const pos = Coord { .x = @intCast(x), .y = @intCast(y) };
      if (!visited.contains(pos)) {
        var group = CoordSet.init(alloc);
        try visited.putNoClobber(pos, {});
        try group.putNoClobber(pos, {});
        try find_neighbors(map,pos, &visited, &group);
        try groups.append(group);
      }
    }
  }

  var sum: usize = 0;

  for (groups.items) |*g| {
    var sides: usize = 0;
    for (g.keys()) |pos| {
      for (DIRS) |d| {
        const p = move_unsafe(pos, d);
        if (!g.contains(p)) {
          sides += 1;
        }
      }
    }

    sum += sides * g.keys().len;

    g.deinit();
  }

  return sum;
}


fn count_corners(g: *CoordSet) usize {
  var corner_count: usize = 0;

  for (g.keys()) |c| {
    const n = g.contains(move_unsafe_diag(c, .North));
    const e = g.contains(move_unsafe_diag(c, .East));
    const s = g.contains(move_unsafe_diag(c, .South));
    const w = g.contains(move_unsafe_diag(c, .West));
    const nw = g.contains(move_unsafe_diag(c, .NorthWest));
    const ne = g.contains(move_unsafe_diag(c, .NorthEast));
    const se = g.contains(move_unsafe_diag(c, .SouthEast));
    const sw = g.contains(move_unsafe_diag(c, .SouthWest));


    if (!n and !w) {
      corner_count += 1;
    }
    if (!n and !e) {
      corner_count += 1;
    }
    if (!s and !w) {
      corner_count += 1;
    }
    if (!s and !e) {
      corner_count += 1;
    }

    if (e and s and !se) {
      corner_count += 1;
    }
    if (w and s and !sw) {
      corner_count += 1;
    }

    if (e and n and !ne) {
      corner_count += 1;
    }
    if (w and n and !nw) {
      corner_count += 1;
    }
  }

  return corner_count;
}


fn solve2(input: []const u8, alloc: Allocator) !usize {
  const map = try FixedLineLengthBuffer.init(input);
  var groups = std.ArrayList(CoordSet).init(alloc);
  defer groups.deinit();
  var visited = CoordSet.init(alloc);
  defer visited.deinit();

  for (0..map.len()) |y| {
    for (0..map.line_len()) |x| {
      const pos = Coord { .x = @intCast(x), .y = @intCast(y) };
      if (!visited.contains(pos)) {
        var group = CoordSet.init(alloc);
        try visited.putNoClobber(pos, {});
        try group.putNoClobber(pos, {});
        try find_neighbors(map,pos, &visited, &group);
        try groups.append(group);
      }
    }
  }

  var sum: usize = 0;

  for (groups.items) |*g| {
    sum += count_corners(g) * g.keys().len;
    g.deinit();
  }

  return sum;
}

pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();

  const file = try std.fs.cwd().openFile(
    "day12/input",
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
    \\RRRRIICCFF
    \\RRRRIICCCF
    \\VVRRRCCFFF
    \\VVRCCCJFFF
    \\VVVVCJJCFE
    \\VVIVCCJJEE
    \\VVIIICJJEE
    \\MIIIIIJJEE
    \\MIIISIJEEE
    \\MMMISSJEEE
  ;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve1(input, gpa);

  try std.testing.expectEqual(1930, res);
}

// test "part 2 - simple" {
//   const input =
//     \\RRRRIICCFF
//     \\RRRRIICCCF
//     \\VVRRRCCFFF
//     \\VVRCCCJFFF
//     \\VVVVCJJCFE
//     \\VVIVCCJJEE
//     \\VVIIICJJEE
//     \\MIIIIIJJEE
//     \\MIIISIJEEE
//     \\MMMISSJEEE
//   ;
//
//
//   var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
//   defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
//
//   const gpa = general_purpose_allocator.allocator();
//
//   const res = try solve2(input, gpa);
//
//   try std.testing.expectEqual(1206, res);
// }

test "part 2 - simple - 2" {
  const input =
    \\EEEEE
    \\EXXXX
    \\EEEEE
    \\EXXXX
    \\EEEEE
  ;


  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve2(input, gpa);

  try std.testing.expectEqual(236, res);
}
