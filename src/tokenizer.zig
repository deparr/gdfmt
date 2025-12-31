const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc = .{},

    pub const Loc = struct {
        start: u32 = 0,
        end: u32 = 0,
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
        .{ "when", .when },
        .{ "yield", .yield },
        .{ "INF", .inf },
        .{ "NAN", .nan },
        .{ "PI", .pi },
        .{ "TAU", .tau },
    });

    pub fn getKeyword(bytes: []const u8) ?Tag {
        return keywords.get(bytes);
    }

    pub fn isValidNodeName(self: Token) bool {
        return switch (self.tag) {
            .identifier,
            .@"and",
            .as,
            .assert,
            .await,
            .@"break",
            .breakpoint,
            .class_name,
            .class, .@"const",
            .pi,
            .inf,
            .nan,
            .tau,
            .@"continue",
            .elif,
            .@"else",
            .@"enum",
            .extends,
            .@"for",
            .func,
            .@"if",
            .in,
            .is,
            .match,
            .namespace,
            .not,
            .@"or",
            .pass,
            .preload,
            .@"return",
            .self,
            .signal,
            .static,
            .super,
            .trait,
            .underscore,
            .@"var",
            .void,
            .@"while",
            .when,
            .yield,
            => true,
            else => false,
        };
    }

    pub const Tag = enum {
        empty,

        annotation,
        identifier,
        literal,

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
                .literal,
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

                .backtick => "`",
                .question_mark => "?",
            };
        }

        pub fn symbol(tag: Tag) []const u8 {
            return tag.lexeme() orelse switch (tag) {
                .empty => "<<empty>>",
                .annotation => "<<annotation>>",
                .identifier => "<<identifier>>",
                .literal => "<<literal>>",
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
    source: [:0]const u8,
    index: u32 = 0,
    sent_eof: bool = false,
    pending_newline: bool = false,
    pending_indents: u32 = 0,

    pub fn init(source: [:0]const u8) Tokenizer {
        // skip utf bom if present
        return .{
            .source = source,
            .index = if (std.mem.startsWith(u8, source, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    pub fn next(self: *Tokenizer) Token {

        // FIXME: THIS IS NOT CORRECT
        self.skipWhitespace();

        if (self.isAtEnd()) {
            return .{
                .tag = .eof,
                .loc = .{
                    .start = self.index,
                    .end = self.index,
                },
            };
        }

        var token = Token{
            .tag = .empty,
            .loc = .{ .start = self.index },
        };

        switch (self.source[self.index]) {
            '\r' => {
                if (self.peek()) |byte| {
                    if (byte == '\n') {
                        token.tag = .newline;
                        token.loc.end = self.index + 1;
                        self.advance(); // not sure if i like this
                    }
                }
            },
            '\n' => {
                token.tag = .newline;
                token.loc.end = self.index + 1;
                self.advance();
            },
            '_', 'A'...'Z', 'a'...'z' => {
                token.tag = self.ident();
                token.loc.end = self.index;
            },
            else => {},
        }

        return token;
    }

    pub fn isAtEnd(self: *const Tokenizer) bool {
        return self.index >= self.source.len - 1 or self.source[self.index] == 0;
    }

    fn advance(self: *Tokenizer) void {
        self.index += 1;
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

    fn skipWhitespace(self: *Tokenizer) void {
        while (true) {
            switch (self.source[self.index]) {
                ' ', '\t', '\r' => self.index += 1,
                else => break,
            }
        }
    }

    fn ident(self: *Tokenizer) Token.Tag {
        var end = self.index + 1;
        while (true) {
            switch (self.source[end]) {
                '_', 'A'...'Z', 'a'...'z', '0'...'9' => end += 1,
                else => break,
            }
        }
        const len = end - self.index;
        const literal = self.source[self.index..end];
        var tag: Token.Tag = .identifier;
        if (len == 1 and literal[0] == '_') {
            tag = .underscore;

            // ident is actually a literal
        } else if (strcmp(literal, "true") or strcmp(literal, "false") or strcmp(literal, "null")) {
            tag = .literal;

            // ident is actually a keyword
        } else if (Token.getKeyword(self.source[self.index..end])) |keyword| {
            tag = keyword;
        }
        self.index = end;
        return tag;
    }
};

fn strcmp(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

fn testTokenize(source: [:0]const u8, expected_token_tags: []const Token.Tag) !void {
    var tokenizer = Tokenizer.init(source);
    for (expected_token_tags) |expected_tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(expected_tag, token.tag);
    }

    // always expect a final eof token
    const eof = tokenizer.next();
    try std.testing.expectEqual(Token.Tag.eof, eof.tag);
    try std.testing.expectEqual(source.len, eof.loc.start);
    try std.testing.expectEqual(source.len, eof.loc.end);
}

test "keywords" {
    try testTokenize("as", &.{.as});
    try testTokenize("assert", &.{.assert});
    try testTokenize("await", &.{.await});
    try testTokenize("breakpoint", &.{.breakpoint});
    try testTokenize("class", &.{.class});
    try testTokenize("class_name", &.{.class_name});
    try testTokenize("const", &.{.@"const"});
    try testTokenize("enum", &.{.@"enum"});
    try testTokenize("extends", &.{.extends});
    try testTokenize("func", &.{.func});
    try testTokenize("in", &.{.in});
    try testTokenize("is", &.{.is});
    try testTokenize("namespace", &.{.namespace});
    try testTokenize("preload", &.{.preload});
    try testTokenize("self", &.{.self});
    try testTokenize("signal", &.{.signal});
    try testTokenize("static", &.{.static});
    try testTokenize("super", &.{.super});
    try testTokenize("trait", &.{.trait});
    try testTokenize("var", &.{.@"var"});
    try testTokenize("void", &.{.void});
    try testTokenize("yield", &.{.yield});
    try testTokenize("PI", &.{.pi});
    try testTokenize("TAU", &.{.tau});
    try testTokenize("INF", &.{.inf});
    try testTokenize("NAN", &.{.nan});
    try testTokenize("if", &.{.@"if"});
    try testTokenize("elif", &.{.elif});
    try testTokenize("else", &.{.@"else"});
    try testTokenize("for", &.{.@"for"});
    try testTokenize("while", &.{.@"while"});
    try testTokenize("break", &.{.@"break"});
    try testTokenize("continue", &.{.@"continue"});
    try testTokenize("pass", &.{.pass});
    try testTokenize("return", &.{.@"return"});
    try testTokenize("match", &.{.match});
    try testTokenize("when", &.{.when});
}
