const std = @import("std");
const Allocator = std.mem.Allocator;

const Reg = struct {
  a: usize = 0,
  b: usize = 0,
  c: usize = 0,
};

fn combo_op(operand: u3, reg: Reg) usize {
  return switch (operand) {
    0 => 0,
    1 => 1,
    2 => 2,
    3 => 3,
    4 => reg.a,
    5 => reg.b,
    6 => reg.c,
    else => {
      std.debug.panic("7 encountered\n", .{});
    }
  };
}

fn solve1(_: []const u8, _: Allocator) !usize {
  var reg =  Reg {
    .a = 22817223,
    .b = 0,
    .c = 0,
  };

  const ops = [_]u3 {2,4,1,2,7,5,4,5,0,3,1,7,5,5,3,0};
  var pc: usize = 0;

  while (pc < ops.len) {
    switch (ops[pc]) {
      0 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.a = reg.a / try std.math.powi(usize, 2, operand);
        pc += 2;
      },
      1 => {
        reg.b = reg.b ^ ops[pc+1];
        pc += 2;
      },
      2 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.b = operand % 8;
        pc += 2;
      },
      3 => {
        const operand = ops[pc+1];
        if (reg.a != 0) {
          pc = operand;
        } else {
          pc += 2;
        }
      },
      4 => {
        reg.b = reg.b ^ reg.c;
        pc += 2;
      },
      5 => {
        const operand = combo_op(ops[pc+1], reg);
        std.debug.print("{d},", .{ operand % 8 });
        pc += 2;
      },
      6 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.b = reg.a / try std.math.powi(usize, 2, operand);
        pc += 2;
      },
      7 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.c = reg.a / try std.math.powi(usize, 2, operand);
        pc += 2;
      },
    }
  }
  return 0;
}

fn solve2(_: []const u8, _: Allocator) !usize {
  const ops = [_]u3 {2,4,1,2,7,5,4,5,0,3,1,7,5,5,3,0};

  std.debug.print("{any} \n", .{ ops });


  var output : [ops.len]u3 = undefined;

  for (0..10) |i| {
    const initial_a = 78191727 * i;
    var reg =  Reg {
      .a = initial_a,
      .b = 0,
      .c = 0,
    };
    var out: usize = 0;
    var pc: usize = 0;

    while (pc < ops.len) {
    switch (ops[pc]) {
      // adv
      0 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.a = reg.a / try std.math.powi(usize, 2, operand);
        pc += 2;
      },
      // bxl
      1 => {
        reg.b = reg.b ^ ops[pc+1];
        pc += 2;
      },
      // bst
      2 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.b = operand % 8;
        pc += 2;
      },
      // jnz
      3 => {
        const operand = ops[pc+1];
        if (reg.a != 0) {
          pc = operand;
        } else {
          pc += 2;
        }
      },
      // bxc
      4 => {
        reg.b = reg.b ^ reg.c;
        pc += 2;
      },
      // out
      5 => {
        const operand = combo_op(ops[pc+1], reg);
        output[out] = @intCast(operand % 8);
        out += 1;
        pc += 2;
      },
      // bdv
      6 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.b = reg.a / try std.math.powi(usize, 2, operand);
        pc += 2;
      },
      // cdv
      7 => {
        const operand = combo_op(ops[pc+1], reg);
        reg.c = reg.a / try std.math.powi(usize, 2, operand);
        pc += 2;
      },
    }
  }

    if (std.mem.eql(u3, &output, &ops)) {
      return initial_a;
    } else {
      std.debug.print("{any} {d}\n", .{ output, initial_a });
    }
  }
  return 0;
}

pub fn main() !void {
  var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
  const gpa = general_purpose_allocator.allocator();

  const file = try std.fs.cwd().openFile(
    "day17/input",
    .{ .mode = .read_only },
  );
  defer file.close();

  const buffer = try file.readToEndAlloc(gpa, 1000000);

  std.debug.print("Part 1: ", .{});
  _ = try solve1(buffer, gpa);
  std.debug.print("\n", .{});


  const res2 = try solve2(buffer, gpa);

  std.debug.print("Part 2: {d}\n", .{res2});
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
