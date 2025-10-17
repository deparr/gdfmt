const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "as", .as },
        .{ "and", .@"and" },
        .{ "assert", .assert },
        .{ "await", .await },
        .{ "break", .@"break" },
        .{ "breakpoint", .breakpoint },
        .{ "class", .class },
        .{ "class_name", .class_name },
        .{ "const", .@"const" },
        .{ "continue", .@"continue" },
        .{ "elif", .elif },
        .{ "else", .@"else" },
        .{ "enum", .@"enum" },
        .{ "extends", .extends },
        .{ "for", .@"for" },
        .{ "func", .func },
        .{ "if", .@"if" },
        .{ "in", .in },
        .{ "is", .is },
        .{ "match", .match },
        .{ "namespace", .namespace },
        .{ "not", .not },
        .{ "or", .@"or" },
        .{ "pass", .pass },
        .{ "preload", .preload },
        .{ "return", .@"return" },
        .{ "self", .self },
        .{ "signal", .signal },
        .{ "static", .static },
        .{ "super", .super },
        .{ "trait", .trait },
        .{ "var", .@"var" },
        .{ "void", .void },
        .{ "while", .@"while" },
        .{ "yield", .yield },
        .{ "INF", .inf },
        .{ "NaN", .nan },
        .{ "PI", .pi },
        .{ "TAU", .tau },
        .{ "null", .null },
        .{ "true", .true },
        .{ "false", .false },
    });

    pub fn getKeyword(bytes: []const u8) ?Tag {
        return keywords.get(bytes);
    }

    pub const Tag = enum {
        empty,

        annotation,
        identifier,
        string_literal,
        int_literal,
        float_literal,

        less,
        less_equal,
        greater,
        greater_equal,
        equal_equal,
        bang_equal,

        @"and",
        @"or",
        not,
        ampersand_ampersand,
        pipe_pipe,
        bang,

        ampersand,
        pipe,
        tilde,
        caret,
        less_less,
        greater_greater,

        plus,
        minus,
        star,
        star_star,
        slash,
        percent,

        equal,
        plus_equal,
        minus_equal,
        star_equal,
        star_star_equal,
        slash_equal,
        percent_equal,
        less_less_equal,
        greater_greater_equal,
        ampersand_equal,
        pipe_equal,
        caret_equal,

        @"if",
        elif,
        @"else",
        @"for",
        @"while",
        @"break",
        @"continue",
        pass,
        @"return",
        match,
        when,

        as,
        assert,
        await,
        breakpoint,
        class,
        class_name,
        @"const",
        @"enum",
        extends,
        func,
        in,
        is,
        namespace,
        preload,
        self,
        signal,
        static,
        super,
        trait,
        @"var",
        void,
        yield,

        bracket_open,
        bracket_close,
        brace_open,
        brace_close,
        paren_open,
        paren_close,
        comma,
        semicolon,
        period,
        period_period,
        period_period_period,
        colon,
        dollar,
        forward_arrow,
        underscore,

        newline,
        indent,
        dedent,

        pi,
        tau,
        inf,
        nan,
        null,
        true,
        false,
        vcs_conflict_marker,
        backtick,
        question_mark,

        @"error",
        eof,

        pub fn lexeme(tag: Tag) ?[]const u8 {
            return switch (tag) {
                .empty,
                .annotation,
                .identifier,
                .string_literal,
                .int_literal,
                .float_literal,
                .newline,
                .indent,
                .dedent,
                .vcs_conflict_marker,
                .@"error",
                .eof,
                => null,

                .less => "<",
                .less_equal => "<=",
                .greater => ">",
                .greater_equal => ">=",
                .equal_equal => "==",
                .bang_equal => "!=",

                .@"and" => "and",
                .@"or" => "or",
                .not => "not",
                .ampersand_ampersand => "&&",
                .pipe_pipe => "||",
                .bang => "!",

                .ampersand => "&",
                .pipe => "|",
                .tilde => "~",
                .caret => "^",
                .less_less => "<<",
                .greater_greater => ">>",

                .plus => "+",
                .minus => "-",
                .star => "*",
                .star_star => "**",
                .slash => "/",
                .percent => "%",

                .equal => "=",
                .plus_equal => "+=",
                .minus_equal => "-=",
                .star_equal => "*=",
                .star_star_equal => "**+",
                .slash_equal => "/=",
                .percent_equal => "%=",
                .less_less_equal => "<<=",
                .greater_greater_equal => ">>=",
                .ampersand_equal => "&=",
                .pipe_equal => "|=",
                .caret_equal => "^=",

                .@"if" => "if",
                .elif => "elif",
                .@"else" => "else",
                .@"for" => "for",
                .@"while" => "while",
                .@"break" => "break",
                .@"continue" => "continue",
                .pass => "pass",
                .@"return" => "return",
                .match => "match",
                .when => "when",

                .as => "as",
                .assert => "assert",
                .await => "await",
                .breakpoint => "breakpoint",
                .class => "class",
                .class_name => "class_name",
                .@"const" => "const",
                .@"enum" => "enum",
                .extends => "extends",
                .func => "func",
                .in => "in",
                .is => "is",
                .namespace => "namespace",
                .preload => "preload",
                .self => "self",
                .signal => "signal",
                .static => "static",
                .super => "super",
                .trait => "trait",
                .@"var" => "var",
                .void => "void",
                .yield => "yield",

                .bracket_open => "[",
                .bracket_close => "]",
                .brace_open => "{",
                .brace_close => "}",
                .paren_open => "(",
                .paren_close => ")",
                .comma => ",",
                .semicolon => ";",
                .period => ".",
                .period_period => "..",
                .period_period_period => "...",
                .colon => ":",
                .dollar => "$",
                .forward_arrow => "->",
                .underscore => "_",

                .pi => "PI",
                .tau => "TAU",
                .inf => "INF",
                .nan => "NaN",
                .null => "null",
                .true => "true",
                .false => "false",

                .backtick => "`",
                .question_mark => "?",
            };
        }

        pub fn symbol(tag: Tag) []const u8 {
            return tag.lexeme() orelse switch (tag) {
                .empty => "<<empty>>",
                .annotation => "<<annotation>>",
                .identifier => "<<identifier>>",
                .string_literal, .int_literal, .float_literal => "<<literal>>",
                .newline => "<<newline>>",
                .indent => "<<indent>>",
                .dedent => "<<dedent>>",
                .vcs_conflict_marker => "<<vcs_conflict_marker>>",
                .@"error" => "<<someerror>>",
                .eof => "<<EOF>>",

                else => unreachable,
            };
        }
    };
};

pub const Tokenizer = struct {
    // [TODO] might need an allocator
    source: [:0]u8,
    index: usize = 0,
    sent_eof: bool = false,
    pending_newline: bool = false,
    pending_indents: u32 = 0,

    pub fn next(self: *Tokenizer) Token {
        // self.skip_whitespace();

        if (self.is_at_end()) {
            return .{
                .tag = .eof,
                .loc = .{
                    .start = self.index,
                    .end = self.index,
                },
            };
        }

        return .{ .tag = .eof, .loc = .{ .start = 0, .end = 0 } };
    }

    inline fn is_at_end(self: *const Tokenizer) bool {
        return self.index >= self.source.len - 1;
    }

    fn advance(self: *Tokenizer) u8 {
        _ = self;
        return 0;
    }

    fn peek(self: *const Tokenizer) ?u8 {
        if (self.index + 1 >= self.source.len)
            return null;
        return self.source[self.index + 1];
    }

    fn peekN(self: *const Tokenizer, n: usize) ?u8 {
        if (self.index + n >= self.source.len)
            return null;
        return self.source[self.index + n];
    }
};
