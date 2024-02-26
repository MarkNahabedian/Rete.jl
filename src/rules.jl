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
"""
macro rule(call, body)
    if !isexpr(call, :call)
        error("The first expression of rule should look like a call")
    end
    rule_name = call.args[1]
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
        struct $rule_name <: Rule end

        function install(root::BasicReteNode, ::$rule_name)
            join = JoinNode($rule_name_str, $rule_name())
            connect_a(ensure_IsaMemoryNode(root, $a_type), join)
            connect_b(ensure_IsaMemoryNode(root, $b_type), join)
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

