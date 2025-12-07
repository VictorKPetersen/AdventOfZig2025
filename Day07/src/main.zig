const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const Timer = std.time.Timer;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer {
        _ = debug_allocator.deinit();
    }

    var arena = std.heap.ArenaAllocator.init(debug_allocator.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var timer_1 = try Timer.start();
    const solution1 = try part1(allocator, file);
    const elapsed_nano_1: u64 = timer_1.read();
    const elapsed_ms_1: f64 = @as(f64, @floatFromInt(elapsed_nano_1)) / @as(f64, @floatFromInt(std.time.ns_per_ms));

    var timer_2 = try Timer.start();
    const solution2 = try part2(allocator, file);
    const elapsed_nano_2: u64 = timer_2.read();
    const elapsed_ms_2: f64 = @as(f64, @floatFromInt(elapsed_nano_2)) / @as(f64, @floatFromInt(std.time.ns_per_ms));

    std.debug.print("The solution for part 1 is: {}\n", .{solution1});
    std.debug.print("Time for part 1: {d:.8}ms\n", .{elapsed_ms_1});

    std.debug.print("The solution for part 2 is: {}\n", .{solution2});
    std.debug.print("Time for part 2: {d:.8}ms\n", .{elapsed_ms_2});
}

fn part1(allocator: Allocator, file: std.fs.File) !u32 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var row_list: std.ArrayList([]u8) = .empty;
    defer row_list.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |row| {
        try row_list.append(allocator, try allocator.dupe(u8, row));
    }

    var splits: u32 = 0;
    for (row_list.items, 0..) |line, row| {
        for (0..line.len) |col| {
            if (line[col] == '|' and row < row_list.items.len - 1) {
                if (row_list.items[row + 1][col] != '^') {
                    row_list.items[row + 1][col] = '|';
                } else if (row_list.items[row + 1][col] == '^') {
                    splits += 1;
                    if (row_list.items[row + 1][col - 1] == '.') {
                        row_list.items[row + 1][col - 1] = '|';
                    }
                    if (row_list.items[row + 1][col + 1] == '.') {
                        row_list.items[row + 1][col + 1] = '|';
                    }
                }
            } else if (line[col] == 'S') {
                row_list.items[row + 1][col] = '|';
            }
        }
    }

    return splits;
}

const Point = struct {
    sign: u8,
    value: u64,
};

fn part2(allocator: Allocator, file: std.fs.File) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var row_list: std.ArrayList([]Point) = .empty;
    defer row_list.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |row| {
        const row_slice = try allocator.alloc(Point, row.len);
        for (0..row.len) |col| {
            row_slice[col] = Point{
                .sign = row[col],
                .value = 0,
            };
        }

        try row_list.append(allocator, row_slice);
    }

    for (row_list.items, 0..) |line, row| {
        for (0..line.len) |col| {
            if (line[col].sign == '|' and row < row_list.items.len - 1) {
                if (row_list.items[row + 1][col].sign != '^') {
                    row_list.items[row + 1][col].sign = line[col].sign;
                    row_list.items[row + 1][col].value += line[col].value;
                } else if (row_list.items[row + 1][col].sign == '^') {
                    row_list.items[row + 1][col - 1].sign = line[col].sign;
                    row_list.items[row + 1][col - 1].value += line[col].value;
                    row_list.items[row + 1][col + 1].sign = line[col].sign;
                    row_list.items[row + 1][col + 1].value += line[col].value;
                }
            } else if (line[col].sign == 'S') {
                row_list.items[row + 1][col].sign = '|';
                row_list.items[row + 1][col].value = 1;
            }
        }
    }

    const sum_line = row_list.getLast();

    var sum: u64 = 0;
    for (sum_line) |timeline| {
        sum += timeline.value;
    }
    return sum;
}

test "part_1" {
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print(" \n", .{});
    const result = try part1(allocator, file);
    try expect(result == 21);
}

test "part_2" {
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try part2(allocator, file);
    try expect(result == 40);
}
