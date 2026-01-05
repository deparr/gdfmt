const std = @import("std");
const tlib = @import("tokenizer.zig");
const Tokenizer = tlib.Tokenizer;
const Token = tlib.Token;
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

    var tokenizer = try Tokenizer.init(source, gpa);
    while (!tokenizer.sent_eof) {
        const token = tokenizer.next();
        const symbol = switch (token.tag) {
            .identifier, .annotation, .literal => source[token.loc.start..token.loc.end],
            else => "",
        };
        std.debug.print(".{s}:{d}'{s}' ", .{
            @tagName(token.tag),
            token.loc.start,
            symbol,
        });
        if (token.tag == .newline) {
            std.debug.print("\n", .{});
        }
    }
    tokenizer.deinit();
}

test {
    _ = tlib;
}
