const std = @import("std");
const gdscript = @import("gdscript.zig");
const zd = @import("zd");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const source = try std.fs.cwd().readFileAllocOptions(gpa, args[1], 1 << 20, null, .@"1", 0);
    defer gpa.free(source);

    const ast = try gdscript.Ast.parse(gpa, source);
    _ = ast;
}
