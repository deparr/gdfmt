const std = @import("std");
const gdscript = @import("gdscript.zig");
const Lexer = gdscript.Lexer;
const Token = gdscript.Token;
const zd = @import("zd");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const source = try std.fs.cwd().readFileAllocOptions(gpa, args[1], 1 << 20, null, .@"1", 0);
    defer gpa.free(source);
    std.debug.print("{s}{{ .len = {d} }}\n", .{ source, source.len });

    var lexer = try Lexer.init(source, gpa);
    while (true) {
        const token = lexer.next();
        std.debug.print(".{t} at[{d}:", .{
            token.tag,
            token.loc.start,
        });
        const symbol = if (token.tag.lexeme()) |lexeme| lexeme else source[token.loc.start..token.loc.end];
        std.debug.print("{d}] '{s}'\n", .{
            token.loc.end,
            if (token.tag != .newline) symbol else "",
        });

        if (token.tag == .eof) break;
    }
    for (lexer.errors.items) |err| {
        std.debug.print("{t} @ {any}\n", .{ err.kind, err.loc });
    }
    lexer.deinit();
}
