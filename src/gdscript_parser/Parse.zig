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

pub fn parseRoot(self: *Parse) Error!void {
    self.nodes.appendAssumeCapacity(.{
        .tag = .root,
        .main_token = self.tok_i,
        .data = undefined,
    });

    var class_name: TokenIndex = 0;
    var extends: Node.Index = .invalid;
    var members = try self.makeNodeList();
    defer members.deinit(self.gpa);

    while (self.tokenTag(self.tok_i) != .eof) {
        const tag = self.tokenTag(self.tok_i);

        switch (tag) {
            .annotation => {
                _ = try self.parseAnnotation();
            },
            .comment => {
                const comment_tok = self.nextToken();
                _ = try self.addNode(.{
                    .tag = .comment,
                    .main_token = comment_tok,
                    .data = .{ .none = {} },
                });
            },
            .class_name => {
                self.skipToken();
                class_name = self.nextToken();
                if (self.tokenTag(self.tok_i) == .newline) {
                    self.skipToken();
                }
            },
            .extends => {
                self.skipToken();
                extends = try self.parseExpression();
                if (self.tokenTag(self.tok_i) == .newline) {
                    self.skipToken();
                }
            },
            .indent => {
                const body = try self.parseClassBody();
                const body_index = try self.finalizeNodeList(&members);
                _ = body;
                _ = body_index;
                break;
            },
            .newline => {
                self.skipToken();
            },
            else => {
                break;
            },
        }
    }

    if (self.tokenTag(self.tok_i) != .eof) {
        try self.warnExpected(.eof);
    }
}

// fn parseExprPrecendence(self: *Parse) !Node.Index {
// }
//
// fn parseExpr(self: *Parse, precedence: i32) !Node.Index {
// }

fn parseExpression(self: *Parse) Error!Node.Index {
    return self.parseBinaryOp(0);
}

fn parseBinaryOp(self: *Parse, precedence: i32) Error!Node.Index {
    var lhs = try self.parseUnaryOp();

    while (true) {
        const tag = self.tokenTag(self.tok_i);
        const op_prec = binaryOpPrecedence(tag) orelse break;

        if (op_prec < precedence) break;

        if (tag == .@"and" or tag == .@"or") {
            const rhs = try self.parseBinaryOp(op_prec + 1);
            lhs = try self.addNode(.{
                .tag = .binary_op,
                .main_token = self.tok_i - 1,
                .data = .{ .binary_op = .{
                    .lhs = lhs,
                    .rhs = rhs,
                    .op = if (tag == .@"and") .log_and else .log_or,
                } },
            });
        } else if (tag == .not) {
            const rhs = try self.parseBinaryOp(op_prec + 1);
            lhs = try self.addNode(.{
                .tag = .binary_op,
                .main_token = self.tok_i - 1,
                .data = .{ .binary_op = .{
                    .lhs = lhs,
                    .rhs = rhs,
                    .op = .not_in,
                } },
            });
        } else {
            self.skipToken();
            const rhs = try self.parseBinaryOp(op_prec);
            lhs = try self.addNode(.{
                .tag = .binary_op,
                .main_token = self.tok_i - 1,
                .data = .{ .binary_op = .{
                    .lhs = lhs,
                    .rhs = rhs,
                    .op = tokenToBinaryOp(tag),
                } },
            });
        }
    }

    if (self.tokenTag(self.tok_i) == .@"if") {
        self.skipToken();
        const condition = try self.parseExpression();
        try self.expectToken(.@"else");
        const else_expr = try self.parseExpression();
        return try self.addNode(.{
            .tag = .ternary_op,
            .main_token = self.tok_i - 1,
            .data = .{ .ternary_op = .{
                .condition = condition,
                .then_expr = lhs,
                .else_expr = else_expr,
            } },
        });
    }

    return lhs;
}

