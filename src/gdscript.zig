const lexer = @import("./gdscript_parser/lexer.zig");
pub const Lexer = lexer.Lexer;
pub const Token = lexer.Token;
pub const Tag = Token.Tag;
pub const Ast = @import("./gdscript_parser/Ast.zig");

test {
    _ = lexer;
    _ = Ast;
}
