const lexer = @import("./gdscript_parser/lexer.zig");
pub const Lexer = lexer.Lexer;
pub const Token = lexer.Token;
pub const Tag = Token.Tag;

test {
    _ = lexer;
}