fn parseUnaryOp(self: *Parse) Error!Node.Index {
    const tag = self.tokenTag(self.tok_i);
    switch (tag) {
        .minus, .plus, .tilde, .not => {
            const op: Node.UnaryOp.Op = switch (tag) {
                .minus => .neg,
                .plus => .pos,
                .tilde => .bit_not,
                .not => .log_not,
                else => unreachable,
            };
            self.skipToken();
            const operand = try self.parseUnaryOp();
            return try self.addNode(.{
                .tag = .unary_op,
                .main_token = self.tok_i - 1,
                .data = .{ .unary_op = .{
                    .operand = operand,
                    .op = op,
                } },
            });
        },
        else => {},
    }
    return self.parsePostfix();
}

fn parsePostfix(self: *Parse) Error!Node.Index {
    var node = try self.parsePrimary();

    while (true) {
        const tag = self.tokenTag(self.tok_i);
        switch (tag) {
            .period => {
                self.skipToken();
                const name_tok = self.nextToken();
                const name_tag = self.tokenTag(name_tok);
                if (name_tag != .identifier and !name_tag.isValidNodeName()) {
                    try self.warnExpected(.identifier);
                }
                const name_node = try self.addNode(.{
                    .tag = .identifier,
                    .main_token = name_tok,
                    .data = .{ .identifier = .{ .token = name_tok } },
                });
                node = try self.addNode(.{
                    .tag = .binary_op,
                    .main_token = name_tok,
                    .data = .{ .binary_op = .{
                        .lhs = node,
                        .rhs = name_node,
                        .op = .equal,
                    } },
                });
            },
            .bracket_open => {
                self.skipToken();
                const index = try self.parseExpression();
                try self.expectToken(.bracket_close);
                node = try self.addNode(.{
                    .tag = .subscript,
                    .main_token = self.tok_i - 1,
                    .data = .{ .subscript = .{
                        .base = node,
                        .index = index,
                    } },
                });
            },
            .paren_open => {
                self.skipToken();
                var args = try self.makeNodeList();
                while (self.tokenTag(self.tok_i) != .paren_close and self.tokenTag(self.tok_i) != .eof) {
                    const arg = try self.parseExpression();
                    try addNodeToList(&args, arg, self.gpa);
                    if (self.tokenTag(self.tok_i) == .comma) {
                        self.skipToken();
                    }
                }
                try self.expectToken(.paren_close);
                const args_index = try self.finalizeNodeList(&args);
                node = try self.addNode(.{
                    .tag = .call,
                    .main_token = self.tok_i - 1,
                    .data = .{ .call = .{
                        .callee = node,
                        .arguments = args_index,
                    } },
                });
            },
            else => break,
        }
    }

    return node;
}

