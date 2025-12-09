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
    const solution2 = try part2(allocator, file);

    std.debug.print("The solution to part 1 is: {}\n", .{solution1});
    std.debug.print("The solution to part 2 is: {}\n", .{solution2});
}

const Point = struct {
    row: i32,
    col: i32,

    fn min(a: Point, b: Point) Point {
        return .{ .row = @min(a.row, b.row), .col = @min(a.col, b.col) };
    }

    fn max(a: Point, b: Point) Point {
        return .{ .row = @max(a.row, b.row), .col = @max(a.col, b.col) };
    }
};

const BoundingBox = struct {
    min: Point,
    max: Point,

    fn init() @This() {
        return .{
            .min = .{ .row = std.math.maxInt(i32), .col = std.math.maxInt(i32) },
            .max = .{ .row = std.math.minInt(i32), .col = std.math.minInt(i32) },
        };
    }

    fn expand(self: *@This(), p: Point) void {
        self.min = Point.min(self.min, p);
        self.min = Point.max(self.max, p);
    }

    fn width(self: @This()) i32 {
        return self.max.row - self.min.row + 1;
    }

    fn height(self: @This()) i32 {
        return self.max.col - self.min.col + 1;
    }

    fn area(self: @This()) i64 {
        return @as(i64, self.width()) * @as(i64, self.height());
    }

    fn fromPoints(p1: Point, p2: Point) @This() {
        return .{
            .min = Point.min(p1, p2),
            .max = Point.max(p1, p2),
        };
    }
};

fn part1(allocator: Allocator, file: std.fs.File) !i64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var point_list: std.ArrayList(Point) = .empty;
    defer point_list.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |input| {
        const line = std.mem.trim(u8, input, "\r\n\t");
        var iter = std.mem.splitAny(u8, line, ",");
        const row_string = iter.next() orelse return FileParsingError.NotANumber;
        const row = try std.fmt.parseInt(i32, row_string, 10);
        const col_string = iter.next() orelse return FileParsingError.NotANumber;
        const col = try std.fmt.parseInt(i32, col_string, 10);

        const point: Point = .{
            .row = row,
            .col = col,
        };
        try point_list.append(allocator, point);
    }

    var largest_area: i64 = 0;
    const points = point_list.items;
    for (0..points.len) |i| {
        for (i + 1..points.len) |j| {
            const bbox = BoundingBox.fromPoints(points[i], points[j]);
            const area = bbox.area();
            if (area > largest_area) {
                largest_area = area;
            }
        }
    }
    return largest_area;
}

fn computeBoundingBox(points: []const Point) BoundingBox {
    var bbox = BoundingBox.init();
    for (points) |p| {
        bbox.expand(p);
    }
    return bbox;
}

const Segment = struct {
    start: Point,
    end: Point,
    is_horizontal: bool,
};

fn removeDuplicates(comptime T: type, allocator: Allocator, sorted: []const T) ![]T {
    if (sorted.len == 0) return try allocator.alloc(T, 0);

    var result: std.ArrayList(T) = .empty;
    try result.append(allocator, sorted[0]);

    for (sorted[1..]) |val| {
        if (val != result.items[result.items.len - 1]) {
            try result.append(allocator, val);
        }
    }

    return result.toOwnedSlice(allocator);
}

fn isRectangleInPolygon(rect: BoundingBox, segments: []const Segment) bool {
    const corners = [_]Point{
        rect.min,
        .{ .row = rect.max.row, .col = rect.min.col },
        rect.max,
        .{ .row = rect.min.row, .col = rect.max.col },
    };

    for (corners) |corner| {
        if (!isPointInPolygon(corner, segments)) {
            return false;
        }
    }

    const rect_edges = [_]Segment{
        .{ .start = corners[0], .end = corners[1], .is_horizontal = true },
        .{ .start = corners[1], .end = corners[2], .is_horizontal = false },
        .{ .start = corners[3], .end = corners[2], .is_horizontal = true },
        .{ .start = corners[0], .end = corners[3], .is_horizontal = false },
    };

    for (rect_edges) |rect_edge| {
        for (segments) |poly_edge| {
            if (edgesCrossImproperly(rect_edge, poly_edge)) {
                return false;
            }
        }
    }
    return true;
}

