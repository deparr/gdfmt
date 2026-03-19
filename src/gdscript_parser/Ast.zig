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


// TODO includes the token end because I need to be able to get token slices
// during parsing (eg annotations). I would just retokenize single tokens on
// demand but lexing needs an allocator for indentation.
//
// This is definitely solvable, but im not sure I want to do it right now
pub const TokenList = std.MultiArrayList(struct {
    tag: Token.Tag,
    start: ByteOffset,
    end: ByteOffset,
});
pub const NodeList = std.MultiArrayList(Node);

pub fn deinit(tree: *Ast, gpa: Allocator) void {
    tree.tokens.deinit(gpa);
    tree.nodes.deinit(gpa);
    gpa.free(tree.extra_data);
    gpa.free(tree.errors);
    tree.* = undefined;
}

pub fn parse(gpa: Allocator, source: [:0]const u8) Allocator.Error!Ast {
    var tokens: Ast.TokenList = .empty;
    defer tokens.deinit(gpa); // this is a no-op when returning without errors
    // todo zig has an 8:1 avg token ratio
    // gdscript should have much more due to indent tokens
    // but also less due to fewer braces/parens ??
    const estimated_token_count = source.len / 5;
    try tokens.ensureTotalCapacity(gpa, estimated_token_count);

    var lexer = try Lexer.init(source, gpa);
    defer lexer.deinit();
    while (true) {
        const token = lexer.next();
        try tokens.append(gpa, .{
            .tag = token.tag,
            .start = token.loc.start,
            .end = token.loc.end,
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
    defer parser.errors.deinit(gpa); // this is a no-op if we return without errors
    defer parser.nodes.deinit(gpa);
    defer parser.extra_data.deinit(gpa);
    defer parser.scratch.deinit(gpa);

    // todo zig has avg 2:1 token to node ratio
    // for now assume the same for gdscript
    // ensure at least one for root node
    const estimated_node_count = (tokens.len + 2) / 2;
    try parser.nodes.ensureTotalCapacity(gpa, estimated_node_count);

    parser.parseRoot() catch |err| switch(err) {
        error.ParseError => {},
        error.OutOfMemory => return error.OutOfMemory,
    };

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
    data: Data,

    pub const Tag = enum {
        root,
        annotation,
        array,
        assert,
        assignment,
        await,
        equal_equal,
        bang_equal,
        less_than,
        greater_than,
        less_or_equal,
        greater_or_equal,

        assign_mul,
        assign_div,
        assign_mod,
        assign_add,
        assign_sub,
        assign_shl,
        assign_shr,
        assign_bit_and,
        assign_bit_xor,
        assign_bit_or,
        assign,

        mul,
        div,
        mod,
        add,
        sub,
        shl,
        shr,
        bit_and,
        bit_xor,
        bit_or,
        bit_not,
        bool_and,
        bool_or,
        bool_not,
        power,

        not_in,
        in,
        negation,
        numeric_identity, // todo ??????

        string_literal,
        number_literal,

        grouped_expression,

        @"break",
        breakpoint,
        call,
        cast,
        class,
        constant,
        @"continue",
        dictionary,
        @"enum",
        @"for",
        function,
        get_node,
        identifier,
        @"if",
        lambda,
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

        /// not in godot's parser
        comment,
        doc_comment,
    };

    pub fn format(self: Node, writer: *std.Io.Writer,) std.Io.Writer.Error!void {
        try writer.print("({t}", .{ self.tag });
        switch (self.data) {
            .node => |n| {
                if (n != .root) {
                    try writer.print(" :node ({d})", .{ n });
                }
            },
            .token => |t| try writer.print(" :token ({d})", .{ t }),
            .node_and_token => |nt| try writer.print(" :node ({d}) :token ({d})", .{ nt.@"0", nt.@"1"}),
            .node_and_node => |nn| try writer.print(" :node ({d}) :node ({d})", .{ nn.@"0", nn.@"1" }),
        }
        try writer.writeByte(')');
    }

    pub const Index = enum(u32) {
        root = 0,
        invalid = std.math.maxInt(u32),
        _,
    };

    pub const Data = union(enum) {
        node: Index,
        token: TokenIndex,
        node_and_token: struct { Index, TokenIndex },
        node_and_node: struct { Index, Index },
        // opt_node: OptionalIndex,
    };
};

pub const Error = struct {
    tag: Tag,
    token: TokenIndex,
    extra: union {
        none: void,
        expected_tag: Token.Tag,
    } = .{ .none = {} },

    pub const Tag = enum {
        missing_newline_after_string_comment,
        expected_token,
        expected_expr,
        unexpected_tag_class_body,
        invalid_annotation,
        expected_prefix_expr,
        invalid_prefix_operand,
        hit_banned_prec,
    };
};

pub const AnnotationTarget = enum(u32) {
        none = 0,
        script = 1,
        class = 1 << 2,
        variable = 1 << 3,
        constant = 1 << 4,
        signal = 1 << 5,
        function = 1 << 6,
        statement = 1 << 7,
        standalone = 1 << 8,

        pub const class_level = @intFromEnum(AnnotationTarget.class)
            | @intFromEnum(AnnotationTarget.variable)
            | @intFromEnum(AnnotationTarget.constant)
            | @intFromEnum(AnnotationTarget.signal)
            | @intFromEnum(AnnotationTarget.function);

        pub fn group(members: []const AnnotationTarget) u32 {
            var res: u32 = 0;
            for (members) |m| {
                res |= @intFromEnum(m);
            }
            return res;
        }
};

pub const validAnnotations = std.StaticStringMap(AnnotationTarget).initComptime(.{
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

