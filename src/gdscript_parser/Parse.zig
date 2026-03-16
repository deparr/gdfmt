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

fn tokenStart(self: *const Parse, token_index: TokenIndex) Ast.ByteOffset {
    return self.tokens.items(.start)[token_index];
}

fn tokenSlice(self: *const Parse, token_index: TokenIndex) []const u8 {
    const tag = self.tokenTag(token_index);
    if (tag.lexeme()) |lexeme| {
        return lexeme;
    }
    const start = self.tokenStart(token_index);
    const end = self.tokens.items(.end)[token_index];
    return self.source[start..end];
}

fn nodeTag(self: *const Parse, node: Node.Index) Node.Tag {
    return self.nodes.items(.tag)[@intFromEnum(node)];
}

fn nodeMainToken(self: *const Parse, node: Node.Index) TokenIndex {
    return self.nodes.items(.main_token)[@intFromEnum(node)];
}

fn nodeData(self: *const Parse, node: Node.Index) Node.Data {
    return self.nodes.items(.data)[@intFromEnum(node)];
}

pub fn parseRoot(self: *Parse) !void {
    self.nodes.appendAssumeCapacity(.{
        .tag = .root,
        .main_token = self.tok_i,
        .data = undefined,
    });

    var state: enum {
        /// at beginning or still parsing script-level annotations
        script,
        /// have not encountered fields / decls yet; allowed to have class_name
        /// or extends
        class_head,
        /// parsing class fields and decls
        class_body,
    } = .script;

    // parse leading anootations and comments
    // parse class_name / extends and comments
    //
    // check for @abstract annotations, godot handles them in the parser
    // parse a class body, the same as for a child class
    // expect eof
    //
    // var can_have_classname_or_extends = true;
    var token = self.nextToken();
    // FIXME: not sure about this
    while (self.tokenTag(token) != .eof) : (token = self.nextToken()) {
        const tag = self.tokenTag(self.tok_i);
        std.debug.print("{t} | ", .{tag});
        switch (tag) {
            .annotation => {
                _ = try self.parseAnnotation();
            },
            .literal => {
                const slice = self.tokenSlice(self.tok_i);
                if (slice[0] != '\'' and slice[0] != '"') {
                    try self.warn(.{ .tag = .unexpected_tag_class_body, .token = self.tok_i });
                    // FIXME: this doesn't *have* to skip over class head
                    state = .class_body;
                }

                const next_token = self.nextToken();
                // FIXME: This should be recoverable / ignoreable by the
                // formatter
                if (self.tokenTag(next_token) != .newline) {
                    try self.warn(.{
                        .token = token,
                        .tag = .missing_newline_after_string_comment,
                    });
                }
                try self.addNode(.{
                    .tag = .comment,
                    .main_token = token,
                    .data = .{ .none = {} },
                });
            },
            .comment => {
                // try self.eatCommentBlock();
                try self.addNode(.{
                    .tag = .comment,
                    .main_token = token,
                    .data = .{ .none = {} },
                });
            },
            .newline => std.debug.print("hit .newline in rootclass\n", .{}),
            else => break,
        }
    }

    // indentation ???
    if (self.tokenTag(self.tok_i) != .eof) {
        try self.warnExpected(.eof);
    }

    // const root_members = try p.parseContainerMembers();
    // const root_decls = try root_members.toSpan(p);
    // p.nodes.items(.data)[0] = .{ .extra_range = root_decls };
}

// fn parseExprPrecendence(self: *Parse) !Node.Index {
// }
//
// fn parseExpr(self: *Parse, precedence: i32) !Node.Index {
// }

fn parseAnnotation(self: *Parse) !Node.Index {
    assert(self.tokenTag(self.tok_i) == .annotation);

    const kind = self.tokenSlice(self.tok_i);
    std.debug.print("anno kind {s}\n", .{kind});
    // skip leading '@'
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

fn warn(self: *Parse, msg: Ast.Error) error{OutOfMemory}!void {
    try self.errors.append(self.gpa, msg);
}

fn warnExpected(self: *Parse, expected_tag: Token.Tag) error{OutOfMemory}!void {
    // zig branchHint(.cold) 's the warn paths
    try self.warn(.{
        .tag = .expected_token,
        .token = self.tok_i,
        .extra = .{ .expected_tag = expected_tag },
    });
}

const validAnnotations = std.StaticStringMap(AnnotationInfo.Target).initComptime(.{
    // script
    .{ "icon", .script },
    .{ "tool", .script },
    .{ "static_unload", .script },
    .{ "abstract", .script },
    // export
    .{ "export", .variable },
    .{ "export_enum", .variable },
    .{ "export_file", .variable },

    .{ "onready", .variable },
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
