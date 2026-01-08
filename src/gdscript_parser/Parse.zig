//! This struct represents an in progress parsing, will convert to Ast upon
//! completion.
//! modeled after the zig parser

gpa: Allocator,
source: []const u8,
tokens: Ast.TokenList.Slice,
tok_i: TokenIndex,
errors: std.ArrayList(AstError),
nodes: Ast.NodeList,
extra_data: std.ArrayList(u32),
scratch: std.ArrayList(Node.Index),

pub const Error = error{ParseError} || Allocator.Error;

fn tokenTag(self: *const Parse, token_index: TokenIndex) Token.Tag {
    return self.tokens.items(.tag)[token_index];
}

fn tokenStart(p: *const Parse, token_index: TokenIndex) Ast.ByteOffset {
    return p.tokens.items(.start)[token_index];
}

fn tokenSlice(self: *const Parse, token_index: TokenIndex) []const u8 {
    const start = self.tokenStart(token_index);
    const end = self.tokens.items(.end)[token_index];
    return self.source[start..end];
}

fn nodeTag(p: *const Parse, node: Node.Index) Node.Tag {
    return p.nodes.items(.tag)[@intFromEnum(node)];
}

fn nodeMainToken(p: *const Parse, node: Node.Index) TokenIndex {
    return p.nodes.items(.main_token)[@intFromEnum(node)];
}

fn nodeData(p: *const Parse, node: Node.Index) Node.Data {
    return p.nodes.items(.data)[@intFromEnum(node)];
}

pub fn parseRoot(self: *Parse) !void {
    self.nodes.appendAssumeCapacity(.{
        .tag = .root,
        .main_token = self.tok_i,
        .data = undefined,
    });

    // var can_have_classname_or_extends = true;
    while (self.tokenTag(self.tok_i) != .eof) {
        const tag = self.tokenTag(self.tok_i);
        std.debug.print("{t} | ", .{ tag });
        switch (tag) {
            .annotation => {
                std.debug.print("hit annotation at idx {d}\n", .{ self.tok_i });
                _ = try self.parseAnnotation();
            },
            else => break,
        }
    }
    // const root_members = try p.parseContainerMembers();
    // const root_decls = try root_members.toSpan(p);
    // if (p.tokenTag(p.tok_i) != .eof) {
    //     try p.warnExpected(.eof);
    // }
    // p.nodes.items(.data)[0] = .{ .extra_range = root_decls };
}

fn parseAnnotation(self: *Parse) !Node.Index {
    assert(self.tokenTag(self.tok_i) == .annotation);

    const kind = self.tokenSlice(self.tok_i);
    std.debug.print("anno kind {s}\n" , .{ kind });
    assert(kind[0] == '@');
    if (validAnnotations.get(kind[1..])) |_| {
        return try self.addNode(.{
            .tag = .annotation,
            .main_token = self.nextToken(),
            .data = undefined,
        });
    } else {
        @panic("invalid annotation kind");
    }
}

fn addNode(p: *Parse, elem: Ast.Node) Allocator.Error!Node.Index {
    const result: Node.Index = @enumFromInt(p.nodes.len);
    try p.nodes.append(p.gpa, elem);
    return result;
}

const AnnotationInfo = struct {
    target: Target = .none,

    const Target = enum {
        none,
        script,
        class,
        variable,
        constant,
        signal,
        function,
        statement,
        standalone,
        class_level,
    };
};

fn nextToken(self: *Parse) TokenIndex {
    const result = self.tok_i;
    self.tok_i += 1;
    return result;
}

const validAnnotations = std.StaticStringMap(AnnotationInfo.Target).initComptime(.{
    .{ "export", .variable },
    .{ "icon", .script },
    .{ "tool", .script },
    .{ "abstract", .script },
    .{ "static_unload", .script },
});

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
const Token = @import("lexer.zig").Token;
