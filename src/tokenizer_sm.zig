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
    source: [:0]u8,
    index: usize = 0,

    const State = enum {
        start,
        percent,
        star,
        star_star,
        plus,
        minus,
        equal,
        bang,
        less,
        less_less,
        greater,
        greater_greater,
        caret,
        ampersand,
        pipe,
        period,
        period_period,
        identifier,
        number,
        r,
        string_literal,
        expect_newline,
    };

    pub fn next(self: *Tokenizer) Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };
        // std.debug.print("bout to start on {d} {x:02}\n", .{ self.source[self.index], self.source[self.index] });
        state: switch (State.start) {
            .start => switch (self.source[self.index]) {
                0 => {
                    if (self.index == self.source.len) {
                        return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    }
                },
                '\r' => {
                    self.index += 1;
                    continue :state .expect_newline;
                },
                '\n' => {
                    self.index += 1;
                    result.tag = .newline;
                },
                ' ', '\t' => {
                    self.index += 1;
                    result.loc.start = self.index;
                    continue :state .start;
                },
                ',' => {
                    result.tag = .comma;
                    self.index += 1;
                },
                '~' => {
                    result.tag = .tilde;
                    self.index += 1;
                },
                ':' => {
                    result.tag = .colon;
                    self.index += 1;
                },
                ';' => {
                    result.tag = .semicolon;
                    self.index += 1;
                },
                '$' => {
                    result.tag = .dollar;
                    self.index += 1;
                },
                '?' => {
                    result.tag = .question_mark;
                    self.index += 1;
                },
                '`' => {
                    result.tag = .backtick;
                    self.index += 1;
                },
                '(' => {
                    result.tag = .paren_open;
                    self.index += 1;
                },
                ')' => {
                    result.tag = .paren_close;
                    self.index += 1;
                },
                '[' => {
                    result.tag = .bracket_open;
                    self.index += 1;
                },
                ']' => {
                    result.tag = .bracket_close;
                    self.index += 1;
                },
                '{' => {
                    result.tag = .brace_open;
                    self.index += 1;
                },
                '}' => {
                    result.tag = .brace_close;
                    self.index += 1;
                },
                '%' => continue :state .percent,
                '*' => continue :state .star,
                '+' => continue :state .plus,
                '-' => continue :state .minus,
                '=' => continue :state .equal,
                '!' => continue :state .bang,
                '<' => continue :state .less,
                '>' => continue :state .greater,
                '^' => continue :state .caret,
                '&' => continue :state .ampersand,
                '|' => continue :state .pipe,
                '.' => continue :state .period,
                'r' => continue :state .r,
                '@' => {
                    result.tag = .annotation;
                    continue :state .identifier;
                },
                'a'...'q', 's'...'z', 'A'...'Z', '_' => {
                    result.tag = .identifier;
                    continue :state .identifier;
                },
                '\'', '"' => {
                    result.tag = .string_literal;
                    continue :state .string_literal;
                },
                else => {
                    result.tag = .empty;
                    self.index += 1;
                },
            },
            .expect_newline => {
                self.index += 1;
                switch (self.source[self.index]) {
                    0 => {
                        std.debug.print("got 0 in expect_newline", .{});
                    },
                    '\n' => {
                        self.index += 1;
                        result.tag = .newline;
                    },
                    else => {
                        std.debug.print("got unexpected CR in expect_newline", .{});
                    },
                }
            },
            .percent => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .percent_equal;
                    },
                    else => result.tag = .percent,
                }
            },
            .star => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .star_equal;
                    },
                    '*' => continue :state .star_star,
                    else => result.tag = .star,
                }
            },
            .star_star => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .star_star_equal;
                    },
                    else => result.tag = .star_star,
                }
            },
            .plus => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .plus_equal;
                    },
                    else => result.tag = .plus,
                }
            },
            .minus => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .minus_equal;
                    },
                    '>' => {
                        self.index += 1;
                        result.tag = .forward_arrow;
                    },
                    else => result.tag = .minus,
                }
            },
            .equal => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .equal_equal;
                    },
                    else => result.tag = .equal,
                }
            },
            .bang => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .bang_equal;
                    },
                    else => result.tag = .bang,
                }
            },
            .less => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .less_equal;
                    },
                    '<' => continue :state .less_less,
                    else => result.tag = .less,
                }
            },
            .less_less => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .less_less_equal;
                    },
                    else => result.tag = .less_less,
                }
            },
            .greater => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .greater_equal;
                    },
                    '>' => continue :state .greater_greater,
                    else => result.tag = .greater,
                }
            },
            .greater_greater => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .greater_greater_equal;
                    },
                    else => result.tag = .greater_greater,
                }
            },
            .caret => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '\'', '"' => continue :state .string_literal,
                    '=' => {
                        self.index += 1;
                        result.tag = .caret_equal;
                    },
                    else => result.tag = .caret,
                }
            },
            .ampersand => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '\'', '"' => continue :state .string_literal,
                    '=' => {
                        self.index += 1;
                        result.tag = .ampersand_equal;
                    },
                    '&' => {
                        self.index += 1;
                        result.tag = .ampersand_ampersand;
                    },
                    else => result.tag = .ampersand,
                }
            },
            .pipe => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .pipe_equal;
                    },
                    '|' => {
                        self.index += 1;
                        result.tag = .pipe_pipe;
                    },
                    else => result.tag = .pipe,
                }
            },
            .period => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '.' => continue :state .period_period,
                    '0'...'9' => continue :state .number,
                    else => result.tag = .period,
                }
            },
            .period_period => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '.' => {
                        self.index += 1;
                        result.tag = .period_period_period;
                    },
                    else => result.tag = .period_period,
                }
            },
            .r => {
                self.index += 1;
                switch (self.source[self.index]) {
                    '\'', '"' => continue :state .string_literal,
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :state .identifier,
                    // is single 'r'
                    else => {
                        result.tag = .identifier;
                    },
                }
            },
            .identifier => {
                self.index += 1;
                switch (self.source[self.index]) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :state .identifier,
                    else => {
                        const ident = self.source[result.loc.start..self.index];
                        if (Token.getKeyword(ident)) |tag| {
                            result.tag = tag;
                        }
                    },
                }
            },
            .string_literal => {
                self.index += 1;
                // pointing at second char here
                const start_quote = self.source[self.index - 1];
                switch (self.source[self.index]) {
                    start_quote => {},
                    else => {},
                }
            },
            else => |state| {
                std.debug.print("unhandled lexer state: {s}\n", .{@tagName(state)});
                self.index += 1;
                result.tag = .empty;
            },
        }

        result.loc.end = self.index;
        return result;
    }
};
