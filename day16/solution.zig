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

const DirNeighbors = struct { Dir, Dir };

fn opposite_dir(dir: Dir) Dir {
  return switch (dir) {
    .East => .West,
    .West => .East,
    .North => .South,
    .South => .North
  };
}

fn rotation_neighbors(dir: Dir) DirNeighbors {
  return switch (dir) {
    .East => DirNeighbors { .North, .South },
    .West => DirNeighbors { .North, .South },
    .North => DirNeighbors { .East, .West },
    .South => DirNeighbors { .East, .West },
  };
}


fn neighbors(pos: Point, dir: Dir) [3]State {
  const ns = rotation_neighbors(dir);
  return [_]State{
    .{ .pos = move_unsafe(pos, dir), .dir = dir },
    .{ .pos = pos, .dir = ns.@"0" },
    .{ .pos = pos, .dir = ns.@"1" }
  };
}


const State = struct { pos: Point, dir: Dir };

const Distances = std.AutoArrayHashMap(State, usize);

const DIRS = [_]Dir { .West, .East, .North, .South };

fn walk(map: FixedLineLengthBuffer, pos: Point, goal: Point, dir: Dir, dist: *Distances, alloc: Allocator) !usize {
  var Q = std.AutoArrayHashMap(State, void).init(alloc);
  defer Q.deinit();

  for (0..map.len()) |y| {
    for (0..map.line_len()) |x| {
      if (map.get(y, x) != '#') {
        try Q.put(.{ .pos = .{.x = x, .y = y }, .dir = .North }, {});
        try Q.put(.{ .pos = .{.x = x, .y = y }, .dir = .South }, {});
        try Q.put(.{ .pos = .{.x = x, .y = y }, .dir = .East }, {});
        try Q.put(.{ .pos = .{.x = x, .y = y }, .dir = .West }, {});
      }
    }
  }

  try Q.put(.{.pos = pos, .dir = dir }, {});

  while (Q.count() > 0) {
    const keys = Q.keys();
    var un = dist.getEntry(keys[0]);
    for (keys[1..]) |k| {
      const d = dist.getEntry(k);
      if (un == null or (d != null and d.?.value_ptr.* < un.?.value_ptr.*)) {
        un = d;
      }
    }
    const u = un.?;

    _ = Q.swapRemove(u.key_ptr.*);

    const upos = u.key_ptr.pos;
    const udir = u.key_ptr.dir;

    for (neighbors(upos, udir)) |vst| {
      if (Q.contains(vst)) {
        const v = try dist.getOrPutValue(vst, std.math.maxInt(usize));
        const cost: usize = if (udir == vst.dir) 1 else 1000;
        const alt = dist.get(.{ .dir = udir, .pos = upos });
        if (alt != null and alt.? + cost < v.value_ptr.*) {
          try dist.put(vst, alt.? + cost);
          try Q.put(vst, {});
        }
      }
    }
  }

  var min_dist: usize = std.math.maxInt(usize);

  for (dist.keys()) |k| {
    if (k.pos.x == goal.x and k.pos.y == goal.y) {
      if (dist.get(k).? < min_dist) {
        min_dist = dist.get(k).?;
      }
    }
  }

  return min_dist;
}

fn solve1(input: []const u8, dist: *Distances, alloc: Allocator) !usize {
  const map = try FixedLineLengthBuffer.init(input);

  const pos = map.indexOf('S') orelse return error.NoStartPos;
  const end_pos = map.indexOf('E') orelse return error.NoEndPos;
  const dir: Dir = .East;


  try dist.put(.{.pos = pos, .dir = dir }, 0);

  return walk(map, pos, end_pos, dir, dist,alloc);
}

const State2 = struct {
  pos: Point,
  dir: Dir,
  cost: usize
};

fn solve2(input: []const u8, dist: *Distances, alloc: Allocator) !usize {
  const map = try FixedLineLengthBuffer.init(input);
  var visited = std.AutoArrayHashMap(Point, void).init(alloc);
  defer visited.deinit();

  const cmp = struct {
    fn cmp(_: void, s1: State2, s2: State2) std.math.Order {
      return std.math.order(s1.cost, s2.cost);
    }
  };



  var todo = std.PriorityDequeue(State2, void, cmp.cmp).init(alloc, {});

  const pos = map.indexOf('S') orelse return error.NoStartPos;
  const goal = map.indexOf('E') orelse return error.NoEndPos;

  try visited.put(pos, {});
  try visited.put(goal, {});

  var min_dist: usize = std.math.maxInt(usize);
  for (dist.keys()) |k| {
    if (k.pos.x == goal.x and k.pos.y == goal.y) {
      if (dist.get(k).? < min_dist) {
        min_dist = dist.get(k).?;
      }
    }
  }

  for (dist.keys()) |k| {
    if (k.pos.x == goal.x and k.pos.y == goal.y) {
      if (dist.get(k).? == min_dist) {
        try todo.add(.{ .cost = min_dist, .dir = k.dir, .pos = k.pos });
      }
    }
  }
  
  while (todo.removeMinOrNull()) |st| {
    try visited.put(st.pos, {});
    if (st.pos.x == pos.x and st.pos.y == pos.y) {
      continue;
    }

    const ns = rotation_neighbors(st.dir);

    const next = [_]State2 {
      .{ .pos = move_unsafe(st.pos, opposite_dir(st.dir)), .dir = st.dir, .cost = st.cost - 1 },
      .{ .pos = st.pos, .dir = ns.@"0", .cost = st.cost - 1000 },
      .{ .pos = st.pos, .dir = ns.@"1", .cost = st.cost - 1000 },
    };

    for (next) |next_st| {
      if (dist.getEntry(.{ .dir = next_st.dir, .pos = next_st.pos })) |entry| {
        if (entry.value_ptr.* == next_st.cost) {
          try todo.add(next_st);
          entry.value_ptr.* = std.math.maxInt(usize);
        }
      }

    }

  }


  return visited.count();

}

pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();
  var dist = std.AutoArrayHashMap(State, usize).init(gpa);
  defer dist.deinit();

  const file = try std.fs.cwd().openFile(
    "day16/input",
    .{ .mode = .read_only },
  );
  defer file.close();

  const buffer = try file.readToEndAlloc(gpa, 1000000);

  const res = try solve1(buffer, &dist, gpa);

  std.debug.print("Part 1: {d}\n", .{res});

  const res2 = try solve2(buffer, &dist, gpa);

  std.debug.print("Part 2: {d}\n", .{res2});
}

test "part 1 - simple" {
  const input =
    \\###############
    \\#.......#....E#
    \\#.#.###.#.###.#
    \\#.....#.#...#.#
    \\#.###.#####.#.#
    \\#.#.#.......#.#
    \\#.#.#####.###.#
    \\#...........#.#
    \\###.#.#####.#.#
    \\#...#.....#.#.#
    \\#.#.#.###.#.#.#
    \\#.....#...#.#.#
    \\#.###.#.#.#.#.#
    \\#S..#.....#...#
    \\###############
  ;

  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

  const gpa = general_purpose_allocator.allocator();

  const res = try solve1(input, gpa);

  try std.testing.expectEqual(7036, res);
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
