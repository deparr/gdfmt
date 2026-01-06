const std = @import("std");

const Ast = @This();
const Token = struct{};

source: [:0]const u8,

tokens: []Token,
nodes: []Node,
errors: []const Error,
