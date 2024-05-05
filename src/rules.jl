using MacroTools
using MacroTools: isexpr, postwalk

export Rule, @rule, emits

"""
Rule is an abstract supertype for all rules.
"""
abstract type Rule end


"""
    emits(rule::Type)

Returns a Tuple of the types which `rule` is declared to emit.
"""
emits(rule) = ()


function exttract_rule_declarations(body::Expr)
    @assert isexpr(body, :block)
    has_decls = false
    forward_triggers = []
    custom_install = false
    decl_expr = nothing
    # If the first non-LineNumberNode is a RULE_DECLARATION
    # expression, then process it:
    for expr in body.args
        if isline(expr)
            continue
        end
        if isexpr(expr, :call) && expr.args[1] == :RULE_DECLARATIONS
            decl_expr = expr
            has_decls = true
            for decl in expr.args
                if !isexpr(decl, :call)
                    continue
                end
                if decl.args[1] == :CUSTOM_INSTALL
                    custom_install = true
                elseif decl.args[1] == :FORWARD_TRIGGERS
                    forward_triggers = decl.args[2:end]
                end
            end
        end
        break
    end
    return (has_decls = has_decls,
            decl_expr = decl_expr,
            forward_triggers = forward_triggers,
            custom_install = custom_install)
end


"""
    @rule Rulename(a::A_Type, b::B_Type, ...) begin ... end

Defines a rule named `Rulename`.  A singleton type named `Rulename`
will be defined to represent the rule.  An [`install`](@ref) method is
defined for that type which can be used to add the necessary nodes and
connections to a Rete to implement the rule.

The default supertype of a rule struct is `Rule`.  When it is
desirable to group rules together, one can define an abstract type
that is a type descendant of Rule and use that as a dotted prefix to
`RuleName`.  The `RuleName` in the @rule invocation is
`MyGroup.MyRule` then the supertype of MyRule will be MyGroup, rather
than [`Rule`](@ref).

A rule can have arbitrarily many parameters.  The parameter list can
also include clauses with no variable name.  Such clauses identify the
types of facts that the rule might assert.  Memory nodes for these
types will be added to the Rete if not already present.

The first expression of the rule can be call-like expression of
RULE_DECLARATION.  Its "parameters" can be declarations of one of the
forms

` `FORWARD_TRIGGERS(argument_names...)`

Only the inputs for the specified argument names will serve as forward
triggers.  For backward compatibility, if there is no RULE_DECLARATION
expression then all inputs are forward triggers.


` `CUSTOM_INSTALL()`

No `install` method will be automatically generated.  The developer
must implement an `install` method for this rule.
    """
macro rule(call, body)
    if !isexpr(call, :call)
        error("The first expression of rule should look like a call")
    end
    rule_decls = exttract_rule_declarations(body)
    supertype = Rule
    rule_name = call.args[1]
    if isexpr(rule_name, :(.))
        supertype = rule_name.args[1]
        rule_name = rule_name.args[2].value  # Unwrap QuoteNode
    end
    rule_name_str = string(rule_name)
    input_exprs = []
    output_types = []
    for arg in call.args[2:end]
        @assert isexpr(arg, :(::))
        if length(arg.args) == 1
            push!(output_types, arg.args[1])
        elseif length(arg.args) == 2
            push!(input_exprs, arg)
        else
            error("Unrecognized rule parameter expression $arg")
        end
    end
    sort!(output_types)
    input_var(i) = input_exprs[i].args[1]
    input_type(i) = input_exprs[i].args[2]
    input_connections = map(1:length(input_exprs)) do i
        :(connect(ensure_IsaMemoryNode(root, $(input_type(i))),
                  join, $i))
    end
    output_memories = map(t -> :(ensure_IsaMemoryNode(root, $t)),
                          output_types)
    function input_arg_to_type(argname)
        for ie in input_exprs
            if ie.args[1] == argname
                return ie.args[2]
            end
        end
        error("There is no rule parameter named $argname " *
            "matching a specified FORWARD_TRIGGER")
    end
    forward_triggers = []
    if rule_decls.has_decls
        # remove the declarations expression from body:
        body.args = filter(body.args) do item
            item != rule_decls.decl_expr
        end
        # Create forward triggers as specified
        for trigger_arg in rule_decls.forward_triggers
            push!(forward_triggers,
                  :(add_forward_trigger(
                      join,
                      ensure_IsaMemoryNode(
                          root,
                          $(input_arg_to_type(trigger_arg))))))
        end
    else
        # No RULE_DECLARATIONS, implement legacy behavior that all
        # inputs are forward triggers.
        for ie in input_exprs
            push!(forward_triggers,
                  :(add_forward_trigger(
                      join,
                      ensure_IsaMemoryNode(root, $(ie.args[2])))))
        end
    end
    arg_decls = map(1:length(input_exprs)) do i
        :($(input_var(i))::$(input_type(i)))
    end
    # Add the node argument to all calls to emit:
    body = postwalk(body) do e
        if isexpr(e, :call) && e.args[1] == :emit
            Expr(:call, :emit, :node, e.args[2])
        else
            e
        end
    end
    install_method = []
    if !rule_decls.custom_install
        push!(install_method,
              :(function Rete.install(root::ReteRootNode, ::$rule_name)
                    join = JoinNode($rule_name_str,
                                    $(length(input_exprs)),
                                    $rule_name())
                    $(input_connections...)
                    $(output_memories...)
                    $(forward_triggers...)
                    connect(join, root)
                end))
    end
    esc(quote
        struct $rule_name <: $supertype end
        Rete.emits(::Type{$rule_name}) = tuple($(output_types...))
        $(install_method...)
        function(::$rule_name)(node::JoinNode, $(arg_decls...))
            $body
        end
    end)
end

#=
@rule MyRule(a::Char, b::Int, c::Symbol, ::Tuple) begin
    emit((a, b, c))
end
=#

