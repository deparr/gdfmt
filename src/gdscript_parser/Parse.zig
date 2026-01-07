//! This struct represents an in progress parsing, will convert to Ast upon
//! completion.
//! modeled after the zig parser
const Parse = @This();
const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Ast = @import("Ast.zig");
const Node = Ast.Node;
const AstError = Ast.Error;
const TokenIndex = Ast.TokenIndex;
const OptionalTokenIndex = Ast.OptionalTokenIndex;
const ExtraIndex = Ast.ExtraIndex;
const Token = std.zig.Token;

gpa: Allocator,
source: []const u8,
tokens: Ast.TokenList.Slice,
tok_i: TokenIndex,
errors: std.ArrayList(AstError),
nodes: Ast.NodeList,
extra_data: std.ArrayList(u32),
scratch: std.ArrayList(Node.Index),

pub const Error = error{ParseError} || Allocator.Error;

pub fn parseRoot(self: *Parse) !void {
    _ = self;
}
