const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "wordcount",
        .root_source_file = b.path("wordcount.zig"),
        .target = b.host,
        .optimize = optimize,
    });

    const exe_threaded = b.addExecutable(.{
        .name = "wordcount_threaded",
        .root_source_file = b.path("wordcount_threaded.zig"),
        .target = b.host,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    b.installArtifact(exe_threaded);
}
