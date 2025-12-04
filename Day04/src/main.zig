const std = @import("std");
const expect = std.testing.expect;

const GridError = error{ HeightIsZero, WidthIsZero };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.heap.page_allocator;

    const solution1 = try part1(file, allocator);
    const solution2 = try part2(file, allocator);

    std.debug.print("Solution for part 1: {}\n", .{solution1});
    std.debug.print("Solution for part 2: {}\n", .{solution2});
}

fn part1(file: std.fs.File, allocator: std.mem.Allocator) !u32 {
    var read_buf: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var warehouse_list: std.ArrayList([]const u8) = .empty;

    defer {
        for (warehouse_list.items) |element| {
            allocator.free(element);
        }
        warehouse_list.deinit(allocator);
    }

    while (try reader.takeDelimiter('\n')) |line| {
        const duplicated_line = try allocator.dupe(u8, line);
        try warehouse_list.append(allocator, duplicated_line);
    }

    const total = try solvePart1(warehouse_list);
    return total;
}

fn solvePart1(list: std.ArrayList([]const u8)) !u32 {
    var accesible: u32 = 0;

    const height = list.items.len;
    const width = list.items[0].len;

    if (height == 0) return GridError.HeightIsZero;
    if (width == 0) return GridError.WidthIsZero;

    for (0..height) |y| {
        for (0..width) |x| {
            if (list.items[y][x] != '@') continue;
            var adjacent_count: u4 = 0;

            const directions = [_][2]i8{
                .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
                .{ 0, -1 },  .{ 0, 1 },  .{ 1, -1 },
                .{ 1, 0 },   .{ 1, 1 },
            };

            for (directions) |dir| {
                const ny = @as(i32, @intCast(y)) + dir[0];
                const nx = @as(i32, @intCast(x)) + dir[1];

                if (ny >= 0 and ny < height and nx >= 0 and nx < width) {
                    if (list.items[@intCast(ny)][@intCast(nx)] == '@') {
                        adjacent_count += 1;
                    }
                }
            }

            if (adjacent_count < 4) {
                accesible += 1;
            }
        }
    }

    return accesible;
}

fn part2(file: std.fs.File, allocator: std.mem.Allocator) !u32 {
    var read_buf: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var warehouse_list: std.ArrayList([]const u8) = .empty;

    defer {
        for (warehouse_list.items) |element| {
            allocator.free(element);
        }
        warehouse_list.deinit(allocator);
    }

    while (try reader.takeDelimiter('\n')) |line| {
        const duplicated_line = try allocator.dupe(u8, line);
        try warehouse_list.append(allocator, duplicated_line);
    }

    const total = try solvePart2(warehouse_list, allocator);
    return total;
}

fn solvePart2(list: std.ArrayList([]const u8), allocator: std.mem.Allocator) !u32 {
    var total_removed: u32 = 0;

    const height = list.items.len;
    const width = list.items[0].len;

    if (height == 0) return GridError.HeightIsZero;
    if (width == 0) return GridError.WidthIsZero;

    var grid = try allocator.alloc([]u8, height);
    defer allocator.free(grid);

    for (0..height) |y| {
        grid[y] = try allocator.alloc(u8, width);
        @memcpy(grid[y], list.items[y]);
    }

    defer {
        for (grid) |row| {
            allocator.free(row);
        }
    }

    while (true) {
        var to_remove: std.ArrayList([2]usize) = .empty;
        defer to_remove.deinit(allocator);

        for (0..height) |y| {
            for (0..width) |x| {
                if (grid[y][x] != '@') continue;
                var adjacent_count: u4 = 0;

                const directions = [_][2]i8{
                    .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 },
                    .{ 0, -1 },  .{ 0, 1 },  .{ 1, -1 },
                    .{ 1, 0 },   .{ 1, 1 },
                };

                for (directions) |dir| {
                    const ny = @as(i32, @intCast(y)) + dir[0];
                    const nx = @as(i32, @intCast(x)) + dir[1];

                    if (ny >= 0 and ny < height and nx >= 0 and nx < width) {
                        if (grid[@intCast(ny)][@intCast(nx)] == '@') {
                            adjacent_count += 1;
                        }
                    }
                }

                if (adjacent_count < 4) {
                    try to_remove.append(allocator, .{ y, x });
                }
            }
        }

        if (to_remove.items.len == 0) break;

        for (to_remove.items) |pos| {
            grid[pos[0]][pos[1]] = '.';
        }

        total_removed += @intCast(to_remove.items.len);
    }

    return total_removed;
}

test "part1_test" {
    const test_allocator = std.testing.allocator;
    const lines = [_][]const u8{
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    };

    var list: std.ArrayList([]const u8) = .empty;

    defer {
        for (list.items) |element| {
            test_allocator.free(element);
        }
        list.deinit(test_allocator);
    }

    for (lines) |line| {
        const duped = try test_allocator.dupe(u8, line);
        try list.append(test_allocator, duped);
    }

    const total = try solvePart1(list);
    try expect(total == 13);
}

test "part2_test" {
    const test_allocator = std.testing.allocator;
    const lines = [_][]const u8{
        "..@@.@@@@.",
        "@@@.@.@.@@",
        "@@@@@.@.@@",
        "@.@@@@..@.",
        "@@.@@@@.@@",
        ".@@@@@@@.@",
        ".@.@.@.@@@",
        "@.@@@.@@@@",
        ".@@@@@@@@.",
        "@.@.@@@.@.",
    };

    var list: std.ArrayList([]const u8) = .empty;

    defer {
        for (list.items) |element| {
            test_allocator.free(element);
        }
        list.deinit(test_allocator);
    }

    for (lines) |line| {
        const duped = try test_allocator.dupe(u8, line);
        try list.append(test_allocator, duped);
    }

    const total = try solvePart2(list, test_allocator);
    try expect(total == 43);
}