fn parsePrimary(self: *Parse) Error!Node.Index {
    const tag = self.tokenTag(self.tok_i);
    switch (tag) {
        .literal => {
            return try self.addNode(.{
                .tag = .literal,
                .main_token = self.nextToken(),
                .data = .{ .literal = .{ .token = self.tok_i - 1 } },
            });
        },
        .identifier => {
            return try self.addNode(.{
                .tag = .identifier,
                .main_token = self.nextToken(),
                .data = .{ .identifier = .{ .token = self.tok_i - 1 } },
            });
        },
        .self => {
            return try self.addNode(.{
                .tag = .self,
                .main_token = self.nextToken(),
                .data = .{ .none = {} },
            });
        },
        .super => {
            return try self.addNode(.{
                .tag = .identifier,
                .main_token = self.nextToken(),
                .data = .{ .identifier = .{ .token = self.tok_i - 1 } },
            });
        },
        .dollar => {
            self.skipToken();
            const path_tok = self.nextToken();
            return try self.addNode(.{
                .tag = .get_node,
                .main_token = self.tok_i - 1,
                .data = .{ .get_node = .{ .token = path_tok } },
            });
        },
        .preload => {
            self.skipToken();
            try self.expectToken(.paren_open);
            const path = try self.parseExpression();
            try self.expectToken(.paren_close);
            return try self.addNode(.{
                .tag = .preload,
                .main_token = self.tok_i - 1,
                .data = .{ .preload = .{ .path = path } },
            });
        },
        .paren_open => {
            self.skipToken();
            const expr = try self.parseExpression();
            try self.expectToken(.paren_close);
            return expr;
        },
        .bracket_open => {
            self.skipToken();
            var elements = try self.makeNodeList();
            while (self.tokenTag(self.tok_i) != .bracket_close and self.tokenTag(self.tok_i) != .eof) {
                const elem = try self.parseExpression();
                try addNodeToList(&elements, elem, self.gpa);
                if (self.tokenTag(self.tok_i) == .comma) {
                    self.skipToken();
                }
            }
            try self.expectToken(.bracket_close);
            const elements_index = try self.finalizeNodeList(&elements);
            return try self.addNode(.{
                .tag = .array,
                .main_token = self.tok_i - 1,
                .data = .{ .array = .{ .elements = elements_index } },
            });
        },
        .brace_open => {
            self.skipToken();
            var pairs = try self.makeNodeList();
            while (self.tokenTag(self.tok_i) != .brace_close and self.tokenTag(self.tok_i) != .eof) {
                const key = try self.parseExpression();
                try self.expectToken(.colon);
                const value = try self.parseExpression();
                const pair = try self.addNode(.{
                    .tag = .binary_op,
                    .main_token = self.tok_i - 1,
                    .data = .{ .binary_op = .{
                        .lhs = key,
                        .rhs = value,
                        .op = .equal,
                    } },
                });
                try addNodeToList(&pairs, pair, self.gpa);
                if (self.tokenTag(self.tok_i) == .comma) {
                    self.skipToken();
                }
            }
            try self.expectToken(.brace_close);
            const pairs_index = try self.finalizeNodeList(&pairs);
            return try self.addNode(.{
                .tag = .dictionary,
                .main_token = self.tok_i - 1,
                .data = .{ .dictionary = .{ .elements = pairs_index } },
            });
        },
        .func => {
            return self.parseLambda();
        },
        else => {
            try self.warnExpected(.identifier);
            return try self.addNode(.{
                .tag = .identifier,
                .main_token = self.tok_i,
                .data = .{ .identifier = .{ .token = self.tok_i } },
            });
        },
    }
}

fn parseLambda(self: *Parse) Error!Node.Index {
    const func_tok = self.nextToken();
    var params = try self.makeNodeList();

    if (self.tokenTag(self.tok_i) != .colon) {
        while (true) {
            const param_name = self.nextToken();
            var param_type: Node.Index = .invalid;
            if (self.tokenTag(self.tok_i) == .colon) {
                self.skipToken();
                param_type = try self.parseType();
            }
            const param = try self.addNode(.{
                .tag = .parameter,
                .main_token = param_name,
                .data = .{ .parameter = .{
                    .name = param_name,
                    .type = param_type,
                    .default_value = .invalid,
                } },
            });
            try addNodeToList(&params, param, self.gpa);
            if (self.tokenTag(self.tok_i) == .comma) {
                self.skipToken();
            } else {
                break;
            }
        }
    }

    try self.expectToken(.colon);
    const body = try self.parseSuite();
    const params_index = try self.finalizeNodeList(&params);

    const func_node = try self.addNode(.{
        .tag = .function,
        .main_token = func_tok,
        .data = .{ .function = .{
            .name = func_tok,
            .params = params_index,
            .return_type = .invalid,
            .body = body,
            .flags = .{},
        } },
    });

    return try self.addNode(.{
        .tag = .lambda,
        .main_token = func_tok,
        .data = .{ .lambda = .{ .function = func_node } },
    });
}

fn parseType(self: *Parse) Error!Node.Index {
    const main_type = self.nextToken();
    var generic_types: Node.Index = .invalid;
    var is_nullable = false;

    if (self.tokenTag(self.tok_i) == .bracket_open) {
        self.skipToken();
        var types = try self.makeNodeList();
        while (self.tokenTag(self.tok_i) != .bracket_close and self.tokenTag(self.tok_i) != .eof) {
            const t = try self.parseType();
            try addNodeToList(&types, t, self.gpa);
            if (self.tokenTag(self.tok_i) == .comma) {
                self.skipToken();
            }
        }
        try self.expectToken(.bracket_close);
        generic_types = try self.finalizeNodeList(&types);
    }

    if (self.tokenTag(self.tok_i) == .question_mark) {
        self.skipToken();
        is_nullable = true;
    }

    return try self.addNode(.{
        .tag = .type,
        .main_token = main_type,
        .data = .{ .type = .{
            .main_type = main_type,
            .generic_types = generic_types,
            .is_nullable = is_nullable,
        } },
    });
}

