
export kb_counts, kb_stats, copy_facts


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

