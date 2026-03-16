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
    // for (ast.tokens.items(.tag)) |tag| {
    //     if (tag == .newline or tag == .eof) std.debug.print("\n", .{})
    //     else std.debug.print("{t} ", .{ tag });
    // }

    for (ast.nodes.items(.tag), ast.nodes.items(.data)) |tag, data| {
        std.debug.print("{t} ", .{tag});
        switch (data) {
            .annotation => |anno| {
                const arg_node = ast.nodes.get(@intFromEnum(anno.arguments));
                const tok = ast.tokens.get(arg_node.main_token);
                std.debug.print("{s} {d}\n", .{ source[tok.start..tok.end], anno.arguments });
            },
            else => {},
        }
    }
    defer ast.deinit(gpa);
}