fn binaryOpPrecedence(tag: Token.Tag) ?i32 {
    return switch (tag) {
        .@"or" => 10,
        .@"and" => 20,
        .not => 25,
        .equal_equal, .bang_equal, .less, .less_equal, .greater, .greater_equal, .is, .in => 30,
        .pipe => 40,
        .caret => 50,
        .ampersand => 60,
        .less_less, .greater_greater => 70,
        .plus, .minus => 80,
        .star, .slash, .percent => 90,
        .star_star => 100,
        else => null,
    };
}

fn tokenToBinaryOp(tag: Token.Tag) Node.BinaryOp.Op {
    return switch (tag) {
        .plus => .add,
        .minus => .sub,
        .star => .mul,
        .slash => .div,
        .percent => .mod,
        .star_star => .power,
        .less_less => .shl,
        .greater_greater => .shr,
        .ampersand => .bit_and,
        .pipe => .bit_or,
        .caret => .bit_xor,
        .equal_equal => .equal,
        .bang_equal => .not_equal,
        .less => .less,
        .less_equal => .less_equal,
        .greater => .greater,
        .greater_equal => .greater_equal,
        .in => .in,
        .is => .is,
        // this doesn't seem right?
        else => .add,
    };
}

fn expectToken(self: *Parse, tag: Token.Tag) Error!void {
    if (self.tokenTag(self.tok_i) != tag) {
        try self.warnExpected(tag);
    } else {
        self.skipToken();
    }
}

fn makeNodeList(self: *Parse) Error!std.ArrayList(Node.Index) {
    return try std.ArrayList(Node.Index).initCapacity(self.gpa, 4);
}

fn addNodeToList(list: *std.ArrayList(Node.Index), node: Node.Index, gpa: Allocator) Error!void {
    try list.append(gpa, node);
}

fn finalizeNodeList(self: *Parse, list: *std.ArrayList(Node.Index)) Error!Node.Index {
    const index: Node.Index = @enumFromInt(self.extra_data.items.len);
    try self.extra_data.appendSlice(self.gpa, @ptrCast(list.items));
    list.deinit(self.gpa);
    return index;
}

fn parseSuite(self: *Parse) Error!Node.Index {
    const indent_tok = self.nextToken();
    if (self.tokenTag(indent_tok) != .indent) {
        try self.warnExpected(.indent);
    }

    var statements = try self.makeNodeList();
    defer statements.deinit(self.gpa);

    while (self.tokenTag(self.tok_i) != .dedent and self.tokenTag(self.tok_i) != .eof) {
        const stmt = try self.parseStatement();
        try addNodeToList(&statements, stmt, self.gpa);
    }

    if (self.tokenTag(self.tok_i) == .dedent) {
        self.skipToken();
    }

    const statements_index = try self.finalizeNodeList(&statements);
    return try self.addNode(.{
        .tag = .suite,
        .main_token = indent_tok,
        .data = .{ .suite = .{ .statements = statements_index } },
    });
}

fn parseStatement(self: *Parse) Error!Node.Index {
    const tag = self.tokenTag(self.tok_i);
    switch (tag) {
        .@"if" => return self.parseIf(),
        .@"while" => return self.parseWhile(),
        .@"for" => return self.parseFor(),
        .@"return" => return self.parseReturn(),
        .@"break" => {
            self.skipToken();
            return try self.addNode(.{
                .tag = .@"break",
                .main_token = self.tok_i - 1,
                .data = .{ .none = {} },
            });
        },
        .@"continue" => {
            self.skipToken();
            return try self.addNode(.{
                .tag = .@"continue",
                .main_token = self.tok_i - 1,
                .data = .{ .none = {} },
            });
        },
        .pass => {
            self.skipToken();
            return try self.addNode(.{
                .tag = .pass,
                .main_token = self.tok_i - 1,
                .data = .{ .none = {} },
            });
        },
        .match => return self.parseMatch(),
        .assert => return self.parseAssert(),
        else => return self.parseExpressionOrAssignment(),
    }
}

