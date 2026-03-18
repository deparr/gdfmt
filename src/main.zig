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
    std.debug.print("{s}\n", .{source});

    var ast = try gdscript.Ast.parse(gpa, source);
    if (ast.errors.len > 0) {
        std.debug.print("Errors:\n", .{});
        for (ast.errors) |err| {
            std.debug.print("{t} @: {t}\n", .{err.tag, ast.tokens.items(.tag)[err.token]});
        }
    } else {
        for (0..ast.nodes.len) |i| {
            const node = ast.nodes.get(i);
            const data = switch(node.data) {
                .node => |n| n,
                .none => null,
            };
            if (data) |n| {
                const other = ast.nodes.get(@intFromEnum(n));
                std.debug.print("({t} {t}) ", .{ node.tag, other.tag });
            } else {
                std.debug.print("{t} ", .{ node.tag, });
            }
        }
    }
    defer ast.deinit(gpa);
}
