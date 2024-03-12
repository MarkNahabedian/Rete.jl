using MacroTools
using MacroTools: isexpr, postwalk

export Rule, @rule

"""
Rule is an abstract supertype for all rules.
"""
abstract type Rule end


"""
    @rule Rulename(a::A_Type, b::B_Type) begin ... end

Defines a rule named `Rulename`.  A singleton type named `Rulename`
will be defined to represent the rule.  An `install` method is defined
which can be used to add the nodes necessary to implement the rule to
a Rete.

The default supertype of a rule struct is `Rule`.  When it is
desirable to group rules together, one can define an abstract type
that is a type descendant of Rule and use that as a dotted prefix to
`RuleName`.  The the `RuleName` in the @rule invocation is
`MyGroup.MyRule` then the supertype of MyRule will be MyGroup, rather
than Rule.
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
    @assert isexpr(call.args[2], :(::))
    @assert isexpr(call.args[3], :(::))
    a_var = call.args[2].args[1]
    a_type = call.args[2].args[2]
    b_var = call.args[3].args[1]
    b_type = call.args[3].args[2]
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
            join = JoinNode($rule_name_str, $rule_name())
            connect(ensure_IsaMemoryNode(root, $a_type), join, 1)
            connect(ensure_IsaMemoryNode(root, $b_type), join, 2)
            connect(join, root)
        end

        function(::$rule_name)(node::JoinNode,
                               $a_var::$a_type,
                               $b_var::$b_type)
            $body
        end
    end)
end

#=
@rule MyRule(a::Char, b::Int) begin
    emit((a, b))
end
=#

