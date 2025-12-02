const std = @import("std");

const FileParsingError = error{NotANumber};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    const solution1: u64 = try part1(file);
    const solution2: u64 = try part2(file);

    std.debug.print("Solution for part 1: {}\n", .{solution1});
    std.debug.print("Solution for part 2: {}\n", .{solution2});
}

fn part1(file: std.fs.File) !u64 {
    var result: u64 = 0;

    var read_buff: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buff);
    const reader = &file_reader.interface;

    while (try reader.takeDelimiter(',')) |input_string| {
        const line = std.mem.trimEnd(u8, input_string, "\r\n\t ");

        var iter = std.mem.splitAny(u8, line, "-");
        const bottom_val = iter.next() orelse return FileParsingError.NotANumber;
        const bottom = try std.fmt.parseInt(u64, bottom_val, 10);
        const top_val = iter.next() orelse return FileParsingError.NotANumber;
        const top = try std.fmt.parseInt(u64, top_val, 10);

        for (bottom..top + 1) |val| {
            result += try handleIdPart1(val);
        }
    }

    return result;
}

fn handleIdPart1(productId: u64) !u64 {
    var buffer: [21]u8 = undefined;
    const slice = try std.fmt.bufPrint(&buffer, "{}", .{productId});

    if (slice.len % 2 != 0) {
        return 0;
    }

    const middle = slice.len / 2;

    const first_half = slice[0..middle];
    const last_half = slice[middle..];

    if (!std.mem.eql(u8, first_half, last_half)) {
        return 0;
    }

    return productId;
}

fn part2(file: std.fs.File) !u64 {
    var result: u64 = 0;

    var read_buff: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buff);
    const reader = &file_reader.interface;

    while (try reader.takeDelimiter(',')) |input_string| {
        const line = std.mem.trimEnd(u8, input_string, "\r\n\t ");

        var iter = std.mem.splitAny(u8, line, "-");
        const bottom_val = iter.next() orelse return FileParsingError.NotANumber;
        const bottom = try std.fmt.parseInt(u64, bottom_val, 10);
        const top_val = iter.next() orelse return FileParsingError.NotANumber;
        const top = try std.fmt.parseInt(u64, top_val, 10);

        for (bottom..top + 1) |val| {
            result += try handleIdPart2(val);
        }
    }

    return result;

}

fn handleIdPart2(productId: u64) !u64 {
    var buffer: [21]u8 = undefined;
    const slice = try std.fmt.bufPrint(&buffer, "{}", .{productId});
    const length = slice.len;

    if (length < 2) return 0;

    for (1..(length / 2) + 1) |k| {
        if (length % k != 0) continue;

        const block = slice[0..k];
        var repeats = true;

        var i: usize = k;
        while (i < length) : (i += k) {
            const current_block = slice[i..i + k];
            if (!std.mem.eql(u8, block, current_block)) {
                repeats = false;
                break;
            }
        }

        if (repeats) return productId;
    }

    return 0;
}
