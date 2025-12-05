const std = @import("std");
const expect = std.testing.expect;

const FileParsingError = error{NotANumber};

pub fn main() !void {
    const file: std.fs.File = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.heap.page_allocator;

    const solution1 = try part1(file, allocator);
    const solution2 = try part2(file, allocator);

    std.debug.print("The solution for part 1: {}\n", .{solution1});
    std.debug.print("The solution for part 2: {}\n", .{solution2});
}

fn part1(file: std.fs.File, allocator: std.mem.Allocator) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var fresh_ranges: std.ArrayList([]const u8) = .empty;
    defer fresh_ranges.deinit(allocator);
    defer for (fresh_ranges.items) |i| allocator.free(i);

    var valid_ids: std.ArrayList(u64) = .empty;
    defer valid_ids.deinit(allocator);

    var allRangesFound = false;

    while (try reader.takeDelimiter('\n')) |input| {
        if (input.len == 0) {
            allRangesFound = true;
            continue;
        }

        if (!allRangesFound) {
            const duped_line = try allocator.dupe(u8, input);
            try fresh_ranges.append(allocator, duped_line);
        } else {
            const id = try std.fmt.parseInt(u64, input, 10);
            var is_valid = false;

            for (fresh_ranges.items) |range_line| {
                const line = std.mem.trimEnd(u8, range_line, "\r\n\t ");

                var iter = std.mem.splitAny(u8, line, "-");
                const bottom_val = iter.next() orelse return FileParsingError.NotANumber;
                const bottom = try std.fmt.parseInt(u64, bottom_val, 10);
                const top_val = iter.next() orelse return FileParsingError.NotANumber;
                const top = try std.fmt.parseInt(u64, top_val, 10);

                if (id >= bottom and id <= top) {
                    is_valid = true;
                    break;
                }
            }

            if (is_valid) {
                var found_duplicate = false;
                for (valid_ids.items) |existing_id| {
                    if (id == existing_id) {
                        found_duplicate = true;
                        break;
                    }
                }

                if (!found_duplicate) {
                    try valid_ids.append(allocator, id);
                }
            }
        }
    }

    return valid_ids.items.len;
}

const Range = struct {
    start: u64,
    end: u64,
};

fn part2(file: std.fs.File, allocator: std.mem.Allocator) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var ranges: std.ArrayList(Range) = .empty;
    defer ranges.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |input| {
        if (input.len == 0) break;

        const line = std.mem.trimEnd(u8, input, "\r\n\t ");
        var iter = std.mem.splitAny(u8, line, "-");
        const bottom_val = iter.next() orelse return FileParsingError.NotANumber;
        const bottom = try std.fmt.parseInt(u64, bottom_val, 10);
        const top_val = iter.next() orelse return FileParsingError.NotANumber;
        const top = try std.fmt.parseInt(u64, top_val, 10);

        const current_range = Range{
            .start = bottom,
            .end = top,
        };

        var i: usize = 0;
        while (i < ranges.items.len) : (i += 1) {
            if (ranges.items[i].start > current_range.start) {
                break;
            }
        }
        try ranges.insert(allocator, i, current_range);
    }

    var merged_ranges: std.ArrayList(Range) = .empty;
    defer merged_ranges.deinit(allocator);

    if (ranges.items.len == 0) return 0;

    try merged_ranges.append(allocator, ranges.items[0]);

    var i: usize = 0;
    while (i < ranges.items.len) : (i += 1) {
        const current = ranges.items[i];
        var last_merged = &merged_ranges.items[merged_ranges.items.len - 1];

        if (current.start <= last_merged.end + 1) {
            if (current.end > last_merged.end) {
                last_merged.end = current.end;
            }
        } else {
            try merged_ranges.append(allocator, current);
        }
    }

    var total_ids: u64 = 0;
    for (merged_ranges.items) |range| {
        total_ids += (range.end - range.start + 1);
    }

    return total_ids;
}

test "part_1" {
    const file: std.fs.File = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.testing.allocator;

    const test_1 = try part1(file, allocator);

    try expect(test_1 == 3);
}

test "part_2" {
    const file: std.fs.File = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.testing.allocator;

    const test_2 = try part2(file, allocator);

    try expect(test_2 == 14);
}
