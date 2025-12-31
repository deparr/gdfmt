const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Token = @import("tokenizer.zig").Token;
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

    var tokenizer = Tokenizer.init(source);
    var tokens: std.ArrayList(Token) = .empty;
    defer tokens.deinit(gpa);
    while (!tokenizer.isAtEnd()) {
        const token = tokenizer.next();
        try tokens.append(gpa, token);
    }

    for (tokens.items) |token| {
        const symbol = switch (token.tag) {
            .identifier, .annotation => source[token.loc.start..token.loc.end],
            else => "",
        };
        if (token.tag == .newline) {
            std.debug.print("\n", .{});
            continue;
        }
        std.debug.print("{s}, {d}, {s}\n", .{
            @tagName(token.tag),
            token.loc.start,
            symbol,
        });
    }
}
