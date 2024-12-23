const std = @import("std");
const Allocator = std.mem.Allocator;

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var rowIter = std.mem.tokenizeScalar(u8, input, '\n');
    var uniq_computers = std.StringArrayHashMap(void).init(alloc);
    defer uniq_computers.deinit();

    while (rowIter.next()) |row| {
        try uniq_computers.put(row[0..2], {});
        try uniq_computers.put(row[3..5], {});
    }

    rowIter.reset();

    const len = uniq_computers.count();

    var adj_matrix = try alloc.alloc(bool, len * len);
    defer alloc.free(adj_matrix);

    while (rowIter.next()) |row| {
        const c1 = row[0..2];
        const c2 = row[3..5];

        const idx1 = uniq_computers.getIndex(c1).?;
        const idx2 = uniq_computers.getIndex(c2).?;

        adj_matrix[idx1 * len + idx2] = true;
        adj_matrix[idx2 * len + idx1] = true;
    }

    const all_keys = uniq_computers.keys();


    var groups = std.StringArrayHashMap(void).init(alloc);
    defer groups.deinit();

    for (all_keys) |computer_name| {
        if (computer_name[0] == 't') {
            const start_idx = uniq_computers.getIndex(computer_name).?;

            for (adj_matrix[(start_idx * len) .. (start_idx * len) + len], 0..) |is_neighbor1, ni| {
                if (is_neighbor1) {
                    for (adj_matrix[(ni * len) .. (ni * len) + len], 0..) |is_neighbor2, ni2| {
                        if (is_neighbor2 and adj_matrix[start_idx * len + ni2] == true) {
                            var sorted_keys = [3][]const u8{
                                all_keys[start_idx],
                                all_keys[ni],
                                all_keys[ni2],
                            };

                            std.mem.sort([]const u8, &sorted_keys, {}, compareStrings);
                            const found_key = try std.mem.join(alloc, "-", &sorted_keys);
                            try groups.put(found_key, {});
                        }
                    }
                }
            }
        }
    }

    return groups.count();
}

// fn solve2(input: []const u8, alloc: Allocator) !usize {
//
// }

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day23/input",
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
        \\kh-tc
        \\qp-kh
        \\de-cg
        \\ka-co
        \\yn-aq
        \\qp-ub
        \\cg-tb
        \\vc-aq
        \\tb-ka
        \\wh-tc
        \\yn-cg
        \\kh-ub
        \\ta-co
        \\de-co
        \\tc-td
        \\tb-wq
        \\wh-td
        \\ta-ka
        \\td-qp
        \\aq-cg
        \\wq-ub
        \\ub-vc
        \\de-ta
        \\wq-aq
        \\wq-vc
        \\wh-yn
        \\ka-de
        \\kh-ta
        \\co-tc
        \\wh-qp
        \\tb-vc
        \\td-yn
    ;

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(7, res);
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