fn parseIf(self: *Parse) Error!Node.Index {
    const if_tok = self.nextToken();
    const condition = try self.parseExpression();
    try self.expectToken(.colon);
    const then_branch = try self.parseSuite();

    var else_branch: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .@"else") {
        self.skipToken();
        try self.expectToken(.colon);
        else_branch = try self.parseSuite();
    } else if (self.tokenTag(self.tok_i) == .elif) {
        else_branch = try self.parseIf();
    }

    return try self.addNode(.{
        .tag = .@"if",
        .main_token = if_tok,
        .data = .{ .@"if" = .{
            .condition = condition,
            .then_branch = then_branch,
            .else_branch = else_branch,
        } },
    });
}

fn parseWhile(self: *Parse) Error!Node.Index {
    const while_tok = self.nextToken();
    const condition = try self.parseExpression();
    try self.expectToken(.colon);
    const body = try self.parseSuite();

    return try self.addNode(.{
        .tag = .@"while",
        .main_token = while_tok,
        .data = .{ .@"while" = .{
            .condition = condition,
            .body = body,
        } },
    });
}

fn parseFor(self: *Parse) Error!Node.Index {
    const for_tok = self.nextToken();
    const var_tok = self.nextToken();
    if (self.tokenTag(var_tok) != .identifier) {
        try self.warnExpected(.identifier);
    }
    try self.expectToken(.in);
    const iter = try self.parseExpression();
    try self.expectToken(.colon);
    const body = try self.parseSuite();

    return try self.addNode(.{
        .tag = .@"for",
        .main_token = for_tok,
        .data = .{ .@"for" = .{
            .variable = var_tok,
            .iter = iter,
            .body = body,
        } },
    });
}

fn parseReturn(self: *Parse) Error!Node.Index {
    const return_tok = self.nextToken();
    var value: Node.Index = .invalid;

    if (self.tokenTag(self.tok_i) != .newline and self.tokenTag(self.tok_i) != .eof) {
        value = try self.parseExpression();
    }

    return try self.addNode(.{
        .tag = .@"return",
        .main_token = return_tok,
        .data = .{ .@"return" = .{ .value = value } },
    });
}

fn parseMatch(self: *Parse) Error!Node.Index {
    const match_tok = self.nextToken();
    const expression = try self.parseExpression();
    try self.expectToken(.colon);

    var branches = try self.makeNodeList();
    defer branches.deinit(self.gpa);

    while (self.tokenTag(self.tok_i) != .dedent and self.tokenTag(self.tok_i) != .eof) {
        const branch = try self.parseMatchBranch();
        try addNodeToList(&branches, branch, self.gpa);
    }

    if (self.tokenTag(self.tok_i) == .dedent) {
        self.skipToken();
    }

    const branches_index = try self.finalizeNodeList(&branches);
    return try self.addNode(.{
        .tag = .match,
        .main_token = match_tok,
        .data = .{ .match = .{
            .expression = expression,
            .branches = branches_index,
        } },
    });
}

fn parseMatchBranch(self: *Parse) Error!Node.Index {
    const patterns = try self.parseMatchPatterns();

    var guard: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .@"if") {
        self.skipToken();
        guard = try self.parseExpression();
    }

    try self.expectToken(.colon);
    const body = try self.parseSuite();

    return try self.addNode(.{
        .tag = .match_branch,
        .main_token = self.tok_i - 1,
        .data = .{ .match_branch = .{
            .patterns = patterns,
            .guard = guard,
            .body = body,
        } },
    });
}

fn parseMatchPatterns(self: *Parse) Error!Node.Index {
    var patterns = try self.makeNodeList();
    defer patterns.deinit(self.gpa);

    while (true) {
        const pattern = try self.parsePattern();
        try addNodeToList(&patterns, pattern, self.gpa);

        if (self.tokenTag(self.tok_i) == .comma) {
            self.skipToken();
        } else {
            break;
        }
    }

    return try self.finalizeNodeList(&patterns);
}

