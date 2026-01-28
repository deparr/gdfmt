const Node = struct {
    tag: enum {},
    annotations: []*AnnotationNode,
    next: *Node,
};

/// if not specifiied, a node inherits from Node
const Variant = union(enum) {};
const Resource = struct {};
const DataType = struct {};

const ExpressionNode = struct { reduced: bool, is_constant: bool, reduced_value: Variant };

const AnnotationNode = struct {
    name: []const u8,
    arguments: []*ExpressionNode,
    info: *struct { info: enum {} },
};

// : ExpressionNode
const ArrayNode = struct {
    elements: []*ExpressionNode,
};

const AssertNode = struct {
    condition: *ExpressionNode,
    message: *ExpressionNode,
};

const AssignableNode = struct {
    identifier: *IdentifierNode,
    initalizer: *ExpressionNode,
    datatype_specifier: *TypeNode,
    infer_datatype: bool,
    usages: i32,
};

// : ExpressionNode
const AssignmentNode = struct {
    const Operation = enum { none, add, sub, mul, div, mod, power, shl, fhr, bit_and, bit_or, bit_xor };
    operation: Operation,
    variant_op: Variant,
    assignee: *ExpressionNode,
    assigned_value: *ExpressionNode,
    use_conversion_assign: bool,
};

// : ExpressionNode
const AwaitNode = struct {
    to_await: *ExpressionNode,
};

const BinaryOpNode = struct {
    const OpType = enum { add, sub, mul, div, mod, power, shl, shr, bit_and, bit_or, bit_xor, log_and, log_or, content_test, equal, not_equal, less, less_equal, greater, greater_equal };
    operation: OpType,
    lhs: *ExpressionNode,
    rhs: *ExpressionNode,
};
const BreakNode = struct {};
const BreakPointNode = struct {};

// : ExpressionNode
const CallNode = struct {
    callee: *ExpressionNode,
    arguments: []*ExpressionNode,
    function_name: []const u8,
    is_super: bool,
    is_static: bool,
};

// : ExpressionNode
const CastNode = struct {
    operand: *ExpressionNode,
    cast_type: *TypeNode,
};

const EnumNode = struct {
    const Value = struct {
        identifier: *IdentifierNode,
        custom_value: *ExpressionNode,
        parent_enum: *EnumNode,
        //...
    };

    identifier: *IdentifierNode,
    values: []Value,
    dictionary: Variant,
};

const ClassNode = struct {
    const Member = struct {
        const Type = enum { undefined, class, constant, function, signal, variable, @"enum", enum_value, group };
        type: Type,
        data: union { m_class: *ClassNode, constant: *ConstantNode, function: *FunctionNode, signal: *SignalNode, variable: *VariableNode, m_enum: *EnumNode, annotation: *AnnotationNode },
    };
    identifier: *IdentifierNode,
    members: []Member,
    outer: *ClassNode,
    //... LOTS of other stuff
};

// : AssignableNode
const ConstantNode = struct {};

const ContinueNode = struct {};

// : ExpressionNode
const DictionaryNode = struct {
    const Pair = struct { key: *ExpressionNode, value: *ExpressionNode };
    elements: []Pair,
    style: enum { lua_table, python_dict },
};

const ForNode = struct {
    variable: *IdentifierNode,
    datatype_specifier: *TypeNode,
    list: *ExpressionNode,
    loop: *SuiteNode,
};

const FunctionNode = struct {
    identifier: *IdentifierNode,
    parameters: []*ParameterNode,
    rest_parameter: *ParameterNode,
    return_type: *TypeNode,
    body: *SuiteNode,
    is_abstract: bool,
    is_static: bool,
    source_lambda: *LambdaNode,
    default_arg_values: []Variant,
};

// : ExpressionNode
const GetNodeNode = struct {
    full_path: []const u8,
    use_dollar: bool,
};

// : ExpressionNode
const IdentifierNode = struct {
    name: []const u8,
    suite: *SuiteNode, // block in which  the ident is used
    source: union(enum) {},
    source_function: *FunctionNode,
};

const IfNode = struct {
    condition: *ExpressionNode,
    consequent: *SuiteNode,
    alternate: *SuiteNode,
};

// : ExpressionNode
const LambdaNode = struct {
    function: *FunctionNode,
    parent_function: *FunctionNode,
    parent_lambda: *LambdaNode,
    captures: []*IdentifierNode,
    use_self: bool,
};

// : ExpressionNode
const LiteralNode = struct { value: Variant };

const MatchNode = struct { patterns: []*PatternNode, block: *SuiteNode, guard_body: *SuiteNode, has_wildcard: bool };

// : AssignableNode
const ParameterNode = struct {};

const PassNode = struct {};

const PatternNode = struct {
    const Pair = struct { key: *ExpressionNode, value_pattern: *PatternNode };
    pattern_type: union(enum) { literal: *LiteralNode, expression: *ExpressionNode, bind: *IdentifierNode, array, dictionary, rest, wildcard },
    array: []*PatternNode,
    rest_used: bool,
    dictionary: []Pair,
    // hashmap<stringname, identifiernode*>
    binds: Variant,
};

const PreloadNode = struct { path: *ExpressionNode, resolved_path: []const u8, resource: *Resource };

const ReturnNode = struct {
    return_value: *ExpressionNode,
    void_return: bool,
};

// : ExpressionNode
const SelfNode = struct { current_class: *ClassNode };

const SignalNode = struct { identifier: *IdentifierNode, parameters: []*ParameterNode };

// : ExpressionNode
const SubscriptNode = struct {
    base: *ExpressionNode,
    data: union(enum) { index: *ExpressionNode, attribute: *IdentifierNode },
};

const SuiteNode = struct {
    const Local = union(enum) { undefined, constant: *ConstantNode, variable: *VariableNode, parameter: *ParameterNode, for_variable, bind: *IdentifierNode };
    parent_block: *SuiteNode,
    statements: []*Node,
    empty: Local,
    locals: []Local,
    parent_function: *FunctionNode,
    parent_if: *IfNode,
    has_return: bool,
    has_continue: bool,
    has_unreachable_code: bool,
    is_in_loop: bool,
};

// : ExpressionNode
const TernaryOpNode = struct {
    condition: *ExpressionNode,
    consequent: *ExpressionNode,
    alternate: *ExpressionNode,
};

const TypeNode = struct {
    type_chain: []*IdentifierNode,
    container_types: []*TypeNode,
};

// : ExpressionNode
const TypeTestNode = struct {
    operand: *ExpressionNode,
    test_type: *TypeNode,
    test_datatype: DataType,
};

// : ExpressionNode
const UnaryOpNode = struct {
    operation: enum { pos, neg, complent, log_not },
    operand: *ExpressionNode,
};

// : AssignableNode
const VariableNode = struct {
    property: enum { none, @"inline", setget },
    set_info: union { setter: *FunctionNode, setter_pointer: *IdentifierNode },
    setter_parameter: *IdentifierNode,
    get_info: union { getter: *FunctionNode, getter_pointer: *IdentifierNode },
};

const WhileNode = struct {
    condition: *ExpressionNode,
    loop: *SuiteNode,
};
