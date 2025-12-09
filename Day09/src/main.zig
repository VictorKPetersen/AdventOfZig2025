const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

const FileParsingError = error{NotANumber};
const InputError = error{InvalidFormat};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    var arena = std.heap.ArenaAllocator.init(debug_allocator.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution1 = try part1(allocator, file);

    std.debug.print("The solution to part 1 is: {}\n", .{solution1});
}

const Point = struct {
    row: u32,
    col: u32,
};

fn part1(allocator: Allocator, file: std.fs.File) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var point_list: std.ArrayList(Point) = .empty;
    defer point_list.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |input| {
        const line = std.mem.trim(u8, input, "\r\n\t");
        var iter = std.mem.splitAny(u8, line, ",");
        const row_string = iter.next() orelse return FileParsingError.NotANumber;
        const row = try std.fmt.parseInt(u32, row_string, 10);
        const col_string = iter.next() orelse return FileParsingError.NotANumber;
        const col = try std.fmt.parseInt(u32, col_string, 10);

        const point: Point = .{
            .row = row,
            .col = col,
        };
        try point_list.append(allocator, point);
    }

    var largest_area: u64 = 0;
    for (0..point_list.items.len) |i| {
        for (i + 1..point_list.items.len) |j| {
            const p1 = point_list.items[i];
            const p2 = point_list.items[j];
            const length: u64 = @abs(@as(i64, p2.row) - @as(i64, p1.row)) + 1;
            const height: u64 = @abs(@as(i64, p2.col) - @as(i64, p1.col)) + 1;
            const area = length * height;
            if (area > largest_area) {
                largest_area = area;
            }
        }
    }
    return largest_area;
}

test "part_1" {
    std.debug.print(" \n", .{});
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try part1(allocator, file);

    try expectEqual(50, result);
}