fn parsePattern(self: *Parse) Error!Node.Index {
    const tag = self.tokenTag(self.tok_i);
    switch (tag) {
        .underscore => {
            self.skipToken();
            return try self.addNode(.{
                .tag = .pattern,
                .main_token = self.tok_i - 1,
                .data = .{ .pattern = .{
                    .pattern_type = .wildcard,
                    .value = .invalid,
                } },
            });
        },
        else => {
            const value = try self.parseExpression();
            return try self.addNode(.{
                .tag = .pattern,
                .main_token = self.tok_i - 1,
                .data = .{ .pattern = .{
                    .pattern_type = .literal,
                    .value = value,
                } },
            });
        },
    }
}

fn parseAssert(self: *Parse) Error!Node.Index {
    const assert_tok = self.nextToken();
    const condition = try self.parseExpression();

    var message: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .comma) {
        self.skipToken();
        message = try self.parseExpression();
    }

    return try self.addNode(.{
        .tag = .assert,
        .main_token = assert_tok,
        .data = .{ .assert = .{
            .condition = condition,
            .message = message,
        } },
    });
}

fn parseExpressionOrAssignment(self: *Parse) Error!Node.Index {
    const lhs = try self.parseExpression();

    const tag = self.tokenTag(self.tok_i);
    if (isAssignmentOp(tag)) {
        const op = tokenToAssignmentOp(tag);
        self.skipToken();
        const rhs = try self.parseExpression();
        return try self.addNode(.{
            .tag = .assignment,
            .main_token = self.tok_i - 1,
            .data = .{ .assignment = .{
                .target = lhs,
                .value = rhs,
                .op = op,
            } },
        });
    }

    return lhs;
}

fn isAssignmentOp(tag: Token.Tag) bool {
    return switch (tag) {
        .equal,
        .plus_equal,
        .minus_equal,
        .star_equal,
        .star_star_equal,
        .slash_equal,
        .percent_equal,
        .less_less_equal,
        .greater_greater_equal,
        .ampersand_equal,
        .pipe_equal,
        .caret_equal,
        => true,
        else => false,
    };
}

fn tokenToAssignmentOp(tag: Token.Tag) Node.Assignment.Op {
    return switch (tag) {
        .equal => .none,
        .plus_equal => .add,
        .minus_equal => .sub,
        .star_equal => .mul,
        .star_star_equal => .power,
        .slash_equal => .div,
        .percent_equal => .mod,
        .less_less_equal => .shl,
        .greater_greater_equal => .shr,
        .ampersand_equal => .bit_and,
        .pipe_equal => .bit_or,
        .caret_equal => .bit_xor,
        else => .none,
    };
}

fn parseClassBody(self: *Parse) Error!Node.Index {
    const indent_tok = self.nextToken();
    if (self.tokenTag(indent_tok) != .indent) {
        try self.warnExpected(.indent);
    }

    var members = try self.makeNodeList();
    defer members.deinit(self.gpa);

    while (self.tokenTag(self.tok_i) != .dedent and self.tokenTag(self.tok_i) != .eof) {
        const member = try self.parseClassMember();
        if (member != .invalid) {
            try addNodeToList(&members, member, self.gpa);
        }
    }

    if (self.tokenTag(self.tok_i) == .dedent) {
        self.skipToken();
    }

    return try self.finalizeNodeList(&members);
}

fn parseClassMember(self: *Parse) Error!Node.Index {
    const tag = self.tokenTag(self.tok_i);

    switch (tag) {
        .comment => {
            const comment_tok = self.nextToken();
            return try self.addNode(.{
                .tag = .comment,
                .main_token = comment_tok,
                .data = .{ .none = {} },
            });
        },
        .newline => {
            self.skipToken();
            return .invalid;
        },
        .func => {
            return self.parseFunction();
        },
        .signal => {
            return self.parseSignal();
        },
        .@"enum" => {
            return self.parseEnum();
        },
        .@"const" => {
            return self.parseConstant();
        },
        .@"var" => {
            return self.parseVariable();
        },
        else => {
            try self.warnExpected(.identifier);
            self.skipToken();
            return .invalid;
        },
    }
}

