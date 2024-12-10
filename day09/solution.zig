const std = @import("std");
const Allocator = std.mem.Allocator;

const Block = union(enum) {
    file: usize,
    space: void,
};

fn shrinkRemoveSpaceAtEnd(disk: *std.ArrayList(Block)) !void {
    while (disk.getLastOrNull()) |last| {
        switch (last) {
            .file => return,
            .space => {
                _ = disk.pop();
            },
        }
    }
    return error.ReachedStart;
}

fn solve1(input: []const u8, alloc: Allocator) !usize {
    var disk = std.ArrayList(Block).init(alloc);
    defer disk.deinit();

    {
        var isSpace = false;
        var id: usize = 0;
        for (input) |c| {
            if (c == '\n') {
                break;
            }
            const size = c - '0';
            if (isSpace) {
                for (0..size) |_| {
                    try disk.append(.{ .space = {} });
                }
            } else {
                for (0..size) |_| {
                    try disk.append(.{ .file = id });
                }
                id += 1;
            }
            isSpace = !isSpace;
        }
    }

    try shrinkRemoveSpaceAtEnd(&disk);

    {
        var i: usize = 0;
        while (i < disk.items.len) : (i += 1) {
            switch (disk.items[i]) {
                .file => {},
                .space => {
                    _ = disk.swapRemove(i);
                    try shrinkRemoveSpaceAtEnd(&disk);
                },
            }
        }
    }

    var sum: usize = 0;

    for (disk.items, 0..) |b, i| {
        switch (b) {
            .file => |id| {
                sum += id * i;
            },
            .space => {
                std.debug.panic("Space left in disk index: {d}\n", .{i});
            },
        }
    }

    return sum;
}

const IndexLen = struct {
    i: usize,
    size: usize,
    id: usize,
};

fn solve2(input: []const u8, alloc: Allocator) !usize {
    var disk = std.ArrayList(Block).init(alloc);
    var spaces = std.ArrayList(IndexLen).init(alloc);
    var files = std.ArrayList(IndexLen).init(alloc);
    defer disk.deinit();
    defer spaces.deinit();
    defer files.deinit();

    var isSpace = false;
    var max_id: usize = 0;
    for (input) |c| {
        if (c == '\n') {
            break;
        }
        const size = c - '0';
        if (isSpace) {
            try spaces.append(.{ .i = disk.items.len, .size = size, .id = 0 });
            try disk.appendNTimes(.{ .space = {} }, size);
        } else {
            try files.append(.{ .i = disk.items.len, .size = size, .id = max_id });
            try disk.appendNTimes(.{ .file = max_id }, size);
            max_id += 1;
        }
        isSpace = !isSpace;
    }

    while (files.popOrNull()) |last| {
        for (spaces.items, 0..) |*space, i| {
            if (space.i > last.i) {
                break;
            }
            if (space.size >= last.size) {
                @memset(disk.items[space.i .. space.i + last.size], .{ .file = last.id });
                @memset(disk.items[last.i .. last.i + last.size], .{ .space = {} });

                space.i += last.size;
                space.size -= last.size;
                if (space.size == 0) {
                    _ = spaces.orderedRemove(i);
                }
                break;
            }
        }
    }

    var sum: usize = 0;
    for (disk.items, 0..) |b, i| {
        switch (b) {
            .file => |id| {
                sum += id * i;
            },
            .space => {},
        }
    }

    return sum;
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();

    const file = try std.fs.cwd().openFile(
        "day09/input",
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
    const input = "2333133121414131402";

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve1(input, gpa);

    try std.testing.expectEqual(1928, res);
}

test "part 2 - simple" {
    const input = "2333133121414131402";

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);

    const gpa = general_purpose_allocator.allocator();

    const res = try solve2(input, gpa);

    try std.testing.expectEqual(2858, res);
}
