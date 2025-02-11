using MacroTools
using MacroTools: isexpr, postwalk

export Rule, @rule, emits

"""
Rule is an abstract supertype for all rules.
"""
abstract type Rule end


install(root::T, rule::Rule) where T =
    install(CanInstallRulesTrait(T), root, (typeof(rule)))


"""
    emits(rule::Type)

Returns a Tuple of the types which `rule` is declared to emit.
"""
emits(rule) = ()


function extract_rule_declarations(body::Expr)
    @assert isexpr(body, :block)
    has_decls = false
    forward_triggers = []
    custom_install = false
    decl_expr = nothing
    # If the first non-LineNumberNode is a RULE_DECLARATIONS
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
that is a type descendant of [`Rule`](@ref) and use that as a dotted
prefix to `RuleName`.  The `RuleName` in the @rule invocation is
`MyGroup.MyRule` then the supertype of MyRule will be `MyGroup`, rather
than [`Rule`](@ref).

A rule can have arbitrarily many parameters.  The parameter list can
also include clauses with no variable name.  Such clauses identify the
types of facts that the rule might assert.  Memory nodes for these
types will be added to the Rete if not already present.  They will be
added by the automatically generated `install` method.  See
CUSTOM_INSTALL below.  There is no enforcement that all types that are
emitted by the rule are listed here, but various introspective tools,
as well as proper rule installation depend on this.

The body of the `@rule` expression implements the behavior of the
rule.  It can perform any tests that are necessary to determine which,
if any facts should be asserted.  This code is included in a function
that has the same name as the rule itself.  This function is used as
the `join_function` of the [`JoinNode`](@ref) that implements the
rule.  The function declares a keyword argument named `emit` whose
default value calls [`emit`](@ref). For testing and debugging
purposes, the rule function can be invoked from the Julia REPL, perhaps
passing `emit=println` to try the rule function independent of the
rest of the network.

Within the body, `@reject`, `@rejectif` and `@continueif` can be used.

 `@reject` will exit the rule body unconditionally and issue a debug
log message.

The other two take a conditional expression.

`@rejectif` will exit the rule body and log a message if the condition
succeeds.

`@continueif` will exit and log if the condition returns false.

The first expression of the rule can be a call-like expression of
RULE_DECLARATIONS.  Its "parameters" can be declarations of one of the
forms

` `FORWARD_TRIGGERS(argument_names...)`

Only the inputs for the specified argument names will serve as forward
triggers.  For backward compatibility, if there is no `RULE_DECLARATIONS`
expression then all inputs are forward triggers.

Note that if a `RULE_DECLARATIONS` clause is included then any forwarde
triggers must be explicitly declared.

` `CUSTOM_INSTALL()`

No `install` method will be automatically generated.  The developer
must implement an `install` method for this rule.
    """
macro rule(call, body)
    prd = ParsedRuleDefinition(__source__, __module__, call, body)
    esc(quote
            struct $(prd.rule_name) <: $(prd.rule_supertype) end
            Rete.emits(::Type{$(prd.rule_name)}) = tuple($((prd.output_types)...))
            $(compose_install_method(prd)...)
            $(compose_join_function(prd))
        end)
end

#=
@rule MyRule(a::Char, b::Int, c::Symbol, ::Tuple) begin
    emit((a, b, c))
end
=#