fn parseFunction(self: *Parse) Error!Node.Index {
    const func_tok = self.nextToken();
    const name_tok = self.nextToken();
    if (self.tokenTag(name_tok) != .identifier) {
        try self.warnExpected(.identifier);
    }

    var params = try self.makeNodeList();
    defer params.deinit(self.gpa);

    if (self.tokenTag(self.tok_i) == .paren_open) {
        self.skipToken();
        while (self.tokenTag(self.tok_i) != .paren_close and self.tokenTag(self.tok_i) != .eof) {
            const param = try self.parseParameter();
            try addNodeToList(&params, param, self.gpa);
            if (self.tokenTag(self.tok_i) == .comma) {
                self.skipToken();
            }
        }
        try self.expectToken(.paren_close);
    }

    var return_type: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .minus) {
        self.skipToken();
        if (self.tokenTag(self.tok_i) == .greater) {
            self.skipToken();
            return_type = try self.parseType();
        } else {
            self.tok_i -= 1;
        }
    }

    const flags: Node.Function.FunctionFlags = .{};
    if (self.tokenTag(self.tok_i) == .newline) {
        self.skipToken();
        const body = try self.parseSuite();
        const params_index = try self.finalizeNodeList(&params);
        return try self.addNode(.{
            .tag = .function,
            .main_token = func_tok,
            .data = .{ .function = .{
                .name = name_tok,
                .params = params_index,
                .return_type = return_type,
                .body = body,
                .flags = flags,
            } },
        });
    }

    return .invalid;
}

fn parseParameter(self: *Parse) Error!Node.Index {
    const name_tok = self.nextToken();
    if (self.tokenTag(name_tok) != .identifier) {
        try self.warnExpected(.identifier);
    }

    var param_type: Node.Index = .invalid;
    var default_value: Node.Index = .invalid;

    if (self.tokenTag(self.tok_i) == .colon) {
        self.skipToken();
        param_type = try self.parseType();
    }

    if (self.tokenTag(self.tok_i) == .equal) {
        self.skipToken();
        default_value = try self.parseExpression();
    }

    return try self.addNode(.{
        .tag = .parameter,
        .main_token = name_tok,
        .data = .{ .parameter = .{
            .name = name_tok,
            .type = param_type,
            .default_value = default_value,
        } },
    });
}

fn parseSignal(self: *Parse) Error!Node.Index {
    const signal_tok = self.nextToken();
    const name_tok = self.nextToken();
    if (self.tokenTag(name_tok) != .identifier) {
        try self.warnExpected(.identifier);
    }

    var params = try self.makeNodeList();
    defer params.deinit(self.gpa);

    if (self.tokenTag(self.tok_i) == .paren_open) {
        self.skipToken();
        while (self.tokenTag(self.tok_i) != .paren_close and self.tokenTag(self.tok_i) != .eof) {
            const param = try self.parseParameter();
            try addNodeToList(&params, param, self.gpa);
            if (self.tokenTag(self.tok_i) == .comma) {
                self.skipToken();
            }
        }
        try self.expectToken(.paren_close);
    }

    if (self.tokenTag(self.tok_i) == .newline) {
        self.skipToken();
    }

    const params_index = try self.finalizeNodeList(&params);
    return try self.addNode(.{
        .tag = .signal,
        .main_token = signal_tok,
        .data = .{ .signal = .{
            .name = name_tok,
            .params = params_index,
        } },
    });
}

