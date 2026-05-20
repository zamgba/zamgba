const std = @import("std");

// Pub is a must. User projects use it to reference to zamgba's build
// script.
pub const arm = @import("./src/build/arm.zig");

const FirstDemoRoot = "demo/first.zig";
const LibName = "zamgba";

// ====================================================================
// The target definition and gba.ld are initialized from two projects:
//
// https://github.com/wendigojaeger/ZigGBA
// https://github.com/ryankurte/rust-gba
//
// It has been modified to fit the changes in zamgba.
//
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Hardware Abstraction Layer module
    const hal_module = b.addModule("zamgba-hal", .{
        .root_source_file = b.path("src/hal/gba.zig"),
    });

    // 2D Drawing Algorithm module (platform-agnostic)
    const gfx2d_module = b.addModule("zamgba-gfx2d", .{
        .root_source_file = b.path("src/gfx2d/gfx2d.zig"),
    });

    // Define a module that can be referenced by client project.
    // It's also the interface for client project to consume zamgba.
    //
    // Note: the module name can change fast as zamgba is in an
    // early stage. To keep a stable @import("...") names in
    // client project, consider defining alias in root_module.addImport().
    //
    // see https://github.com/fuzhouch/consumezamgba for how to use it.
    const m = b.addModule(LibName, .{ .root_source_file = b.path("src/zamgba.zig") });

    // Root module exposes submodules to clients referencing "zamgba"
    m.addImport("zamgba-hal", hal_module);
    m.addImport("zamgba-gfx2d", gfx2d_module);

    // Step 2: Create demo executables
    var first = arm.addROM(b, .{
        .optimize = optimize,
        .name = "first",
        .root_source_file = b.path(FirstDemoRoot),
    });

    first.root_module.addImport(LibName, m);

    // Unit tests are compiled and executed in host machine. Some
    // GBA-specific code, e.g., manipulation of registers, will not be
    // covered by unit tests.
    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/unittest.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });

    // Add submodules to unit tests so we can test them on desktop
    lib_unit_tests.root_module.addImport("zamgba-hal", hal_module);
    lib_unit_tests.root_module.addImport("zamgba-gfx2d", gfx2d_module);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
