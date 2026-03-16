# gdfmt Parser Implementation Plan

## Overview
A GDScript 4.x parser implementation for the gdfmt formatter.

**Constraints:**
- GDScript 4.x only
- Abort on syntax errors (no error recovery)
- Store comments in AST
- Formatter re-computes whitespace

---

## Implementation Plan

### Phase 1: Complete AST Node Data Structures
**Goal**: Define what data each AST node holds

- Complete `Node.Data` union in `Ast.zig` - one variant per `Node.Tag`
- Include fields for: child nodes, tokens, source spans
- Add comment text storage for `.comment` and `.doc_comment` nodes

### Phase 2: Expression Parser
**Goal**: Parse all GDScript expressions with correct precedence

Implementation order:
1. **Atomics**: literals, identifiers, `self`, `super`, `$` (get_node), `preload`
2. **Postfix**: subscript `[]`, call `()`, member access `.`
3. **Unary**: `-`, `not`, `~`, `@` (cast)
4. **Binary** (by precedence): `**`, then `*`/`/`/`%`, then `+`/`-`, then `<<`/`>>`, then `&`, then `^`, then `|`, then `==`/`<`/.../`is`/`in`, then `not` (lowest), then `and`/`or`
5. **Ternary**: `a if cond else b`
6. **Lambda**: `func(a, b): body`

### Phase 3: Statement Parser  
**Goal**: Parse statements and blocks

1. **Suite/Block**: Handle indent/dedent tokens, collect statements
2. **Control flow**: `if`/`elif`/`else`, `while`, `for`, `match`
3. **Jump statements**: `return`, `break`, `continue`, `pass`, `await`
4. **Assertions**: `assert`

### Phase 4: Class-Level Parser
**Goal**: Parse top-level constructs

1. **Annotations**: Parse `@annotation` and store on following node
2. **Class header**: `class_name`, `extends`
3. **Members**: 
   - Variables (`var`) with types, annotations, `onready`, `setget`
   - Constants (`const`)
   - Functions (`func`) with parameters, return types, body
   - Signals (`signal`)
   - Enums (`enum`)

### Phase 5: Integration & Testing
- Wire parser into `Ast.parse()`
- Add test cases for parsing valid GDScript
- Verify formatter works end-to-end
