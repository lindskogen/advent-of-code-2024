const std = @import("std");
const Allocator = std.mem.Allocator;

const Inputs = std.StringArrayHashMap(bool);
const Exprs = std.StringArrayHashMap(Expr);

const Oper = enum {
    XOR,
    AND,
    OR
};

const Expr = struct {
    operator: Oper,
    op1: []const u8,
    op2: []const u8
};

fn resolve(key: []const u8, inputs: *Inputs, exprs: *Exprs) !bool {
    if (inputs.get(key)) |v| {
        return v;
    }

    const ex = exprs.get(key).?;

    const v1 = try resolve(ex.op1, inputs, exprs);
    const v2 = try resolve(ex.op2, inputs, exprs);

    const v = switch (ex.operator) {
        .AND => v1 and v2,
        .OR => v1 or v2,
        .XOR => v1 != v2,
    };

    try inputs.put(key, v);

    return v;
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var inputs = Inputs.init(alloc);
    defer inputs.deinit();

    var connections = Exprs.init(alloc);
    defer connections.deinit();

    var left = std.StringArrayHashMap(void).init(alloc);
    defer left.deinit();


    var groupIter = std.mem.tokenizeSequence(u8, input, "\n\n");

    const g1 = groupIter.next() orelse return error.InvalidInput;


    {
        var inputRowIter = std.mem.tokenizeScalar(u8, g1, '\n');

        while (inputRowIter.next()) |in| {
            var inputIter = std.mem.tokenizeAny(u8, in, ": ");

            const key = inputIter.next() orelse return error.InvalidInput;
            const value = inputIter.next() orelse return error.InvalidInput;

            try inputs.put(key, value[0] == '1');
        }
    }

    const g2 = groupIter.next() orelse return error.InvalidInput;

    {
        var rowIter = std.mem.tokenizeScalar(u8, g2, '\n');

        while (rowIter.next()) |in| {
            var inputIter = std.mem.tokenizeAny(u8, in, " ->");

            const in1 = inputIter.next() orelse return error.InvalidInput;
            const op = inputIter.next() orelse return error.InvalidInput;
            const in2 = inputIter.next() orelse return error.InvalidInput;
            const out = inputIter.next() orelse return error.InvalidInput;

            const oper: Oper = switch (op[0]) {
                'X' => .XOR,
                'A' => .AND,
                else => .OR
            };

            try connections.put(out, .{ .op1 = in1, .op2 = in2, .operator = oper });
            if (out[0] == 'z') {
                try left.put(out, {});
            }
        }
    }

    var res = std.bit_set.IntegerBitSet(64).initEmpty();

    for (left.keys()) |zkey| {
        const v = try resolve(zkey, &inputs, &connections);
        const idx = try std.fmt.parseInt(usize, zkey[1..], 10);
        res.setValue(idx, v);
    }

    return res.mask;
}

// fn solve2(input: []const u8, alloc: Allocator) !usize {
//
// }

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day24/input",
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
        \\x00: 1
        \\x01: 0
        \\x02: 1
        \\x03: 1
        \\x04: 0
        \\y00: 1
        \\y01: 1
        \\y02: 1
        \\y03: 1
        \\y04: 1
        \\
        \\ntg XOR fgs -> mjb
        \\y02 OR x01 -> tnw
        \\kwq OR kpj -> z05
        \\x00 OR x03 -> fst
        \\tgd XOR rvg -> z01
        \\vdt OR tnw -> bfw
        \\bfw AND frj -> z10
        \\ffh OR nrd -> bqk
        \\y00 AND y03 -> djm
        \\y03 OR y00 -> psh
        \\bqk OR frj -> z08
        \\tnw OR fst -> frj
        \\gnj AND tgd -> z11
        \\bfw XOR mjb -> z00
        \\x03 OR x00 -> vdt
        \\gnj AND wpb -> z02
        \\x04 AND y00 -> kjc
        \\djm OR pbm -> qhw
        \\nrd AND vdt -> hwm
        \\kjc AND fst -> rvg
        \\y04 OR y02 -> fgs
        \\y01 AND x02 -> pbm
        \\ntg OR kjc -> kwq
        \\psh XOR fgs -> tgd
        \\qhw XOR tgd -> z09
        \\pbm OR djm -> kpj
        \\x03 XOR y03 -> ffh
        \\x00 XOR y04 -> ntg
        \\bfw OR bqk -> z06
        \\nrd XOR fgs -> wpb
        \\frj XOR qhw -> z04
        \\bqk OR frj -> z07
        \\y03 OR x01 -> nrd
        \\hwm AND bqk -> z03
        \\tgd XOR rvg -> z12
        \\tnw OR pbm -> gnj
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(2024, res);
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