fn isPointInPolygon(p: Point, segments: []const Segment) bool {
    var crossings: i32 = 0;
    for (segments) |seg| {
        if (seg.is_horizontal) {
            if (p.col == seg.start.col and p.row >= seg.start.row and p.row <= seg.end.row) {
                return true;
            }
        } else {
            if (p.row == seg.start.row and p.col >= seg.start.col and p.col <= seg.end.col) {
                return true;
            }

            if (p.row < seg.start.row and p.col > seg.start.col and p.col <= seg.end.col) {
                crossings += 1;
            }
        }
    }

    return @mod(crossings, 2) == 1;
}

fn edgesCrossImproperly(rect_edge: Segment, poly_edge: Segment) bool {
    if (rect_edge.is_horizontal and !poly_edge.is_horizontal) {
        const rx1 = rect_edge.start.row;
        const rx2 = rect_edge.end.row;
        const ry = rect_edge.start.col;

        const px = poly_edge.start.row;
        const py1 = poly_edge.start.col;
        const py2 = poly_edge.end.col;

        if (px > rx1 and px < rx2 and ry > py1 and ry < py2) {
            return true;
        }
    } else if (!rect_edge.is_horizontal and poly_edge.is_horizontal) {
        const rx = rect_edge.start.row;
        const ry1 = rect_edge.start.col;
        const ry2 = rect_edge.end.col;

        const py = poly_edge.start.col;
        const px1 = poly_edge.start.row;
        const px2 = poly_edge.end.row;

        if (rx > px1 and rx < px2 and py > ry1 and py < ry2) {
            return true;
        }
    }

    return false;
}

fn part2(allocator: Allocator, file: std.fs.File) !i64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var point_list: std.ArrayList(Point) = .empty;
    defer point_list.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |input| {
        const line = std.mem.trim(u8, input, "\r\n\t");
        var iter = std.mem.splitAny(u8, line, ",");
        const row_string = iter.next() orelse return FileParsingError.NotANumber;
        const row = try std.fmt.parseInt(i32, row_string, 10);
        const col_string = iter.next() orelse return FileParsingError.NotANumber;
        const col = try std.fmt.parseInt(i32, col_string, 10);

        const point: Point = .{
            .row = row,
            .col = col,
        };
        try point_list.append(allocator, point);
    }

    var segments: std.ArrayList(Segment) = .empty;
    defer segments.deinit(allocator);

    const points = point_list.items;
    for (0..points.len) |i| {
        const p1 = points[i];
        const p2 = points[(i + 1) % points.len];
        try segments.append(allocator, .{
            .start = Point.min(p1, p2),
            .end = Point.max(p1, p2),
            .is_horizontal = (p1.col == p2.col),
        });
    }

    var x_coords: std.ArrayList(i32) = .empty;
    defer x_coords.deinit(allocator);
    var y_coords: std.ArrayList(i32) = .empty;
    defer y_coords.deinit(allocator);

    for (points) |p| {
        try x_coords.append(allocator, p.row);
        try y_coords.append(allocator, p.col);
    }

    std.mem.sort(i32, x_coords.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, y_coords.items, {}, std.sort.asc(i32));

    const unique_x = try removeDuplicates(i32, allocator, x_coords.items);
    defer allocator.free(unique_x);
    const unique_y = try removeDuplicates(i32, allocator, y_coords.items);
    defer allocator.free(unique_y);

    var x_to_idx = std.AutoHashMap(i32, usize).init(allocator);
    defer x_to_idx.deinit();
    var y_to_idx = std.AutoHashMap(i32, usize).init(allocator);
    defer y_to_idx.deinit();

    for (unique_x, 0..) |x, i| {
        try x_to_idx.put(x, i);
    }

    for (unique_y, 0..) |y, i| {
        try y_to_idx.put(y, i);
    }

    var largest_area: i64 = 0;
    for (0..points.len) |i| {
        for (i + 1..points.len) |j| {
            const p1 = points[i];
            const p2 = points[j];

            const bbox = BoundingBox.fromPoints(p1, p2);
            const area = bbox.area();

            if (area <= largest_area) continue;
            if (isRectangleInPolygon(bbox, segments.items)) {
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

test "part_2" {
    std.debug.print(" \n", .{});
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try part2(allocator, file);

    try expectEqual(24, result);
}
