// SPDX-License-Identifier: MIT
// Copyright (c) 2024 Michael Ortmann

const std = @import("std");

const Entry = struct { key_ptr: []const u8, value: u32 };

fn cmp(context: void, a: Entry, b: Entry) bool {
    _ = context;

    if (a.value == b.value)
        // faster than return std.mem.lessThan(u8, a.key_ptr, b.key_ptr);
        return std.mem.order(u8, a.key_ptr, b.key_ptr).compare(std.math.CompareOperator.lt);

    if (a.value < b.value)
        return false;

    return true;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    // faster than bufferedReader
    const buf = try std.io.getStdIn().readToEndAllocOptions(allocator, 16 * 1024 * 1024 * 1024, 6 * 1024 * 1024 * 1024, @alignOf(u8), null);
    var tokens = std.mem.tokenizeAny(u8, buf, " \t\n");
    var map = std.StringHashMap(u32).init(allocator);
    // tune StringHashMap capacity to avoid resize / rehash
    try map.ensureTotalCapacity(@intCast(tokens.buffer.len / 231));

    while (tokens.next()) |word| {
        if (map.getPtr(word)) |ptr| {
            ptr.* += 1;
        } else try map.put(word, 1);
    }

    var it = map.iterator();
    const a = try allocator.alloc(Entry, map.count());
    var i: u32 = 0;

    while (it.next()) |kv| {
        a[i] = Entry{ .key_ptr = kv.key_ptr.*, .value = (kv.value_ptr.* << 7) | ((kv.key_ptr.*[0] >> 1) ^ 0x7f) };
        i += 1;
    }

    std.mem.sortUnstable(Entry, a, {}, cmp);
    var buffered_writer = std.io.bufferedWriter(std.io.getStdOut().writer());

    for (a) |e| {
        try buffered_writer.writer().print("{s}\t{any}\n", .{ e.key_ptr, e.value >> 7 });
    }

    try buffered_writer.flush();
}