fn parseEnum(self: *Parse) Error!Node.Index {
    const enum_tok = self.nextToken();
    const name_tok = self.nextToken();
    if (self.tokenTag(name_tok) != .identifier) {
        try self.warnExpected(.identifier);
    }

    var values = try self.makeNodeList();
    defer values.deinit(self.gpa);

    if (self.tokenTag(self.tok_i) == .brace_open) {
        self.skipToken();
        while (self.tokenTag(self.tok_i) != .brace_close and self.tokenTag(self.tok_i) != .eof) {
            const value_tok = self.nextToken();
            if (self.tokenTag(value_tok) != .identifier) {
                try self.warnExpected(.identifier);
            }

            var value_expr: Node.Index = .invalid;
            if (self.tokenTag(self.tok_i) == .equal) {
                self.skipToken();
                value_expr = try self.parseExpression();
            }

            const value = try self.addNode(.{
                .tag = .enum_value,
                .main_token = value_tok,
                .data = .{ .enum_value = .{
                    .name = value_tok,
                    .value = value_expr,
                } },
            });
            try addNodeToList(&values, value, self.gpa);

            if (self.tokenTag(self.tok_i) == .comma) {
                self.skipToken();
            }
        }
        try self.expectToken(.brace_close);
    }

    if (self.tokenTag(self.tok_i) == .newline) {
        self.skipToken();
    }

    const values_index = try self.finalizeNodeList(&values);
    return try self.addNode(.{
        .tag = .@"enum",
        .main_token = enum_tok,
        .data = .{ .@"enum" = .{
            .name = name_tok,
            .values = values_index,
        } },
    });
}

fn parseConstant(self: *Parse) Error!Node.Index {
    const const_tok = self.nextToken();
    const name_tok = self.nextToken();
    if (self.tokenTag(name_tok) != .identifier) {
        try self.warnExpected(.identifier);
    }

    var var_type: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .colon) {
        self.skipToken();
        var_type = try self.parseType();
    }

    var value: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .equal) {
        self.skipToken();
        value = try self.parseExpression();
    }

    if (self.tokenTag(self.tok_i) == .newline) {
        self.skipToken();
    }

    return try self.addNode(.{
        .tag = .constant,
        .main_token = const_tok,
        .data = .{ .constant = .{
            .name = name_tok,
            .type = var_type,
            .value = value,
        } },
    });
}

fn parseVariable(self: *Parse) Error!Node.Index {
    const var_tok = self.nextToken();
    const name_tok = self.nextToken();
    if (self.tokenTag(name_tok) != .identifier) {
        try self.warnExpected(.identifier);
    }

    var var_type: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .colon) {
        self.skipToken();
        var_type = try self.parseType();
    }

    var value: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .equal) {
        self.skipToken();
        value = try self.parseExpression();
    }

    const flags: Node.Variable.VariableFlags = .{};
    if (self.tokenTag(self.tok_i) == .newline) {
        self.skipToken();
    }

    return try self.addNode(.{
        .tag = .variable,
        .main_token = var_tok,
        .data = .{ .variable = .{
            .name = name_tok,
            .type = var_type,
            .value = value,
            .flags = flags,
        } },
    });
}

fn parseAnnotation(self: *Parse) Error!Node.Index {
    const name_tok = self.nextToken();

    var args: Node.Index = .invalid;
    if (self.tokenTag(self.tok_i) == .paren_open) {
        self.skipToken();
        var arg_list = try self.makeNodeList();
        while (self.tokenTag(self.tok_i) != .paren_close and self.tokenTag(self.tok_i) != .eof) {
            const arg = try self.parseExpression();
            try addNodeToList(&arg_list, arg, self.gpa);
            if (self.tokenTag(self.tok_i) == .comma) {
                self.skipToken();
            }
        }
        try self.expectToken(.paren_close);
        args = try self.finalizeNodeList(&arg_list);
    }

    return try self.addNode(.{
        .tag = .annotation,
        .main_token = name_tok,
        .data = .{ .annotation = .{
            .arguments = args,
        } },
    });
}

fn addNode(p: *Parse, elem: Ast.Node) Allocator.Error!Node.Index {
    const result: Node.Index = @enumFromInt(p.nodes.len);
    try p.nodes.append(p.gpa, elem);
    return result;
}

fn skipToken(self: *Parse) void {
    self.tok_i += 1;
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
    // zig branchHint(.cold) 's the warn paths
    try self.warn(.{
        .tag = .expected_token,
        .token = self.tok_i,
        .extra = .{ .expected_tag = expected_tag },
    });
}

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
