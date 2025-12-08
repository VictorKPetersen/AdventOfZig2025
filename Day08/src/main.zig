const std = @import("std");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const FileParsingError = error{NotANumber};

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input/input.txt", .{ .mode = .read_only });
    defer file.close();

    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    var arena = std.heap.ArenaAllocator.init(debug_allocator.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    const solution1 = try part1(allocator, file, 1000);
    std.debug.print("Part 1 finished \n", .{});

    const solution2 = try part2(allocator, file);

    std.debug.print("The solution to part 1 is: {}\n", .{solution1});
    std.debug.print("The solution to part 2 is: {}\n", .{solution2});
}

const Point = struct {
    x: u32,
    y: u32,
    z: u32,

    pub fn distanceSquared(self: Point, other: Point) u64 {
        const dx = @as(i64, @intCast(self.x)) - @as(i64, @intCast(other.x));
        const dy = @as(i64, @intCast(self.y)) - @as(i64, @intCast(other.y));
        const dz = @as(i64, @intCast(self.z)) - @as(i64, @intCast(other.z));
        const sum_sq: u64 = @as(u64, @intCast(dx * dx)) +
            @as(u64, @intCast(dy * dy)) +
            @as(u64, @intCast(dz * dz));

        return sum_sq;
    }
};

const Edge = struct {
    i1: usize,
    i2: usize,
    dist_sq: u64,

    pub fn compare(context: void, a: Edge, b: Edge) bool {
        _ = context;
        return a.dist_sq < b.dist_sq;
    }
};

const Dsu = struct {
    parent: []usize,
    rank: []usize,

    pub fn init(allocator: Allocator, n: usize) !Dsu {
        const parent = try allocator.alloc(usize, n);
        const rank = try allocator.alloc(usize, n);
        for (0..n) |i| {
            parent[i] = i;
            rank[i] = 0;
        }
        return Dsu{ .parent = parent, .rank = rank };
    }

    pub fn find(self: *Dsu, x: usize) usize {
        if (self.parent[x] != x) {
            self.parent[x] = self.find(self.parent[x]);
        }
        return self.parent[x];
    }

    pub fn unite(self: *Dsu, x: usize, y: usize) bool {
        var root_x = self.find(x);
        var root_y = self.find(y);

        if (root_x == root_y) return false;

        if (self.rank[root_x] < self.rank[root_y]) {
            const tmp = root_x;
            root_x = root_y;
            root_y = tmp;
        }

        self.parent[root_y] = root_x;
        if (self.rank[root_x] == self.rank[root_y]) {
            self.rank[root_x] += 1;
        }

        return true;
    }
};

fn part1(allocator: Allocator, file: std.fs.File, pairs: u32) !u32 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var box_list: std.ArrayList(Point) = .empty;
    defer box_list.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |row| {
        const line = std.mem.trimEnd(u8, row, "\r\n\t ");
        var iter = std.mem.splitAny(u8, line, ",");
        const x_string = iter.next() orelse return FileParsingError.NotANumber;
        const x = try std.fmt.parseInt(u32, x_string, 10);
        const y_string = iter.next() orelse return FileParsingError.NotANumber;
        const y = try std.fmt.parseInt(u32, y_string, 10);
        const z_string = iter.next() orelse return FileParsingError.NotANumber;
        const z = try std.fmt.parseInt(u32, z_string, 10);

        const point: Point = .{ .x = x, .y = y, .z = z };
        try box_list.append(allocator, point);
    }

    var edges: std.ArrayList(Edge) = .empty;
    defer edges.deinit(allocator);

    for (0..box_list.items.len) |i| {
        for (i + 1..box_list.items.len) |j| {
            const p1 = box_list.items[i];
            const p2 = box_list.items[j];
            const distance = p1.distanceSquared(p2);

            const edge: Edge = .{ .i1 = i, .i2 = j, .dist_sq = distance };
            try edges.append(allocator, edge);
        }
    }

    std.mem.sort(Edge, edges.items, {}, Edge.compare);

    var dsu = try Dsu.init(allocator, box_list.items.len);

    var connections: u32 = 0;
    for (edges.items) |edge| {
        if (connections >= pairs) break;
        _ = dsu.unite(edge.i1, edge.i2);
        connections += 1;
    }

    var circuit_sizes = std.AutoHashMap(usize, u32).init(allocator);
    defer circuit_sizes.deinit();

    for (0..box_list.items.len) |i| {
        const root = dsu.find(i);
        const entry = try circuit_sizes.getOrPut(root);
        if (!entry.found_existing) {
            entry.value_ptr.* = 0;
        }
        entry.value_ptr.* += 1;
    }

    var sizes: std.ArrayList(u32) = .empty;
    defer sizes.deinit(allocator);

    var iter = circuit_sizes.valueIterator();
    while (iter.next()) |size| {
        try sizes.append(allocator, size.*);
    }

    std.mem.sort(u32, sizes.items, {}, std.sort.desc(u32));

    const result = sizes.items[0] * sizes.items[1] * sizes.items[2];
    return result;
}

fn part2(allocator: Allocator, file: std.fs.File) !u64 {
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var box_list: std.ArrayList(Point) = .empty;
    defer box_list.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |row| {
        const line = std.mem.trimEnd(u8, row, "\r\n\t ");
        var iter = std.mem.splitAny(u8, line, ",");
        const x_string = iter.next() orelse return FileParsingError.NotANumber;
        const x = try std.fmt.parseInt(u32, x_string, 10);
        const y_string = iter.next() orelse return FileParsingError.NotANumber;
        const y = try std.fmt.parseInt(u32, y_string, 10);
        const z_string = iter.next() orelse return FileParsingError.NotANumber;
        const z = try std.fmt.parseInt(u32, z_string, 10);

        const point: Point = .{ .x = x, .y = y, .z = z };
        try box_list.append(allocator, point);
    }

    var edges: std.ArrayList(Edge) = .empty;
    defer edges.deinit(allocator);

    for (0..box_list.items.len) |i| {
        for (i + 1..box_list.items.len) |j| {
            const p1 = box_list.items[i];
            const p2 = box_list.items[j];
            const distance = p1.distanceSquared(p2);

            const edge: Edge = .{ .i1 = i, .i2 = j, .dist_sq = distance };
            try edges.append(allocator, edge);
        }
    }

    std.mem.sort(Edge, edges.items, {}, Edge.compare);

    var dsu = try Dsu.init(allocator, box_list.items.len);

    var num_circuits = box_list.items.len;
    var last_edge: ?Edge = null;

    for (edges.items) |edge| {
        if (dsu.unite(edge.i1, edge.i2)) {
            num_circuits -= 1;
            last_edge = edge;

            if (num_circuits == 1) break;
        }
    }

    const final_edge = last_edge.?;
    const p1 = box_list.items[final_edge.i1];
    const p2 = box_list.items[final_edge.i2];

    const result = p1.x * p2.x;
    return result;
}

test "part_1" {
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print(" \n", .{});
    const solution = try part1(allocator, file, 10);

    try expect(solution == 40);
}

test "part_2" {
    const file = try std.fs.cwd().openFile("input/test.txt", .{ .mode = .read_only });
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print(" \n", .{});
    const solution = try part2(allocator, file);

    try expect(solution == 25272);
}
