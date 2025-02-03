
struct ParsedRuleDefinition
    source
    _module
    rule_name::Symbol
    rule_supertype::Symbol
    call  # ::Expr
    body  # ::Expr
    input_exprs
    output_types
    has_decls::Bool
    decl_expr # ::Expr
    forward_triggers::Vector
    custom_install::Bool
    
    function  ParsedRuleDefinition(__source__, __module__, call, body)
        if !isexpr(call, :call)
            error("The first expression of rule should look like a call")
        end
        rule_decls = extract_rule_declarations(body)
        if rule_decls.has_decls
            # remove the declarations expression from body:
            body.args = filter(body.args) do item
                item != rule_decls.decl_expr
            end
        end
        rule_supertype = :Rule
        rule_name = call.args[1]
        if isexpr(rule_name, :(.))
            rule_supertype = rule_name.args[1]
            rule_name = rule_name.args[2].value  # Unwrap QuoteNode
        end
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
        
        new(__source__, __module__,
            rule_name, rule_supertype, call, body,
            input_exprs,
            output_types,
            rule_decls.has_decls,
            rule_decls.decl_expr,
            rule_decls.forward_triggers,
            rule_decls.custom_install)
    end
end

input_var(prd::ParsedRuleDefinition, index) = prd.input_exprs[index].args[1]
input_type(prd::ParsedRuleDefinition, index) = prd.input_exprs[index].args[2]

function input_arg_to_type(prd::ParsedRuleDefinition, argname)
    for ie in prd.input_exprs
        if ie.args[1] == argname
            return ie.args[2]
        end
    end
    error("There is no rule parameter named $argname " *
        "matching a specified FORWARD_TRIGGERS")
end

function compose_install_method(prd::ParsedRuleDefinition)
    input_connections = map(1:length(prd.input_exprs)) do i
        :(connect(ensure_memory_node(root, $(input_type(prd, i))),
                  join, $i))
    end
    output_memories = map(t -> :(ensure_memory_node(root, $t)),
                          prd.output_types)
    forward_triggers = []
    if prd.has_decls
        # Create forward triggers as specified
        for trigger_arg in prd.forward_triggers
            push!(forward_triggers,
                  :(add_forward_trigger(
                      join,
                      ensure_memory_node(
                          root,
                          $(input_arg_to_type(prd, trigger_arg))))))
        end
    else
        # No RULE_DECLARATIONS, implement legacy behavior that all
        # inputs are forward triggers.
        for ie in prd.input_exprs
            push!(forward_triggers,
                  :(add_forward_trigger(
                      join,
                      ensure_memory_node(root, $(ie.args[2])))))
        end
    end
    install_method = []
    if !prd.custom_install
        push!(install_method,
              :(function Rete.install(::CanInstallRulesTrait,
                                      root, ::$(prd.rule_name))
                    join = JoinNode($(string(prd.rule_name)),
                                    $(length(prd.input_exprs)),
                                    $(prd.rule_name)())
                    $(input_connections...)
                    $(output_memories...)
                    $(forward_triggers...)
                    connect(join, root)
                end))
    end
    install_method
end

function compuse_join_function(prd::ParsedRuleDefinition)
    arg_decls = map(1:length(prd.input_exprs)) do i
        :($(input_var(prd, i))::$(input_type(prd, i)))
    end
    :(function(::$(prd.rule_name))(__NODE__::JoinNode,
                                   $(arg_decls...);
                                   emit = fact -> emit(__NODE__, fact))
          $(prd.body)
      end)
end


#=

using Rete
using Rete: ParsedRuleDefinition, input_var, input_type, compose_install_method, compuse_join_function

rule_str = raw"""
@rule ThreeInputRule(a::Char, b::Int, c::Char, ::String) begin
    if a != c
        emit("$a$b$c")
    end
end
"""

rule_expr = Meta.parse(rule_str)

prd = ParsedRuleDefinition(nothing, nothing, rule_expr.args[3], rule_expr.args[4])

input_var(prd, 1) == :a
input_var(prd, 2) == :b
input_type(prd, 1) == :Char
input_type(prd, 2) == :Int

compose_install_method(prd)

compuse_join_function(prd)

=#

