
struct PatternVariable
    name::Symbol
end

pattern_matcher(pattern::Any, expression::Any, bindings::Dict) = pattern == expression

function pattern_matcher(pattern::PatternVariable, expression, bindings::Dict)
    if pattern.name in keys(bindings)
        return expression == bindings[pattern.name]
    else
        bindings[pattern.name] = expression
        return true
    end
end

function pattern_matcher(pattern::Expr, expression::Expr, bindings::Dict)
    if !pattern_matcher(pattern.head, expression.head, bindings)
        return false
    end
    pattern_matcher(pattern.args, expression.args, bindings)
end

function pattern_matcher(pattern::Vector, expression::Vector, bindings::Dict)
    if length(pattern) != length(expression)
        return false
    end
    for i in 1:length(pattern)
        if !pattern_matcher(pattern[i], expression[i], bindings)
            return false
        end
    end
    true
end


struct Rewrite
    pattern::Expr
    rewrite_function
end

function (rewrite::Rewrite)(expression)
    bindings = Dict()
    if pattern_matcher(rewrite.pattern, expression, bindings)
        rewrite.rewrite_function(bindings)
    else
        expression
    end
end

function (rewrite::Vector{Rewrite})(expression)
    # Just go with the first match:
    for rw in rewrite
        rewritten = rw(expression)
        if expression != rewritten
            return rewritten
        end
    end
    expression
end


RULE_REWRITERS = [
    Rewrite(Expr(:macrocall, Symbol("@reject")),
            function(bindings)
                quote
                    let
                        params = task_local_storage(:RuleRejectionLoggingParameters)
                        other_params = filter(pairs(params)) do pair
                            !(pair.first in (:group, :location))
                        end
                        @debug("@reject",
                               _group = params.group,
                               _file = $(string(bindings[:linenumbernode].file)),
                               _line = $(bindings[:linenumbernode].line),
                               other_params...)
                        return
                    end
                end
            end),
    Rewrite(Expr(:macrocall, Symbol("@rejectif"),
                 PatternVariable(:linenumbernode),
                 PatternVariable(:predicate)),
            function(bindings)
                quote
                    let
                        params = task_local_storage(:RuleRejectionLoggingParameters)
                        other_params = filter(pairs(params)) do pair
                            !(pair.first in (:group, :location))
                        end
                        if $(bindings[:predicate])
                            @debug("@rejectif",
                                   _group = params.group,
                                   _file = $(string(bindings[:linenumbernode].file)),
                                   _line = $(bindings[:linenumbernode].line),
                                   predicate = $(QuoteNode(bindings[:predicate])),
                                   other_params...)
                            return
                        end
                    end
                end
            end),
    Rewrite(Expr(:macrocall, Symbol("@continueif"),
                 PatternVariable(:linenumbernode),
                 PatternVariable(:predicate)),
            function(bindings)
                quote
                    let
                        params = task_local_storage(:RuleRejectionLoggingParameters)
                        other_params = filter(pairs(params)) do pair
                            !(pair.first in (:group, :location))
                        end
                        if !$(bindings[:predicate])
                            @debug("@continueif",
                                   _group = params.group,
                                   _file = $(string(bindings[:linenumbernode].file)),
                                   _line = $(bindings[:linenumbernode].line),
                                   predicate = $(QuoteNode(bindings[:predicate])),
                                   other_params...)
                            return
                        end
                    end
                end
            end)
]


function rewrite_rule_body(body::Expr)
    MacroTools.postwalk(RULE_REWRITERS, body)
end

