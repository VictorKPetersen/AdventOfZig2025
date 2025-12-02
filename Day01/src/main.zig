const std = @import("std");

const FileParsingError = error{
    UnsupportedSign,
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    const solution_1: u32 = try part1(file);
    const solution_2: i32 = try part2(file);

    std.debug.print("Solution for part 1: {}\n", .{solution_1});
    std.debug.print("Solution for part 2: {}\n", .{solution_2});
}

fn part1(file: std.fs.File) !u32 {
    var read_buff: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buff);
    const reader = &file_reader.interface;

    var dial: i32 = 50;
    var password: u32 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        const dir = line[0];
        const amount = try std.fmt.parseInt(i32, line[1..], 10);

        switch (dir) {
            'L' => dial = @mod(dial - amount, 100),
            'R' => dial = @mod(dial + amount, 100),
            else => return FileParsingError.UnsupportedSign,
        }

        if (dial == 0) password += 1;
    }

    return password;
}

fn part2(file: std.fs.File) !i32 {
    var read_buff: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buff);
    const reader = &file_reader.interface;

    var dial: i32 = 50;
    var password: i32 = 0;

    while (try reader.takeDelimiter('\n')) |line| {
        const dir = line[0];
        const amount = try std.fmt.parseInt(i32, line[1..], 10);

        switch (dir) {
            'L' => {
                password += @divTrunc(amount, 100);
                if (dial > 0 and dial - @rem(amount, 100) <= 0) password += 1;
                dial = @mod(dial - amount, 100);
            },
            'R' => {
                password += @divTrunc(amount, 100);
                if (dial + @rem(amount, 100) >= 100) password += 1;
                dial = @mod(dial + amount, 100);
            },
            else => return FileParsingError.UnsupportedSign,
        }
    }

    return password;
}
