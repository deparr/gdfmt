const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Token = @import("tokenizer.zig").Token;

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const gpa = debug_allocator.allocator();

    const source = try std.fs.cwd().readFileAllocOptions(gpa, "./res/example.gd", 1 << 20, null, 1, 0);
    std.debug.print("{s} {{ .len = {d} }}\n", .{ source, source.len });

    var tokenizer: Tokenizer = .{ .source = source };
    var tokens: std.ArrayListUnmanaged(struct {
        tag: Token.Tag,
        start: u32,
    }) = .empty;
    defer tokens.deinit(gpa);
    while (true) {
        const token = tokenizer.next();
        try tokens.append(gpa, .{
            .tag = token.tag,
            .start = @intCast(token.loc.start),
        });
        if (token.tag == .eof) break;
    }

    for (tokens.items) |token| {
        const symbol = switch (token.tag) {
            .identifier, .annotation => blk: {
                var t: Tokenizer = .{
                    .source = source,
                    .index = token.start,
                };
                const tk = t.next();
                break :blk source[tk.loc.start..tk.loc.end];
            },
            else => token.tag.symbol(),
        };
        if (token.tag == .newline) {
            std.debug.print("\n", .{});
            continue;
        }
        std.debug.print("{{ .{s}, {d}, {s} }}, ", .{
            @tagName(token.tag),
            token.start,
            symbol,
        });
    }
}
