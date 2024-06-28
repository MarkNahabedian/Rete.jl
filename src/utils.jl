
export counting, collecting, kb_counts, kb_stats, copy_facts


"""
    counting(body)

Runs `body`, passing it a continuation of one argument (which is
ignored), that counts the number of times the continuation is called.
One `body` is fnished, `counting` returns that count.

As a special case, you can pass `counting` as the `continuation`
argument to `askc` to perform the `counting` aggregation.
"""
function counting(body)
    count = 0
    function counter(_)
        count += 1
    end
    body(counter)
    count
end

Rete.askc(f::typeof(counting), kb::ReteRootNode, q::Type) =
    f() do c
        askc(c, kb, q)
    end


"""
    collecting(body, t::Type = Any)

runs `body`, passing it a continuation of one argument that collects the
values it's called with. `collecting` returns those values.

As a special case, you can pass `collecting` as the `continuation`
argument to `askc` to perform the `collecting` aggregation.
"""
function collecting(body::Function, t::Type = Any)
    results = Vector{t}()
    function collect(thing)
        push!(results, thing)
    end
    body(collect)
    results
end

Rete.askc(f::typeof(collecting), kb::ReteRootNode, q::Type) =
    f() do c
        askc(c, kb, q)
    end


"""
    kb_counts(root::ReteRootNode)

Returns a `Dict{Type, Int}` of the number of facts of each type.
"""
function kb_counts(root::ReteRootNode)
    result = Dict{Type, Int}()
    function walk(node)
        if node isa IsaMemoryNode
            result[typeof(node).parameters[1]] = length(node.memory)
        end
        for o in node.outputs
            if o !== root
                walk(o)
            end
        end
    end
    walk(root)
    result
end


"""
    kb_stats(io, root)

Show the input count, output count, fact count and label for each
node.
"""
function kb_stats(io, node)
    stats = []
    walk_by_outputs(node) do node
        push!(stats, node)
    end
    stats = sort!(stats; by = label)
    @printf(io, "inputs \toutputs \tfacts \tlabel\n")
    for node in stats
        if fact_count(node) == nothing
            @printf(io, "%6d \t%6d \t       \t%s\n",
                    input_count(node),
                    output_count(node),
                    label(node))
        else
            @printf(io, "%6d \t%6d \t%6d \t%s\n",
                    input_count(node),
                    output_count(node),
                    fact_count(node),
                    label(node))
        end
    end
end

kb_stats(node) = kb_stats(stdout, node)


"""
    copy_facts(from_kb::ReteRootNode, to_kb::ReteRootNode, fact_types)

Copues facts if the specified `fact_type` from `from_kb` to `to_kb`.

for multiple fact types, one can broadcast over a collection of fact
types.
"""
function copy_facts(from_kb::ReteRootNode, to_kb::ReteRootNode,
                    fact_type)
    askc(from_kb, fact_type) do fact
        receive(to_kb, fact)
    end
end

