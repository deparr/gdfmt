const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const Parse = @import("Parse.zig");
const Allocator = std.mem.Allocator;

const Ast = @This();

/// externally owned reference to the source
source: [:0]const u8,

tokens: TokenList.Slice,
nodes: NodeList.Slice,
extra_data: []u32,
errors: []const Error,

pub const TokenIndex = u32;
pub const ByteOffset = u32;

pub const TokenList = std.MultiArrayList(struct {
    tag: Token.Tag,
    start: ByteOffset,
});
pub const NodeList = std.MultiArrayList(Node);

pub fn parse(gpa: Allocator, source: [:0]const u8) Allocator.Error!Ast {
    var tokens: Ast.TokenList = .empty;
    defer tokens.deinit(gpa); // actually a no-op since we call toOwnedSlice in return
    // todo zig has an 8:1 avg token ratio
    // gdscript should have much more due to indent tokens
    // but also less due to fewer braces/parens ??
    const estimated_token_count = source.len / 5;
    try tokens.ensureTotalCapacity(gpa, estimated_token_count);

    var lexer = try Lexer.init(source, gpa);
    while (true) {
        const token = lexer.next();
        try tokens.append(gpa, .{
            .tag = token.tag,
            .start = token.loc.start,
        });
        if (token.tag == .eof) break;
    }

    var parser: Parse = .{
        .source = source,
        .gpa = gpa,
        .tokens = tokens.slice(),
        .tok_i = 0,
        .errors = .empty,
        .nodes = .empty,
        .extra_data = .empty,
        .scratch = .empty,
    };
    // actually a no-op since we call toOwnedSlice in return
    defer parser.errors.deinit(gpa);
    defer parser.nodes.deinit(gpa);
    defer parser.extra_data.deinit(gpa);
    defer parser.scratch.deinit(gpa);

    // todo zig has avg 2:1 token to node ratio
    // for now assume the same for gdscript
    // ensure at least one for root node
    const estimated_node_count = (tokens.len + 2) / 2;
    try parser.nodes.ensureTotalCapacity(gpa, estimated_node_count);

    try parser.parseRoot();

    const extra_data = try parser.extra_data.toOwnedSlice(gpa);
    errdefer gpa.free(extra_data);
    const errors = try parser.errors.toOwnedSlice(gpa);
    errdefer gpa.free(errors); // technically unnecessary

    return Ast{
        .source = source,
        .tokens = tokens.toOwnedSlice(),
        .nodes = parser.nodes.toOwnedSlice(),
        .extra_data = extra_data,
        .errors = errors,
    };
}

pub const Node = struct {
    tag: Tag,
    main_token: TokenIndex,

    pub const Tag = enum {
        annotation,
        array,
        assert,
        assignment,
        await,
        binary_op,
        @"break",
        breakpoint,
        call,
        cast,
        class,
        constant,
        @"continue",
        dictionary,
        @"enum",
        expression, // not sure if I need this
        @"for",
        function,
        get_node,
        identifier,
        @"if",
        lambda,
        literal,
        match,
        match_branch,
        parameter,
        pass,
        pattern,
        preload,
        @"return",
        self,
        signal,
        subscript,
        suite,
        ternary_op,
        type,
        type_test,
        unary_op,
        variable,
        @"while",
    };

    pub const Index = enum(u32) {
        root = 0,
        invalid = std.math.maxInt(u32),
        _,
    };
};

pub const Error = struct {
    tag: Tag,
    token: TokenIndex,
    extra: union {
        none: void,
        exptected_tag: Token.Tag,
    } = .{ .none = {} },

    pub const Tag = enum {};
};
