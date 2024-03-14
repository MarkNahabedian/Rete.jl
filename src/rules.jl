using MacroTools
using MacroTools: isexpr, postwalk

export Rule, @rule

"""
Rule is an abstract supertype for all rules.
"""
abstract type Rule end


"""
    @rule Rulename(a::A_Type, b::B_Type, ...) begin ... end

Defines a rule named `Rulename`.  A singleton type named `Rulename`
will be defined to represent the rule.  An `install` method is defined
for that type which can be used to add the necessary nodes and
connections to a Rete to implement the rule.

The default supertype of a rule struct is `Rule`.  When it is
desirable to group rules together, one can define an abstract type
that is a type descendant of Rule and use that as a dotted prefix to
`RuleName`.  The the `RuleName` in the @rule invocation is
`MyGroup.MyRule` then the supertype of MyRule will be MyGroup, rather
than Rule.

A rule an have arbitrarily many parameters.  The parameter list can
also include clauses with no variable name.  Such clauses identify the
types of facts that the rule might assert.  Memory nodes for these
types will be added to the Rete if not already present.
"""
macro rule(call, body)
    if !isexpr(call, :call)
        error("The first expression of rule should look like a call")
    end
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
    input_var(i) = input_exprs[i].args[1]
    input_type(i) = input_exprs[i].args[2]
    input_connections = map(1:length(input_exprs)) do i
        :(connect(ensure_IsaMemoryNode(root, $(input_type(i))),
                  join, $i))
    end
    output_memories = map(t -> :(ensure_IsaMemoryNode(root, $t)),
                          output_types)
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
    
    esc(quote
        struct $rule_name <: $supertype end

        function Rete.install(root::BasicReteNode, ::$rule_name)
            join = JoinNode($rule_name_str,
                            $(length(input_exprs)),
                            $rule_name())
            $(input_connections...)
            $(output_memories...)
            connect(join, root)
        end

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

