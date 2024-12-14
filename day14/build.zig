const std = @import("std");

const CFlags = &.{};

pub fn build(b: *std.Build) void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const exe = b.addExecutable(.{
    .name = "day14",
    .root_source_file = b.path("fenster_solution.zig"),
    .target = target,
    .optimize = optimize,
  });

  exe.addIncludePath(b.path("vendor"));
  exe.addCSourceFile(.{ .file = b.path("vendor/fenster.c") });

  switch (target.result.os.tag) {
    .macos => {
      exe.linkFramework("Cocoa");
    },
    .windows => {
      exe.linkSystemLibrary("gdi32");
    },
    else => {
      exe.linkSystemLibrary("X11");
    },
  }

  exe.linkSystemLibrary("c");

  b.installArtifact(exe);

  const run_cmd = b.addRunArtifact(exe);

  run_cmd.step.dependOn(b.getInstallStep());

  if (b.args) |args| {
    run_cmd.addArgs(args);
  }

  const run_step = b.step("run", "Run the app");
  run_step.dependOn(&run_cmd.step);
}
