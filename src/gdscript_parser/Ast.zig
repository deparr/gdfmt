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

pub fn parse(gpa: Allocator, source: [:0]const u8) anyerror!Ast {
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
    data: Data,

    pub const Tag = enum {
        root,
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
        enum_value,
        expression,
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

        comment,
        doc_comment,
    };

    pub const Index = enum(u32) {
        root = 0,
        invalid = std.math.maxInt(u32),
        _,
    };

    pub const Data = union(enum) {
        none,
        node: Index,
        annotation: Annotation,
        array: Array,
        assert: Assert,
        assignment: Assignment,
        await: Await,
        binary_op: BinaryOp,
        call: Call,
        cast: Cast,
        class: Class,
        constant: Constant,
        dictionary: Dictionary,
        @"enum": EnumDecl,
        enum_value: EnumValue,
        @"for": ForLoop,
        function: Function,
        get_node: GetNode,
        identifier: Identifier,
        @"if": If,
        lambda: Lambda,
        literal: Literal,
        match: Match,
        match_branch: MatchBranch,
        parameter: Parameter,
        pattern: Pattern,
        preload: Preload,
        @"return": Return,
        signal: Signal,
        subscript: Subscript,
        suite: Suite,
        ternary_op: Ternary,
        type: TypeExpr,
        type_test: TypeTest,
        unary_op: UnaryOp,
        variable: Variable,
        @"while": WhileLoop,
    };

    pub const Array = struct {
        elements: Index,
    };

    pub const Assert = struct {
        condition: Index,
        message: Index,
    };

    pub const Assignment = struct {
        target: Index,
        value: Index,
        op: Op,
        pub const Op = enum {
            none,
            add,
            sub,
            mul,
            div,
            mod,
            power,
            shl,
            shr,
            bit_and,
            bit_or,
            bit_xor,
        };
    };

    pub const Await = struct {
        expression: Index,
    };

    pub const BinaryOp = struct {
        lhs: Index,
        rhs: Index,
        op: Op,
        pub const Op = enum {
            add,
            sub,
            mul,
            div,
            mod,
            power,
            shl,
            shr,
            bit_and,
            bit_or,
            bit_xor,
            log_and,
            log_or,
            equal,
            not_equal,
            less,
            less_equal,
            greater,
            greater_equal,
            in,
            not_in,
            is,
            not_is,
        };
    };

    pub const Call = struct {
        callee: Index,
        arguments: Index,
    };

    pub const Cast = struct {
        operand: Index,
        cast_type: Index,
    };

    pub const Class = struct {
        name: TokenIndex,
        extends: Index,
        members: Index,
    };

    pub const Constant = struct {
        name: TokenIndex,
        type: Index,
        value: Index,
    };

    pub const Dictionary = struct {
        elements: Index,
    };

    pub const EnumDecl = struct {
        name: TokenIndex,
        values: Index,
    };

    pub const EnumValue = struct {
        name: TokenIndex,
        value: Index,
    };

    pub const ForLoop = struct {
        variable: TokenIndex,
        iter: Index,
        body: Index,
    };

    pub const Function = struct {
        name: TokenIndex,
        params: Index,
        return_type: Index,
        body: Index,
        flags: FunctionFlags,
        pub const FunctionFlags = packed struct {
            is_static: bool = false,
            is_virtual: bool = false,
            is_override: bool = false,
            is_const: bool = false,
            is_async: bool = false,
            is_export: bool = false,
            _: u2 = 0,
        };
    };

    pub const GetNode = struct {
        token: TokenIndex,
    };

    pub const Identifier = struct {
        token: TokenIndex,
    };

    pub const If = struct {
        condition: Index,
        then_branch: Index,
        else_branch: Index,
    };

    pub const Lambda = struct {
        function: Index,
    };

    pub const Literal = struct {
        token: TokenIndex,
    };

    pub const Match = struct {
        expression: Index,
        branches: Index,
    };

    pub const MatchBranch = struct {
        patterns: Index,
        guard: Index,
        body: Index,
    };

    pub const Parameter = struct {
        name: TokenIndex,
        type: Index,
        default_value: Index,
    };

    pub const Pattern = struct {
        pattern_type: PatternType,
        value: Index,
        pub const PatternType = enum {
            literal,
            expression,
            bind,
            array,
            dictionary,
            rest,
            wildcard,
        };
    };

    pub const Preload = struct {
        path: Index,
    };

    pub const Return = struct {
        value: Index,
    };

    pub const Signal = struct {
        name: TokenIndex,
        params: Index,
    };

    pub const Subscript = struct {
        base: Index,
        index: Index,
    };

    pub const Suite = struct {
        statements: Index,
    };

    pub const Ternary = struct {
        condition: Index,
        then_expr: Index,
        else_expr: Index,
    };

    pub const TypeExpr = struct {
        main_type: TokenIndex,
        generic_types: Index,
        is_nullable: bool = false,
    };

    pub const TypeTest = struct {
        operand: Index,
        test_type: Index,
    };

    pub const UnaryOp = struct {
        operand: Index,
        op: Op,
        pub const Op = enum {
            neg,
            pos,
            bit_not,
            log_not,
        };
    };

    pub const Variable = struct {
        name: TokenIndex,
        type: Index,
        value: Index,
        flags: VariableFlags,
        pub const VariableFlags = packed struct {
            is_export: bool = false,
            is_onready: bool = false,
            is_static: bool = false,
            is_const: bool = false,
            is_await: bool = false,
            setget: bool = false,
            setter: bool = false,
            getter: bool = false,
            _: u2 = 0,
        };
    };

    pub const WhileLoop = struct {
        condition: Index,
        body: Index,
    };
};

pub const Annotation = struct {
    arguments: Node.Index,
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
        unexpected_tag_class_body,
    };
};
