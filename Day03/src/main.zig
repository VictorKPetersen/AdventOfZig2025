const std = @import("std");
const expect = std.testing.expect;

const BatteryError = error{
    DigitLengthTooSmall
};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{.mode = .read_only});
    defer file.close();

    const solution1 = try part1(file);
    const solution2 = try part2(file);

    std.debug.print("Solution for part 1: {} \n", .{solution1});
    std.debug.print("Solution for part 2: {} \n", .{solution2});
}

fn part1(file: std.fs.File) !u32 {
    var read_buf: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);
    const reader = &file_reader.interface;
    
    var total: u32 = 0;
    while (try reader.takeDelimiter('\n')) |line| {
        total += @as(u32, try handleLinePart1(line));
    }
    return total;
}

fn handleLinePart1(line: []const u8) !u8 {
    var max_joltage: u8 = 0;

    for (line, 0..) |char, i| {
        const tens_digit = try std.fmt.charToDigit(char, 10);

        var j: usize = i + 1;
        while (j < line.len) : (j += 1) {
            const ones_digit =  try std.fmt.charToDigit(line[j], 10);

            const current_joltage: u8 = (tens_digit * 10) + ones_digit;

            if (current_joltage > max_joltage) {
                max_joltage = current_joltage;
            }
        }
    }
    return max_joltage;
}

fn part2(file: std.fs.File) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var total: u64 = 0;
    while (try reader.takeDelimiter('\n')) |line| {
        total += try handleLinePart2(line, 12);
    }

    return total;
}

fn handleLinePart2(line: []const u8, digit_lenght: u8) !u64 {
    if (digit_lenght < 1) return BatteryError.DigitLengthTooSmall;

    var current_joltage: u64 = 0;
    var left_pointer: usize = 0;
    var i: usize = digit_lenght;
    while (i > 0){
        i -= 1;
        const right_pointer: usize = line.len - i;
        var highest_digit: u8 = 0;
        for (left_pointer..right_pointer) |j| {
            const digit_value = try std.fmt.charToDigit(line[j], 10);
            if (digit_value > highest_digit) {
                highest_digit = digit_value;
                left_pointer = j + 1;
            }
        }

        current_joltage += (highest_digit * std.math.pow(u64, 10, i));
    }

    return current_joltage;
}

test "part1_test" {
    const lines = [_][]const u8 {
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111"
    };

    var total: u32 = 0;
    for (lines) |val| {
        total += try handleLinePart1(val);
    }

    try expect(total == 357);
}

test "part2_test" {
    const lines = [_][]const u8 {
        "987654321111111",
        "811111111111119",
        "234234234234278",
        "818181911112111"
    };

    var total: u64 = 0;
    for (lines) |val| {
        total += try handleLinePart2(val, 12);
    }

    try expect(total == 3121910778619);
}
