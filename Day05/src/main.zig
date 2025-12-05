const std = @import("std");
const expect = std.testing.expect;

const FileParsingError = error{NotANumber};

pub fn main() !void {
    const file: std.fs.File = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.heap.page_allocator;

    const solution1 = try part1(file, allocator);

    std.debug.print("The solution for part 1: {}\n", .{solution1});
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

            for (fresh_ranges.items) |range_line| {
                const line = std.mem.trimEnd(u8, range_line, "\r\n\t ");

                var iter = std.mem.splitAny(u8, line, "-");
                const bottom_val = iter.next() orelse return FileParsingError.NotANumber;
                const bottom = try std.fmt.parseInt(u64, bottom_val, 10);
                const top_val = iter.next() orelse return FileParsingError.NotANumber;
                const top = try std.fmt.parseInt(u64, top_val, 10);

                for (bottom..top + 1) |valid_id| {
                    if (id != valid_id) continue;

                    if (valid_ids.items.len == 0) {
                        try valid_ids.append(allocator, id);
                        break;
                    }
                }
            }
        }
    }

    return valid_ids.items.len;
}

test "part_1" {
    const file: std.fs.File = try std.fs.cwd().openFile("input/test_part1.txt", .{ .mode = .read_only });
    defer file.close();

    const allocator = std.testing.allocator;

    const test_1 = try part1(file, allocator);

    try expect(test_1 == 3);
}
