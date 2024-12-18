const std = @import("std");
const Allocator = std.mem.Allocator;

const Parsed = struct { a: usize, ops: []u3 };

fn parse(input: []const u8, alloc: Allocator) !Parsed {
    var parsed = Parsed{ .a = 0, .ops = undefined };
    var programSlice = std.ArrayList(u3).init(alloc);
    var groupIter = std.mem.tokenizeSequence(u8, input, "\n\n");

    if (groupIter.next()) |registers| {
        var regs = std.mem.tokenizeScalar(u8, registers[12..], '\n');
        if (regs.next()) |r| {
            const a = try std.fmt.parseInt(usize, r, 10);
            parsed.a = a;
        }
    }

    if (groupIter.next()) |program| {
        var nums = std.mem.tokenizeScalar(u8, program[9..], ',');

        while (nums.next()) |ns| {
            const p = try std.fmt.parseInt(u3, ns, 10);
            try programSlice.append(p);
        }
    }
    parsed.ops = try programSlice.toOwnedSlice();

    return parsed;
}

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
        },
    };
}

fn run(a: usize, ops: []u3, output: []u3) !usize {
    var reg = Reg{
        .a = a,
        .b = 0,
        .c = 0,
    };
    var out: usize = 0;
    var pc: usize = 0;

    while (pc < ops.len) {
        switch (ops[pc]) {
            // adv
            0 => {
                const operand = combo_op(ops[pc + 1], reg);
                reg.a = reg.a / try std.math.powi(usize, 2, operand);
                pc += 2;
            },
            // bxl
            1 => {
                reg.b = reg.b ^ ops[pc + 1];
                pc += 2;
            },
            // bst
            2 => {
                const operand = combo_op(ops[pc + 1], reg);
                reg.b = operand % 8;
                pc += 2;
            },
            // jnz
            3 => {
                const operand = ops[pc + 1];
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
                const operand = combo_op(ops[pc + 1], reg);
                output[out] = @intCast(operand % 8);
                out += 1;
                pc += 2;
            },
            // bdv
            6 => {
                const operand = combo_op(ops[pc + 1], reg);
                reg.b = reg.a / try std.math.powi(usize, 2, operand);
                pc += 2;
            },
            // cdv
            7 => {
                const operand = combo_op(ops[pc + 1], reg);
                reg.c = reg.a / try std.math.powi(usize, 2, operand);
                pc += 2;
            },
        }
    }

    return out;
}

fn solve1(input: []const u8, alloc: Allocator) ![]u3 {
    const parsed = try parse(input, alloc);
    const ops = parsed.ops;
    defer alloc.free(ops);

    var output: [16]u3 = undefined;

    const len = try run(parsed.a, ops, &output);
    return output[0..len];
}

fn solve2(input: []const u8, alloc: Allocator) !usize {
    const parsed = try parse(input, alloc);
    const ops = parsed.ops;

    var output: [16]u3 = undefined;
    var a: usize = 0;
    var len: usize = 3;

    while (true) {
        const first_index = ops.len - len;
        _ = try run(a, ops, &output);
        if (std.mem.eql(u3, ops[first_index..], output[0..len])) {
            if (len == ops.len) {
                break;
            }
            len += 1;
            a *= 8;
        } else {
            a += 1;
        }
    }

    return a;
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
    const res1 = try solve1(buffer, gpa);
    for (res1, 0..) |o, i| {
        if (i == res1.len - 1) {
            std.debug.print("{d}", .{o});
        } else {
            std.debug.print("{d},", .{o});
        }
    }
    std.debug.print("\n", .{});

    const res2 = try solve2(buffer, gpa);

    std.debug.print("Part 2: {d}\n", .{res2});
}

test "part 1 - simple" {
    const input =
        \\Register A: 729
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqualDeep(&[_]u3{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 }, res[0..10]);
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
