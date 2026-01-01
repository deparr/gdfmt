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
            .class,
            .@"const",
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

        invalid,
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
                .invalid,
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
                .nan => "NAN",

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

        pub fn canPrecedeBinOp(self: Tag) bool {
            return switch (self) {
                .identifier,
                .literal,
                .self,
                .paren_close,
                .bracket_close,
                .brace_close,
                .pi,
                .nan,
                .tau,
                .inf,
                => true,
                else => false,
            };
        }
    };
};

pub const Tokenizer = struct {
    // [TODO] might need an allocator
    source: [:0]const u8,
    index: u32 = 0,
    last_tag: Token.Tag = .empty,
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
        if (self.isAtEnd()) {
            return .{
                .tag = .eof,
                .loc = .{
                    .start = self.index,
                    .end = self.index,
                },
            };
        }

        // FIXME: THIS IS NOT CORRECT
        self.skipWhitespace();

        var token = Token{
            .tag = .empty,
            .loc = .{ .start = self.index },
        };

        const at = self.source[self.index];
        switch (at) {
            '\r' => {
                if (self.peek(1) == '\n') {
                    token.tag = .newline;
                    token.loc.end = self.index + 1;
                    self.advance(); // not sure if i like this
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
            '@' => {
                token.tag = self.annotation();
                token.loc.end = self.index;
            },

            '0'...'9' => {
                token.tag = self.number();
                token.loc.end = self.index;
            },

            // godot handles comments in skipwhitespace
            '#' => token.tag = .invalid,
            '~' => token.tag = .tilde,
            ',' => token.tag = .comma,
            ':' => token.tag = .colon,
            ';' => token.tag = .semicolon,
            '$' => token.tag = .dollar,
            '?' => token.tag = .question_mark,

            // TODO godot tracks the paren stack during lexing
            // not sure if I want or need to do that
            '(' => token.tag = .paren_open,
            ')' => token.tag = .paren_close,
            '[' => token.tag = .bracket_open,
            ']' => token.tag = .bracket_close,
            '{' => token.tag = .brace_open,
            '}' => token.tag = .brace_close,

            '!' => token.tag = if (self.peek(1) == '=') .bang_equal else .bang,
            '/' => token.tag = if (self.peek(1) == '=') .slash_equal else .slash,
            '%' => token.tag = if (self.peek(1) == '=') .percent_equal else .percent,
            '=' => token.tag = if (self.peek(1) == '=') self.VCSMarker() else .equal,
            '+' => token.tag = blk: {
                if (self.peek(1) == '=') {
                    break :blk .plus_equal;
                } else if (std.ascii.isDigit(self.peek(1)) and !self.last_tag.canPrecedeBinOp()) {
                    const tag = self.number();
                    token.loc.end = self.index;
                    break :blk tag;
                } else {
                    break :blk .plus;
                }
            },
            '-' => token.tag = blk: {
                if (self.peek(1) == '=') {
                    break :blk .minus_equal;
                } else if (std.ascii.isDigit(self.peek(1)) and !self.last_tag.canPrecedeBinOp()) {
                    const tag = self.number();
                    token.loc.end = self.index;
                    break :blk tag;
                } else if (self.peek(1) == '>') {
                    break :blk .forward_arrow;
                } else {
                    break :blk .minus;
                }
            },
            '*' => token.tag = blk: {
                if (self.peek(1) == '*') {
                    break :blk if (self.peek(2) == '=') .star_star_equal else .star_star;
                } else if (self.peek(1) == '=') {
                    break :blk .star_equal;
                } else {
                    break :blk .star;
                }
            },
            '^' => token.tag = switch (self.peek(1)) {
                '=' => .caret_equal,
                '"', '\'' => self.string(),
                else => .caret,
            },
            '&' => token.tag = switch (self.peek(1)) {
                '=' => .ampersand_equal,
                '&' => .ampersand_ampersand,
                '"', '\'' => self.string(),
                else => .ampersand,
            },
            '|' => token.tag = switch (self.peek(1)) {
                '=' => .pipe_equal,
                '|' => .pipe_pipe,
                else => .pipe,
            },
            '.' => token.tag = blk: {
                if (self.peek(1) == '.') {
                    break :blk if (self.peek(2) == '.') .period_period_period else .period_period;
                } else if (std.ascii.isDigit(self.peek(1))) {
                    const tag = self.number();
                    token.loc.end = self.index;
                    break :blk tag;
                } else {
                    break :blk .period;
                }
            },

            '<' => {
                const compound_tag: Token.Tag = switch (self.peek(1)) {
                    '<' => .less_less,
                    '=' => .less_equal,
                    else => .empty,
                };
                token.tag = switch (compound_tag) {
                    .less_less => if (self.peek(2) == '=')
                        .less_less_equal
                    else
                        // TODO VCS markers ??
                        .less_less,
                    .less_equal => .less_equal,
                    else => .less,
                };
            },
            '>' => {
                const compound_tag: Token.Tag = switch (self.peek(1)) {
                    '>' => .greater_greater,
                    '=' => .greater_equal,
                    else => .empty,
                };
                token.tag = switch (compound_tag) {
                    .greater_greater => if (self.peek(2) == '=')
                        .greater_greater_equal
                    else
                        .greater_greater,
                    .greater_equal => .greater_equal,
                    else => .greater,
                };
            },
            else => token.tag = .invalid,
        }

        // variable length tokens update the index as they are created
        if (token.tag.lexeme()) |lexeme| {
            self.index += @truncate(lexeme.len);
        } else if (token.tag == .invalid) {
            self.index += 1;
        }

        self.last_tag = token.tag;
        return token;
    }

    pub fn isAtEnd(self: *const Tokenizer) bool {
        return self.index > self.source.len or self.source[self.index] == 0;
    }

    fn advance(self: *Tokenizer) void {
        self.index += 1;
    }

    fn peek(self: *const Tokenizer, n: i32) u8 {
        const peek_index: i32 = n + @as(i32, @intCast(self.index));
        if (peek_index < 0 or peek_index > self.source.len) return 0;
        // std.debug.assert(peek_index <= self.source.len);
        // std.debug.assert(peek_index >= 0);
        return self.source[@abs(peek_index)];
    }

    // TODO comments
    fn skipWhitespace(self: *Tokenizer) void {
        while (true) {
            switch (self.source[self.index]) {
                ' ', '\t', '\r' => self.index += 1,
                else => break,
            }
        }
    }

    // TODO unicode
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
        var tag: Token.Tag = .empty;
        if (len == 1 and literal[0] == '_') {
            tag = .underscore;
            // ident is actually a literal
        } else if (strcmp(literal, "true") or strcmp(literal, "false") or strcmp(literal, "null")) {
            tag = .literal;
            self.index = end;
            // ident is actually a keyword
        } else if (Token.getKeyword(literal)) |keyword| {
            tag = keyword;
        } else {
            tag = .identifier;
            self.index = end;
        }

        return tag;
    }

    // TODO unicode
    // TODO merge with ident ?
    fn annotation(self: *Tokenizer) Token.Tag {
        var end = self.index + 1;
        while (true) {
            switch (self.source[end]) {
                '_', 'A'...'Z', 'a'...'z', '0'...'9' => end += 1,
                else => break,
            }
        }
        self.index = end;
        return .annotation;
    }

    fn number(self: *Tokenizer) Token.Tag {
        var base = Base.decimal;
        var has_decimal = false;
        var has_error = false;
        var need_digits = false;

        // consume sign
        if (self.peek(0) == '-' or self.peek(0) == '+') self.index += 1;

        // consume 0x, 0b, and leading .
        if (self.peek(0) == '0') {
            self.index += 1;
            if (self.peek(0) == 'x' or self.peek(0) == 'X') {
                base = .hexadecimal;
                need_digits = true;
                self.index += 1;
            } else if (self.peek(0) == 'b' or self.peek(0) == 'B') {
                base = .binary;
                need_digits = true;
                self.index += 1;
            }
        } else if (self.peek(0) == '.') {
            has_decimal = true;
            self.index += 1;
        }

        // hex and bin literals cannot start with '_'
        if (base != .decimal and self.peek(0) == '_') {
            std.debug.print("TODO errors: unexpected underscore after '0{c}'\n", .{self.peek(-1)});
            has_error = true;
            // TODO push the error somewhere
        }

        // consume to end of literal OR '.'
        var prev_was_underscore = false;
        while (isDigit(self.peek(0), base)) {
            if (self.peek(0) == '_') {
                if (prev_was_underscore) {
                    std.debug.print("TODO errors: multiple underscores cannot adjacent in numeric literal\n", .{});
                    has_error = true;
                }
                prev_was_underscore = true;
            } else {
                prev_was_underscore = false;
                need_digits = false;
            }
            self.index += 1;
        }

        // make sure we don't consume a ..
        if (self.peek(0) == '.' and self.peek(1) != '.') {
            if (base == .decimal and !has_decimal) {
                has_decimal = true;
            } else if (base == .decimal) {
                // pushing an error aborts the whole parser
                std.debug.print("TODO errors: cannot use two decimal points in decimal number ONE\n", .{});
                // has_error = true;
            } else {
                std.debug.print("TODO errors: cannot use decimal point in {t} number\n", .{base});
                has_error = true;
            }

            // consume the rest of the digits
            if (!has_error) {
                self.index += 1;
                prev_was_underscore = false;
                while (isDigit(self.peek(0), base)) {
                    if (self.peek(0) == '_') {
                        if (prev_was_underscore) {
                            std.debug.print("TODO errors: multiple underscores cannot adjacent in numeric literal\n", .{});
                            has_error = true;
                        }
                        prev_was_underscore = true;
                    } else {
                        prev_was_underscore = false;
                    }
                    self.index += 1;
                }
            }
        }

        // only decimals can have exponents
        if (base == .decimal and (self.peek(0) == 'e' or self.peek(0) == 'E')) {
            self.index += 1;
            if (self.peek(0) == '+' or self.peek(0) == '-')
                self.index += 1;

            if (!isDigit(self.peek(0), base)) {
                std.debug.print("TODO errors: expected digit after \"e\".\n", .{});
            }

            prev_was_underscore = false;
            while (isDigit(self.peek(0), base)) {
                if (self.peek(0) == '_') {
                    if (prev_was_underscore) {
                        std.debug.print("TODO errors: multiple underscores cannot adjacent in numeric literal\n", .{});
                        has_error = true;
                    }
                    prev_was_underscore = true;
                } else {
                    prev_was_underscore = false;
                }
                self.index += 1;
            }
        }

        // hex or bin literal that has no digits
        if (need_digits) {
            std.debug.print("TODO: errors: expected {t} digits after \"0{c}\".\n", .{ base, if (base == .binary) @as(u8, 'b') else @as(u8, 'x') });
            return .@"error";
        }

        // TODO not sure how this is being hit
        if (!has_error and has_decimal and self.peek(0) == '.' and self.peek(1) != '.') {
            std.debug.print("TODO errors: cannot use two decimals points in decimal number TWO\n", .{});
            has_error = true;
        } else if (isIdentContinue(self.peek(0))) {
            std.debug.print("TODO errors: invalid numeric notation\n", .{});
        }

        // godot creates a string and parses into a number here
        // but I dont think I need to do that, at least not at this point

        return .literal;
    }

    fn string(self: *Tokenizer) Token.Tag {
        self.index += 1;
        return .literal;
    }

    // TODO vcs markers
    fn VCSMarker(self: *Tokenizer) Token.Tag {
        _ = self;
        return .equal_equal;
    }
};

