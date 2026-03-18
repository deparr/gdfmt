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

    const prefix = try self.parsePrefixExpr();
    self.nodes.items(.data)[0] = .{ .node = prefix.? };

    // var state: enum {
    //     /// at beginning or still parsing script-level annotations
    //     script,
    //     /// have not encountered fields / decls yet; allowed to have class_name
    //     /// or extends
    //     class_head,
    //     /// parsing class fields and decls
    //     class_body,
    // } = .script;

    // parse leading anootations and comments
    // parse class_name / extends and comments
    //
    // check for @abstract annotations, godot handles them in the parser
    // parse a class body, the same as for a child class
    // expect eof
    //
    // var can_have_classname_or_extends = true;
    // can_have_classname_or_extends = false;
    // while (self.tokenTag(self.tok_i) != .eof) {
    //     const token = self.tok_i;
    //     const tag = self.tokenTag(self.tok_i);
    //     switch (tag) {
    //         .annotation => {
    //             const anno_idx = try self.parseAnnotation(AnnotationTarget.group(&.{.script, .standalone}) | AnnotationTarget.class_level);
    //             const anno_tok = self.nodeMainToken(anno_idx);
    //             const anno_name = self.tokenSlice(anno_tok);
    //             const anno_target = validAnnotations.get(anno_name) orelse {
    //                 try self.warn(.{
    //                     .tag = .invalid_annotation,
    //                     .token = anno_tok,
    //                 });
    //                 return Error.ParseError;
    //             };
    //
    //             switch (anno_target) {
    //                 .class => {
    //                     // TODO at this point we don't know if anno applies to
    //                     // root or inner class, modules/gdscript/gdscript_parser.cpp:720
    //                 },
    //                 .script => {
    //                 },
    //                 .standalone => {
    //                 },
    //                 else => {},
    //             }
    //         },
    //         .literal => {
    //             const slice = self.tokenSlice(self.tok_i);
    //             if (slice[0] != '\'' and slice[0] != '"') {
    //                 try self.warn(.{ .tag = .unexpected_tag_class_body, .token = self.tok_i });
    //                 // FIXME: this doesn't *have* to skip over class head
    //                 state = .class_body;
    //             }
    //
    //             const next_token = self.nextToken();
    //             // FIXME: This should be recoverable / ignoreable by the
    //             // formatter
    //             if (self.tokenTag(next_token) != .newline) {
    //                 try self.warn(.{
    //                     .token = token,
    //                     .tag = .missing_newline_after_string_comment,
    //                 });
    //             }
    //             _ = try self.addNode(.{
    //                 .tag = .comment,
    //                 .main_token = token,
    //                 .data = .{ .none = {} },
    //             });
    //         },
    //         .comment => {
    //             // try self.eatCommentBlock();
    //             _ = try self.addNode(.{
    //                 .tag = .comment,
    //                 .main_token = token,
    //                 .data = .{ .none = {} },
    //             });
    //         },
    //         .newline => std.debug.print("hit .newline in rootclass\n", .{}),
    //         else => break,
    //     }
    // }
    //
    // // indentation ???
    // if (self.tokenTag(self.tok_i) != .eof) {
    //     try self.warnExpected(.eof);
    // }
    //
    // const root_members = try p.parseContainerMembers();
    // const root_decls = try root_members.toSpan(p);
    // p.nodes.items(.data)[0] = .{ .extra_range = root_decls };
}

// fn parseExprPrecendence(self: *Parse) !Node.Index {
// }
//
// fn parseExpr(self: *Parse, precedence: i32) !Node.Index {
// }

