const std = @import("std");
const expect = std.testing.expect;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution1 = try part1(file, allocator);
    const solution2 = try part2(file, allocator);

    std.debug.print("The solution to part 1 is: {}\n", .{solution1});
    std.debug.print("The solution to part 2 is: {}\n", .{solution2});
}

fn part1(file: std.fs.File, allocator: std.mem.Allocator) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var map = std.AutoHashMap(usize, std.ArrayList([]const u8)).init(allocator);
    defer map.deinit();

    while (try reader.takeDelimiter('\n')) |input_line| {
        const line = std.mem.trimEnd(u8, input_line, "\r\n\t ");

        var iter = std.mem.tokenizeAny(u8, line, " ");

        var i: usize = 0;
        while (iter.next()) |num| {
            if (map.contains(i)) {
                var list = map.get(i).?;
                try list.append(allocator, try allocator.dupe(u8, num));
                try map.put(i, list);
            } else {
                var list = std.ArrayList([]const u8).empty;
                try list.append(allocator, try allocator.dupe(u8, num));
                try map.put(i, list);
            }
            i += 1;
        }
    }

    var map_iter = map.iterator();
    var total_result: u64 = 0;

    while (map_iter.next()) |entry| {
        const list = entry.value_ptr;
        const op = list.orderedRemove(list.items.len - 1);
        const op_char = op[0];

        var local_result: u64 = 0;
        switch (op_char) {
            '+' => {
                for (list.items) |item| {
                    const number = try std.fmt.parseInt(u64, item, 10);
                    local_result += number;
                }
            },
            '*' => {
                for (list.items) |item| {
                    if (local_result == 0) local_result = 1;
                    const number = try std.fmt.parseInt(u64, item, 10);
                    local_result *= number;
                }
            },
            else => unreachable,
        }

        total_result += local_result;
    }

    return total_result;
}

fn part2(file: std.fs.File, allocator: std.mem.Allocator) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |input_line| {
        const line = std.mem.trimEnd(u8, input_line, "\r\n");
        try lines.append(allocator, try allocator.dupe(u8, line));
    }

    const op_line = lines.items[lines.items.len - 1];
    const num_lines = lines.items[0 .. lines.items.len - 1];

    var col_start: usize = 0;
    var total_result: u64 = 0;
    while (col_start < op_line.len) {
        if (op_line[col_start] == ' ') {
            col_start += 1;
            continue;
        }

        const op = op_line[col_start];

        var col_end = col_start + 1;
        while (col_end < op_line.len and op_line[col_end] == ' ') {
            var has_content = false;
            for (num_lines) |line| {
                if (col_end < line.len and line[col_end] != ' ') {
                    has_content = true;
                    break;
                }
            }
            if (has_content) col_end += 1 else break;
        }

        var local_result: u64 = 0;
        for (col_start..col_end) |index| {
            var col_number: std.ArrayList(u8) = .empty;
            defer col_number.deinit(allocator);

            for (num_lines) |number_row| {
                if (number_row[index] == ' ') continue;
                try col_number.append(allocator, number_row[index]);
            }

            const concat = col_number.items;
            const number = try std.fmt.parseInt(u64, concat, 10);

            switch (op) {
                '+' => {
                    local_result += number;
                },
                '*' => {
                    if (local_result == 0) local_result = 1;
                    local_result *= number;
                },
                else => unreachable,
            }
        }

        col_start = col_end;
        total_result += local_result;
    }

    return total_result;
}

test "part_1" {
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print(" \n", .{});
    const result = try part1(file, allocator);
    try expect(result == 4277556);
}

test "part_2" {
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print(" \n", .{});
    const result = try part2(file, allocator);
    try expect(result == 3263827);
}