fn strcmp(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

const Base = enum {
    decimal,
    hexadecimal,
    binary,
};
// todo not sure if I like this more than nested switches
fn isDigit(c: u8, base: Base) bool {
    const digits = [_]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' };
    if (c == '_') return true;
    const lc = std.ascii.toLower(c);
    const digit_set = switch (base) {
        .binary => digits[0..2],
        .decimal,
        => digits[0..10],
        .hexadecimal,
        => &digits,
    };
    return std.mem.indexOfScalar(u8, digit_set, lc) != null;
}

// TODO unicode
fn isIdentContinue(c: u8) bool {
    return switch (c) {
        '_', 'a'...'z', 'A'...'Z' => true,
        else => false,
    };
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

test "operators" {
    try testTokenize(
        "%%=*=**=***++=--====!!=<<>><=<>=>->^^=&&&=&|||=....|..?",
        &.{
            .percent,
            .percent_equal,
            .star_equal,
            .star_star_equal,
            .star_star,
            .star,
            .plus,
            .plus_equal,
            .minus,
            .minus_equal,
            .equal_equal,
            .equal,
            .bang,
            .bang_equal,
            .less_less,
            .greater_greater,
            .less_equal,
            .less,
            .greater_equal,
            .greater,
            .forward_arrow,
            .caret,
            .caret_equal,
            .ampersand_ampersand,
            .ampersand_equal,
            .ampersand,
            .pipe_pipe,
            .pipe_equal,
            .period_period_period,
            .period,
            .pipe,
            .period_period,
            .question_mark,
        },
    );
}