fn parseAnnotation(self: *Parse, valid_targets: u32) !Node.Index {
    if (valid_targets == 0) {
        return error.ParseError;
    }
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

// zig does this not sure if gdscript needs it
const Assoc = enum {
    left,
    none,
};

const OperInfo = struct {
    prec: i8,
    tag: Node.Tag,
    assoc: Assoc = .left,
};

// binary operater precendence table, higher precendence number binds tighter
const binop_prec_table = std.enums.directEnumArray(Token.Tag, OperInfo, 0, .{
    .as = .{ .prec = 10, .tag = .cast },

    .@"or" = .{ .prec = 20, .tag = .bool_or },
    .@"and" = .{ .prec = 25, .tag = .bool_and },

    .in = .{ .prec = 30, .tag = .in },
    .not = .{ .prec = 30, .tag = .not_in },

    .equal_equal = .{ .prec = 40, .tag = .equal_equal, .assoc = Assoc.none },
    .bang_equal = .{ .prec = 40, .tag = .bang_equal, .assoc = Assoc.none },
    .less = .{ .prec = 40, .tag = .less_than, .assoc = Assoc.none },
    .greater = .{ .prec = 40, .tag = .greater_than, .assoc = Assoc.none },
    .less_equal = .{ .prec = 40, .tag = .less_or_equal, .assoc = Assoc.none },
    .greater_equal = .{ .prec = 40, .tag = .greater_or_equal, .assoc = Assoc.none },

    .ampersand = .{ .prec = 50, .tag = .bit_and },
    .caret = .{ .prec = 50, .tag = .bit_xor },
    .pipe = .{ .prec = 50, .tag = .bit_or },

    .less_less = .{ .prec = 60, .tag = .shl },
    .greater_greater = .{ .prec = 60, .tag = .shr },

    .plus = .{ .prec = 70, .tag = .add },
    .minus = .{ .prec = 70, .tag = .sub },

    .star = .{ .prec = 80, .tag = .mul },
    .slash = .{ .prec = 80, .tag = .div },
    .percent = .{ .prec = 80, .tag = .mod },

    .star_star = .{ .prec = 85, .tag = .power },

    .is = .{ .prec = 90, .tag = .type_test },

    // prec call // suffix expr
    // prec_attribute // field access // suffix expr
    // prec_subscript // array access // suffix expr
    // prec_primary  // unused
});

fn parseExpr(self: *Parse) Error!?Node.Index {
    return self.parseExprPrecedence(0);
}

fn parseExprPrecedence(self: *Parse, min_prec: i32) Error!?Node.Index {
    assert(min_prec >= 0);
    const node = try self.parsePrefixExpr() orelse return null;
    return node;
}

fn parsePrefixExpr(self: *Parse) Error!?Node.Index {
    const tag: Node.Tag = switch (self.tokenTag(self.tok_i)) {
        .not, .bang => .bool_not,
        .tilde => .bit_not,
        .minus => .negation,
        .plus => .positation,
        .dollar, .percent => .get_node,
        // await ???
        // yield ??
        // paren ??
        // dict ??
        // array ??
        else => return self.parsePrimaryExpr(),
    };
    return try self.addNode(.{
        .tag = tag,
        .main_token = self.nextToken(),
        .data = .{ .node = try self.expectPrefixExpr() },
    });
}

fn expectPrefixExpr(self: *Parse) Error!Node.Index {
    return try self.parsePrefixExpr() orelse return self.fail(.expected_prefix_expr);
}

fn parsePrimaryExpr(self: *Parse) Error!?Node.Index {
    switch (self.tokenTag(self.tok_i)) {
        .identifier,
        .self,
        // .super, // not sure about this
        => return try self.addNode(.{
            .tag = .identifier,
            .main_token = self.nextToken(),
        }),
        .literal => {
            const tok = self.tokenSlice(self.tok_i);
            if (tok[0] == '"' or tok[0] == '\'') {
                // TODO minor hack, though it seems all prefix operate on numbers
                return self.fail(.invalid_prefix_operand);
            }
            return try self.addNode(.{
                .tag = .number_literal,
                .main_token = self.nextToken(),
            });
        },
        else => @panic("faileur"),
    }

    return null;
}

fn addNode(p: *Parse, elem: Ast.Node) Allocator.Error!Node.Index {
    const result: Node.Index = @enumFromInt(p.nodes.len);
    try p.nodes.append(p.gpa, elem);
    return result;
}

fn nextToken(self: *Parse) TokenIndex {
    const result = self.tok_i;
    self.tok_i += 1;
    return result;
}

fn warn(self: *Parse, msg: Ast.Error) error{OutOfMemory}!void {
    try self.errors.append(self.gpa, msg);
}

fn warnExpected(self: *Parse, expected_tag: Token.Tag) error{OutOfMemory}!void {
    @branchHint(.cold);
    try self.warn(.{
        .tag = .expected_token,
        .token = self.tok_i,
        .extra = .{ .expected_tag = expected_tag },
    });
}

fn fail(p: *Parse, tag: Ast.Error.Tag) error{ ParseError, OutOfMemory } {
    @branchHint(.cold);
    return p.failMsg(.{ .tag = tag, .token = p.tok_i });
}

fn failExpected(p: *Parse, expected_token: Token.Tag) error{ ParseError, OutOfMemory } {
    @branchHint(.cold);
    return p.failMsg(.{
        .tag = .expected_token,
        .token = p.tok_i,
        .extra = .{ .expected_tag = expected_token },
    });
}

fn failMsg(p: *Parse, msg: Ast.Error) error{ ParseError, OutOfMemory } {
    @branchHint(.cold);
    try p.warn(msg);
    return error.ParseError;
}

const Parse = @This();
const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Ast = @import("Ast.zig");
const validAnnotations = Ast.validAnnotations;
const AnnotationTarget = Ast.AnnotationTarget;
const Node = Ast.Node;
const AstError = Ast.Error;
const TokenIndex = Ast.TokenIndex;
const OptionalTokenIndex = Ast.OptionalTokenIndex;
const ExtraIndex = Ast.ExtraIndex;
const Token = @import("lexer.zig").Token;
